class RiskRewardInstrument {
  const RiskRewardInstrument({
    required this.symbol,
    required this.name,
    required this.data,
  });

  final String symbol;
  final String name;
  final Map<String, dynamic> data;

  factory RiskRewardInstrument.fromEntry(String symbol, Object? raw) {
    final data = _map(raw);
    return RiskRewardInstrument(
      symbol: symbol,
      name: _text(data['name'], symbol),
      data: data,
    );
  }
}

class RiskRewardMarket {
  const RiskRewardMarket({
    required this.key,
    required this.label,
    required this.description,
    required this.instruments,
    required this.data,
  });

  final String key;
  final String label;
  final String description;
  final List<RiskRewardInstrument> instruments;
  final Map<String, dynamic> data;

  factory RiskRewardMarket.fromEntry(String key, Object? raw) {
    final data = _map(raw);
    final instruments = _map(data['instruments']).entries
        .map((entry) => RiskRewardInstrument.fromEntry(entry.key, entry.value))
        .toList(growable: false);
    return RiskRewardMarket(
      key: key,
      label: _text(data['label'], key),
      description: _text(data['description']),
      instruments: instruments,
      data: data,
    );
  }
}

class StockInstrument {
  const StockInstrument({
    required this.symbol,
    required this.name,
    required this.region,
    required this.exchange,
    required this.currency,
    required this.dataMode,
  });

  final String symbol;
  final String name;
  final String region;
  final String exchange;
  final String currency;
  final String dataMode;

  factory StockInstrument.fromJson(Object? raw) {
    final json = _map(raw);
    return StockInstrument(
      symbol: _text(json['symbol']),
      name: _text(json['name']),
      region: _text(json['region']),
      exchange: _text(json['exchange']),
      currency: _text(json['currency'], 'USD'),
      dataMode: _text(json['data_mode'], 'MANUAL'),
    );
  }
}

class RiskRewardCatalog {
  const RiskRewardCatalog({
    required this.markets,
    required this.stocks,
    required this.dividendProviderAvailable,
    required this.dividendMessage,
    required this.disclaimer,
    required this.isOffline,
    required this.isStale,
  });

  final Map<String, RiskRewardMarket> markets;
  final List<StockInstrument> stocks;
  final bool dividendProviderAvailable;
  final String dividendMessage;
  final String disclaimer;
  final bool isOffline;
  final bool isStale;

  factory RiskRewardCatalog.fromResponse(Map<String, dynamic> response) {
    final data = _map(response['data']);
    final markets = _map(data['markets']).map(
      (key, value) => MapEntry(key, RiskRewardMarket.fromEntry(key, value)),
    );
    final stockData = _map(data['stocks']);
    final dividends = _map(data['dividends']);
    final offline = _map(response['_offline_cache']);
    return RiskRewardCatalog(
      markets: markets,
      stocks: _list(stockData['symbols'])
          .map(StockInstrument.fromJson)
          .where((stock) => stock.symbol.isNotEmpty)
          .toList(growable: false),
      dividendProviderAvailable: dividends['provider_available'] == true,
      dividendMessage: _text(dividends['message']),
      disclaimer: _text(data['disclaimer']),
      isOffline: offline.isNotEmpty,
      isStale: offline['is_stale'] == true,
    );
  }
}

class RiskRewardResult {
  const RiskRewardResult(this.data);

  final Map<String, dynamic> data;

  factory RiskRewardResult.fromResponse(Map<String, dynamic> response) =>
      RiskRewardResult(_map(response['data']));

