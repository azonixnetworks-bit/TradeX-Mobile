enum MarketAssetKind {
  forexPair,
  cryptoPair,
  commodityPair,
  stock,
  synthetic,
  unknown,
}

class MarketAssetVisual {
  const MarketAssetVisual({
    required this.kind,
    required this.label,
    this.primaryAsset,
    this.baseAsset,
    this.quoteAsset,
    this.primaryVerified = false,
  });

  final MarketAssetKind kind;
  final String label;
  final String? primaryAsset;
  final String? baseAsset;
  final String? quoteAsset;
  final bool primaryVerified;

  bool get hasPair => baseAsset != null || quoteAsset != null;
}

abstract final class MarketAssetResolver {
  static const _assetRoot = 'assets/market_assets';
  static const _currencyCountry = <String, String>{
    'EUR': 'eu',
    'USD': 'us',
    'GBP': 'gb',
    'JPY': 'jp',
    'AUD': 'au',
    'CAD': 'ca',
    'CHF': 'ch',
    'LKR': 'lk',
    'NZD': 'nz',
    'SGD': 'sg',
    'HKD': 'hk',
    'CNY': 'cn',
  };
  static const _verifiedCrypto = {'BTC', 'ETH', 'XMR'};
  static const _cryptoFallbacks = {'USDT', 'USDC', 'BNB', 'SOL', 'XRP', 'DOGE'};
  static const _cryptoQuotes = ['USDT', 'USDC', 'USD', 'BTC', 'ETH'];

  static MarketAssetVisual resolve({
    required String market,
    required String symbol,
    String? baseCurrency,
  }) {
    var normalizedMarket = market.trim().toUpperCase();
    var normalizedSymbol = _cleanSymbol(symbol);
    if (normalizedSymbol.startsWith('FRX') && normalizedSymbol.length > 3) {
      normalizedMarket = 'FOREX';
      normalizedSymbol = normalizedSymbol.substring(3);
    } else if (normalizedSymbol.startsWith('CRY') &&
        normalizedSymbol.length > 3) {
      normalizedMarket = 'CRYPTO';
      normalizedSymbol = normalizedSymbol.substring(3);
    }

    if (normalizedSymbol.startsWith('XAU') && normalizedSymbol.length >= 6) {
      final quote = normalizedSymbol.substring(3, 6);
      return MarketAssetVisual(
        kind: MarketAssetKind.commodityPair,
        label: normalizedSymbol,
        baseAsset: '$_assetRoot/instruments/gold_xau_bullion.png',
        quoteAsset: _flagForCurrency(quote),
      );
    }

    if (normalizedMarket == 'FOREX' && normalizedSymbol.length >= 6) {
      final base = normalizedSymbol.substring(0, 3);
      final quote = normalizedSymbol.substring(3, 6);
      final baseAsset = _flagForCurrency(base);
      final quoteAsset = _flagForCurrency(quote);
      if (baseAsset != null || quoteAsset != null) {
        return MarketAssetVisual(
          kind: MarketAssetKind.forexPair,
          label: normalizedSymbol,
          baseAsset: baseAsset,
          quoteAsset: quoteAsset,
        );
      }
    }

    if (normalizedMarket == 'CRYPTO') {
      final base = baseCurrency?.trim().toUpperCase().isNotEmpty == true
          ? baseCurrency!.trim().toUpperCase()
          : _cryptoBase(normalizedSymbol);
      final quote = _cryptoQuote(normalizedSymbol);
      final primaryAsset = _cryptoAsset(base);
      return MarketAssetVisual(
        kind: MarketAssetKind.cryptoPair,
        label: base.isEmpty ? normalizedSymbol : base,
        baseAsset: primaryAsset,
        quoteAsset: primaryAsset == null
            ? null
            : _cryptoAsset(quote) ?? _flagForCurrency(quote),
        primaryVerified: _verifiedCrypto.contains(base),
      );
    }

    if (normalizedMarket == 'STOCKS' || normalizedMarket == 'STOCK') {
      return MarketAssetVisual(
        kind: MarketAssetKind.stock,
        label: normalizedSymbol,
      );
    }

    if (normalizedMarket == 'DERIV') {
      return MarketAssetVisual(
        kind: MarketAssetKind.synthetic,
        label: normalizedSymbol,
        primaryAsset: '$_assetRoot/instruments/unknown_instrument.png',
      );
    }

    return MarketAssetVisual(
      kind: MarketAssetKind.unknown,
      label: normalizedSymbol,
      primaryAsset: '$_assetRoot/instruments/unknown_instrument.png',
    );
  }

  static String _cleanSymbol(String value) {
    final upper = value.trim().toUpperCase();
    final afterExchange = upper.contains(':') ? upper.split(':').last : upper;
    return afterExchange.replaceAll(RegExp('[^A-Z0-9_]'), '');
  }

  static String? _flagForCurrency(String currency) {
    final country = _currencyCountry[currency];
    return country == null ? null : '$_assetRoot/flags/$country.png';
  }

  static String _cryptoBase(String symbol) {
    final quote = _cryptoQuote(symbol);
    return quote.isNotEmpty && symbol.length > quote.length
        ? symbol.substring(0, symbol.length - quote.length)
        : symbol;
  }

  static String _cryptoQuote(String symbol) {
    for (final quote in _cryptoQuotes) {
      if (symbol.endsWith(quote) && symbol.length > quote.length) return quote;
    }
    return '';
  }

  static String? _cryptoAsset(String symbol) {
    final normalized = symbol.toLowerCase();
    if (_verifiedCrypto.contains(symbol)) {
      return '$_assetRoot/crypto/$normalized.png';
    }
    if (_cryptoFallbacks.contains(symbol)) {
      return '$_assetRoot/crypto/${normalized}_fallback.png';
    }
    return null;
  }
}
