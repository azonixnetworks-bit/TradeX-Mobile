abstract final class TradeXApiConfig {
  static const String productionHost = 'api.tradex.lk';

  static const Map<String, String> _moduleHostsByPathPrefix = {
    '/api/v1/education': 'education.tradex.lk',
    '/api/v1/trade-ideas': 'signals.tradex.lk',
    '/api/v1/affiliate': 'affiliate.tradex.lk',
    '/api/v1/support': 'support.tradex.lk',
    '/api/v1/copy-trade': 'copytrade.tradex.lk',
    '/api/v1/screener': 'screener.tradex.lk',
    '/api/v1/investments': 'investments.tradex.lk',
  };

  static const Set<String> productionApiHosts = {
    productionHost,
    'education.tradex.lk',
    'signals.tradex.lk',
    'affiliate.tradex.lk',
    'support.tradex.lk',
    'copytrade.tradex.lk',
    'screener.tradex.lk',
    'investments.tradex.lk',
  };

  static const String _configuredBaseUrl = String.fromEnvironment(
    'TRADEX_API_BASE_URL',
    defaultValue: 'https://api.tradex.lk',
  );

  static const String _configuredCertificatePins = String.fromEnvironment(
    'TRADEX_CERT_SHA256_PINS',
    defaultValue:
        '6ff84c2543380b964262dab48b4a7d0249d51c9eef73d0c6b87cf441ca11489d',
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
    if (!productionApiHosts.contains(host)) return const <String>{};

    return _configuredCertificatePins
        .split(',')
        .map((pin) => pin.trim().toLowerCase().replaceAll(':', ''))
        .where((pin) => RegExp(r'^[0-9a-f]{64}$').hasMatch(pin))
        .toSet();
  }

  /// Routes high-traffic module requests to their isolated production host.
  /// Custom development/staging base URLs intentionally remain on one host.
  static String resolveRequestUrl(String value) {
    final requestUri = Uri.tryParse(value);
    if (requestUri?.hasScheme == true) return value;

    final configuredBase = Uri.parse(baseUrl);
    if (configuredBase.host != productionHost) return value;

    final path = requestUri?.path ?? value;
    for (final entry in _moduleHostsByPathPrefix.entries) {
      if (path == entry.key || path.startsWith('${entry.key}/')) {
        return Uri(
          scheme: 'https',
          host: entry.value,
          path: path,
          query: requestUri?.hasQuery == true ? requestUri!.query : null,
          fragment: requestUri?.hasFragment == true
              ? requestUri!.fragment
              : null,
        ).toString();
      }
    }

    return value;
  }

  static const Duration requestTimeout = Duration(seconds: 30);
}
