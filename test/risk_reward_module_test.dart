import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/risk_reward/data/risk_reward_repository.dart';
import 'package:tradex_mobile/features/risk_reward/models/risk_reward_models.dart';
import 'package:tradex_mobile/features/risk_reward/presentation/bloc/risk_reward_cubit.dart';
import 'package:tradex_mobile/features/risk_reward/presentation/risk_reward_module.dart';

void main() {
  testWidgets('risk reward dashboard is responsive and exposes four markets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRiskRewardDataSource();

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: RiskRewardHomeScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Risk Reward'), findsOneWidget);
    for (final market in const <String>['Forex', 'Deriv', 'Crypto', 'Stocks']) {
      await tester.scrollUntilVisible(
        find.text(market),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(market), findsOneWidget);
    }
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all seven risk reward views render without fake provider data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRiskRewardDataSource();
    final cubit = RiskRewardCubit(repository);
    await cubit.initialize();
    addTearDown(cubit.close);
    final stock = repository.catalogValue.stocks.first;
    final result = await repository.calculate(const <String, dynamic>{});
    final screens = <(Widget, String)>[
      (const ForexDerivCalculatorScreen(), 'Forex & Deriv'),
      (const CryptoRiskCalculatorScreen(), 'Crypto'),
      (const StockRiskCalculatorScreen(), 'Stocks Risk Reward'),
      (DividendCalculatorScreen(initialStock: stock), 'Dividend'),
      (DividendHistoryScreen(stock: stock), 'Verified provider unavailable'),
      (
        CalculationResultScreen(
          input: const <String, dynamic>{'market': 'forex'},
          result: result,
          type: 'risk_reward',
        ),
        'Calculation Result',
      ),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(
          theme: TradeXTheme.dark,
          home: BlocProvider.value(value: cubit, child: screen.$1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(screen.$2), findsWidgets);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'crypto mode switch keeps one screen and shows honest CFD state',
    (tester) async {
      final repository = _FakeRiskRewardDataSource();
      final cubit = RiskRewardCubit(repository);
      await cubit.initialize();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: TradeXTheme.dark,
          home: BlocProvider.value(
            value: cubit,
            child: const CryptoRiskCalculatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crypto CFD'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('Margin is shown only when'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Margin is shown only when'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('crypto-risk-calculator')),
        findsOneWidget,
      );
    },
  );

  testWidgets('forex symbol search selects a suggestion and fills live entry', (
    tester,
  ) async {
    final repository = _FakeRiskRewardDataSource();
    final cubit = RiskRewardCubit(repository);
    await cubit.initialize();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: BlocProvider.value(
          value: cubit,
          child: const ForexDerivCalculatorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('forex-deriv-symbol-search')),
      'GBP',
    );
    await tester.pump();
    expect(find.text('GBPUSD'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('symbol-suggestion-GBPUSD')));
    await tester.pumpAndSettle();

    final entry = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(entry.controller?.text, '1.23456');
    expect(find.textContaining('Entry price remains editable'), findsOneWidget);
  });

  testWidgets('both crypto modes search coins and fill editable live entry', (
    tester,
  ) async {
    final repository = _FakeRiskRewardDataSource();
    final cubit = RiskRewardCubit(repository);
    await cubit.initialize();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: BlocProvider.value(
          value: cubit,
          child: const CryptoRiskCalculatorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('forex-deriv-symbol-search')),
      'ETH',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('symbol-suggestion-ETHUSDT')));
    await tester.pumpAndSettle();
    var entry = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(entry.controller?.text, '65000.50');

    await tester.tap(find.text('Crypto CFD'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('forex-deriv-symbol-search')),
      'ETH',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('symbol-suggestion-ETHUSD')));
    await tester.pumpAndSettle();
    entry = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(entry.controller?.text, '65001.25');
  });

  testWidgets(
    'Binance Futures derives leverage from entry and stop without sending manual leverage',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakeRiskRewardDataSource();
      final cubit = RiskRewardCubit(repository);
      await cubit.initialize();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: TradeXTheme.dark,
          home: BlocProvider.value(
            value: cubit,
            child: const CryptoRiskCalculatorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('forex-deriv-symbol-search')),
        'BTC',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('symbol-suggestion-BTCUSDT')));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '65000');
      await tester.enterText(fields.at(1), '64350');
      await tester.enterText(fields.at(2), '100');
      await tester.pump();

      expect(find.text('Calculated Leverage'), findsOneWidget);
      expect(find.text('50x'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Calculate'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(repository.lastCalculation, isNot(contains('leverage')));
      expect(repository.lastCalculation, isNot(contains('take_profit')));
    },
  );

  test('cubit uses server result and preserves optional take profit', () async {
    final repository = _FakeRiskRewardDataSource();
    final cubit = RiskRewardCubit(repository);
    addTearDown(cubit.close);

    final result = await cubit.calculate(const <String, dynamic>{
      'market': 'forex',
      'symbol': 'EURUSD',
      'side': 'BUY',
      'entry': '1.1000',
      'stop_loss': '1.0950',
      'risk_amount': '100',
    });

    expect(result?.symbol, 'EURUSD');
    expect(repository.lastCalculation, isNot(contains('take_profit')));
    expect(cubit.state.result?.recommendedSize, 0.2);
  });

  test(
    'saving keeps the authoritative server calculation in history',
    () async {
      final repository = _FakeRiskRewardDataSource();
      final cubit = RiskRewardCubit(repository);
      addTearDown(cubit.close);
      const input = <String, dynamic>{
        'market': 'forex',
        'symbol': 'EURUSD',
        'side': 'BUY',
        'entry': '1.1000',
        'stop_loss': '1.0950',
        'risk_amount': '100',
      };

      await cubit.calculate(input);
      final saved = await cubit.saveCurrent(type: 'risk_reward', input: input);

      expect(saved, isTrue);
      expect(cubit.state.saved, hasLength(1));
      expect(cubit.state.saved.single.uuid, 'saved-1');
      expect(cubit.state.saving, isFalse);
    },
  );
}