  String get market => _text(data['market']);
  String get marketLabel => _text(data['market_label'], market);
  String get symbol => _text(data['symbol'], 'Manual');
  String get instrumentName => _text(data['instrument_name'], symbol);
  String get side => _text(data['side']);
  double? get recommendedSize => _number(data['recommended_lot']);
  double? get positionUnits => _number(data['position_units']);
  double? get actualRisk => _number(data['actual_risk']);
  double? get potentialProfit => _number(data['potential_profit']);
  double? get riskReward => _number(data['risk_reward_ratio']);
  double? get requiredInvestment =>
      _number(data['required_investment_usd'] ?? data['required_investment']);
  double? get requiredMargin =>
      _number(_map(data['futures'])['required_initial_margin']);
  int? get leverage {
    final value = _number(_map(data['futures'])['leverage']);
    return value?.round();
  }

  bool get leverageAutoCalculated =>
      _map(data['futures'])['leverage_auto_calculated'] == true;
  List<String> get warnings =>
      _list(data['warnings']).map((item) => item.toString()).toList();
}

class RiskRewardQuote {
  const RiskRewardQuote({
    required this.market,
    required this.symbol,
    required this.price,
    required this.displayPrice,
    required this.observedAt,
    required this.provider,
  });

  final String market;
  final String symbol;
  final double price;
  final String displayPrice;
  final DateTime? observedAt;
  final String provider;

  factory RiskRewardQuote.fromResponse(Map<String, dynamic> response) {
    final data = _map(response['data']);
    return RiskRewardQuote(
      market: _text(data['market']),
      symbol: _text(data['symbol']),
      price: _number(data['price']) ?? 0,
      displayPrice: _text(
        data['display_price'],
        data['price']?.toString() ?? '',
      ),
      observedAt: DateTime.tryParse(_text(data['observed_at_utc'])),
      provider: _text(data['provider']),
    );
  }
}

class DividendResult {
  const DividendResult(this.data);

  final Map<String, dynamic> data;
  factory DividendResult.fromResponse(Map<String, dynamic> response) =>
      DividendResult(_map(response['data']));

  String get symbol => _text(data['symbol']);
  String get currency => _text(data['currency'], 'USD');
  double? get annualGross => _number(data['projected_annual_gross']);
  double? get annualNet => _number(data['projected_annual_net']);
  double? get yieldPercent => _number(data['dividend_yield_percent']);
  double? get grossPerPayment => _number(data['gross_per_payment']);
  double? get investmentValue => _number(data['investment_value']);
  List<String> get warnings =>
      _list(data['warnings']).map((item) => item.toString()).toList();
}

class DividendHistory {
  const DividendHistory({
    required this.symbol,
    required this.companyName,
    required this.providerAvailable,
    required this.message,
    required this.history,
    required this.upcoming,
  });

  final String symbol;
  final String companyName;
  final bool providerAvailable;
  final String message;
  final List<Map<String, dynamic>> history;
  final Map<String, dynamic>? upcoming;

  factory DividendHistory.fromResponse(Map<String, dynamic> response) {
    final data = _map(response['data']);
    return DividendHistory(
      symbol: _text(data['symbol']),
      companyName: _text(data['company_name']),
      providerAvailable: data['provider_available'] == true,
      message: _text(data['message']),
      history: _list(data['history']).map(_map).toList(growable: false),
      upcoming: data['upcoming'] is Map ? _map(data['upcoming']) : null,
    );
  }
}

class SavedCalculation {
  const SavedCalculation({
    required this.uuid,
    required this.type,
    required this.title,
    required this.input,
    required this.result,
    required this.createdAt,
  });

  final String uuid;
  final String type;
  final String title;
  final Map<String, dynamic> input;
  final Map<String, dynamic> result;
  final DateTime? createdAt;

  factory SavedCalculation.fromJson(Object? raw) {
    final json = _map(raw);
    return SavedCalculation(
      uuid: _text(json['uuid']),
      type: _text(json['calculator_type']),
      title: _text(json['title'], 'Saved calculation'),
      input: _map(json['input']),
      result: _map(json['result']),
      createdAt: DateTime.tryParse(_text(json['created_at_utc'])),
    );
  }
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : const [];

String _text(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double? _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
