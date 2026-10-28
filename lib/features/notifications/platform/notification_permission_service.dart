import 'package:flutter/services.dart';

enum DeviceNotificationPermission {
  granted,
  denied,
  notDetermined,
  unsupported,
}

class NotificationPermissionService {
  const NotificationPermissionService();

  static const MethodChannel _channel = MethodChannel(
    'com.azonixnetworks.tradex_mobile/notifications',
  );

  Future<DeviceNotificationPermission> status() async {
    try {
      return _decode(await _channel.invokeMethod<String>('status'));
    } on MissingPluginException {
      return DeviceNotificationPermission.unsupported;
    } on PlatformException {
      return DeviceNotificationPermission.denied;
    }
  }

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
