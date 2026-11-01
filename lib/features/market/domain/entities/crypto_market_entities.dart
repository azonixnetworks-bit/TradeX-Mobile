String cryptoMarketKey(String symbol, String segment) =>
    '${segment.toUpperCase() == 'FUTURES' ? 'FUTURES' : 'SPOT'}:${symbol.trim().toUpperCase()}';

String cryptoSymbolFromMarketKey(String key) =>
    key.contains(':') ? key.split(':').last : key.trim().toUpperCase();

String cryptoSegmentFromMarketKey(String key) =>
    key.toUpperCase().startsWith('FUTURES:') ? 'FUTURES' : 'SPOT';

enum CryptoBubbleMode {
  gainers('GAINERS'),
  losers('LOSERS');

  const CryptoBubbleMode(this.apiValue);
  final String apiValue;
}

class CryptoMarketSnapshot {
  const CryptoMarketSnapshot({
    required this.summary,
    required this.assets,
    required this.bubbleAssets,
    required this.topAssets,
    required this.generatedAt,
    required this.stale,
    required this.pagination,
    required this.partialData,
  });
  final CryptoMarketSummary summary;
  final List<CryptoAsset> assets;
  final List<CryptoAsset> bubbleAssets;
  final List<CryptoAsset> topAssets;
  final DateTime? generatedAt;
  final bool stale;
  final CryptoPagination pagination;
  final bool partialData;
  CryptoMarketSnapshot copyWith({
    CryptoMarketSummary? summary,
    List<CryptoAsset>? assets,
    List<CryptoAsset>? bubbleAssets,
    List<CryptoAsset>? topAssets,
    DateTime? generatedAt,
    bool? stale,
  }) => CryptoMarketSnapshot(
    summary: summary ?? this.summary,
    assets: assets ?? this.assets,
    bubbleAssets: bubbleAssets ?? this.bubbleAssets,
    topAssets: topAssets ?? this.topAssets,
    generatedAt: generatedAt ?? this.generatedAt,
    stale: stale ?? this.stale,
    pagination: pagination,
    partialData: partialData,
  );
}

class CryptoBubbleUpdate {
  const CryptoBubbleUpdate({
    required this.summary,
    required this.assets,
    required this.marketAssets,
    required this.generatedAt,
    required this.stale,
  });
  final CryptoMarketSummary summary;
  final List<CryptoAsset> assets;
  final List<CryptoAsset> marketAssets;
  final DateTime? generatedAt;
  final bool stale;
}

class CryptoPagination {
  const CryptoPagination({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
  });
  factory CryptoPagination.fromJson(Map<String, dynamic> json) =>
      CryptoPagination(
        currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
        lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
        total: (json['total'] as num?)?.toInt() ?? 0,
        hasMore: json['has_more'] == true,
      );
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;
}

class CryptoMarketSummary {
  const CryptoMarketSummary({
    required this.totalVolume,
    required this.averageChange,
    required this.gainers,
    required this.losers,
  });
  factory CryptoMarketSummary.fromJson(Map<String, dynamic> json) =>
      CryptoMarketSummary(
        totalVolume: _number(json['total_quote_volume']),
        averageChange: _number(json['average_change']),
        gainers: (json['gainers'] as num?)?.toInt() ?? 0,
        losers: (json['losers'] as num?)?.toInt() ?? 0,
      );
  final double totalVolume;
  final double averageChange;
  final int gainers;
  final int losers;
}

class CryptoAsset {
  const CryptoAsset({
    required this.symbol,
    required this.name,
    required this.baseCurrency,
    required this.logoUrl,
    required this.price,
    required this.changePercent,
    required this.quoteVolume,
    this.segment = 'SPOT',
    this.trend,
  });
  factory CryptoAsset.fromJson(Map<String, dynamic> json) => CryptoAsset(
    symbol: json['symbol']?.toString().toUpperCase() ?? '',
    name: json['name']?.toString() ?? '',
    baseCurrency: json['base_currency']?.toString().toUpperCase() ?? '',
    logoUrl: json['logo_url']?.toString(),
    price: _number(json['price'] ?? json['close']),
    changePercent: _number(json['change_percent']),
    quoteVolume: _number(json['quote_volume']),
    segment: json['segment']?.toString().toUpperCase() ?? 'SPOT',
    trend: json['trend']?.toString(),
  );
  final String symbol;
  final String name;
  final String baseCurrency;
  final String? logoUrl;
  final double price;
  final double changePercent;
  final double quoteVolume;
  final String segment;
  final String? trend;
  String get marketKey => cryptoMarketKey(symbol, segment);
  String get resolvedTrend {
    final normalized = trend?.trim().toUpperCase();
    if (normalized == 'BULLISH' ||
        normalized == 'BEARISH' ||
        normalized == 'SIDEWAYS') {
      return normalized!;
    }
    if (changePercent > .05) return 'BULLISH';
    if (changePercent < -.05) return 'BEARISH';
    return 'SIDEWAYS';
  }

  String get fallbackLabel {
    final source = baseCurrency.isNotEmpty ? baseCurrency : symbol;
    return source.substring(0, source.length.clamp(0, 3).toInt());
  }

  CryptoAsset mergeMarket(CryptoAsset? market) => CryptoAsset(
    symbol: symbol,
    name: name.isNotEmpty ? name : (market?.name ?? ''),
    baseCurrency: baseCurrency.isNotEmpty
        ? baseCurrency
        : (market?.baseCurrency ?? ''),
    logoUrl: logoUrl?.isNotEmpty == true ? logoUrl : market?.logoUrl,
    price: price > 0 ? price : (market?.price ?? 0),
    changePercent: price > 0 || quoteVolume > 0
        ? changePercent
        : (market?.changePercent ?? changePercent),
    quoteVolume: quoteVolume > 0 ? quoteVolume : (market?.quoteVolume ?? 0),
    segment: segment,
    trend: trend,
  );
  CryptoAsset withSegment(String value) => CryptoAsset(
    symbol: symbol,
    name: name,
    baseCurrency: baseCurrency,
    logoUrl: logoUrl,
    price: price,
    changePercent: changePercent,
    quoteVolume: quoteVolume,
    segment: value.toUpperCase() == 'FUTURES' ? 'FUTURES' : 'SPOT',
    trend: trend,
  );
  CryptoAsset withLiveMarket(CryptoAsset? live) {
    if (live == null) return this;
    return CryptoAsset(
      symbol: symbol,
      name: name.isNotEmpty ? name : live.name,
      baseCurrency: baseCurrency.isNotEmpty ? baseCurrency : live.baseCurrency,
      logoUrl: logoUrl?.isNotEmpty == true ? logoUrl : live.logoUrl,
      price: live.price > 0 ? live.price : price,
      changePercent: live.changePercent,
      quoteVolume: live.quoteVolume > 0 ? live.quoteVolume : quoteVolume,
      segment: segment,
      trend: live.trend ?? trend,
    );
  }

  CryptoAsset withLiveTicker({
    required double price,
    required double changePercent,
    required double quoteVolume,
  }) => CryptoAsset(
    symbol: symbol,
    name: name,
    baseCurrency: baseCurrency,
    logoUrl: logoUrl,
    price: price > 0 ? price : this.price,
    changePercent: changePercent,
    quoteVolume: quoteVolume > 0 ? quoteVolume : this.quoteVolume,
    segment: segment,
    trend: trend,
  );
}

double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
