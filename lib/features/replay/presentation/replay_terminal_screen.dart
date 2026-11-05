import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tradex_colors.dart';
import 'bloc/replay_terminal_cubit.dart';

/// Phase 05.6: an isolated, VISUAL-ONLY local replay terminal inside TradeX.
/// Full Python TradeSimulator execution parity and authorized broker history
/// are NOT integrated: no virtual or real orders may be submitted here.
class ReplayTerminalScreen extends StatefulWidget {
  const ReplayTerminalScreen({super.key});

  @override
  State<ReplayTerminalScreen> createState() => _ReplayTerminalScreenState();
}

class _ReplayTerminalScreenState extends State<ReplayTerminalScreen>
    with WidgetsBindingObserver {
  static const _assetDir = 'assets/replay_terminal';
  late final ReplayTerminalCubit _cubit;
  WebViewController? _controller;
  bool _landscape = false;

  @override
  void initState() {
    super.initState();
    _cubit = ReplayTerminalCubit();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final manifestText = await rootBundle.loadString('$_assetDir/bundle_manifest.json');
      final parsed = jsonDecode(manifestText);
      if (parsed is! Map<String, dynamic> ||
          parsed['contract_version'] != 1 ||
          parsed['built'] != true) {
        if (!_cubit.isClosed) _cubit.missingBundle();
        return;
      }
      final files = parsed['files'];
      if (files is! List || files.length < 2 || files.length > 12) {
        throw const FormatException('Replay bundle manifest is invalid');
      }
      final seen = <String>{};
      for (final entry in files) {
        if (entry is! Map<String, dynamic>) throw const FormatException('Invalid bundle entry');
        final name = entry['name'];
        final digest = entry['sha256'];
        if (name is! String ||
            !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(name) ||
            name.contains('..') ||
            digest is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
            !seen.add(name)) {
          throw const FormatException('Unsafe replay bundle asset');
        }
        final bytes = await rootBundle.load('$_assetDir/$name');
        final data = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
        if (sha256.convert(data).toString() != digest) {
          throw const FormatException('Replay chart asset integrity mismatch');
        }
      }
      if (!seen.contains('index.html')) throw const FormatException('Missing terminal entry page');
      if (!mounted) return;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF050706))
        ..addJavaScriptChannel('TradeXReplayChannel',
          onMessageReceived: (message) {
            if (!_cubit.isClosed) _cubit.receiveMessage(message.message);
          },
        )
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme == 'https' &&
                <String>{'tradingview.com', 'www.tradingview.com'}.contains(uri.host)) {
              unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
              return NavigationDecision.prevent;
            }
            final trustedLocal = uri != null &&
                ((uri.scheme == 'about' && uri.path == 'blank') ||
                 (uri.scheme == 'file' && uri.path.contains('/replay_terminal/')) ||
                 (uri.scheme == 'https' &&
                  uri.host == 'appassets.androidplatform.net' &&
                  uri.path.contains('/replay_terminal/')));
            return trustedLocal
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && !_cubit.isClosed) {
              _cubit.failed('The local replay chart could not be opened.');
            }
          },
        ));
      setState(() => _controller = controller);
      await controller.loadFlutterAsset('$_assetDir/index.html');
      // A missing/failed JS bundle must not leave a permanent spinner.
      unawaited(Future<void>.delayed(const Duration(seconds: 20)).then((_) {
        if (mounted && !_cubit.isClosed &&
            _cubit.state.phase == ReplayTerminalPhase.loading) {
          _cubit.failed('Replay terminal did not complete its versioned handshake.');
        }
      }));
    } catch (_) {
      if (!_cubit.isClosed) {
        _cubit.failed('Replay assets failed integrity or loading checks. '
            'Rebuild the terminal bundle and reinstall the app.');
      }
    }
  }

  Future<void> _command(String type) async {
    final controller = _controller;
    if (controller == null || _cubit.state.phase != ReplayTerminalPhase.ready) return;
    final payload = jsonEncode(_cubit.nextCommand(type));
    try {
      // Commands contain only fixed enum names and server-independent IDs.
      await controller.runJavaScript('''
        (() => {
          const result = window.TradeXReplayTerminal?.send($payload);
          if (result && !result.ok) {
            window.TradeXReplayChannel?.postMessage(JSON.stringify({
              version: 1, type: 'COMMAND_ERROR', payload: {
                message: String(result.error || 'Command rejected').slice(0, 150)
              }
            }));
          }
        })();
      ''');
    } catch (_) {
      if (!_cubit.isClosed) _cubit.failed('Replay WebView command failed.');
    }
  }

  Future<void> _toggleOrientation() async {
    if (!mounted) return;
    final next = !_landscape;
    try {
      await SystemChrome.setPreferredOrientations(next
          ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : const [DeviceOrientation.portraitUp]);
      if (next) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      if (mounted) setState(() => _landscape = next);
    } catch (_) {
      // Orientation changes can be restricted by the operating system.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_command('PAUSE'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_command('PAUSE'));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]));
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocBuilder<ReplayTerminalCubit, ReplayTerminalState>(
      builder: (context, state) {
        final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
        return Scaffold(
          backgroundColor: const Color(0xFF050706),
          appBar: isLandscape ? null : AppBar(
            backgroundColor: const Color(0xFF0D1110),
            foregroundColor: TradeXColors.primaryText,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TradeX Replay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text('XAUUSD · Visual-only demo', style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Pause replay',
                icon: const Icon(Icons.pause_rounded),
                onPressed: state.phase == ReplayTerminalPhase.ready ? () => _command('PAUSE') : null,
              ),
              IconButton(
                tooltip: 'Rotate fullscreen',
                icon: const Icon(Icons.screen_rotation_rounded),
                onPressed: _toggleOrientation,
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(children: [
              if (_controller != null &&
                  (state.phase == ReplayTerminalPhase.loading ||
                   state.phase == ReplayTerminalPhase.ready))
                WebViewWidget(controller: _controller!),
              if (state.phase == ReplayTerminalPhase.loading)
                const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
              if (state.phase == ReplayTerminalPhase.unavailable ||
                  state.phase == ReplayTerminalPhase.error)
                Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.layers_clear_rounded, color: Color(0xFFD4AF37), size: 46),
                      const SizedBox(height: 16),
                      const Text('Replay Terminal Unavailable',
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(state.message ?? 'Chart assets are unavailable.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFBDC4B9), fontSize: 13)),
                      const SizedBox(height: 12),
                      const Text('No broker trades or virtual positions were changed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFE0BA59), fontSize: 12)),
                    ]),
                  ),
                )),
              if (isLandscape)
                Positioned(top: 4, right: 4, child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xDD111614),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: 'Pause replay',
                      icon: const Icon(Icons.pause_rounded, color: Color(0xFFD4AF37)),
                      onPressed: state.phase == ReplayTerminalPhase.ready ? () => _command('PAUSE') : null,
                    ),
                    IconButton(
                      tooltip: 'Return to portrait',
                      icon: const Icon(Icons.screen_rotation_rounded, color: Colors.white),
                      onPressed: _toggleOrientation,
                    ),
                    IconButton(
                      tooltip: 'Exit replay',
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ]),
                )),
            ]),
          ),
          bottomNavigationBar: isLandscape || state.phase != ReplayTerminalPhase.ready
              ? null
              : Container(
                  color: const Color(0xFF0D1110),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: SafeArea(
                    top: false,
                    child: Row(children: [
                      const Icon(Icons.science_outlined, color: Color(0xFFD4AF37), size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        state.isSynthetic ? 'SYNTHETIC DEMO · NO TRADES' : 'UNVERIFIED DATA · NO TRADES',
                        style: const TextStyle(color: Color(0xFFE6C878), fontSize: 10),
                      )),
                      Text(state.timeframe, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      IconButton(
                        tooltip: 'Step next M1 candle',
                        icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFD4AF37)),
                        onPressed: () => _command('STEP'),
                      ),
                    ]),
                  ),
                ),
        );
      },
    ),
  );
}
