abstract interface class SecureWorkflowPlatform {
  Future<PickedImage?> pickImage({
    required bool camera,
    int imageQuality = 88,
    double? maxWidth,
    double? maxHeight,
  });
  Future<bool> launchExternal(String url);
  Future<String> timezoneId();
  String newUuid();
}

class PickedImage {
  const PickedImage({required this.path, required this.name});
  final String path;
  final String name;
}

abstract final class SecureWorkflowPlatformRegistry {
  static SecureWorkflowPlatform? _current;

  static SecureWorkflowPlatform get current {
    final value = _current;
    if (value == null) {
      throw StateError('Secure workflow platform is not configured.');
    }
    return value;
  }

  static void configure(SecureWorkflowPlatform platform) {
    _current = platform;
  }
}
