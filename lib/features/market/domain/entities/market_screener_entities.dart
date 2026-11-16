class MarketScreenerSnapshot {
  const MarketScreenerSnapshot({
    required this.market,
    required this.timeframe,
    required this.generatedAt,
    required this.quotes,
  });

  final String market;
  final String timeframe;
  final DateTime? generatedAt;
  final List<MarketScreenerQuote> quotes;
}

class MarketScreenerQuote {
  const MarketScreenerQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.trend,
    required this.rsi,
    required this.region,
    required this.exchange,
  });

  factory MarketScreenerQuote.fromJson(Map<String, dynamic> json) =>
      MarketScreenerQuote(
        symbol: json['symbol']?.toString().trim().toUpperCase() ?? '',
        name: json['name']?.toString().trim() ?? '',
        price: _number(json['close'] ?? json['price']),
        changePercent: _number(json['change_percent']),
        trend: json['trend']?.toString().trim().toUpperCase() ?? 'LIVE',
        rsi: _number(json['rsi']),
        region: json['region']?.toString().trim().toUpperCase() ?? '',
        exchange: json['exchange']?.toString().trim().toUpperCase() ?? '',
      );

  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final String trend;
  final double rsi;
  final String region;
  final String exchange;
}

double _number(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
