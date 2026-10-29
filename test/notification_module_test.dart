import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/notifications/data/notification_repository.dart';
import 'package:tradex_mobile/features/notifications/domain/notification_models.dart';
import 'package:tradex_mobile/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:tradex_mobile/features/notifications/presentation/notification_module.dart';

void main() {
  test('notification model preserves dynamic server fields', () {
    final item = TradeXNotification.fromJson({
      'uuid': 'receipt-1',
      'notification_uuid': 'message-1',
      'category': 'TRADE_IDEA',
      'priority': 'HIGH',
      'title': 'EUR/USD entry triggered',
      'body': 'Entry conditions were met.',
      'action': {'type': 'TRADE_IDEA', 'resource_uuid': 'idea-1'},
      'is_read': false,
      'published_at': '2026-10-28T12:00:00Z',
    });

    expect(item.uuid, 'receipt-1');
    expect(item.title, 'EUR/USD entry triggered');
    expect(item.isTrading, isTrue);
    expect(item.hasAction, isTrue);
    expect(item.actionResourceUuid, 'idea-1');
  });

  test('cubit uses server filters and updates read state', () async {
    final repository = _FakeNotificationRepository();
    final cubit = NotificationCubit(repository);

    await cubit.initialize();
    expect(repository.lastFilter, NotificationFeedFilter.all);
    expect(cubit.state.unreadCount, 1);

    await cubit.selectFilter(NotificationFeedFilter.trading);
    expect(repository.lastFilter, NotificationFeedFilter.trading);

    await cubit.markRead('receipt-1');
    expect(cubit.state.items.single.isRead, isTrue);
    expect(cubit.state.unreadCount, 0);

    await cubit.close();
  });

  testWidgets('center renders dynamic data and opens details', (tester) async {
    final repository = _FakeNotificationRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: NotificationCenterScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('EUR/USD entry triggered'), findsOneWidget);
    expect(find.text('1 new notification'), findsOneWidget);

    await tester.tap(find.text('EUR/USD entry triggered'));
    await tester.pumpAndSettle();

    expect(find.text('Notification details'), findsOneWidget);
    expect(find.text('Entry conditions were met.'), findsOneWidget);
  });
}

class _FakeNotificationRepository implements NotificationDataSource {
  NotificationFeedFilter? lastFilter;
  bool read = false;

  TradeXNotification get item => TradeXNotification(
    uuid: 'receipt-1',
    notificationUuid: 'message-1',
    category: 'TRADE_IDEA',
    priority: 'HIGH',
    title: 'EUR/USD entry triggered',
    body: 'Entry conditions were met.',
    actionType: 'TRADE_IDEA',
    actionResourceUuid: 'idea-1',
    isRead: read,
    publishedAt: DateTime.now(),
  );

  @override
  Future<NotificationFeed> feed(NotificationFeedFilter filter) async {
    lastFilter = filter;
    return NotificationFeed(
      items: [item],
      unreadCount: read ? 0 : 1,
      total: 1,
      currentPage: 1,
      lastPage: 1,
    );
  }

  @override
  Future<TradeXNotification> detail(String uuid) async => item;

  @override
  Future<int> markAllRead() async {
    read = true;
    return 0;
  }

  @override
  Future<int> markRead(String uuid) async {
    read = true;
    return 0;
  }

  @override
  Future<NotificationPreferences> preferences() async =>
      const NotificationPreferences();

  @override
  Future<void> savePreferences(NotificationPreferences value) async {}

  @override
  Future<PushDeviceStatus> pushStatus() async =>
      const PushDeviceStatus.unavailable();
}
