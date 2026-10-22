import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
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
        home: CryptoMarketScreen(apiClient: api),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Crypto Market'), findsOneWidget);
    expect(find.text('All Crypto Coins'), findsOneWidget);
    expect(find.text('24h Volume'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('All Crypto Coins')).dy,
      lessThan(tester.getTopLeft(find.text('24h Volume')).dy),
    );
    expect(find.text('BTCUSDT'), findsWidgets);
    expect(find.text('PRICE'), findsOneWidget);
    expect(find.text('24H CHANGE'), findsOneWidget);
    expect(find.text('TREND'), findsOneWidget);
    expect(find.text('BULLISH'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open map'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Live Gainers Map'), findsOneWidget);
    expect(find.text('Gainers'), findsOneWidget);
    expect(find.text('Losers'), findsOneWidget);
    await tester.tap(find.text('Losers'));
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('crypto market ends with filtered crypto trade idea cards', (
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
      find.text('Crypto Trade Ideas'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Crypto Trade Ideas'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('crypto-trade-idea-crypto-idea-1')),
      findsOneWidget,
    );
    expect(find.text('Open TradingView chart'), findsOneWidget);
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

  test('bubble repository limits the ranked bubble field to twenty', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _CryptoApiClient(
      store,
      DeviceIdentity(store),
      bubbleAssets: List.generate(
        25,
        (index) => _CryptoApiClient.asset(
          symbol: 'COIN${index.toString().padLeft(2, '0')}USDT',
          changePercent: 25 - index.toDouble(),
          quoteVolume: 1000000 - index.toDouble(),
        ),
      ),
    );

    final market = await CryptoMarketRepository(api).load(segment: 'SPOT');

    expect(market.bubbleAssets, hasLength(20));
    expect(market.bubbleAssets.first.symbol, 'COIN00USDT');
    expect(market.bubbleAssets.last.symbol, 'COIN19USDT');
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
    await tester.scrollUntilVisible(
      find.text('All Crypto Coins'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(find.byType(TextField), 'BTC');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('SPOT'), findsOneWidget);
    expect(find.text('FUTURES'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'BTCUSDT.P');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('FUTURES'), findsOneWidget);
    expect(find.text('SPOT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('TradingView ticker selects Spot and Futures correctly', () {
    expect(tradingViewTicker('BTCUSDT', 'SPOT'), 'BINANCE:BTCUSDT');
    expect(tradingViewTicker('BTCUSDT', 'FUTURES'), 'BINANCE:BTCUSDT.P');
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

  @override
  Future<String?> currentAccountStorageKey() async => null;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/trade-ideas?')) {
      if (path.contains('category=CRYPTO')) cryptoTradeIdeasRequestCount++;
      return {
        'data': {
          'trade_ideas': [
            {'uuid': 'crypto-idea-1', 'category': 'CRYPTO'},
          ],
        },
      };
    }
    if (path == '/api/v1/trade-ideas/crypto-idea-1') {
      return {
        'data': {
          'trade_idea': {
            'uuid': 'crypto-idea-1',
            'category': 'CRYPTO',
            'symbol': 'BTCUSDT',
            'instrument_name': 'Bitcoin / Tether',
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
          'bubbles': selectedBubbles,
          'assets': selectedBubbles,
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
    double changePercent = 2.4,
    double quoteVolume = 2500000000,
  }) => {
    'symbol': symbol,
    'name': '${symbol.replaceAll('USDT', '')} / Tether',
    'base_currency': symbol.replaceAll('USDT', ''),
    'quote_currency': 'USDT',
    'logo_url': '',
    'price': 68000,
    'change_percent': changePercent,
    'trend': 'BULLISH',
    'quote_volume': quoteVolume,
  };
}
