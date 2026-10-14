abstract final class TradeXApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'TRADEX_API_BASE_URL',
  );

  static String get baseUrl {
    final value = _configuredBaseUrl.trim();

    if (value.isEmpty) {
      throw StateError(
        'TRADEX_API_BASE_URL is not configured. '
        'Run Flutter with --dart-define=TRADEX_API_BASE_URL=...',
      );
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static const Duration requestTimeout = Duration(seconds: 30);
}
