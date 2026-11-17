import 'dart:typed_data';

import '../../../../core/network/tradex_api_client.dart';
import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';

final class ApiInvestmentRepository implements InvestmentRepository {
  ApiInvestmentRepository(this._api);
  final TradeXApiClient _api;

  @override
  Future<InvestmentDashboard> loadDashboard({bool refresh = false}) async {
    final response = refresh
        ? await _api.getJson('/api/v1/investments')
        : await _api.getJsonCacheFirst('/api/v1/investments');
    return _dashboard(_map(response['data']));
  }

  @override
  Future<InvestmentDashboard> loadInvestment(
    String investmentId, {
    bool refresh = false,
  }) async {
    final all = await loadDashboard(refresh: refresh);
    final selected = all.investments
        .where((item) => item.id == investmentId)
        .toList(growable: false);
    return InvestmentDashboard(
      portfolio: all.portfolio,
      products: all.products,
      investments: selected,
      agreement: selected.isEmpty ? null : all.agreement,
      onboarding: all.onboarding,
    );
  }

  @override
  Future<CustomerInvestment> createApplication({
    required double amount,
    required int periodYears,
    required int reviewIntervalMonths,
  }) async {
    final response = await _api.postJson('/api/v1/investments', {
      'amount': amount,
      'period_years': periodYears,
      'review_interval_months': reviewIntervalMonths,
      'accept_risk': true,
      'accept_agreement': true,
    });
    return _investment(_map(response['data']));
  }

  @override
  Future<void> submitDeposit({
    required String investmentId,
    required String transactionId,
    String? senderAddress,
  }) async {
    await _api.postJson('/api/v1/investments/$investmentId/deposit', {
      'txid': transactionId,
      if (senderAddress?.trim().isNotEmpty == true)
        'sender_address': senderAddress!.trim(),
    });
  }

  @override
  Future<Uint8List> downloadAgreement(String investmentId) =>
      _api.getBytes('/api/v1/investments/$investmentId/agreement');

  InvestmentDashboard _dashboard(Map<String, dynamic> json) {
    final rawInvestments = _maps(json['investments']);
    final investments = rawInvestments.map(_investment).toList(growable: false);
    InvestmentAgreement? agreement;
    for (final raw in rawInvestments) {
      agreement ??= _agreement(_map(raw['agreement']));
    }
    final portfolio = _map(json['portfolio']);
    return InvestmentDashboard(
      portfolio: InvestmentPortfolio(
        totalInvested: _number(portfolio['total_invested']),
        portfolioValue: _number(portfolio['portfolio_value']),
        verifiedProfit: _number(portfolio['verified_profit']),
        currency: portfolio['currency']?.toString(),
        activeCount: (portfolio['active_count'] as num?)?.toInt(),
        valuedAt: _date(portfolio['valued_at']),
      ),
      products: _maps(json['products']).map(_product).toList(growable: false),
      investments: investments,
      agreement: agreement,
      onboarding: _onboarding(_map(json['onboarding'])),
    );
  }

  InvestmentOnboarding _onboarding(Map<String, dynamic> json) =>
      InvestmentOnboarding(
        kycVerified: json['kyc_verified'] == true,
        kycStatus: json['kyc_status']?.toString() ?? 'NOT_SUBMITTED',
        minimumAmount: _number(json['minimum_amount']) ?? 3000,
        maximumAmount: _number(json['maximum_amount']) ?? 500000,
        currency: json['currency']?.toString() ?? 'USDT',
        network: json['network']?.toString() ?? 'TRC20',
        depositAddress: json['deposit_address']?.toString(),
        periodYears: _list(json['period_years'])
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(),
        reviewIntervalsMonths: _list(json['review_intervals_months'])
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(),
        riskStatements: _list(json['risk_statements'])
            .map((value) => value.toString())
            .toList(),
      );

  InvestmentProduct _product(Map<String, dynamic> json) => InvestmentProduct(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    availability: json['availability']?.toString().toLowerCase() == 'active'
        ? InvestmentAvailability.active
        : InvestmentAvailability.comingSoon,
    currencies: _list(json['currencies']).map((e) => e.toString()).toList(),
    networks: _list(json['networks']).map((e) => e.toString()).toList(),
    profitSharingModel: json['profit_sharing_model']?.toString(),
    periodTerms: json['period_terms']?.toString(),
    riskTier: json['risk_tier']?.toString(),
  );

  CustomerInvestment _investment(Map<String, dynamic> json) =>
      CustomerInvestment(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        productName: json['product_name']?.toString() ?? 'Crypto Investment',
        status: _status(json['status']?.toString()),
        amount: _number(json['amount']),
        currency: json['currency']?.toString(),
        network: json['network']?.toString(),
        periodLabel: json['period_label']?.toString(),
        customerSharePercent: _number(json['customer_share_percent']),
        companySharePercent: _number(json['company_share_percent']),
      );

  InvestmentAgreement? _agreement(Map<String, dynamic> json) => json.isEmpty
      ? null
      : InvestmentAgreement(
          riskAccepted: json['risk_accepted'] == true,
          disclosureVersion: json['disclosure_version']?.toString(),
          riskAcceptedAt: _date(json['risk_accepted_at']),
          agreementVersion: json['agreement_version']?.toString(),
          status: _recordStatus(json['status']?.toString()),
          generatedAt: _date(json['generated_at']),
          signedAt: _date(json['signed_at']),
          authorizedViewPath: json['download_path']?.toString(),
          authorizedDownloadPath: json['download_path']?.toString(),
        );

  InvestmentStatus _status(String? value) => switch (value?.toLowerCase()) {
    'active' => InvestmentStatus.active,
    'matured' => InvestmentStatus.matured,
    'closed' => InvestmentStatus.closed,
    'completed' => InvestmentStatus.completed,
    'loss' => InvestmentStatus.loss,
    _ => InvestmentStatus.pending,
  };

  InvestmentRecordStatus _recordStatus(String? value) =>
      switch (value?.toLowerCase()) {
        'verified' => InvestmentRecordStatus.verified,
        'signed' || 'generated' => InvestmentRecordStatus.prepared,
        'rejected' => InvestmentRecordStatus.rejected,
        _ => InvestmentRecordStatus.pending,
      };
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};
List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.map(_map).toList() : const [];
List<Object?> _list(Object? value) => value is List ? value : const [];
double? _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
DateTime? _date(Object? value) => DateTime.tryParse(value?.toString() ?? '');
