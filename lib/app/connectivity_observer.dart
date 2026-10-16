import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../core/network/app_messenger.dart';

class ConnectivityObserver extends StatefulWidget {
  const ConnectivityObserver({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityObserver> createState() => _ConnectivityObserverState();
}

class _ConnectivityObserverState extends State<ConnectivityObserver> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    _onChanged(connectivity);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);

    if (offline && !_wasOffline) {
      AppMessenger.showNoInternetConnection();
    }

    if (!offline) {
      AppMessenger.markConnectionAvailable();
    }

    _wasOffline = offline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
