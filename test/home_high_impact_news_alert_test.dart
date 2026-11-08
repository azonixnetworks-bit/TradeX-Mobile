import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/home/domain/market_news_repository.dart';
import 'package:tradex_mobile/features/home/domain/no_trade_zone_warning.dart';
import 'package:tradex_mobile/features/home/presentation/widgets/home_high_impact_news_preview.dart';
import 'package:tradex_mobile/shared/widgets/no_trade_zone_warning.dart';

void main() {
  testWidgets('home shows backend HIGH-impact headline and funded warning', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now().toUtc();
    final high = _news(
      uuid: 'high-1',
      impact: 'HIGH',
      title: 'US CPI Release',
      scheduled: now.add(const Duration(minutes: 10)),
    );
    final medium = _news(
      uuid: 'medium-1',
      impact: 'MEDIUM',
      title: 'Medium event',
      scheduled: now.add(const Duration(minutes: 2)),
    );
    final repository = _NewsRepository([medium, high]);
    var navigated = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                NoTradeZoneWarningBanner(source: _FakeSource([high])),
                HomeHighImpactNewsPreview(
                  repository: repository,
                  onOpenAll: () => navigated = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Don't Trade in Funded Accounts"), findsOneWidget);
    expect(find.byKey(const ValueKey('no-trade-countdown')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-high-impact-news')), findsOneWidget);
    expect(find.text('US CPI Release'), findsWidgets);
    expect(find.text('Medium event'), findsNothing);
    expect(repository.todayCalls, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('home-high-impact-news')));
    expect(navigated, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no HIGH event means no invented highlight or funded warning', (
    tester,
  ) async {
    final medium = _news(
      uuid: 'medium-only',
      impact: 'MEDIUM',
      title: 'Medium-only event',
      scheduled: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              NoTradeZoneWarningBanner(source: _FakeSource([medium])),
              HomeHighImpactNewsPreview(
                repository: _NewsRepository([medium]),
                onOpenAll: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('home-high-impact-news')), findsNothing);
    expect(find.byKey(const ValueKey('no-trade-active-panel')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

MarketNewsItem _news({
  required String uuid,
  required String impact,
  required String title,
  required DateTime scheduled,
}) => MarketNewsItem(
  uuid: uuid,
  title: title,
  summary: 'Published by Laravel',
  category: 'Economics',
  previous: '2.5%',
  forecast: '2.7%',
  actual: null,
  countryCode: 'US',
  currency: 'USD',
  impact: impact,
  bias: 'NEUTRAL',
  confidenceScore: 0,
  source: 'TradeX Economic Calendar',
  affectedPairs: const ['EURUSD'],
  status: 'SCHEDULED',
  occurredAt: scheduled,
  isLiveUpdate: false,
  observedAtUtc: DateTime.now().toUtc(),
);

class _NewsRepository implements MarketNewsRepositoryContract {
  _NewsRepository(this.items);

  final List<MarketNewsItem> items;
  int todayCalls = 0;

  @override
  Future<List<MarketNewsItem>> today({
    DateTime? now,
    bool forceRefresh = false,
  }) async {
    todayCalls++;
    return items;
  }

  @override
  Future<List<MarketNewsItem>> latest({
    int limit = 4,
    bool forceRefresh = false,
  }) async => items.take(limit).toList();
}

class _FakeSource implements NoTradeWarningSource {
  _FakeSource(this.items);

  final List<MarketNewsItem> items;

  @override
  Future<List<EconomicNewsSnapshot>> load({bool forceRefresh = false}) async =>
      items.map((item) => item.toWarningSnapshot()).toList();
}
