import 'package:flutter/services.dart';

import '../../domain/repositories/notification_repository.dart';

class NotificationPermissionService
    implements NotificationPermissionRepository {
  const NotificationPermissionService();

  static const MethodChannel _channel = MethodChannel(
    'com.azonixnetworks.tradex_mobile/notifications',
  );

  @override
  Future<DeviceNotificationPermission> status() async {
    try {
      return _decode(await _channel.invokeMethod<String>('status'));
    } on MissingPluginException {
      return DeviceNotificationPermission.unsupported;
    } on PlatformException {
      return DeviceNotificationPermission.denied;
    }
  }

  @override
  Future<DeviceNotificationPermission> request() async {
    try {
      return _decode(await _channel.invokeMethod<String>('request'));
    } on MissingPluginException {
      return DeviceNotificationPermission.unsupported;
    } on PlatformException {
      return DeviceNotificationPermission.denied;
    }
  }

  DeviceNotificationPermission _decode(String? value) => switch (value) {
    'granted' => DeviceNotificationPermission.granted,
    'denied' => DeviceNotificationPermission.denied,
    'notDetermined' => DeviceNotificationPermission.notDetermined,
    _ => DeviceNotificationPermission.unsupported,
  };
}
