import '../../domain/entities/copy_trading_entities.dart';

typedef CopyTradeJson = Map<String, dynamic>;

final class CopyTradingDashboardModel {
  const CopyTradingDashboardModel({
    required this.accounts,
    required this.copyTradeReady,
    required this.nextStep,
  });

  factory CopyTradingDashboardModel.fromJson(CopyTradeJson json) =>
      CopyTradingDashboardModel(
        accounts: copyTradeList(json['broker_accounts'])
            .map(CopyTradingAccountModel.fromJson)
            .toList(growable: false),
        copyTradeReady: json['copy_trade_ready'] == true,
        nextStep: copyText(json['next_step'], 'NOT READY'),
      );

  final List<CopyTradingAccountModel> accounts;
  final bool copyTradeReady;
  final String nextStep;

  CopyTradingDashboard toEntity() => CopyTradingDashboard(
    accounts: accounts.map((item) => item.toEntity()).toList(growable: false),
    copyTradeReady: copyTradeReady,
    nextStep: nextStep,
  );
}

final class CopyTradingBrokerMarketModel {
  const CopyTradingBrokerMarketModel({
    required this.brokerMarketUuid,
    required this.brokerUuid,
    required this.brokerName,
    required this.marketCategory,
    required this.requiredCurrency,
    required this.logoUrl,
  });

  factory CopyTradingBrokerMarketModel.fromJson(CopyTradeJson json) =>
      CopyTradingBrokerMarketModel(
        brokerMarketUuid: copyText(json['broker_market_uuid']),
        brokerUuid: copyText(json['broker_uuid']),
        brokerName: copyText(json['broker_name'] ?? json['name'], 'Broker'),
        marketCategory: copyText(
          json['market_category'],
          'CTRADER',
        ).toUpperCase(),
        requiredCurrency: copyText(
          json['required_currency'],
          'Configured by broker',
        ),
        logoUrl: copyNullableText(json['logo_url']),
      );

  final String brokerMarketUuid;
  final String brokerUuid;
  final String brokerName;
  final String marketCategory;
  final String requiredCurrency;
  final String? logoUrl;

  CopyTradingBrokerMarket toEntity() => CopyTradingBrokerMarket(
    brokerMarketUuid: brokerMarketUuid,
    brokerUuid: brokerUuid,
    brokerName: brokerName,
    marketCategory: marketCategory,
    requiredCurrency: requiredCurrency,
    logoUrl: logoUrl,
  );
}

final class CopyTradingOnboardingIntentModel {
  const CopyTradingOnboardingIntentModel({
    required this.uuid,
    required this.openAccountUrl,
    required this.expiresAt,
  });

  factory CopyTradingOnboardingIntentModel.fromJson(CopyTradeJson json) =>
      CopyTradingOnboardingIntentModel(
        uuid: copyText(json['onboarding_intent_uuid']),
        openAccountUrl: copyText(json['open_account_via_tradex_url']),
        expiresAt: DateTime.tryParse(copyText(json['expires_at'])),
      );

  final String uuid;
  final String openAccountUrl;
  final DateTime? expiresAt;

  CopyTradingOnboardingIntent toEntity() => CopyTradingOnboardingIntent(
    uuid: uuid,
    openAccountUrl: openAccountUrl,
    expiresAt: expiresAt,
  );
}

final class CopyTradingAccountModel {
  const CopyTradingAccountModel({
    required this.uuid,
    required this.broker,
    required this.marketCategory,
    required this.accountNumberMasked,
    required this.status,
    required this.activationState,
    required this.verifiedCurrency,
    required this.statusReason,
  });

  factory CopyTradingAccountModel.fromJson(
    CopyTradeJson json,
  ) => CopyTradingAccountModel(
    uuid: copyText(json['uuid']),
    broker: CopyTradingBrokerMarketModel.fromJson(copyTradeMap(json['broker'])),
    marketCategory: copyText(json['market_category'], 'CTRADER').toUpperCase(),
    accountNumberMasked: copyText(json['account_number_masked'], '—'),
    status: copyText(json['status'], 'PENDING').toUpperCase(),
    activationState: copyText(
      json['activation_state'],
      'NOT_ELIGIBLE',
    ).toUpperCase(),
    verifiedCurrency: copyNullableText(json['verified_currency']),
    statusReason: copyNullableText(json['status_reason']),
  );

  final String uuid;
  final CopyTradingBrokerMarketModel broker;
  final String marketCategory;
  final String accountNumberMasked;
  final String status;
  final String activationState;
  final String? verifiedCurrency;
  final String? statusReason;

  CopyTradingAccount toEntity() => CopyTradingAccount(
    uuid: uuid,
    broker: broker.toEntity(),
    marketCategory: marketCategory,
    accountNumberMasked: accountNumberMasked,
    status: status,
    activationState: activationState,
    verifiedCurrency: verifiedCurrency,
    statusReason: statusReason,
  );
}

final class CopyTradingActivationModel {
  const CopyTradingActivationModel({
    required this.state,
    required this.copyTradeReady,
  });

  factory CopyTradingActivationModel.fromJson(CopyTradeJson json) =>
      CopyTradingActivationModel(
        state: copyText(json['state'], 'NOT ELIGIBLE'),
        copyTradeReady: json['copy_trade_ready'] == true,
      );

  final String state;
  final bool copyTradeReady;

  CopyTradingActivation toEntity() =>
      CopyTradingActivation(state: state, copyTradeReady: copyTradeReady);
}

CopyTradeJson copyTradeMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<CopyTradeJson> copyTradeList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const <CopyTradeJson>[];

String copyText(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? copyNullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
