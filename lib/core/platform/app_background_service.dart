import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class AppBackgroundService {
  static const _channel = MethodChannel(
    'com.azonixnetworks.tradex_mobile/app_lifecycle',
  );

  static Future<bool> moveToBackground() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('moveTaskToBack') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
