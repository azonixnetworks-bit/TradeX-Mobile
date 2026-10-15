abstract final class TradeXApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'TRADEX_API_BASE_URL',
    defaultValue: 'https://cloudvideo.online',
  );

  static String get baseUrl {
    final value = _configuredBaseUrl.trim();
    final uri = Uri.tryParse(value);

    if (value.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'TRADEX_API_BASE_URL must be an absolute URL. '
        'Run Flutter with --dart-define=TRADEX_API_BASE_URL=https://api.example.com',
      );
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static const Duration requestTimeout = Duration(seconds: 30);
}
