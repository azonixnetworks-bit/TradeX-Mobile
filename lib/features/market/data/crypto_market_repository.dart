import '../../../core/network/tradex_api_client.dart';

class CryptoMarketRepository {
  const CryptoMarketRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  static const topSymbols = <String>[
    'BNBUSDT',
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
    'XRPUSDT',
  ];

  Future<CryptoMarketSnapshot> load({
    required String segment,
    int page = 1,
    String search = '',
  }) async {
    final encodedSearch = Uri.encodeQueryComponent(search.trim());
    final requests = await Future.wait([
      _apiClient.getJson(
        '/api/v1/screener/bubbles?limit=100&page=1&per_page=20',
      ),
      _apiClient.getJson(
        '/api/v1/screener/symbols?market=CRYPTO&segment=$segment'
        '&page=$page&per_page=20&search=$encodedSearch',
      ),
      _apiClient.getJson(
        '/api/v1/screener/results?market=CRYPTO&timeframe=H1'
        '&segment=$segment&symbols=${topSymbols.join(',')}',
      ),
    ]);
    final bubbles = _data(requests[0]);
    final catalog = _data(requests[1]);
    final screener = _data(requests[2]);
    final assets = _maps(catalog['symbols'])
        .map(CryptoAsset.fromJson)
        .toList(growable: false);
    final bubbleAssets = _maps(bubbles['bubbles'])
        .map(CryptoAsset.fromJson)
        .toList(growable: false);
    final topBySymbol = {
      for (final row in _maps(screener['results']))
        row['symbol']?.toString().toUpperCase() ?? '': CryptoAsset.fromJson(
          row,
        ),
    };
    final bubbleBySymbol = {for (final asset in assets) asset.symbol: asset};
    final top = <CryptoAsset>[
      for (final symbol in topSymbols)
        if (topBySymbol[symbol] != null)
          topBySymbol[symbol]!.mergeMarket(bubbleBySymbol[symbol])
        else if (bubbleBySymbol[symbol] != null)
          bubbleBySymbol[symbol]!,
    ];
    return CryptoMarketSnapshot(
      summary: CryptoMarketSummary.fromJson(_map(bubbles['summary'])),
      assets: assets,
      bubbleAssets: bubbleAssets,
      topAssets: top,
      generatedAt: DateTime.tryParse(
        bubbles['generated_at_utc']?.toString() ?? '',
      ),
      stale: bubbles['stale'] == true,
      pagination: CryptoPagination.fromJson(_map(catalog['pagination'])),
    );
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];
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
  });

  final CryptoMarketSummary summary;
  final List<CryptoAsset> assets;
  final List<CryptoAsset> bubbleAssets;
  final List<CryptoAsset> topAssets;
  final DateTime? generatedAt;
  final bool stale;
  final CryptoPagination pagination;
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
    trend: json['trend']?.toString(),
  );

  final String symbol;
  final String name;
  final String baseCurrency;
  final String? logoUrl;
  final double price;
  final double changePercent;
  final double quoteVolume;
  final String? trend;

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
    changePercent: changePercent,
    quoteVolume: market?.quoteVolume ?? quoteVolume,
    trend: trend,
  );
}

double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
