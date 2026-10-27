class TradeIdeaTradingViewSymbolResolver {
  const TradeIdeaTradingViewSymbolResolver();

  static const _qualifiedProviders = <String>{
    'AMEX',
    'BINANCE',
    'BSE',
    'COINBASE',
    'FOREXCOM',
    'FX',
    'KRAKEN',
    'NASDAQ',
    'NSE',
    'NYMEX',
    'NYSE',
    'OANDA',
    'TVC',
  };

  static const _forexCurrencies = <String>{
    'AUD',
    'CAD',
    'CHF',
    'EUR',
    'GBP',
    'JPY',
    'NZD',
    'SGD',
    'USD',
    'ZAR',
  };

  static const _cryptoBases = <String>{
    'ADA',
    'AVAX',
    'BNB',
    'BTC',
    'DOGE',
    'DOT',
    'ETH',
    'LINK',
    'LTC',
    'SOL',
    'TON',
    'TRX',
    'XRP',
  };

  String? resolve({
    required String category,
    required String symbol,
    String marketRegion = '',
  }) {
    final raw = symbol.trim().toUpperCase();
    if (raw.isEmpty) return null;

    final qualified = RegExp(r'^([A-Z0-9_]+):([A-Z0-9._-]+)$').firstMatch(raw);
    if (qualified != null) {
      return _qualifiedProviders.contains(qualified.group(1)) ? raw : null;
    }

    final clean = raw.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final normalizedCategory = category.trim().toUpperCase();
    return switch (normalizedCategory) {
      'FOREX' => _forex(clean),
      'CRYPTO' => _crypto(clean),
      'DERIV' => _derivative(clean),
      'STOCKS' => null,
      _ => null,
    };
  }

  String? _forex(String symbol) {
    if (symbol == 'XAUUSD' || symbol == 'XAGUSD') return 'OANDA:$symbol';
    if (symbol.length != 6) return null;
    final base = symbol.substring(0, 3);
    final quote = symbol.substring(3);
    if (!_forexCurrencies.contains(base) ||
        !_forexCurrencies.contains(quote) ||
        base == quote) {
      return null;
    }
    return 'OANDA:$symbol';
  }

  String? _crypto(String symbol) {
    const quotes = ['USDT', 'USDC', 'BTC', 'ETH'];
    for (final quote in quotes) {
      if (!symbol.endsWith(quote) || symbol.length <= quote.length) continue;
      final base = symbol.substring(0, symbol.length - quote.length);
      if (_cryptoBases.contains(base)) return 'BINANCE:$symbol';
    }
    return null;
  }

  String? _derivative(String symbol) => switch (symbol) {
    'NAS100' || 'US100' || 'NAS100USD' => 'OANDA:NAS100USD',
    _ => null,
  };
}

String tradeIdeaTradingViewInterval(String timeframe) =>
    switch (timeframe.trim().toUpperCase()) {
      'M1' => '1',
      'M5' => '5',
      'M15' => '15',
      'M30' => '30',
      'H1' => '60',
      'H4' => '240',
      'D1' => 'D',
      'W1' => 'W',
      'MN1' => 'M',
      _ => '60',
    };

bool isSafeTradingViewAnalysisUrl(String? raw) {
  final uri = Uri.tryParse(raw?.trim() ?? '');
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
    return false;
  }
  if (uri.hasPort && uri.port != 443) return false;
  final host = uri.host.toLowerCase();
  if (host != 'tradingview.com' && !host.endsWith('.tradingview.com')) {
    return false;
  }
  return uri.path.startsWith('/chart/') || uri.path.startsWith('/x/');
}
