import 'dart:typed_data';

abstract interface class AppPlatform {
  Future<SelectedImage?> pickImage({
    required bool camera,
    int imageQuality = 88,
    double? maxWidth,
    double? maxHeight,
  });

  Future<bool> launchExternal(String url);
  Future<String> timezoneId();
  DateTime timeInZone(String timezone, DateTime fallback);
  Future<void> shareImage({
    required Uint8List bytes,
    required String fileName,
    required String text,
    double? originLeft,
    double? originTop,
    double? originWidth,
    double? originHeight,
  });
}

class SelectedImage {
  const SelectedImage({
    required this.path,
    required this.name,
    required this.bytes,
  });

  final String path;
  final String name;
  final Uint8List bytes;
}

abstract final class AppPlatformRegistry {
  static AppPlatform? _current;

  static AppPlatform get current =>
      _current ?? (throw StateError('App platform is not configured.'));

  static void configure(AppPlatform platform) => _current = platform;
}