final class _FakeRiskRewardDataSource implements RiskRewardDataSource {
  final drafts = <String, Map<String, dynamic>>{};
  Map<String, dynamic>? lastCalculation;

  final catalogValue = RiskRewardCatalog(
    markets: <String, RiskRewardMarket>{
      'forex': RiskRewardMarket(
        key: 'forex',
        label: 'Forex',
        description: 'Forex calculator',
        instruments: const <RiskRewardInstrument>[
          RiskRewardInstrument(
            symbol: 'EURUSD',
            name: 'Euro / US Dollar',
            data: <String, dynamic>{},
          ),
          RiskRewardInstrument(
            symbol: 'GBPUSD',
            name: 'British Pound / US Dollar',
            data: <String, dynamic>{},
          ),
        ],
        data: const <String, dynamic>{},
      ),
      'deriv': RiskRewardMarket(
        key: 'deriv',
        label: 'Deriv',
        description: 'Deriv calculator',
        instruments: const <RiskRewardInstrument>[
          RiskRewardInstrument(
            symbol: 'VOL75',
            name: 'Volatility 75',
            data: <String, dynamic>{},
          ),
        ],
        data: const <String, dynamic>{},
      ),
      'binance_futures': RiskRewardMarket(
        key: 'binance_futures',
        label: 'Binance Futures',
        description: 'Futures calculator',
        instruments: const <RiskRewardInstrument>[
          RiskRewardInstrument(
            symbol: 'BTCUSDT',
            name: 'Bitcoin / USDT',
            data: <String, dynamic>{},
          ),
          RiskRewardInstrument(
            symbol: 'ETHUSDT',
            name: 'Ethereum / USDT',
            data: <String, dynamic>{},
          ),
        ],
        data: const <String, dynamic>{},
      ),
      'crypto': RiskRewardMarket(
        key: 'crypto',
        label: 'Crypto CFD',
        description: 'Crypto CFD calculator',
        instruments: const <RiskRewardInstrument>[
          RiskRewardInstrument(
            symbol: 'BTCUSD',
            name: 'Bitcoin / US Dollar',
            data: <String, dynamic>{},
          ),
          RiskRewardInstrument(
            symbol: 'ETHUSD',
            name: 'Ethereum / US Dollar',
            data: <String, dynamic>{},
          ),
        ],
        data: const <String, dynamic>{},
      ),
    },
    stocks: const <StockInstrument>[
      StockInstrument(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        region: 'INTERNATIONAL',
        exchange: 'NASDAQ',
        currency: 'USD',
        dataMode: 'REFERENCE',
      ),
    ],
    dividendProviderAvailable: false,
    dividendMessage: 'Manual estimate mode.',
    disclaimer: 'Planning tool only.',
    isOffline: false,
    isStale: false,
  );

