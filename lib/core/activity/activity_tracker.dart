import 'dart:async';

import 'package:uuid/uuid.dart';

import '../network/api_exception.dart';
import 'activity_event_store.dart';

typedef ActivityAccountResolver = Future<String?> Function();
typedef ActivityAvailabilityProbe = Future<bool> Function();
typedef ActivityBatchSender = Future<void> Function(
  String accountUuid,
  List<Map<String, dynamic>> events,
);

/// Privacy-limited, best-effort mobile analytics.
///
/// Activity is disabled by the Laravel readiness API until the migration,
/// server configuration, and authenticated API are available. No financial
/// or security outcomes are inferred from client telemetry.
class ActivityTracker {
  factory ActivityTracker({
    required ActivityAccountResolver accountResolver,
    required ActivityAvailabilityProbe availabilityProbe,
    required ActivityBatchSender sendBatch,
    ActivityEventStore? store,
    bool enabled = const bool.fromEnvironment(
      'TRADEX_ACTIVITY_TRACKING_ENABLED',
      defaultValue: true,
    ),
    DateTime Function()? clock,
  }) => ActivityTracker._(
    accountResolver,
    availabilityProbe,
    sendBatch,
    store ?? ActivityEventStore(),
    clock ?? DateTime.now,
    enabled,
  );

  ActivityTracker._(
    this._accountResolver,
    this._availabilityProbe,
    this._sendBatch,
    this._store,
    this._clock,
    this.enabled,
  );

  final ActivityAccountResolver _accountResolver;
  final ActivityAvailabilityProbe _availabilityProbe;
  final ActivityBatchSender _sendBatch;
  final ActivityEventStore _store;
  final DateTime Function() _clock;
  final bool enabled;
  final Uuid _uuid = const Uuid();

  static const modules = <String>{
    'app',
    'learning',
    'trade_ideas',
    'journal',
    'calculator',
    'news',
    'funded_accounts',
    'copy_trading',
    'investments',
    'affiliate',
    'support',
    'profile',
  };
  static const events = <String>{
    'screen_viewed',
    'lesson_viewed',
    'lesson_completed',
    'signal_viewed',
    'journal_opened',
    'journal_saved',
    'calculator_used',
    'news_viewed',
    'feature_opened',
    'session_started',
    'session_heartbeat',
    'session_resumed',
    'session_paused',
    'session_ended',
  };

  String? _accountId;
  String? _visitId;
  bool _foreground = true;
  bool _backendReady = false;
  DateTime? _nextProbeAt;
  Future<bool>? _probeInFlight;
  Future<void>? _syncing;
  Timer? _timer;

  bool get isActive => enabled && _accountId != null && _backendReady;

