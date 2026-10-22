import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/tradex_api_client.dart';

class CryptoMarketRepository {
  CryptoMarketRepository(this._apiClient);

  static const _watchlistKey = 'tradex.crypto.watchlist.v1';

  final TradeXApiClient _apiClient;

  Future<CryptoScreenerDataset> screener() async {
    final response = await _apiClient.getJson(
      '/api/v1/screener/results?market=CRYPTO&timeframe=H1&sort=change_percent&order=desc',
    );
    final data = response['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : const {};
    final rawResults = map['results'];
    return CryptoScreenerDataset(
      provider: _text(map['provider'], fallback: 'BINANCE'),
      generatedAt: DateTime.tryParse(_text(map['generated_at_utc'])),
      stale: map['cache'] is Map && (map['cache'] as Map)['stale'] == true,
      assets: rawResults is List
          ? rawResults
                .whereType<Map>()
                .map(
                  (item) => CryptoScreenerAsset.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where((item) => item.symbol.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  Future<CryptoBubbleDataset> bubbles({int limit = 50}) async {
    final response = await _apiClient.getJson(
      '/api/v1/screener/bubbles?limit=$limit',
    );
    final data = response['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : const {};
    final summary = map['summary'];
    final rawAssets = map['assets'];
    return CryptoBubbleDataset(
      provider: _text(map['provider'], fallback: 'BINANCE'),
      source: _text(map['source']),
      generatedAt: DateTime.tryParse(_text(map['generated_at_utc'])),
      stale: map['stale'] == true,
      summary: CryptoMarketSummary.fromJson(
        summary is Map ? Map<String, dynamic>.from(summary) : const {},
      ),
      assets: rawAssets is List
          ? rawAssets
                .whereType<Map>()
                .map(
                  (item) => CryptoBubbleAsset.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where((item) => item.symbol.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  Future<Set<String>> watchlist() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences
            .getStringList(_watchlistKey)
            ?.map((symbol) => symbol.trim().toUpperCase())
            .where((symbol) => symbol.isNotEmpty)
            .toSet() ??
        <String>{};
  }

  Future<Set<String>> toggleWatchlist(String symbol) async {
    final normalized = symbol.trim().toUpperCase();
    final values = await watchlist();
    if (values.contains(normalized)) {
      values.remove(normalized);
    } else if (normalized.isNotEmpty) {
      values.add(normalized);
    }
    await _saveWatchlist(values);
    return values;
  }

  Future<void> clearWatchlist() async => _saveWatchlist(<String>{});

  Future<void> _saveWatchlist(Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();
    await preferences.setStringList(_watchlistKey, sorted);
  }
}

class CryptoScreenerDataset {
  const CryptoScreenerDataset({
    required this.provider,
    required this.generatedAt,
    required this.stale,
    required this.assets,
  });

  final String provider;
  final DateTime? generatedAt;
  final bool stale;
  final List<CryptoScreenerAsset> assets;
}

class CryptoScreenerAsset {
  const CryptoScreenerAsset({
    required this.symbol,
    required this.name,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.logoUrl,
    required this.price,
    required this.changePercent,
    required this.trend,
    required this.rsi,
    required this.volume,
    required this.quoteVolume,
  });

  factory CryptoScreenerAsset.fromJson(Map<String, dynamic> json) =>
      CryptoScreenerAsset(
        symbol: _text(json['symbol']).toUpperCase(),
        name: _text(json['name'], fallback: _text(json['symbol'])),
        baseCurrency: _text(json['base_currency']).toUpperCase(),
        quoteCurrency: _text(
          json['quote_currency'],
          fallback: 'USDT',
        ).toUpperCase(),
        logoUrl: _nullableText(json['logo_url']),
        price: _number(json['price']),
        changePercent: _number(json['change_percent']),
        trend: _text(json['trend'], fallback: 'SIDEWAYS').toUpperCase(),
        rsi: _nullableNumber(json['rsi_14']),
        volume: _nullableNumber(json['volume']),
        quoteVolume: _number(json['quote_volume']),
      );

  CryptoScreenerAsset withLiveData(CryptoBubbleAsset live) =>
      CryptoScreenerAsset(
        symbol: symbol,
        name: name,
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        logoUrl: logoUrl,
        price: live.price,
        changePercent: live.changePercent,
        trend: trend,
        rsi: rsi,
        volume: volume,
        quoteVolume: live.quoteVolume,
      );

  final String symbol;
  final String name;
  final String baseCurrency;
  final String quoteCurrency;
  final String? logoUrl;
  final double price;
  final double changePercent;
  final String trend;
  final double? rsi;
  final double? volume;
  final double quoteVolume;
}

class CryptoBubbleDataset {
  const CryptoBubbleDataset({
    required this.provider,
    required this.source,
    required this.generatedAt,
    required this.stale,
    required this.summary,
    required this.assets,
  });

  final String provider;
  final String source;
  final DateTime? generatedAt;
  final bool stale;
  final CryptoMarketSummary summary;
  final List<CryptoBubbleAsset> assets;
}

class CryptoMarketSummary {
  const CryptoMarketSummary({
    required this.totalAssets,
    required this.gainers,
    required this.losers,
    required this.averageChange,
    required this.totalQuoteVolume,
  });

  factory CryptoMarketSummary.fromJson(Map<String, dynamic> json) =>
      CryptoMarketSummary(
        totalAssets: _integer(json['total_assets']),
        gainers: _integer(json['gainers']),
        losers: _integer(json['losers']),
        averageChange: _number(json['average_change']),
        totalQuoteVolume: _number(json['total_quote_volume']),
      );

  static const empty = CryptoMarketSummary(
    totalAssets: 0,
    gainers: 0,
    losers: 0,
    averageChange: 0,
    totalQuoteVolume: 0,
  );

  final int totalAssets;
  final int gainers;
  final int losers;
  final double averageChange;
  final double totalQuoteVolume;
}

class CryptoBubbleAsset {
  const CryptoBubbleAsset({
    required this.symbol,
    required this.baseCurrency,
    required this.price,
    required this.changePercent,
    required this.quoteVolume,
  });

  factory CryptoBubbleAsset.fromJson(Map<String, dynamic> json) =>
      CryptoBubbleAsset(
        symbol: _text(json['symbol']).toUpperCase(),
        baseCurrency: _text(json['base_currency']).toUpperCase(),
        price: _number(json['price']),
        changePercent: _number(json['change_percent']),
        quoteVolume: _number(json['quote_volume']),
      );

  final String symbol;
  final String baseCurrency;
  final double price;
  final double changePercent;
  final double quoteVolume;
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

double? _nullableNumber(Object? value) {
  if (value == null) return null;
  return value is num ? value.toDouble() : double.tryParse('$value');
}

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