  @override
  Future<RiskRewardCatalog> catalog({bool forceRefresh = false}) async =>
      catalogValue;

  @override
  Future<RiskRewardQuote> quote({
    required String market,
    required String symbol,
    required String side,
  }) async {
    final displayPrice = switch (market) {
      'binance_futures' => '65000.50',
      'crypto' => '65001.25',
      _ => '1.23456',
    };
    return RiskRewardQuote(
      market: market,
      symbol: symbol,
      price: double.parse(displayPrice),
      displayPrice: displayPrice,
      observedAt: DateTime.utc(2026, 10, 29),
      provider: 'TEST',
    );
  }

  @override
  Future<RiskRewardResult> calculate(Map<String, dynamic> input) async {
    lastCalculation = Map<String, dynamic>.from(input);
    return RiskRewardResult(<String, dynamic>{
      'market': input['market'] ?? 'forex',
      'market_label': 'Forex',
      'symbol': input['symbol'] ?? 'EURUSD',
      'instrument_name': 'Euro / US Dollar',
      'side': input['side'] ?? 'BUY',
      'recommended_lot': 0.2,
      'position_units': 20000,
      'actual_risk': 100,
      'potential_profit': 500,
      'risk_reward_ratio': 5,
      if (input['market'] == 'binance_futures')
        'futures': <String, dynamic>{
          'required_initial_margin': 200,
          'leverage': 50,
          'leverage_auto_calculated': true,
        },
      'warnings': <String>['Verify live broker specifications.'],
    });
  }

  @override
  Future<DividendResult> calculateDividend(Map<String, dynamic> input) async =>
      DividendResult(<String, dynamic>{
        'symbol': input['symbol'] ?? 'AAPL',
        'currency': 'USD',
        'projected_annual_gross': 100,
        'projected_annual_net': 90,
        'dividend_yield_percent': 1.2,
        'gross_per_payment': 25,
        'investment_value': 8000,
        'warnings': <String>['Manual estimate.'],
      });

  @override
  Future<DividendHistory> dividendHistory(String symbol) async =>
      DividendHistory(
        symbol: symbol,
        companyName: 'Apple Inc.',
        providerAvailable: false,
        message: 'No approved dividend provider is connected.',
        history: const <Map<String, dynamic>>[],
        upcoming: null,
      );

  @override
  Future<List<SavedCalculation>> saved() async => const <SavedCalculation>[];

  @override
  Future<SavedCalculation> save({
    required String type,
    required Map<String, dynamic> input,
    String? title,
  }) async => SavedCalculation(
    uuid: 'saved-1',
    type: type,
    title: title ?? 'Saved calculation',
    input: input,
    result: const <String, dynamic>{},
    createdAt: DateTime.utc(2026, 10, 28),
  );

  @override
  Future<Map<String, dynamic>?> loadDraft(String key) async => drafts[key];

  @override
  Future<void> saveDraft(String key, Map<String, dynamic> value) async {
    drafts[key] = Map<String, dynamic>.from(value);
  }

  @override
  Future<void> clearDraft(String key) async => drafts.remove(key);
}
