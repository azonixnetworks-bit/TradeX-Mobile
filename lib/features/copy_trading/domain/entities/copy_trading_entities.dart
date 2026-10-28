import 'dart:typed_data';

class CopyTradingDashboard {
  const CopyTradingDashboard({
    required this.accounts,
    required this.copyTradeReady,
    required this.nextStep,
  });

  final List<CopyTradingAccount> accounts;
  final bool copyTradeReady;
  final String nextStep;
}

class CopyTradingBrokerMarket {
  const CopyTradingBrokerMarket({
    required this.brokerMarketUuid,
    required this.brokerUuid,
    required this.brokerName,
    required this.marketCategory,
    required this.requiredCurrency,
    required this.logoUrl,
  });

  final String brokerMarketUuid;
  final String brokerUuid;
  final String brokerName;
  final String marketCategory;
  final String requiredCurrency;
  final String? logoUrl;
}

class CopyTradingOnboardingIntent {
  const CopyTradingOnboardingIntent({
    required this.uuid,
    required this.openAccountUrl,
    required this.expiresAt,
  });

  final String uuid;
  final String openAccountUrl;
  final DateTime? expiresAt;
}

class CopyTradingAccount {
  const CopyTradingAccount({
    required this.uuid,
    required this.broker,
    required this.marketCategory,
    required this.accountNumberMasked,
    required this.status,
    required this.activationState,
    required this.verifiedCurrency,
    required this.statusReason,
  });

  final String uuid;
  final CopyTradingBrokerMarket broker;
  final String marketCategory;
  final String accountNumberMasked;
  final String status;
  final String activationState;
  final String? verifiedCurrency;
  final String? statusReason;

  bool get isActive => status == 'ACTIVE';
  bool get isVerified => status == 'VERIFIED' || isActive;
  bool get needsReview =>
      const {'PENDING', 'NEEDS_RESUBMISSION', 'ESCALATED'}.contains(status);
}

class CopyTradingActivation {
  const CopyTradingActivation({
    required this.state,
    required this.copyTradeReady,
  });

  final String state;
  final bool copyTradeReady;
}

typedef CopyTradingLogoBytes = Uint8List;