  Future<void> activate() async {
    if (!enabled) return;

    String? userId;
    try {
      userId = await _accountResolver();
    } catch (_) {
      return;
    }
    if (userId == null ||
        !RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(userId)) {
      return;
    }

    if (_accountId == userId) {
      await sync();
      return;
    }

    _timer?.cancel();
    final previous = _accountId;
    _accountId = userId;
    _visitId = _uuid.v4();
    _backendReady = false;
    _nextProbeAt = null;
    _foreground = true;

    if (previous != null) {
      try {
        await _store.clear(previous);
      } catch (_) {
        // An unexpected account switch must never block login.
      }
    }

    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (isActive && _foreground) {
        track('app', 'session_heartbeat');
      }
      unawaited(sync().catchError((Object _) {}));
    });

    try {
      await sync();
    } catch (_) {
      // Analytics is never part of the authentication success condition.
    }
  }

  /// Deactivate before revoking a device session; purge pending telemetry on
  /// sign out so a future account can never inherit another user's queue.
  Future<void> deactivate() async {
    final account = _accountId;
    if (account == null) return;
    _timer?.cancel();
    _timer = null;

    try {
      if (_foreground && _backendReady) {
        try {
          await _enqueue('app', 'session_ended');
        } catch (_) {
          // Do not delay sign out on a storage error.
        }
      }
      try {
        await sync().timeout(const Duration(milliseconds: 750));
      } catch (_) {
        // Offline/slow analytics must not delay device revocation.
      }
    } finally {
      _accountId = null;
      _visitId = null;
      _backendReady = false;
      _nextProbeAt = null;
      try {
        await _store.clear(account);
      } catch (_) {
        // Authentication state is independent of telemetry state.
      }
    }
  }

  void track(String module, String eventName, {String? subjectId}) {
    if (!isActive || !_foreground) return;
    unawaited(
      _enqueue(module, eventName, subjectId: subjectId)
          .catchError((Object _) {}),
    );
  }

  void view(String module, String screen) {
    track(module, 'screen_viewed', subjectId: screen);
  }

  void openedFeature(String id) {
    track('app', 'feature_opened', subjectId: id.replaceAll('-', '_'));
  }

  void onBackground() {
    if (!_foreground) return;
    if (isActive) track('app', 'session_paused');
    _foreground = false;
  }

  void onForeground() {
    if (_foreground) return;
    _foreground = true;
    if (isActive) track('app', 'session_resumed');
    unawaited(sync().catchError((Object _) {}));
  }

  Future<void> _enqueue(
    String module,
    String eventName, {
    String? subjectId,
  }) async {
    final account = _accountId;
    if (!isActive ||
        account == null ||
        !modules.contains(module) ||
        !events.contains(eventName)) {
      return;
    }
    if (subjectId != null &&
        !RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(subjectId)) {
      return;
    }

    final event = <String, dynamic>{
      'event_id': _uuid.v4(),
      'module': module,
      'event_name': eventName,
      'session_id': _visitId,
      'occurred_at': _clock().toUtc().toIso8601String(),
    };
    if (subjectId != null) event['subject_id'] = subjectId;
    await _store.append(account, event);
  }

  Future<bool> _ensureReady(String account) async {
    if (_accountId != account || !enabled) return false;
    if (_backendReady) return true;
    if (_nextProbeAt != null && _clock().isBefore(_nextProbeAt!)) {
      return false;
    }
    final inFlight = _probeInFlight;
    if (inFlight != null) return inFlight;

    final operation = _probe(account);
    _probeInFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_probeInFlight, operation)) _probeInFlight = null;
    }
  }

  Future<bool> _probe(String account) async {
    var ready = false;
    try {
      ready = await _availabilityProbe();
    } catch (_) {
      // Backend not deployed, user offline, or auth token not yet refreshed.
    }
    if (_accountId != account || !_foreground) return false;
    if (!ready) {
      _nextProbeAt = _clock().add(const Duration(minutes: 2));
      return false;
    }

    _backendReady = true;
    _nextProbeAt = null;
    try {
      await _enqueue('app', 'session_started');
      await _enqueue('app', 'screen_viewed', subjectId: 'dashboard_home');
    } catch (_) {
      // No user-visible failure when secure telemetry storage is unavailable.
    }
    return true;
  }

  Future<void> sync() async {
    final account = _accountId;
    if (!enabled || account == null || !_foreground) return;
    final ongoing = _syncing;
    if (ongoing != null) {
      await ongoing;
      return;
    }

    final operation = _syncPending(account);
    _syncing = operation;
    try {
      await operation;
    } finally {
      if (identical(_syncing, operation)) _syncing = null;
    }
  }

  Future<void> _syncPending(String account) async {
    if (!await _ensureReady(account)) return;
    if (_accountId != account || !_foreground) return;

    final pending = await _store.pending(account);
    for (var i = 0; i < pending.length; i += 25) {
      if (_accountId != account || !_foreground || !_backendReady) return;
      final batch = pending.skip(i).take(25).toList();
      try {
        // The API client verifies that the current Sanctum session belongs
        // to this exact user before sending the batch.
        await _sendBatch(account, batch);
        if (_accountId != account) return;
        await _store.remove(
          account,
          batch.map((e) => e['event_id'] as String).toSet(),
        );
      } on ApiException catch (error) {
        if (error.statusCode == 404 ||
            error.statusCode == 403 ||
            (error.statusCode == 503 &&
                error.code == 'ACTIVITY_DISABLED')) {
          _backendReady = false;
          _nextProbeAt = _clock().add(const Duration(minutes: 2));
          try {
            await _store.clear(account);
          } catch (_) {}
        } else if (error.statusCode == 400 || error.statusCode == 422) {
          await _store.remove(
            account,
            batch.map((e) => e['event_id'] as String).toSet(),
          );
          continue;
        }
        return; // Temporary failures are retried on reconnect/resume/timer.
      } catch (_) {
        return;
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
