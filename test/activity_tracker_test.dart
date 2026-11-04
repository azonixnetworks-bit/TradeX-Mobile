import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tradex_mobile/core/activity/activity_event_store.dart';
import 'package:tradex_mobile/core/activity/activity_tracker.dart';
import 'package:tradex_mobile/core/network/api_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('encrypted outbox is isolated per account and retry-idempotent', () async {
    final store = ActivityEventStore();
    final event = <String, dynamic>{
      'event_id': '4d57f24d-55c3-41b5-94f6-d2c24dc1cd83',
      'module': 'learning',
      'event_name': 'screen_viewed',
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    };

    await store.append('account_a', event);
    await store.append('account_a', event);
    expect(await store.pending('account_a'), hasLength(1));
    expect(await store.pending('account_b'), isEmpty);

    await store.append('account_b', event);
    await store.clear('account_a');
    expect(await store.pending('account_a'), isEmpty);
    expect(await store.pending('account_b'), hasLength(1));
  });

  test('unready backend causes no event collection or transmission', () async {
    final store = ActivityEventStore();
    var ready = false;
    var clock = DateTime.now().toUtc();
    final sent = <Map<String, dynamic>>[];
    final tracker = ActivityTracker(
      enabled: true,
      accountResolver: () async => 'account_a',
      availabilityProbe: () async => ready,
      clock: () => clock,
      store: store,
      sendBatch: (_, batch) async => sent.addAll(batch),
    );

    await tracker.activate();
    tracker.track('learning', 'lesson_viewed', subjectId: 'lesson_1');
    expect(tracker.isActive, isFalse);
    expect(await store.pending('account_a'), isEmpty);
    expect(sent, isEmpty);

    ready = true;
    clock = clock.add(const Duration(minutes: 3));
    await tracker.sync();
    expect(tracker.isActive, isTrue);
    expect(sent.map((event) => event['event_name']), contains('session_started'));
    tracker.dispose();
  });

  test('offline events retry silently after backend readiness', () async {
    final store = ActivityEventStore();
    var offline = true;
    final uploaded = <Map<String, dynamic>>[];
    final tracker = ActivityTracker(
      enabled: true,
      accountResolver: () async => 'account_a',
      availabilityProbe: () async => true,
      store: store,
      sendBatch: (_, batch) async {
        if (offline) {
          throw const ApiException(message: 'No connection', code: 'NO_INTERNET');
        }
        uploaded.addAll(batch);
      },
    );

    await tracker.activate();
    tracker.view('learning', 'dashboard_learn');
    tracker.track('trade_ideas', 'signal_viewed', subjectId: 'idea_uuid');
    await tracker.sync();
    expect(await store.pending('account_a'), isNotEmpty);

    offline = false;
    await tracker.sync();
    final names = uploaded.map((event) => event['event_name']).toList();
    expect(names, contains('session_started'));
    expect(names, contains('screen_viewed'));
    expect(names, contains('signal_viewed'));
    expect(await store.pending('account_a'), isEmpty);

    await tracker.deactivate();
    expect(tracker.isActive, isFalse);
    tracker.dispose();
  });

  test('allowlist blocks client asserted financial events and PII', () async {
    final store = ActivityEventStore();
    final tracker = ActivityTracker(
      enabled: true,
      accountResolver: () async => 'account_a',
      availabilityProbe: () async => true,
      store: store,
      sendBatch: (_, _) async {
        throw const ApiException(message: 'offline');
      },
    );
    await tracker.activate();
    tracker.track('app', 'payment_approved');
    tracker.track('learning', 'lesson_viewed', subjectId: 'Email: secret@x.io');
    tracker.track('learning', 'lesson_viewed', subjectId: 'safe_lesson');
    await tracker.sync();

    final events = await store.pending('account_a');
    expect(events.where((event) => event['event_name'] == 'payment_approved'), isEmpty);
    expect(events.where((event) => event['subject_id'] == 'safe_lesson'), hasLength(1));
    expect(events.where((event) => event['subject_id'] == 'Email: secret@x.io'), isEmpty);
    tracker.dispose();
  });

  testWidgets('foreground heartbeat is emitted but background is quiet', (tester) async {
    final store = ActivityEventStore();
    final emitted = <String>[];
    final tracker = ActivityTracker(
      enabled: true,
      accountResolver: () async => 'account_heartbeat',
      availabilityProbe: () async => true,
      store: store,
      sendBatch: (_, batch) async {
        emitted.addAll(batch.map((event) => event['event_name'] as String));
      },
    );

    await tracker.activate();
    await tester.pump(const Duration(minutes: 2));
    await tracker.sync();
    expect(emitted, contains('session_heartbeat'));

    final beforeBackground = emitted.where(
      (name) => name == 'session_heartbeat',
    ).length;
    tracker.onBackground();
    await tester.pump(const Duration(minutes: 4));
    tracker.onForeground();
    await tracker.sync();
    final afterBackground = emitted.where(
      (name) => name == 'session_heartbeat',
    ).length;
    expect(afterBackground, beforeBackground);
    tracker.dispose();
  });

  test('feature opt-out prevents all tracking and probes', () async {
    var probes = 0;
    var sends = 0;
    final tracker = ActivityTracker(
      enabled: false,
      accountResolver: () async => 'account_a',
      availabilityProbe: () async {
        probes++;
        return true;
      },
      sendBatch: (_, _) async {
        sends++;
      },
    );
    await tracker.activate();
    tracker.view('app', 'dashboard_home');
    await tracker.sync();
    expect(tracker.isActive, isFalse);
    expect(probes, 0);
    expect(sends, 0);
    tracker.dispose();
  });

  test('server disable response suspends events and clears pending queue', () async {
    final store = ActivityEventStore();
    var disabled = false;
    var clock = DateTime.now().toUtc();
    final tracker = ActivityTracker(
      enabled: true,
      clock: () => clock,
      accountResolver: () async => 'account_a',
      availabilityProbe: () async => !disabled,
      store: store,
      sendBatch: (_, _) async {
        disabled = true;
        throw const ApiException(
          message: 'disabled',
          statusCode: 503,
          code: 'ACTIVITY_DISABLED',
        );
      },
    );

    await tracker.activate();
    expect(tracker.isActive, isFalse);
    expect(await store.pending('account_a'), isEmpty);

    clock = clock.add(const Duration(minutes: 3));
    await tracker.sync();
    expect(tracker.isActive, isFalse);
    tracker.dispose();
  });

  test('batched sync never sends more than 25 events per request', () async {
    final store = ActivityEventStore();
    var online = false;
    final sizes = <int>[];
    final tracker = ActivityTracker(
      enabled: true,
      accountResolver: () async => 'account_a',
      availabilityProbe: () async => true,
      store: store,
      sendBatch: (_, batch) async {
        if (!online) throw const ApiException(message: 'offline');
        sizes.add(batch.length);
      },
    );

    await tracker.activate();
    for (var index = 0; index < 51; index++) {
      tracker.track('app', 'screen_viewed', subjectId: 'screen_$index');
    }
    await tracker.sync();
    online = true;
    await tracker.sync();

    expect(sizes, isNotEmpty);
    expect(sizes.every((size) => size <= 25), isTrue);
    expect(await store.pending('account_a'), isEmpty);
    tracker.dispose();
  });

  test('changing accounts does not upload first user events as second user', () async {
    final store = ActivityEventStore();
    var account = 'account_a';
    final transmissions = <String>[];
    final tracker = ActivityTracker(
      enabled: true,
      accountResolver: () async => account,
      availabilityProbe: () async => true,
      store: store,
      sendBatch: (accountId, batch) async {
        transmissions.add(accountId);
      },
    );

    await tracker.activate();
    account = 'account_b';
    await tracker.activate();

    expect(transmissions, contains('account_a'));
    expect(transmissions, contains('account_b'));
    expect(await store.pending('account_a'), isEmpty);
    tracker.dispose();
  });
}
