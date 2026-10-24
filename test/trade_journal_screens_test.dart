import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/journal/data/trade_journal_models.dart';
import 'package:tradex_mobile/features/journal/data/trade_journal_repository.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_home_screen.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_insights_screens.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_risk_psychology_sections.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_strategy_section.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_trade_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all twelve trade journal screens render without bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');
    final entry = TradeJournalEntry.fromJson(_JournalApiClient.entry());
    final screens = <(Widget, String)>[
      (
        TradeJournalHomeScreen(apiClient: api, repository: repository),
        'Trade Journal',
      ),
      (TradeJournalEntriesScreen(repository: repository), 'All Trades'),
      (TradeJournalPlanScreen(repository: repository), 'Plan a Trade'),
      (
        TradeJournalDetailsScreen(repository: repository, entry: entry),
        'Trade Details',
      ),
      (
        TradeJournalPlanScreen(repository: repository, entry: entry),
        'Edit Planned Trade',
      ),
      (
        TradeJournalOpenScreen(repository: repository, entry: entry),
        'Open Trade',
      ),
      (
        TradeJournalCloseScreen(repository: repository, entry: entry),
        'Close Trade',
      ),
      (TradeJournalAnalyticsScreen(repository: repository), 'Trade Analytics'),
      (
        TradeJournalReviewScreen(repository: repository, type: 'weekly'),
        'Weekly Review',
      ),
      (
        TradeJournalReviewScreen(repository: repository, type: 'monthly'),
        'Monthly Review',
      ),
      (TradeJournalFiltersScreen(repository: repository), 'Search & Filters'),
      (
        TradeJournalScreenshotsScreen(repository: repository, entry: entry),
        'Trade Screenshots',
      ),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(theme: TradeXTheme.dark, home: screen.$1),
      );
      await tester.pumpAndSettle();
      expect(find.text(screen.$2), findsOneWidget, reason: screen.$2);
      expect(find.byType(BottomNavigationBar), findsNothing);
      final exception = tester.takeException();
      if (exception != null) throw exception;
    }
  });

  testWidgets('journal home opens the real all trades list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalHomeScreen(apiClient: api, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Net P&L'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('All Trades'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('All Trades'));
    await tester.pumpAndSettle();
    expect(find.text('Search, filter and review your journal'), findsOneWidget);
    expect(find.text('BTCUSDT'), findsOneWidget);
    expect(
      api.paths.any((path) => path.startsWith('/api/v1/trade-journal?')),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan trade suggests market symbols and aligns trade choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalPlanScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final strategySection = find.byKey(
      const ValueKey('strategy-reason-section'),
    );
    final tradeSetupCard = find.byKey(
      const ValueKey('strategy-trade-setup-card'),
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('trade-symbol-field')),
        matching: strategySection,
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trade-direction-selector')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('trade-status-selector')), findsNothing);
    for (final key in const [
      ValueKey('strategy-entry-buy'),
      ValueKey('strategy-entry-sell'),
      ValueKey('strategy-entry-planned'),
      ValueKey('strategy-entry-open'),
    ]) {
      expect(
        find.ancestor(of: find.byKey(key), matching: strategySection),
        findsOneWidget,
      );
    }
    expect(
      tester.getTopLeft(tradeSetupCard).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('strategy-htf-MN'))).dy,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('trade-symbol-field')),
      'btc',
    );
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('trade-symbol-suggestions')),
      findsOneWidget,
    );
    expect(find.text('BTCUSDT'), findsOneWidget);
    expect(find.text('Bitcoin / Tether'), findsOneWidget);
    expect(
      api.paths.any(
        (path) =>
            path.startsWith('/api/v1/screener/symbols?') &&
            path.contains('market=CRYPTO') &&
            path.contains('search=BTC'),
      ),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('trade-symbol-BTCUSDT')));
    await tester.pump();
    final symbolField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('trade-symbol-field')),
    );
    expect(symbolField.controller?.text, 'BTCUSDT');
    expect(
      find.byKey(const ValueKey('trade-symbol-suggestions')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('trade-session-dropdown')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('trade-time-picker')), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-time-now')), findsOneWidget);
    expect(find.text('Broker'), findsNothing);
    expect(find.text('Account'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('trade-session-dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('Asia'), findsWidgets);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('New York'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    expect(find.text('Other Session (Optional)'), findsOneWidget);
    final otherSessionField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Other Session (Optional)'),
    );
    expect(otherSessionField.validator, isNull);

    final useCurrentTime = tester.widget<TextButton>(
      find.byKey(const ValueKey('trade-time-now')),
    );
    useCurrentTime.onPressed!();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium strategy controls keep independent responsive state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalPlanScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('trade-plan-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> reveal(Key key) async {
      await tester.scrollUntilVisible(
        find.byKey(key),
        260,
        scrollable: scrollable,
      );
      await tester.pump();
    }

    const mnUp = ValueKey('strategy-trend-MN-up');
    const mnDown = ValueKey('strategy-trend-MN-down');
    const w1Down = ValueKey('strategy-trend-W1-down');
    await reveal(mnUp);
    await tester.tap(find.byKey(mnUp));
    await tester.tap(find.byKey(w1Down));
    await tester.tap(find.byKey(mnDown));
    await tester.pumpAndSettle();
    expect(tester.widget<TrendOptionTile>(find.byKey(mnUp)).selected, isFalse);
    expect(tester.widget<TrendOptionTile>(find.byKey(mnDown)).selected, isTrue);
    expect(tester.widget<TrendOptionTile>(find.byKey(w1Down)).selected, isTrue);

    const htfZoneSupply = ValueKey('strategy-htf-zone-supply_demand');
    const htfZoneWick = ValueKey('strategy-htf-zone-wick');
    await reveal(htfZoneSupply);
    await tester.tap(find.byKey(htfZoneSupply));
    await tester.tap(find.byKey(htfZoneWick));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(htfZoneSupply)).selected,
      isTrue,
    );
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(htfZoneWick)).selected,
      isTrue,
    );

    const ltfZoneFvg = ValueKey('strategy-ltf-zone-fvg');
    const ltfZoneBankTrap = ValueKey('strategy-ltf-zone-bank_trap_entry');
    await reveal(ltfZoneFvg);
    await tester.tap(find.byKey(ltfZoneFvg));
    await tester.tap(find.byKey(ltfZoneBankTrap));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(ltfZoneFvg)).selected,
      isTrue,
    );
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(ltfZoneBankTrap)).selected,
      isTrue,
    );

    const zoneSupply = ValueKey('strategy-zone-M30-supply_demand');
    const zoneOrderFlow = ValueKey('strategy-zone-M30-orderflow');
    const zoneBankTrap = ValueKey('strategy-zone-M30-bank_trap_entry');
    await reveal(zoneSupply);
    await tester.tap(find.byKey(zoneSupply));
    await tester.tap(find.byKey(zoneOrderFlow));
    await tester.tap(find.byKey(zoneBankTrap));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(zoneSupply)).selected,
      isTrue,
    );
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(zoneOrderFlow)).selected,
      isTrue,
    );
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(zoneBankTrap)).selected,
      isTrue,
    );

    const confirmationMss = ValueKey('strategy-confirmation-M5-mss');
    const confirmationSms = ValueKey('strategy-confirmation-M5-sms');
    await reveal(confirmationMss);
    await tester.tap(find.byKey(confirmationMss));
    await tester.tap(find.byKey(confirmationSms));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(confirmationMss)).selected,
      isTrue,
    );
    expect(
      tester.widget<PremiumCheckboxTile>(find.byKey(confirmationSms)).selected,
      isTrue,
    );

    const directionPro = ValueKey('strategy-direction-pro');
    const directionCounter = ValueKey('strategy-direction-counter');
    await reveal(directionPro);
    await tester.tap(find.byKey(directionPro));
    await tester.tap(find.byKey(directionCounter));
    await tester.pumpAndSettle();
    expect(
      tester.widget<DirectionSelector>(find.byType(DirectionSelector)).value,
      'COUNTER',
    );

    const entrySell = ValueKey('strategy-entry-sell');
    await reveal(entrySell);
    await tester.tap(find.byKey(entrySell));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EntryTypeSelector>(find.byType(EntryTypeSelector)).value,
      'sell',
    );
    const entryOpen = ValueKey('strategy-entry-open');
    await tester.tap(find.byKey(entryOpen));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EntryTypeSelector>(find.byType(EntryTypeSelector)).status,
      'open',
    );

    const setupField = ValueKey('strategy-setup-field');
    await reveal(setupField);
    final field = tester.widget<TextFormField>(find.byKey(setupField));
    await tester.enterText(find.byKey(setupField), 'x' * 801);
    expect(field.controller?.text.length, 800);
    await tester.enterText(
      find.byKey(setupField),
      'Liquidity sweep and retest',
    );
    tester
        .widget<EntryTypeSelector>(find.byType(EntryTypeSelector))
        .onChanged('buy');
    await tester.pump();
    expect(field.controller?.text, 'Liquidity sweep and retest');
    expect(find.text('Reversal'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('strategy selections use the existing trade save workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalPlanScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('trade-plan-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.enterText(
      find.byKey(const ValueKey('trade-symbol-field')),
      'BTCUSDT',
    );
    final strategySection = find.byKey(
      const ValueKey('strategy-reason-section'),
    );
    await tester.scrollUntilVisible(
      strategySection,
      320,
      scrollable: scrollable,
    );
    final strategy = tester.widget<StrategyReasonSection>(
      find.byType(StrategyReasonSection),
    );
    strategy.onHtfChanged('MN', 'UP');
    strategy.onLtfChanged('H2', 'DOWN');
    strategy.onHtfZoneChanged('OB / Hidden OB');
    strategy.onLtfZoneChanged('Bank Trap Entry');
    strategy.onZoneChanged('M30', 'Supply / Demand');
    strategy.onConfirmationChanged('M5', 'MSS');
    strategy.onDirectionChanged('PRO');
    strategy.onEntryTypeChanged('sell');
    await tester.pump();
    final setup = 'Liquidity sweep confirmation ' * 10;
    final setupField = find.byKey(const ValueKey('strategy-setup-field'));
    tester.widget<TextFormField>(setupField).controller!.text = setup;
    await tester.pump();

    final save = find.byKey(const ValueKey('save-trade-button'));
    for (var attempt = 0; attempt < 12 && save.evaluate().isEmpty; attempt++) {
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(save, findsOneWidget);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(api.lastPostedPath, '/api/v1/trade-journal');
    final body = api.lastPostedBody!;
    expect(body['direction'], 'sell');
    expect(body['setup_strategy'].toString().length, 160);
    expect(body['timeframes'], ['M30', 'M5']);
    final encoded = body['entry_reason'].toString();
    expect(encoded, startsWith('TRADEX_STRATEGY_REASON_V1:'));
    final decodedStrategy = jsonDecode(encoded.split(':').skip(1).join(':'));
    expect(decodedStrategy['htf']['MN'], 'UP');
    expect(decodedStrategy['ltf']['H2'], 'DOWN');
    expect(decodedStrategy['htf_zones'], contains('OB / Hidden OB'));
    expect(decodedStrategy['ltf_zones'], contains('Bank Trap Entry'));
    expect(decodedStrategy['zone_finding']['M30'], contains('Supply / Demand'));
    expect(decodedStrategy['confirmation_finding']['M5'], contains('MSS'));
    expect(decodedStrategy['direction'], 'PRO');
    expect(decodedStrategy['entry_type'], 'sell');
    expect(decodedStrategy['strategy_setup'], setup.trim());
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium strategy layout does not overflow on narrow phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final repository = TradeJournalRepository(
      _JournalApiClient(store, DeviceIdentity(store)),
      'UTC',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalPlanScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('trade-plan-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('strategy-reason-section')),
      280,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(find.byType(StrategyReasonSection), findsOneWidget);
    expect(find.byType(ConfirmationFindingCard), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium risk and psychology controls preserve form state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final repository = TradeJournalRepository(
      _JournalApiClient(store, DeviceIdentity(store)),
      'UTC',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalPlanScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('trade-plan-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> jumpUntilBuilt(Finder finder) async {
      for (
        var attempt = 0;
        attempt < 30 && finder.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(finder, findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('strategy-reason-section')),
      320,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await jumpUntilBuilt(find.byKey(const ValueKey('price-risk-plan-section')));
    expect(find.byType(PriceRiskPlanSection), findsOneWidget);
    expect(find.byKey(const ValueKey('risk-stop-loss')), findsOneWidget);
    expect(find.byKey(const ValueKey('risk-take-profit')), findsOneWidget);
    expect(find.byKey(const ValueKey('risk-position-size')), findsOneWidget);
    expect(find.byKey(const ValueKey('risk-percent')), findsOneWidget);
    expect(find.byKey(const ValueKey('risk-amount')), findsOneWidget);

    final plannedEntry = find.descendant(
      of: find.byKey(const ValueKey('risk-planned-entry')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(plannedEntry, '1.2345');
    expect(
      tester.widget<TextFormField>(plannedEntry).controller?.text,
      '1.2345',
    );
    final currency = tester.widget<DropdownButtonFormField<String>>(
      find.descendant(
        of: find.byKey(const ValueKey('risk-currency')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    expect(currency.initialValue, 'USD');

    await jumpUntilBuilt(
      find.byKey(const ValueKey('psychology-checklist-section')),
    );
    final confidence = tester.widget<ConfidenceSelector>(
      find.byType(ConfidenceSelector),
    );
    confidence.onChanged(3);
    await tester.pump();
    expect(
      tester.widget<ConfidenceSelector>(find.byType(ConfidenceSelector)).value,
      3,
    );

    final note = find.byKey(const ValueKey('mental-state-note-field'));
    await tester.enterText(note, 'x' * 301);
    expect(tester.widget<TextFormField>(note).controller?.text.length, 300);
    final checklist = tester.widget<PremiumChecklistTile>(
      find.byKey(const ValueKey('checklist-news_checked')),
    );
    checklist.onChanged(false);
    await tester.pump();
    expect(
      tester
          .widget<PremiumChecklistTile>(
            find.byKey(const ValueKey('checklist-news_checked')),
          )
          .selected,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('risk and psychology cards remain responsive at 320 pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final repository = TradeJournalRepository(
      _JournalApiClient(store, DeviceIdentity(store)),
      'UTC',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalPlanScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('trade-plan-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final psychology = find.byKey(
      const ValueKey('psychology-checklist-section'),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('strategy-reason-section')),
      280,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final priceRisk = find.byKey(const ValueKey('price-risk-plan-section'));
    for (
      var attempt = 0;
      attempt < 30 && priceRisk.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(find.byType(PriceRiskPlanSection), findsOneWidget);
    for (
      var attempt = 0;
      attempt < 30 && psychology.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(find.byType(PsychologyChecklistSection), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _JournalApiClient extends TradeXApiClient {
  _JournalApiClient(super.sessionStore, super.deviceIdentity);

  final paths = <String>[];
  String? lastPostedPath;
  Map<String, dynamic>? lastPostedBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    paths.add(path);
    if (path.startsWith('/api/v1/trade-journal/meta')) {
      return {
        'data': {
          'markets': ['forex', 'crypto', 'deriv', 'stocks'],
          'stock_regions': ['sri_lanka_cse', 'india', 'international'],
          'directions': ['buy', 'sell'],
          'statuses': ['planned', 'open', 'closed', 'cancelled'],
          'results': ['win', 'loss', 'breakeven', 'partial'],
          'timeframes': ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1', 'W1'],
          'emotions_before': ['calm', 'confident', 'fear'],
          'emotions_after': ['calm', 'satisfied', 'disappointed'],
          'followed_plan_after': ['yes', 'partially', 'no'],
          'mistake_tags': ['early_entry', 'fomo', 'overtrading'],
        },
      };
    }
    if (path.startsWith('/api/v1/screener/symbols?')) {
      return {
        'data': {
          'market': 'CRYPTO',
          'symbols': [
            {
              'symbol': 'BTCUSDT',
              'name': 'Bitcoin / Tether',
              'logo_url': 'https://example.test/btc.png',
            },
            {'symbol': 'BTTCUSDT', 'name': 'BitTorrent / Tether'},
          ],
        },
      };
    }
    if (path.startsWith('/api/v1/trade-journal/home')) {
      return {
        'data': {
          'timezone': 'Asia/Colombo',
          'today': summary(),
          'week': summary(),
          'month': summary(),
          'recent': [entry()],
        },
      };
    }
    if (path.startsWith('/api/v1/trade-journal/analytics')) {
      return {'data': analytics()};
    }
    if (path.startsWith('/api/v1/trade-journal/reviews/')) {
      return {
        'data': {
          'period_type': path.contains('monthly') ? 'monthly' : 'weekly',
          'period_start': '2026-10-19',
          'period_end': '2026-10-25',
          'timezone': 'Asia/Colombo',
          'summary': summary(),
          'review': null,
        },
      };
    }
    if (RegExp(r'^/api/v1/trade-journal/entry-1').hasMatch(path)) {
      return {'data': entry()};
    }
    if (path.startsWith('/api/v1/trade-journal?')) {
      return {
        'data': {
          'data': [entry()],
          'current_page': 1,
          'last_page': 1,
          'total': 1,
        },
      };
    }
    return const {'data': <String, dynamic>{}};
  }

  @override
  Future<Uint8List> getBytes(String path) async => Uint8List(0);

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    paths.add(path);
    lastPostedPath = path;
    lastPostedBody = Map<String, dynamic>.from(body);
    return {'data': entry()};
  }

  static Map<String, dynamic> summary() => {
    'total_executed': 12,
    'open': 3,
    'closed': 9,
    'wins': 6,
    'losses': 3,
    'win_rate': 66.7,
    'net_pnl': 1284.5,
    'pnl_currency': 'USD',
    'plan_followed_percent': 83.3,
    'best_week': {'period': '2026-10-05', 'net_pnl': 900, 'currency': 'USD'},
    'worst_week': {'period': '2026-10-12', 'net_pnl': -120, 'currency': 'USD'},
  };

  static Map<String, dynamic> analytics() => {
    'overview': summary(),
    'risk': {'average_realized_r': 1.42},
    'performance': {
      'profit_factor': 2.35,
      'average_win': 320,
      'average_loss': -110,
      'max_win_streak': 4,
      'max_loss_streak': 2,
      'equity_curves': [
        {
          'currency': 'USD',
          'points': [
            {'cumulative_pnl': 200},
            {'cumulative_pnl': 80},
            {'cumulative_pnl': 1284.5},
          ],
        },
      ],
    },
    'sessions': [
      {'key': 'London', 'trades': 6, 'win_rate': 70},
    ],
    'symbols': [
      {'key': 'BTCUSDT', 'trades': 4, 'win_rate': 75},
    ],
    'discipline': {
      'plan_followed_percent': 83.3,
      'session_checked_percent': 90,
      'news_checked_percent': 80,
      'risk_checked_percent': 100,
      'most_common_mistake': 'early_entry',
    },
  };

  static Map<String, dynamic> entry() => {
    'uuid': 'entry-1',
    'market': 'crypto',
    'stock_region': null,
    'symbol': 'BTCUSDT',
    'direction': 'buy',
    'status': 'planned',
    'trade_at_local': '2026-10-23T10:00:00+05:30',
    'display_timezone': 'Asia/Colombo',
    'session': {
      'label': 'London / New York Overlap',
      'keys': ['london', 'new_york'],
      'source': 'auto',
    },
    'broker': 'Binance',
    'account_label': 'Main',
    'setup_strategy': 'Breakout',
    'timeframes': ['M15', 'H1'],
    'entry_reason': 'Breakout above resistance with volume.',
    'notes_before': 'Wait for candle close.',
    'prices': {
      'planned_entry': '68000',
      'actual_entry': null,
      'planned_sl': '66000',
      'current_sl': '66000',
      'planned_tp': '72000',
      'current_tp': '72000',
      'exit_price': null,
    },
    'risk': {
      'position_size': '0.1',
      'risk_amount': '200',
      'risk_currency': 'USD',
      'risk_percent': '1',
      'planned_rr': '2',
      'realized_r': null,
    },
    'psychology_before': {
      'emotion': 'calm',
      'confidence': 4,
      'note': 'Focused',
    },
    'checklist': {
      'followed_trading_plan': 'yes',
      'session_checked': 'yes',
      'news_checked': 'yes',
      'risk_checked': 'yes',
      'setup_confirmed': 'yes',
    },
    'execution_note': null,
    'opened_at': null,
    'exit_at': null,
    'result': null,
    'pnl': {
      'gross': null,
      'fees': null,
      'net': null,
      'currency': null,
      'percent': null,
    },
    'review': {'followed_plan': null, 'lesson_learned': null, 'rating': null},
    'screenshots': {'before_available': false, 'after_available': false},
    'actions': {
      'can_edit': true,
      'can_open': true,
      'can_close': false,
      'can_cancel': true,
    },
  };
}
