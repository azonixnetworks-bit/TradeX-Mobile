import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/tradex_colors.dart';

Uri tradingViewUrlForSymbol(String symbol) {
  final normalized = symbol.trim().toUpperCase().replaceAll('/', '');
  return Uri.https('s.tradingview.com', '/widgetembed/', {
    'symbol': 'BINANCE:$normalized',
    'interval': '60',
    'theme': 'dark',
    'style': '1',
    'timezone': 'Etc/UTC',
    'locale': 'en',
    'hidesidetoolbar': '1',
    'symboledit': '0',
    'saveimage': '0',
    'hideideas': '1',
    'withdateranges': '1',
    'studies': '[]',
  });
}

class TradingViewChartScreen extends StatefulWidget {
  const TradingViewChartScreen({super.key, required this.symbol});

  final String symbol;

  @override
  State<TradingViewChartScreen> createState() => _TradingViewChartScreenState();
}

class _TradingViewChartScreenState extends State<TradingViewChartScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_enterLandscape());
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(TradeXColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host.toLowerCase() ?? '';
            return host == 's.tradingview.com' ||
                    host == 'www.tradingview.com' ||
                    host.endsWith('.tradingview.com')
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(tradingViewUrlForSymbol(widget.symbol));
  }

  Future<void> _enterLandscape() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restorePortrait() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    unawaited(_restorePortrait());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (_, _) => unawaited(_restorePortrait()),
    child: Scaffold(
      backgroundColor: TradeXColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(
              key: const ValueKey('crypto-tradingview-chart'),
              controller: _controller,
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .72),
                  shape: BoxShape.circle,
                  border: Border.all(color: TradeXColors.borderStrong),
                ),
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: TradeXColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: SafeArea(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: TradeXColors.borderStrong),
                    ),
                    child: Text(
                      '${widget.symbol.toUpperCase()} · TradingView',
                      style: const TextStyle(
                        color: TradeXColors.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: TradeXColors.goldBright,
                strokeWidth: 2.4,
              ),
            ),
        ],
      ),
    ),
  );
}
