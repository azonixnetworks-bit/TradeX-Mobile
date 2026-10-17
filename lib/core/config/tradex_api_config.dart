abstract final class TradeXApiConfig {
  static const String productionHost = 'cloudvideo.online';

  static const String _configuredBaseUrl = String.fromEnvironment(
    'TRADEX_API_BASE_URL',
    defaultValue: 'https://cloudvideo.online',
  );

  static const String _configuredCertificatePins = String.fromEnvironment(
    'TRADEX_CERT_SHA256_PINS',
    defaultValue:
        '468a8c0eb690cef0370f4c44537abeed9c6b70445bf117c5b7c91aa34e1feef3',
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

    if (uri.host == productionHost && uri.scheme != 'https') {
      throw StateError('The TradeX production API requires HTTPS.');
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Set<String> certificatePinsFor(String host) {
    if (host != productionHost) return const <String>{};

    return _configuredCertificatePins
        .split(',')
        .map((pin) => pin.trim().toLowerCase().replaceAll(':', ''))
        .where((pin) => RegExp(r'^[0-9a-f]{64}$').hasMatch(pin))
        .toSet();
  }

  static const Duration requestTimeout = Duration(seconds: 30);
}
