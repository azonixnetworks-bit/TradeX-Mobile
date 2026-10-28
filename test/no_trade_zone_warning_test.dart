import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/home/domain/no_trade_zone_warning.dart';
import 'package:tradex_mobile/features/trade_ideas/data/trade_idea_repository.dart';
import 'package:tradex_mobile/features/trade_ideas/models/trade_idea_models.dart';
import 'package:tradex_mobile/features/trade_ideas/presentation/trade_ideas_screen.dart';
import 'package:tradex_mobile/shared/widgets/no_trade_zone_warning.dart';

void main() {
  const evaluator = NoTradeZoneWarningEvaluator();
  final scheduled = DateTime.utc(2026, 10, 28, 12);

  test('warning activates 30 minutes before and ends at plus 30 minutes', () {
    final windowStart = scheduled.subtract(const Duration(minutes: 30));
    final beforeWindowEnd = scheduled.add(
      const Duration(minutes: 29, seconds: 59),
    );
    final windowEnd = scheduled.add(const Duration(minutes: 30));
    final endedVisibilityEnd = scheduled.add(const Duration(minutes: 35));

    expect(
      evaluator
          .evaluateEvent(
            _event(scheduled: scheduled, observedAt: windowStart),
            windowStart,
          )
          .phase,
      NoTradeWarningPhase.active,
    );
    expect(
      evaluator
          .evaluateEvent(
            _event(scheduled: scheduled, observedAt: beforeWindowEnd),
            beforeWindowEnd,
          )
          .phase,
      NoTradeWarningPhase.active,
    );
    expect(
      evaluator
          .evaluateEvent(
            _event(scheduled: scheduled, observedAt: windowEnd),
            windowEnd,
          )
          .phase,
      NoTradeWarningPhase.ended,
    );
    expect(
      evaluator
          .evaluateEvent(
            _event(scheduled: scheduled, observedAt: endedVisibilityEnd),
            endedVisibilityEnd,
          )
          .phase,
      NoTradeWarningPhase.normal,
    );
  });

  test(
    'overlapping high impact windows remain active until the latest end',
    () {
      final now = scheduled;
      final result = evaluator.evaluate(<EconomicNewsSnapshot>[
        _event(uuid: 'first', scheduled: scheduled, observedAt: now),
        _event(
          uuid: 'second',
          scheduled: scheduled.add(const Duration(minutes: 20)),
          observedAt: now,
        ),
      ], now);

      expect(result.phase, NoTradeWarningPhase.active);
      expect(result.relevantEvents, hasLength(2));
      expect(result.windowEndsAtUtc, DateTime.utc(2026, 10, 28, 12, 50));
    },
  );

  test('currency and forex symbol filters select applicable news only', () {
    final event = _event(scheduled: scheduled, observedAt: scheduled);

    expect(
      evaluator
          .evaluate(
            <EconomicNewsSnapshot>[event],
            scheduled,
            applicableSymbolsOrCurrencies: const ['GBPJPY'],
          )
          .phase,
      NoTradeWarningPhase.normal,
    );
    expect(
      evaluator
          .evaluate(
            <EconomicNewsSnapshot>[event],
            scheduled,
            applicableSymbolsOrCurrencies: const ['XAUUSD'],
          )
          .phase,
      NoTradeWarningPhase.active,
    );
  });

  test(
    'UTC comparison handles local timezone instants and suppresses stale data',
    () {
      final fresh = _event(scheduled: scheduled, observedAt: scheduled);
      final localInstant = DateTime.parse('2026-10-28T17:30:00+05:30');
      expect(
        evaluator.evaluateEvent(fresh, localInstant).phase,
        NoTradeWarningPhase.active,
      );

      final stale = _event(
        scheduled: scheduled,
        observedAt: scheduled.subtract(const Duration(minutes: 16)),
      );
      expect(
        evaluator.evaluateEvent(stale, scheduled).phase,
        NoTradeWarningPhase.normal,
      );
    },
  );

  testWidgets('banner recalculates and refreshes its source on app resume', (
    tester,
  ) async {
    final now = DateTime.now();
    final source = _CountingWarningSource(<EconomicNewsSnapshot>[
      _event(
        scheduled: now.toUtc().add(const Duration(minutes: 5)),
        observedAt: now.toUtc(),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: Scaffold(body: NoTradeZoneWarningBanner(source: source)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text("Don't Trade in Funded Accounts"), findsOneWidget);
    expect(find.byKey(const ValueKey('no-trade-countdown')), findsOneWidget);
    expect(source.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(source.calls, 2);
  });

  testWidgets('ended caution window briefly shows the safe-to-trade state', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final source = _CountingWarningSource(<EconomicNewsSnapshot>[
      _event(
        scheduled: now.subtract(const Duration(minutes: 31)),
        observedAt: now,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: Scaffold(body: NoTradeZoneWarningBanner(source: source)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('You Can Trade on Funded Accounts'), findsOneWidget);
    expect(find.byKey(const ValueKey('no-trade-ended-panel')), findsOneWidget);
  });

  testWidgets('Forex Trade Ideas shows warning without blocking idea cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now().toUtc();
    final ideas = _FakeTradeIdeas();
    final source = _CountingWarningSource(<EconomicNewsSnapshot>[
      _event(scheduled: now.add(const Duration(minutes: 5)), observedAt: now),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: Scaffold(
          body: TradeIdeasScreen(repository: ideas, warningSource: source),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Forex'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(ideas.categories, contains('FOREX'));
    expect(find.text("Don't Trade in Funded Accounts"), findsOneWidget);
    expect(find.text('EURUSD'), findsOneWidget);
    expect(find.text('BUY'), findsOneWidget);
  });
}

EconomicNewsSnapshot _event({
  String uuid = 'event',
  required DateTime scheduled,
  required DateTime observedAt,
}) => EconomicNewsSnapshot(
  uuid: uuid,
  title: 'US CPI',
  currency: 'USD',
  impact: 'HIGH',
  status: 'SCHEDULED',
  scheduledAtUtc: scheduled.toUtc(),
  affectedPairs: const ['EURUSD', 'XAUUSD'],
  observedAtUtc: observedAt.toUtc(),
);

final class _CountingWarningSource implements NoTradeWarningSource {
  _CountingWarningSource(this.events);

  final List<EconomicNewsSnapshot> events;
  int calls = 0;

  @override
  Future<List<EconomicNewsSnapshot>> load({bool forceRefresh = false}) async {
    calls++;
    return events;
  }
}

final class _FakeTradeIdeas implements TradeIdeaDataSource {
  final List<String?> categories = <String?>[];

  @override
  Future<TradeIdeaPage> list({
    int page = 1,
    int perPage = 10,
    String? category,
    String? symbol,
  }) async {
    categories.add(category);
    return TradeIdeaPage(
      items: <TradeIdeaSummary>[
        TradeIdeaSummary.fromJson(<String, dynamic>{
          'uuid': '11111111-1111-4111-8111-111111111111',
          'title': 'EURUSD momentum',
          'summary': 'Educational market analysis',
          'category': 'FOREX',
          'symbol': 'EURUSD',
          'instrument_name': 'Euro / U.S. Dollar',
          'direction': 'BUY',
          'timeframe': 'H1',
          'status': 'PUBLISHED',
          'entry': <String, dynamic>{'low': '1.0800', 'high': '1.0820'},
          'stop_loss': <String, dynamic>{'value': '1.0750'},
          'targets': <String, dynamic>{'total': 2, 'hit': 0},
          'reactions': <String, dynamic>{},
        }),
      ],
      currentPage: 1,
      lastPage: 1,
      total: 1,
    );
  }

  @override
  Future<Uint8List> analysisChart(String uuid) async => Uint8List(0);

  @override
  Future<TradeIdeaDetail> detail(String uuid) => throw UnimplementedError();

  @override
  Future<TradeIdeaReactionSummary> react(String uuid, String? reaction) =>
      throw UnimplementedError();

  @override
  Future<TradeIdeaShareAction> shareAction(
    String uuid, {
    required String channel,
    String variant = 'portrait',
  }) => throw UnimplementedError();
}
