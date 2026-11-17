import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/investments/domain/investment_entities.dart';
import 'package:tradex_mobile/features/investments/domain/investment_repository.dart';
import 'package:tradex_mobile/features/investments/presentation/investment_module.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('all seven investment screens render server-backed data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeInvestmentRepository(_dashboard);
    final screens = <(Widget, String)>[
      (InvestmentHomeScreen(repository: repository), 'Investments'),
      (InvestmentProductsScreen(repository: repository), 'Available Products'),
      (MyInvestmentsScreen(repository: repository), 'My Investments'),
      (
        InvestmentDetailsScreen(
          repository: repository,
          investmentId: 'investment-1',
        ),
        'Investment Details',
      ),
      (ProfitPerformanceScreen(repository: repository), 'Profit Performance'),
      (
        InvestmentTransactionsScreen(repository: repository),
        'Transactions & Payouts',
      ),
      (
        InvestmentAgreementsRiskScreen(repository: repository),
        'Agreements & Risk',
      ),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(theme: TradeXTheme.dark, home: screen.$1),
      );
      await tester.pumpAndSettle();
      expect(find.text(screen.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('investment home navigates and persists hidden values', (
    tester,
  ) async {
    final repository = _FakeInvestmentRepository(_dashboard);
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: InvestmentHomeScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$27,350.40'), findsOneWidget);
    await tester.tap(find.text('Hide values'));
    await tester.pumpAndSettle();
    expect(find.text('••••••••'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Available Products'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Available Products'));
    await tester.pumpAndSettle();
    expect(find.text('Available Products'), findsOneWidget);
  });

  testWidgets('unavailable API never displays illustrative balances', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: const InvestmentHomeScreen(
          repository: _UnavailableInvestmentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investment data unavailable'), findsOneWidget);
    expect(find.text(r'$27,350.40'), findsNothing);
    expect(find.text(r'$0.00'), findsNothing);
  });

  testWidgets('coming-soon product action is disabled', (tester) async {
    final repository = _FakeInvestmentRepository(_dashboard);
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: InvestmentProductsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final unavailable = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Unavailable'),
    );
    expect(unavailable.onPressed, isNull);
  });

  testWidgets('transaction details expose only masked sensitive values', (
    tester,
  ) async {
    final repository = _FakeInvestmentRepository(_dashboard);
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: InvestmentTransactionsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deposit'));
    await tester.pumpAndSettle();

    expect(find.text('0x7f••••a92'), findsOneWidget);
    expect(find.text('T9••••3kP'), findsOneWidget);
    expect(
      find.text('Sensitive IDs and wallet addresses are masked by default.'),
      findsOneWidget,
    );
  });
}

class _FakeInvestmentRepository implements InvestmentRepository {
  const _FakeInvestmentRepository(this.dashboard);

  final InvestmentDashboard dashboard;

  @override
  Future<InvestmentDashboard> loadDashboard({bool refresh = false}) async =>
      dashboard;

  @override
  Future<InvestmentDashboard> loadInvestment(
    String investmentId, {
    bool refresh = false,
  }) async => dashboard;

  @override
  Future<CustomerInvestment> createApplication({
    required double amount,
    required int periodYears,
    required int reviewIntervalMonths,
  }) async => dashboard.investments.first;

  @override
  Future<void> submitDeposit({
    required String investmentId,
    required String transactionId,
    String? senderAddress,
  }) async {}

  @override
  Future<Uint8List> downloadAgreement(String investmentId) async =>
      Uint8List(0);
}

class _UnavailableInvestmentRepository implements InvestmentRepository {
  const _UnavailableInvestmentRepository();

  @override
  Future<InvestmentDashboard> loadDashboard({bool refresh = false}) =>
      Future.error(const InvestmentFeatureUnavailable());

  @override
  Future<InvestmentDashboard> loadInvestment(
    String investmentId, {
    bool refresh = false,
  }) => Future.error(const InvestmentFeatureUnavailable());

  @override
  Future<CustomerInvestment> createApplication({
    required double amount,
    required int periodYears,
    required int reviewIntervalMonths,
  }) => Future.error(const InvestmentFeatureUnavailable());

  @override
  Future<void> submitDeposit({
    required String investmentId,
    required String transactionId,
    String? senderAddress,
  }) => Future.error(const InvestmentFeatureUnavailable());

  @override
  Future<Uint8List> downloadAgreement(String investmentId) =>
      Future.error(const InvestmentFeatureUnavailable());
}

final _dashboard = InvestmentDashboard(
  portfolio: InvestmentPortfolio(
    totalInvested: 25000,
    portfolioValue: 27350.40,
    verifiedProfit: 2350.40,
    currency: 'USD',
    activeCount: 1,
    nextReviewAt: DateTime.utc(2026, 11, 15),
    valuedAt: DateTime.utc(2026, 11, 1),
  ),
  products: const [
    InvestmentProduct(
      id: 'crypto',
      name: 'Crypto Investment',
      availability: InvestmentAvailability.active,
      currencies: ['USDT'],
      networks: ['TRC20'],
      riskTier: 'High risk',
    ),
    InvestmentProduct(
      id: 'stocks',
      name: 'US Stocks Investment',
      availability: InvestmentAvailability.comingSoon,
    ),
  ],
  investments: [
    CustomerInvestment(
      id: 'investment-1',
      code: 'INV-TEST-1',
      productName: 'Crypto Investment',
      status: InvestmentStatus.active,
      amount: 20000,
      currency: 'USD',
      network: 'TRC20',
      progress: .64,
      startAt: DateTime.utc(2026, 10, 15),
      maturityAt: DateTime.utc(2027, 4, 15),
      customerSharePercent: 70,
      companySharePercent: 30,
      highWaterMark: 27350,
      lossCarryForward: 0,
      maskedPayoutWallet: 'T9••••3kP',
      lifecycle: const [
        InvestmentLifecycleStep(label: 'Created', completed: true),
        InvestmentLifecycleStep(
          label: 'Active',
          completed: false,
          current: true,
        ),
      ],
    ),
  ],
  profitPeriods: [
    InvestmentProfitPeriod(
      id: 'period-1',
      label: 'Period 01',
      status: InvestmentRecordStatus.approved,
      openingValue: 25000,
      closingValue: 27350.40,
      grossProfitLoss: 2350.40,
      customerShare: 1645.28,
      companyShare: 705.12,
      highWaterMark: 27350.40,
      currency: 'USD',
      verified: true,
      openedAt: DateTime.utc(2026, 10, 1),
      closedAt: DateTime.utc(2026, 11, 15),
    ),
  ],
  transactions: [
    InvestmentTransaction(
      id: 'transaction-1',
      reference: 'TXN-TEST-1',
      type: 'Deposit',
      status: InvestmentRecordStatus.verified,
      amount: 20000,
      currency: 'USD',
      network: 'TRC20',
      maskedTransactionHash: '0x7f••••a92',
      maskedWallet: 'T9••••3kP',
      referenceCopyAllowed: true,
    ),
  ],
  agreement: InvestmentAgreement(
    riskAccepted: true,
    disclosureVersion: 'v1.2',
    agreementVersion: 'v1.2',
    status: InvestmentRecordStatus.verified,
    generatedAt: DateTime.utc(2026, 10, 15),
    signedAt: DateTime.utc(2026, 10, 15),
    verifiedAt: DateTime.utc(2026, 10, 15),
  ),
);
