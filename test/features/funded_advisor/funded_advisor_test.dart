import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/funded_advisor/data/models/funded_advisor_models.dart';
import 'package:tradex_mobile/features/funded_advisor/domain/entities/funded_advisor_entities.dart';
import 'package:tradex_mobile/features/funded_advisor/domain/repositories/funded_advisor_repository.dart';
import 'package:tradex_mobile/features/funded_advisor/domain/usecases/funded_advisor_use_cases.dart';
import 'package:tradex_mobile/features/funded_advisor/presentation/bloc/funded_advisor_cubit.dart';
import 'package:tradex_mobile/features/funded_advisor/presentation/funded_advisor_module.dart';
import 'package:tradex_mobile/features/home/domain/no_trade_zone_warning.dart';

void main() {
  test('catalog model parses backend values without inventing partners', () {
    final model = FundedAdvisorCatalogModel.fromJson(<String, dynamic>{
      'version': 'catalog-v1',
      'generated_at': '2026-10-28T10:00:00Z',
      'partners': <Object>[],
    });

    expect(model.toEntity().version, 'catalog-v1');
    expect(model.toEntity().partners, isEmpty);
  });

  test(
    'cubit serves cache then avoids catalog download for same version',
    () async {
      final repository = _FakeFundedRepository(cached: _cached());
      final cubit = FundedAdvisorCubit(FundedAdvisorUseCases(repository));

      await cubit.initialize();

      expect(cubit.state.status, FundedAdvisorStatus.fresh);
      expect(cubit.state.catalog?.partners.single.name, 'Test Funding Ltd');
      expect(repository.versionCalls, 1);
      expect(repository.catalogCalls, 0);
      await cubit.close();
    },
  );

  testWidgets('five funded advisor screens navigate with dynamic values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeFundedRepository(catalog: _catalog());
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FundedAdvisorScreen(
          useCases: FundedAdvisorUseCases(repository),
          warningSource: const _ActiveWarningSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Funded Companies'), findsOneWidget);
    expect(find.text('Test Funding Ltd'), findsOneWidget);
    await tester.tap(find.text('Test Funding Ltd'));
    await tester.pumpAndSettle();

    expect(find.text('Company Details'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Account Options'));
    await tester.pumpAndSettle();

    expect(find.text('Account Options'), findsOneWidget);
    await tester.tap(find.text('Two Step').first);
    await tester.tap(find.text('25000').first);
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review No Trade Zone Rules'));
    await tester.pumpAndSettle();

    expect(find.text('No Trade Zone Rules'), findsOneWidget);
    expect(find.text("Don't Trade in Funded Accounts"), findsOneWidget);
    expect(find.text('Two Step'), findsWidgets);
    await tester.drag(find.byType(ListView).last, const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Do not open around CPI.'));
    await tester.pumpAndSettle();

    expect(find.text('Rule Details'), findsOneWidget);
    expect(find.text('Before event'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Open Official Source'), findsOneWidget);
  });

  testWidgets('cached catalog remains visible when refresh is offline', (
    tester,
  ) async {
    final repository = _FakeFundedRepository(
      cached: _cached(lastCheckedLocalDay: '2000-01-01'),
      failVersion: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FundedAdvisorScreen(
          useCases: FundedAdvisorUseCases(repository),
          warningSource: const _NoWarningSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Funding Ltd'), findsOneWidget);
    expect(
      find.text('Saved funded rules are shown. Connect to refresh updates.'),
      findsOneWidget,
    );
  });
}

final class _NoWarningSource implements NoTradeWarningSource {
  const _NoWarningSource();

  @override
  Future<List<EconomicNewsSnapshot>> load({bool forceRefresh = false}) async =>
      const <EconomicNewsSnapshot>[];
}

final class _ActiveWarningSource implements NoTradeWarningSource {
  const _ActiveWarningSource();

  @override
  Future<List<EconomicNewsSnapshot>> load({bool forceRefresh = false}) async {
    final now = DateTime.now().toUtc();
    return <EconomicNewsSnapshot>[
      EconomicNewsSnapshot(
        uuid: 'active-news',
        title: 'US CPI',
        currency: 'USD',
        impact: 'HIGH',
        status: 'SCHEDULED',
        scheduledAtUtc: now.add(const Duration(minutes: 5)),
        affectedPairs: const <String>['XAUUSD'],
        observedAtUtc: now,
      ),
    ];
  }
}

final class _FakeFundedRepository implements FundedAdvisorRepository {
  _FakeFundedRepository({
    this.cached,
    FundedAdvisorCatalog? catalog,
    this.failVersion = false,
  }) : catalog = catalog ?? cached?.catalog ?? _catalog();

  final FundedAdvisorCachedCatalog? cached;
  final FundedAdvisorCatalog catalog;
  final bool failVersion;
  int versionCalls = 0;
  int catalogCalls = 0;

  @override
  Future<String> fetchVersion() async {
    versionCalls++;
    if (failVersion) throw Exception('offline');
    return catalog.version;
  }

  @override
  Future<FundedAdvisorCatalog> fetchCatalog() async {
    catalogCalls++;
    return catalog;
  }

  @override
  Future<FundedAdvisorCachedCatalog?> loadCached() async => cached;

  @override
  Future<Uint8List> loadLogo(String path) async => Uint8List(0);

  @override
  Future<void> saveCatalog(
    FundedAdvisorCatalog catalog, {
    required DateTime checkedAt,
  }) async {}
}

FundedAdvisorCachedCatalog _cached({String? lastCheckedLocalDay}) =>
    FundedAdvisorCachedCatalog(
      catalog: _catalog(),
      cachedAt: DateTime.utc(2026, 10, 28),
      lastCheckedAt: DateTime.utc(2026, 10, 27),
      lastCheckedLocalDay: lastCheckedLocalDay,
    );

FundedAdvisorCatalog _catalog() => FundedAdvisorCatalog(
  version: 'catalog-v1',
  generatedAt: DateTime.utc(2026, 10, 28),
  partners: <FundedPartner>[
    FundedPartner(
      uuid: 'partner-uuid',
      name: 'Test Funding Ltd',
      websiteUrl: 'https://funding.example',
      affiliateUrl: 'https://funding.example/tradex',
      promoCode: 'TEST10',
      offerText: 'Verified customer offer',
      disclosure: 'Verify current rules on the official website.',
      supportedCountries: const ['LK'],
      accountSizes: const ['25000'],
      challengeTypes: const ['Two Step'],
      logoUrl: null,
      isFeatured: true,
      priority: 1,
      rules: <FundedRule>[
        FundedRule(
          uuid: 'rule-uuid',
          programName: 'Two Step',
          phase: 'CHALLENGE',
          policy: 'RESTRICTED',
          enforcementType: 'BLOCKED',
          impactLevels: const ['HIGH'],
          eventKeywords: const ['CPI'],
          minutesBefore: 2,
          minutesAfter: 2,
          affectedInstrumentsOnly: true,
          restrictedCurrencies: const ['USD'],
          restrictedInstruments: const ['XAUUSD'],
          blockOpenNewTrades: true,
          blockCloseTrades: false,
          blockPendingOrders: true,
          summary: 'Do not open around CPI.',
          sourceUrl: 'https://funding.example/news-rules',
          sourceReference: 'News Trading Policy',
          verifiedAt: DateTime.utc(2026, 10, 27),
          effectiveFrom: DateTime.utc(2026, 10, 1),
          expiresAt: null,
          priority: 1,
        ),
      ],
    ),
  ],
);
