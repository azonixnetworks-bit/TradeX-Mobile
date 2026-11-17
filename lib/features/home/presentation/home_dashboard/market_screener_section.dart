part of '../home_dashboard_screen.dart';

class _HomeMarketScreener extends StatefulWidget {
  const _HomeMarketScreener({required this.apiClient});

  final ApiGateway apiClient;

  @override
  State<_HomeMarketScreener> createState() => _HomeMarketScreenerState();
}

class _HomeMarketScreenerState extends State<_HomeMarketScreener>
    with WidgetsBindingObserver {
  static const _markets = <(String, String)>[
    ('CRYPTO', 'Crypto'),
    ('FOREX', 'Forex'),
    ('STOCKS', 'Stocks'),
    ('DERIV', 'Deriv'),
    ('COMMODITY', 'Commodity'),
    ('INDICES', 'Indices'),
  ];
  static const _stockRegions = <(String, String)>[
    ('SRI_LANKA', 'CSE'),
    ('INDIA', 'India'),
    ('INTERNATIONAL', 'International'),
  ];

  String _market = 'CRYPTO';
  String _stockRegion = 'INTERNATIONAL';
  List<_HomeScreenerQuote> _quotes = const [];
  Timer? _timer;
  bool _loading = true;
  int _requestVersion = 0;
  String? _error;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _load({bool silent = false}) async {
    final requestVersion = ++_requestVersion;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final requestedMarket = _market;
    final requestedStockRegion = _stockRegion;
    final stockQuery = requestedMarket == 'STOCKS'
        ? '&region=$requestedStockRegion'
        : '';
    final timeframe =
        requestedMarket == 'STOCKS' && requestedStockRegion != 'INTERNATIONAL'
        ? 'D1'
        : 'H1';
    try {
      final response = await widget.apiClient.getJson(
        '/api/v1/screener/results?market=$requestedMarket'
        '&timeframe=$timeframe$stockQuery'
        '&sort=change_percent&order=desc',
      );
      final data = _screenerMap(response['data']);
      final rows = _screenerRows(data['results'])
          .map(_HomeScreenerQuote.fromJson)
          .where((quote) => quote.symbol.isNotEmpty)
          .take(5)
          .toList(growable: false);
      if (!mounted ||
          requestVersion != _requestVersion ||
          requestedMarket != _market ||
          requestedStockRegion != _stockRegion) {
        return;
      }
      setState(() {
        _quotes = rows;
        _loading = false;
        _error = null;
        _updatedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted ||
          requestVersion != _requestVersion ||
          requestedMarket != _market ||
          requestedStockRegion != _stockRegion) {
        return;
      }
      setState(() {
        _loading = false;
        if (_quotes.isEmpty) {
          _error = '$requestedMarket live data is temporarily unavailable.';
        }
      });
    }
  }

  void _selectMarket(String market) {
    if (market == _market) return;
    setState(() {
      _market = market;
      _quotes = const [];
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _selectStockRegion(String region) {
    if (region == _stockRegion) return;
    setState(() {
      _stockRegion = region;
      _quotes = const [];
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _openChart(_HomeScreenerQuote quote) {
    final qualifiedSymbol = _screenerTradingViewSymbol(
      market: _market,
      quote: quote,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/market-screener/tradingview'),
        builder: (_) => TradingViewChartScreen.qualified(
          qualifiedSymbol: qualifiedSymbol,
          interval: _market == 'STOCKS' && _stockRegion != 'INTERNATIONAL'
              ? 'D'
              : '60',
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const ValueKey('home-market-screener'),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: palette.goldText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Market Screener',
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.success.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: palette.success.withValues(alpha: .5),
                  ),
                ),
                child: Text(
                  'LIVE · 15S',
                  style: TextStyle(
                    color: palette.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _markets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final market = _markets[index];
                final selected = market.$1 == _market;
                return ChoiceChip(
                  key: ValueKey('home-screener-${market.$1.toLowerCase()}'),
                  label: Text(market.$2),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: palette.gold,
                  backgroundColor: palette.surfaceRaised,
                  side: BorderSide(
                    color: selected ? palette.gold : palette.borderStrong,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : palette.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => _selectMarket(market.$1),
                );
              },
            ),
          ),
          if (_market == 'STOCKS') ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                key: const ValueKey('home-screener-stock-regions'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _stockRegions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final region = _stockRegions[index];
                  final selected = region.$1 == _stockRegion;
                  return ChoiceChip(
                    key: ValueKey(
                      'home-screener-stock-${region.$1.toLowerCase()}',
                    ),
                    label: Text(region.$2),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: palette.gold,
                    backgroundColor: palette.surfaceRaised,
                    side: BorderSide(
                      color: selected ? palette.gold : palette.borderStrong,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : palette.primaryText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                    onSelected: (_) => _selectStockRegion(region.$1),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_loading && _quotes.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _quotes.isEmpty)
            _HomeScreenerMessage(message: _error!, onRetry: _load)
          else if (_quotes.isEmpty)
            const _HomeScreenerMessage(
              message: 'No live instruments are available for this market.',
            )
          else ...[
            Row(
              children: [
                Text(
                  'Latest ${_quotes.length}',
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_updatedAt != null)
                  Text(
                    'Updated ${_screenerTime(_updatedAt!)}',
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            for (var index = 0; index < _quotes.length; index++) ...[
              _HomeScreenerRow(
                quote: _quotes[index],
                onTap: () => _openChart(_quotes[index]),
              ),
              if (index != _quotes.length - 1)
                Divider(height: 1, color: palette.border),
            ],
          ],
        ],
      ),
    );
  }
}

class _HomeScreenerRow extends StatelessWidget {
  const _HomeScreenerRow({required this.quote, required this.onTap});

  final _HomeScreenerQuote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final positive = quote.changePercent >= 0;
    final movement = positive ? palette.success : palette.error;
    return InkWell(
      key: ValueKey('home-screener-quote-${quote.symbol}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.goldSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                quote.symbol.substring(0, math.min(3, quote.symbol.length)),
                style: TextStyle(
                  color: palette.goldText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    quote.trend,
                    maxLines: 1,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _screenerPrice(quote.price),
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 62,
              child: Text(
                '${positive ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: movement,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.candlestick_chart_rounded,
              size: 16,
              color: palette.goldText,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenerMessage extends StatelessWidget {
  const _HomeScreenerMessage({required this.message, this.onRetry});

  final String message;
  final Future<void> Function({bool silent})? onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 140,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.query_stats_rounded, color: context.palette.goldText),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 12,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: () => onRetry!(), child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _HomeScreenerQuote {
  const _HomeScreenerQuote({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.trend,
    required this.exchange,
    required this.tradingViewSymbol,
  });

  factory _HomeScreenerQuote.fromJson(Map<String, dynamic> json) =>
      _HomeScreenerQuote(
        symbol: json['symbol']?.toString().trim().toUpperCase() ?? '',
        price: _screenerNumber(json['close'] ?? json['price']),
        changePercent: _screenerNumber(json['change_percent']),
        trend: json['trend']?.toString().trim().toUpperCase() ?? 'LIVE',
        exchange: json['exchange']?.toString().trim().toUpperCase() ?? '',
        tradingViewSymbol:
            json['tradingview_symbol']?.toString().trim().toUpperCase() ?? '',
      );

  final String symbol;
  final double price;
  final double changePercent;
  final String trend;
  final String exchange;
  final String tradingViewSymbol;
}

String _screenerTradingViewSymbol({
  required String market,
  required _HomeScreenerQuote quote,
}) {
  if (quote.tradingViewSymbol.contains(':')) return quote.tradingViewSymbol;
  final symbol = quote.symbol.replaceAll(RegExp(r'[^A-Z0-9._-]'), '');
  final resolved = const TradeIdeaTradingViewSymbolResolver().resolve(
    category: market,
    symbol: symbol,
  );
  if (resolved != null) return resolved;
  return switch (market) {
    'CRYPTO' => 'BINANCE:$symbol',
    'FOREX' => 'OANDA:$symbol',
    'STOCKS' => '${_stockTradingViewExchange(quote.exchange)}:$symbol',
    'COMMODITY' =>
      symbol == 'XAUUSD' || symbol == 'XAGUSD'
          ? 'OANDA:$symbol'
          : 'TVC:$symbol',
    'INDICES' => 'TVC:$symbol',
    'DERIV' => 'OANDA:$symbol',
    _ => 'TVC:$symbol',
  };
}

String _stockTradingViewExchange(String exchange) => switch (exchange) {
  'NASDAQ' || 'NYSE' || 'NSE' || 'BSE' => exchange,
  'CSE' || 'XCOL' => 'CSELK',
  _ => 'NASDAQ',
};

Map<String, dynamic> _screenerMap(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

List<Map<String, dynamic>> _screenerRows(Object? value) => value is List
    ? value.map(_screenerMap).toList(growable: false)
    : const <Map<String, dynamic>>[];

double _screenerNumber(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

String _screenerPrice(double value) {
  if (value == 0) return '—';
  if (value.abs() >= 1000) return value.toStringAsFixed(2);
  if (value.abs() >= 1) return value.toStringAsFixed(4);
  return value.toStringAsFixed(6);
}

String _screenerTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
