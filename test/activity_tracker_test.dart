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

  test(
    'encrypted outbox is isolated per account and retry-idempotent',
    () async {
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
    },
  );

  test('offline analytics retry without interrupting user actions', () async {
    final store = ActivityEventStore();
    var offline = true;
    final uploaded = <Map<String, dynamic>>[];

    final tracker = ActivityTracker(
      enabled: true,
      accountResolver: () async => 'account_a',
      store: store,
      sendBatch: (batch) async {
        if (offline) {
          throw const ApiException(
            message: 'No connection',
            code: 'NO_INTERNET',
          );
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

  test(
    'only allowlisted event names and safe subject IDs are stored',
    () async {
      final store = ActivityEventStore();
      final tracker = ActivityTracker(
        enabled: true,
        accountResolver: () async => 'account_a',
        store: store,
        sendBatch: (_) async {
          throw const ApiException(message: 'offline');
        },
      );
      await tracker.activate();
      tracker.track('app', 'payment_approved');
      tracker.track(
        'learning',
        'lesson_viewed',
        subjectId: 'Email: secret@x.io',
      );
      tracker.track('learning', 'lesson_viewed', subjectId: 'safe_lesson');
      await tracker.sync();

      final events = await store.pending('account_a');
      expect(
        events.where((event) => event['event_name'] == 'payment_approved'),
        isEmpty,
      );
      expect(
        events.where((event) => event['subject_id'] == 'safe_lesson'),
        hasLength(1),
      );
      expect(
        events.where((event) => event['subject_id'] == 'Email: secret@x.io'),
        isEmpty,
      );
      tracker.dispose();
    },
  );

  test('feature flag disables all tracking and uploads', () async {
    var sends = 0;
    final tracker = ActivityTracker(
      enabled: false,
      accountResolver: () async => 'account_a',
      sendBatch: (_) async {
        sends++;
      },
    );
    await tracker.activate();
    tracker.view('app', 'dashboard_home');
    await tracker.sync();
    expect(tracker.isActive, isFalse);
    expect(sends, 0);
    tracker.dispose();
  });
}
