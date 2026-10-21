import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../../core/network/app_messenger.dart';
import '../../core/network/tradex_api_client.dart';

enum ConnectivityStatus { checking, online, offline }

class ConnectivityCubit extends Cubit<ConnectivityStatus>
    with WidgetsBindingObserver {
  ConnectivityCubit(this._apiClient, {Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      super(ConnectivityStatus.checking);

  final TradeXApiClient _apiClient;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _checking = false;
  bool _hasConnectivityState = false;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
    await check();
  }

  Future<void> check({bool forceSync = false}) async {
    final results = await _connectivity.checkConnectivity();
    await _onChanged(results, forceSync: forceSync);
  }

  Future<void> _onChanged(
    List<ConnectivityResult> results, {
    bool forceSync = false,
  }) async {
    if (isClosed) return;
    final noNetwork =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    if (noNetwork) {
      _setStatus(ConnectivityStatus.offline, forceSync: forceSync);
      return;
    }
    if (_checking) return;
    _checking = true;
    final reachable = await _apiClient.checkReachability();
    _checking = false;
    if (isClosed) return;
    _setStatus(
      reachable ? ConnectivityStatus.online : ConnectivityStatus.offline,
      forceSync: forceSync,
    );
  }

  void _setStatus(ConnectivityStatus next, {bool forceSync = false}) {
    final wasOffline = state == ConnectivityStatus.offline;
    final offline = next == ConnectivityStatus.offline;
    final shouldSync =
        !offline && (forceSync || !_hasConnectivityState || wasOffline);

    if (offline && !wasOffline) AppMessenger.showNoInternetConnection();
    if (!offline) {
      AppMessenger.markConnectionAvailable();
      if (shouldSync) unawaited(_syncOfflineChanges());
    }

    _hasConnectivityState = true;
    if (state != next) emit(next);
  }

  Future<void> _syncOfflineChanges() async {
    try {
      await _apiClient.syncOfflineMutations();
    } catch (_) {
      // A later connectivity event or app resume retries queued changes.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(check(forceSync: true));
    }
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    return super.close();
  }
}
