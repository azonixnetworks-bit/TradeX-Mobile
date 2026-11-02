import 'dart:async';

import 'package:uuid/uuid.dart';

import '../network/api_exception.dart';
import 'activity_event_store.dart';

typedef ActivityAccountResolver = Future<String?> Function();
typedef ActivityBatchSender = Future<void> Function(
  List<Map<String, dynamic>> events,
);

/// Best-effort analytics: never an authority for money, authentication,
/// entitlements, journal mutations or security-sensitive actions.
class ActivityTracker {
  factory ActivityTracker({
    required ActivityAccountResolver accountResolver,
    required ActivityBatchSender sendBatch,
    ActivityEventStore? store,
    bool enabled = const bool.fromEnvironment(
      'TRADEX_ACTIVITY_TRACKING_ENABLED',
      defaultValue: false,
    ),
    DateTime Function()? clock,
  }) => ActivityTracker._(
    accountResolver,
    sendBatch,
    store ?? ActivityEventStore(),
    clock ?? DateTime.now,
    enabled,
  );

  ActivityTracker._(
    this._accountResolver,
    this._sendBatch,
    this._store,
    this._clock,
    this.enabled,
  );

  final ActivityAccountResolver _accountResolver;
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
    'session_resumed',
    'session_paused',
    'session_ended',
  };

  String? _accountId;
  String? _visitId;
  bool _foreground = true;
  bool _endpointUnavailable = false;
  Future<void>? _syncing;
  Timer? _timer;

  bool get isActive => enabled && _accountId != null;

  Future<void> activate() async {
    if (!enabled) return;
    String? userId;
    try {
      userId = await _accountResolver();
    } catch (_) {
      return; // Telemetry failures cannot break authentication.
    }
    if (userId == null || !RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(userId)) {
      return;
    }
    if (_accountId == userId) return;
    _timer?.cancel();
    _accountId = userId;
    _visitId = _uuid.v4();
    _foreground = true;
    try {
      await _enqueue('app', 'session_started');
    } catch (_) {
      // Secure-storage failures must not affect login or navigation.
    }
    try {
      await _enqueue('app', 'screen_viewed', subjectId: 'dashboard_home');
    } catch (_) {
      // Best effort only.
    }
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      unawaited(sync().catchError((Object _) {}));
    });
    unawaited(sync().catchError((Object _) {}));
  }

  /// Call after login/logout succeeds at the session gate, never on app start
  /// while a remembered account is still awaiting biometric/PIN unlock.
  Future<void> deactivate() async {
    final account = _accountId;
    if (account == null) return;
    _timer?.cancel();
    _timer = null;
    try {
      if (_foreground) {
        try {
          await _enqueue('app', 'session_ended');
        } catch (_) {
          // Telemetry storage failures never block logout.
        }
      }
      try {
        await sync().timeout(const Duration(milliseconds: 750));
      } catch (_) {
        // A short best-effort flush is enough.
      }
    } finally {
      _accountId = null;
      _visitId = null;
      try {
        await _store.clear(account);
      } catch (_) {
        // Sign-out must always complete.
      }
    }
  }

  void track(String module, String eventName, {String? subjectId}) {
    if (!isActive || !_foreground) return;
    unawaited(
      _enqueue(
        module,
        eventName,
        subjectId: subjectId,
      ).catchError((Object _) {}),
    );
  }

  void view(String module, String screen) {
    track(module, 'screen_viewed', subjectId: screen);
  }

  void openedFeature(String id) {
    // Feature identifiers come from the app's static feature catalogue.
    final normalized = id.replaceAll('-', '_');
    track('app', 'feature_opened', subjectId: normalized);
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
    if (!enabled ||
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

  Future<void> sync() async {
    if (!isActive || !_foreground || _endpointUnavailable) return;
    final ongoing = _syncing;
    if (ongoing != null) {
      await ongoing;
      return;
    }
    final operation = _syncPending(_accountId!);
    _syncing = operation;
    try {
      await operation;
    } finally {
      if (identical(_syncing, operation)) _syncing = null;
    }
  }

  Future<void> _syncPending(String account) async {
    if (_accountId != account) return;
    final pending = await _store.pending(account);
    for (var i = 0; i < pending.length; i += 25) {
      if (_accountId != account || !_foreground) return;
      final batch = pending.skip(i).take(25).toList();
      try {
        await _sendBatch(batch);
        await _store.remove(
          account,
          batch.map((e) => e['event_id'] as String).toSet(),
        );
      } on ApiException catch (error) {
        if (error.statusCode == 404 || error.statusCode == 403) {
          // Backend feature branch has not shipped or was disabled.
          _endpointUnavailable = true;
        } else if (error.statusCode == 400 || error.statusCode == 422) {
          // Permanently invalid batch; do not retry indefinitely.
          await _store.remove(
            account,
            batch.map((e) => e['event_id'] as String).toSet(),
          );
          continue;
        }
        return; // Offline, rate-limited, auth failure or 5xx: retry later.
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
