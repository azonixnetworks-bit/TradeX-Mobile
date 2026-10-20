import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../core/network/app_messenger.dart';
import '../core/network/tradex_api_client.dart';

class ConnectivityObserver extends StatefulWidget {
  const ConnectivityObserver({
    super.key,
    required this.child,
    required this.apiClient,
  });

  final Widget child;
  final TradeXApiClient apiClient;

  @override
  State<ConnectivityObserver> createState() => _ConnectivityObserverState();
}

class _ConnectivityObserverState extends State<ConnectivityObserver>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _healthTimer;
  bool _wasOffline = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
    _checkInitialConnectivity();
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkInitialConnectivity(),
    );
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    _onChanged(connectivity);
  }

  Future<void> _onChanged(List<ConnectivityResult> results) async {
    final noNetwork =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    if (noNetwork) {
      _setOffline(true);
      return;
    }
    if (_checking) return;
    _checking = true;
    final reachable = await widget.apiClient.checkReachability();
    _checking = false;
    if (!mounted) return;
    _setOffline(!reachable);
  }

  void _setOffline(bool offline) {
    if (offline && !_wasOffline) {
      AppMessenger.showNoInternetConnection();
    }

    if (!offline) {
      AppMessenger.markConnectionAvailable();
      unawaited(widget.apiClient.syncOfflineMutations());
    }

    if (mounted && offline != _wasOffline) {
      setState(() => _wasOffline = offline);
    } else {
      _wasOffline = offline;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkInitialConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _healthTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_wasOffline)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              color: const Color(0xFFE2A72E),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        IconData(0xe37c, fontFamily: 'MaterialIcons'),
                        size: 16,
                        color: Color(0xFF101612),
                      ),
                      SizedBox(width: 7),
                      Text(
                        "You're offline — showing saved data",
                        style: TextStyle(
                          color: Color(0xFF101612),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
