import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/market/data/binance_live_ticker_service.dart';
import 'package:tradex_mobile/features/market/data/crypto_market_repository.dart';
import 'package:tradex_mobile/features/market/presentation/crypto_market_screen.dart';
import 'package:tradex_mobile/features/market/presentation/crypto_market_cubit.dart';
import 'package:tradex_mobile/features/market/presentation/trading_view_chart_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crypto market initializes without async setState error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(store, DeviceIdentity(store));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CryptoMarketScreen(
          apiClient: api,
          enableDirectBubbleStream: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Crypto Market'), findsOneWidget);
    expect(find.text('All Crypto Coins'), findsOneWidget);
    expect(find.text('Search BTC, ETH, SOL...'), findsOneWidget);
    expect(find.text('Spot'), findsOneWidget);
    expect(find.text('Futures'), findsOneWidget);
    expect(find.text('BTCUSDT'), findsWidgets);
    expect(find.text(r'$68000.00'), findsOneWidget);
    expect(find.text('+2.40%'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Open BTCUSDT Spot chart',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Open map'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Live Gainers Map'), findsOneWidget);
    expect(find.text('Gainers'), findsWidgets);
    expect(find.text('Losers'), findsWidgets);
    await tester.tap(find.text('Losers').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Live Losers Map'), findsOneWidget);
    expect(api.lastBubbleRequestPath, contains('bubble_mode=LOSERS'));
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(api.bubbleRequestCount, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('crypto market keeps usable catalog when bubbles API is absent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(
      store,
      DeviceIdentity(store),
      failBubbles: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CryptoMarketScreen(apiClient: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.text('Limited market data · server update required'),
      findsOneWidget,
    );
    expect(
      find.text('Live crypto market is temporarily unavailable.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all crypto section shows five cards in its default batch', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(
      store,
      DeviceIdentity(store),
      pagedCatalog: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CryptoMarketScreen(apiClient: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('crypto-coin-batch-0')), findsOneWidget);
    for (var index = 0; index < 5; index++) {
      expect(find.text('COIN${index}USDT'), findsOneWidget);
    }
    expect(find.text('COI'), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('crypto market starts with five swipeable crypto signals', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(store, DeviceIdentity(store));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CryptoMarketScreen(apiClient: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Crypto Trade Ideas'), findsOneWidget);
    expect(find.text('RECENT SIGNAL'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('crypto-trade-idea-crypto-idea-1')),
      findsOneWidget,
    );
    expect(find.text('Open TradingView chart'), findsOneWidget);

    final carousel = find.byKey(const ValueKey('crypto-trade-ideas-carousel'));
    expect(tester.getSize(carousel).height, 184);
    await tester.ensureVisible(carousel);
    await tester.fling(carousel, const Offset(-500, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('PREVIOUS 2 / 5'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('crypto-trade-idea-crypto-idea-2')),
      findsOneWidget,
    );
    expect(api.cryptoTradeIdeasRequestCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coin watchlist persists and opens on its own screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(store, DeviceIdentity(store));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CryptoMarketScreen(apiClient: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.scrollUntilVisible(
      find.text('All Crypto Coins'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    final addStar = find.byTooltip('Add BTCUSDT to watchlist').first;
    await tester.ensureVisible(addStar);
    await tester.tap(addStar);
    await tester.pump();

    expect(find.byTooltip('Remove BTCUSDT from watchlist'), findsWidgets);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('crypto_watchlist_symbols_v1'),
      contains('SPOT:BTCUSDT'),
    );

    await tester.tap(find.byTooltip('Open watchlist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('My Watchlist'), findsOneWidget);
    expect(find.text('1 saved coin'), findsOneWidget);
    expect(find.text('BTCUSDT'), findsWidgets);
    expect(find.text('BULLISH'), findsWidgets);

    await tester.tap(find.byTooltip('Remove BTCUSDT from watchlist').last);
    await tester.pump();
    expect(find.text('Your watchlist is empty'), findsOneWidget);
    expect(preferences.getStringList('crypto_watchlist_symbols_v1'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('bubble repository ranks live assets and fills after gainers', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(
      store,
      DeviceIdentity(store),
      bubbleAssets: [
        _CryptoApiClient.asset(
          symbol: 'BTCUSDT',
          changePercent: 1,
          quoteVolume: 3000000,
        ),
        _CryptoApiClient.asset(
          symbol: 'ETHUSDT',
          changePercent: 8,
          quoteVolume: 2000000,
        ),
        _CryptoApiClient.asset(
          symbol: 'XRPUSDT',
          changePercent: 4,
          quoteVolume: 1000000,
        ),
        _CryptoApiClient.asset(
          symbol: 'BNBUSDT',
          changePercent: -5,
          quoteVolume: 4000000,
        ),
      ],
    );

    final market = await CryptoMarketRepository(api).load(segment: 'SPOT');

    expect(market.bubbleAssets.map((asset) => asset.symbol), [
      'ETHUSDT',
      'XRPUSDT',
      'BTCUSDT',
      'BNBUSDT',
    ]);
  });

  test('bubble repository limits the ranked bubble field to fifty', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(
      store,
      DeviceIdentity(store),
      bubbleAssets: List.generate(
        60,
        (index) => _CryptoApiClient.asset(
          symbol: 'COIN${index.toString().padLeft(2, '0')}USDT',
          changePercent: 60 - index.toDouble(),
          quoteVolume: 1000000 - index.toDouble(),
        ),
      ),
    );

    final market = await CryptoMarketRepository(api).load(segment: 'SPOT');

    expect(market.bubbleAssets, hasLength(50));
    expect(market.bubbleAssets.first.symbol, 'COIN00USDT');
    expect(market.bubbleAssets.last.symbol, 'COIN49USDT');
    expect(api.lastBubbleRequestPath, contains('per_page=50'));
  });

  test('bubble repository requests and ranks live losers', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final losers = [
      _CryptoApiClient.asset(symbol: 'BTCUSDT', changePercent: 1),
      _CryptoApiClient.asset(symbol: 'ETHUSDT', changePercent: -8),
      _CryptoApiClient.asset(symbol: 'XRPUSDT', changePercent: -4),
      _CryptoApiClient.asset(symbol: 'BNBUSDT', changePercent: 3),
    ];
    final api = _CryptoApiClient(
      store,
      DeviceIdentity(store),
      loserBubbleAssets: losers,
    );

    final update = await CryptoMarketRepository(api)
        .loadBubbleUpdate(segment: 'SPOT', mode: CryptoBubbleMode.losers);

    expect(update.assets.map((asset) => asset.symbol), [
      'ETHUSDT',
      'XRPUSDT',
      'BTCUSDT',
      'BNBUSDT',
    ]);
    expect(api.lastBubbleRequestPath, contains('bubble_mode=LOSERS'));
  });

  testWidgets('coin search shows both markets and dot P selects futures', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(store, DeviceIdentity(store));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: CryptoMarketScreen(apiClient: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.enterText(find.byType(TextField), 'BTC');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('crypto-search-suggestions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('crypto-search-suggestion-SPOT:BTCUSDT')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('SPOT'), findsWidgets);
    expect(find.text('FUTURES'), findsWidgets);
    expect(
      find.byKey(const ValueKey('crypto-search-suggestion-FUTURES:BTCUSDT')),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'BTCUSDT.P');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('FUTURES'), findsWidgets);
    expect(find.text('SPOT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('TradingView ticker selects Spot and Futures correctly', () {
    expect(tradingViewTicker('BTCUSDT', 'SPOT'), 'BINANCE:BTCUSDT');
    expect(tradingViewTicker('BTCUSDT', 'FUTURES'), 'BINANCE:BTCUSDT.P');
  });

  test('Binance mini ticker parser returns live bubble values', () {
    final updates = parseBinanceMiniTickerPayload(
      jsonEncode([
        {'s': 'BTCUSDT', 'c': '105', 'o': '100', 'q': '1250000'},
        {'s': 'ETHBTC', 'c': '0.04', 'o': '0.03', 'q': '100'},
      ]),
    );

    expect(updates.keys, ['BTCUSDT']);
    expect(updates['BTCUSDT']?.price, 105);
    expect(updates['BTCUSDT']?.changePercent, 5);
    expect(updates['BTCUSDT']?.quoteVolume, 1250000);
  });

  test('bubble map applies Binance ticks over the Laravel snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final service = _FakeBinanceLiveTickerService();
    final cubit = CryptoBubbleMapCubit(
      CryptoMarketRepository(_CryptoApiClient(store, DeviceIdentity(store))),
      segment: 'SPOT',
      initialGainers: [CryptoAsset.fromJson(_CryptoApiClient.asset())],
      liveTickerService: service,
    );

    await cubit.setLivePricesEnabled(true);
    service.add(
      const BinanceLiveTicker(
        symbol: 'BTCUSDT',
        price: 71234.5,
        changePercent: 4.25,
        quoteVolume: 9900000,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.assets.first.price, 71234.5);
    expect(cubit.state.assets.first.changePercent, 4.25);
    expect(cubit.state.assets.first.quoteVolume, 9900000);
    await cubit.close();
    await service.close();
  });

  test('catalog metadata is enriched with live ticker price and change', () {
    const catalog = CryptoAsset(
      symbol: 'BTCUSDT',
      name: 'Bitcoin / Tether',
      baseCurrency: 'BTC',
      logoUrl: '',
      price: 0,
      changePercent: 0,
      quoteVolume: 0,
    );
    const ticker = CryptoAsset(
      symbol: 'BTCUSDT',
      name: 'BTC / USDT',
      baseCurrency: 'BTC',
      logoUrl: '',
      price: 70123.45,
      changePercent: 2.75,
      quoteVolume: 9000000,
    );

    final enriched = catalog.mergeMarket(ticker);

    expect(enriched.price, 70123.45);
    expect(enriched.changePercent, 2.75);
    expect(enriched.quoteVolume, 9000000);
  });

  test('live refresh updates prices for coins already on screen', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(store, DeviceIdentity(store));
    final cubit = CryptoMarketCubit(CryptoMarketRepository(api));

    await cubit.initialize();
    expect(cubit.state.snapshot?.assets.first.price, 68000);

    api.liveBubblePrice = 69125.5;
    await cubit.refreshBubbles();

    expect(cubit.state.snapshot?.assets.first.price, 69125.5);
    await cubit.close();
  });

  test('right-to-left paging appends the next coin batch', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final cubit = CryptoMarketCubit(
      CryptoMarketRepository(
        _CryptoApiClient(store, DeviceIdentity(store), pagedCatalog: true),
      ),
    );

    await cubit.initialize();
    expect(cubit.state.snapshot?.assets, hasLength(10));
    expect(cubit.state.snapshot?.pagination.hasMore, isTrue);

    await cubit.nextPage();
    expect(cubit.state.snapshot?.assets, hasLength(11));
    expect(cubit.state.snapshot?.assets.last.symbol, 'EXTRAUSDT');
    await cubit.close();
  });
}

class _FakeBinanceLiveTickerService extends BinanceLiveTickerService {
  final _controller =
      StreamController<Map<String, BinanceLiveTicker>>.broadcast();

  @override
  Stream<Map<String, BinanceLiveTicker>> watch(String segment) =>
      _controller.stream;

  void add(BinanceLiveTicker ticker) {
    _controller.add({ticker.symbol: ticker});
  }

  Future<void> close() => _controller.close();
}

class _CryptoApiClient extends TradeXApiClient {
  _CryptoApiClient(
    super.sessionStore,
    super.deviceIdentity, {
    this.failBubbles = false,
    this.bubbleAssets,
    this.loserBubbleAssets,
    this.pagedCatalog = false,
  });

  final bool failBubbles;
  final List<Map<String, dynamic>>? bubbleAssets;
  final List<Map<String, dynamic>>? loserBubbleAssets;
  final bool pagedCatalog;
  var bubbleRequestCount = 0;
  String? lastBubbleRequestPath;
  var cryptoTradeIdeasRequestCount = 0;
  double liveBubblePrice = 68000;

  @override
  Future<String?> currentAccountStorageKey() async => null;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/trade-ideas?')) {
      if (path.contains('category=CRYPTO')) cryptoTradeIdeasRequestCount++;
      return {
        'data': {
          'trade_ideas': List.generate(
            5,
            (index) => {
              'uuid': 'crypto-idea-${index + 1}',
              'category': 'CRYPTO',
            },
          ),
        },
      };
    }
    if (path.startsWith('/api/v1/trade-ideas/crypto-idea-')) {
      final ideaNumber = int.tryParse(path.split('-').last) ?? 1;
      return {
        'data': {
          'trade_idea': {
            'uuid': 'crypto-idea-$ideaNumber',
            'category': 'CRYPTO',
            'symbol': ideaNumber == 1 ? 'BTCUSDT' : 'ETHUSDT',
            'instrument_name': ideaNumber == 1
                ? 'Bitcoin / Tether'
                : 'Ethereum / Tether',
            'direction': 'BUY',
            'timeframe': 'H1',
            'entry': {'low': '68000', 'high': '68200'},
            'stop_loss': {'current': '67000'},
            'targets': [
              {'label': 'TP1', 'price': '70000'},
            ],
            'chart_available': false,
            'tradingview_url':
                'https://www.tradingview.com/chart/?symbol=BINANCE:BTCUSDT',
            'timeline': <dynamic>[],
            'reactions': {
              'likes_count': 2,
              'dislikes_count': 0,
              'viewer_reaction': null,
            },
          },
        },
      };
    }
    if (path.startsWith('/api/v1/screener/bubbles')) {
      bubbleRequestCount++;
      lastBubbleRequestPath = path;
      if (failBubbles) throw StateError('Route not deployed');
      final selectedBubbles = path.contains('bubble_mode=LOSERS')
          ? loserBubbleAssets ??
                [
                  asset(
                    symbol: 'ETHUSDT',
                    changePercent: -3.4,
                    quoteVolume: 1800000000,
                  ),
                ]
          : bubbleAssets ?? [asset()];
      final liveBubbles = path.contains('bubble_mode=LOSERS')
          ? selectedBubbles
          : bubbleAssets ?? [asset(price: liveBubblePrice)];
      return {
        'data': {
          'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
          'stale': false,
          'summary': {
            'total_quote_volume': 2500000000,
            'average_change': 1.25,
            'gainers': 12,
            'losers': 8,
          },
          'bubble_selection': path.contains('bubble_mode=LOSERS')
              ? 'TOP_LOSERS_24H'
              : 'TOP_GAINERS_24H',
          'bubbles': liveBubbles,
          'assets': liveBubbles,
          'pagination': {
            'current_page': 1,
            'last_page': 1,
            'total': 1,
            'has_more': false,
          },
          'partial_data': false,
        },
      };
    }
    if (path.startsWith('/api/v1/screener/symbols')) {
      final query = Uri.parse(path).queryParameters;
      final segment = query['segment'] ?? 'SPOT';
      final page = int.tryParse(query['page'] ?? '') ?? 1;
      final symbols = pagedCatalog
          ? page == 1
                ? List.generate(
                    10,
                    (index) => asset(symbol: 'COIN${index}USDT'),
                  )
                : [asset(symbol: 'EXTRAUSDT')]
          : [asset()];
      return {
        'data': {
          'segment': segment,
          'symbols': symbols,
          'pagination': {
            'current_page': page,
            'last_page': pagedCatalog ? 2 : 1,
            'total': pagedCatalog ? 11 : 1,
            'has_more': pagedCatalog && page == 1,
          },
        },
      };
    }
    if (path.startsWith('/api/v1/screener/results')) {
      return {
        'data': {
          'results': [asset()],
        },
      };
    }
    throw StateError('Unexpected request: $path');
  }

  static Map<String, dynamic> asset({
    String symbol = 'BTCUSDT',
    double price = 68000,
    double changePercent = 2.4,
    double quoteVolume = 2500000000,
  }) => {
    'symbol': symbol,
    'name': '${symbol.replaceAll('USDT', '')} / Tether',
    'base_currency': symbol.replaceAll('USDT', ''),
    'quote_currency': 'USDT',
    'logo_url': '',
    'price': price,
    'change_percent': changePercent,
    'trend': 'BULLISH',
    'quote_volume': quoteVolume,
  };
}
