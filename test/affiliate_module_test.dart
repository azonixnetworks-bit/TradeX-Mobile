import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/network/api_exception.dart';
import 'package:tradex_mobile/features/affiliate/presentation/affiliate_module.dart';
import 'package:tradex_mobile/features/affiliate/presentation/bloc/affiliate_cubits.dart';
import 'package:tradex_mobile/features/affiliate/presentation/services/affiliate_share_card_service.dart';

void main() {
  Widget host(Widget child, {Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('affiliate metric card is responsive on a narrow phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AffiliateMetricCard(
          width: 170,
          label: 'Total Earnings',
          value: r'$1,245.50',
          icon: Icons.monetization_on_outlined,
        ),
        size: const Size(320, 640),
      ),
    );

    expect(find.text('Total Earnings'), findsOneWidget);
    expect(find.text(r'$1,245.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiliate dashboard header omits the TradeX wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: AffiliateScaffold(
          title: 'Affiliate Dashboard',
          subtitle: 'Invite traders. Grow together. Earn rewards.',
          showBack: false,
          dashboardHeader: true,
          onMenu: () {},
          onNotifications: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Affiliate Dashboard'), findsOneWidget);
    expect(find.text('Trade'), findsNothing);
    expect(find.text('X'), findsNothing);
    expect(find.bySemanticsLabel('Affiliate menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('earnings header omits the TradeX wordmark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const AffiliateScaffold(
          title: 'Earnings & Sales',
          subtitle: 'Track commission income and qualified sales.',
          showBrand: false,
          child: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Earnings & Sales'), findsOneWidget);
    expect(find.text('Trade'), findsNothing);
    expect(find.text('X'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('technical API routes are never exposed as customer messages', () {
    const error = ApiException(
      message: 'The route api/v1/affiliate/earnings-series was not found.',
      statusCode: 404,
    );

    expect(error.message, 'This information is not available yet.');
    expect(error.message, isNot(contains('api/v1')));
  });

  testWidgets('empty earnings chart uses a friendly state card', (
    tester,
  ) async {
    await tester.pumpWidget(host(const EarningsChart(points: [])));

    expect(find.text('Earnings activity will appear here'), findsOneWidget);
    expect(find.textContaining('/api/'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('referral panel shows only the referral code', (tester) async {
    var copied = false;
    var shared = false;
    await tester.pumpWidget(
      host(
        ReferralLinkPanel(
          code: 'TXPREMIUM25',
          onCopy: () => copied = true,
          onWhatsApp: () {},
          onTelegram: () {},
          onShare: () => shared = true,
          onQr: () {},
        ),
        size: const Size(320, 640),
      ),
    );

    expect(find.text('Your Referral Code'), findsOneWidget);
    expect(find.text('TXPREMIUM25'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);

    await tester.tap(find.byTooltip('Copy referral code'));
    await tester.pump();
    expect(copied, isTrue);

    await tester.tap(find.bySemanticsLabel('Share'));
    await tester.pump();
    expect(shared, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium share card renders live values and QR at story size', (
    tester,
  ) async {
    final result = await tester.runAsync(() async {
      final bytes = await const AffiliateShareCardService().renderCard(
        clientName: 'Arun Trader',
        referralUrl: 'https://tradex.example/register?ref=TXAFF001',
        referralCode: 'TXAFF001',
        earnings: r'$2,450.00',
        averageEarningsPerSale: r'$58.00',
        totalReferrals: 42,
        qualifiedSales: 8,
        commissionRate: '20.00',
        currentLevel: 'Pro',
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final dimensions = (frame.image.width, frame.image.height, bytes.length);
      frame.image.dispose();
      codec.dispose();
      return dimensions;
    });

    expect(result, isNotNull);
    expect(result!.$1, 1080);
    expect(result.$2, 1920);
    expect(result.$3, greaterThan(0));
  });

  testWidgets('referral tile renders only API-backed referral fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const ReferralTile(
          data: {
            'name': 'Arun Kumar',
            'joined_at': '2026-10-12T00:00:00Z',
            'qualification': {
              'has_qualified_sale': true,
              'active_qualified_sales_count': 3,
            },
          },
        ),
      ),
    );

    expect(find.text('Arun Kumar'), findsOneWidget);
    expect(find.text('Qualified'), findsOneWidget);
    expect(find.text('3 sales'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('stage tile exposes current state from actual stage code', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const StageTile(
          sales: 90,
          currentCode: 'PRO',
          data: {
            'code': 'PRO',
            'name': 'Pro',
            'qualified_sales_range': {'min': 81, 'max': 150},
            'standard_commission_percent': '20.00',
            'milestone': {
              'gift': {'amount': '200.00', 'currency': 'USD'},
            },
          },
        ),
      ),
    );

    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text(r'$200.00'), findsOneWidget);
  });

  test('affiliate load cubit emits immutable ready state', () async {
    final cubit = AffiliateLoadCubit(() async => {'value': 42});
    await cubit.load();

    expect(cubit.state.status, AffiliateLoadStatus.ready);
    expect(cubit.state.data['value'], 42);
    await cubit.close();
  });
}
