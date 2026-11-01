import '../entities/notification_entities.dart';

enum DeviceNotificationPermission {
  granted,
  denied,
  notDetermined,
  unsupported,
}

abstract interface class NotificationRepository {
  Future<NotificationFeed> feed(NotificationFeedFilter filter);
  Future<TradeXNotification> detail(String uuid);
  Future<int> markRead(String uuid);
  Future<int> markAllRead();
  Future<PushDeviceStatus> pushStatus();
  Future<NotificationPreferences> preferences();
  Future<void> savePreferences(NotificationPreferences value);
}

// Backwards-compatible contract name retained for existing callers.
abstract interface class NotificationDataSource
    implements NotificationRepository {}

abstract interface class NotificationPermissionRepository {
  Future<DeviceNotificationPermission> status();
  Future<DeviceNotificationPermission> request();
}
