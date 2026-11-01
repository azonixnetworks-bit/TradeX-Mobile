enum InvestmentAvailability { active, comingSoon, unavailable }

enum InvestmentStatus { active, pending, matured, completed, closed, loss }

enum InvestmentRecordStatus {
  pending,
  prepared,
  approved,
  verified,
  paid,
  rejected,
  closed,
  loss,
}

class InvestmentPortfolio {
  const InvestmentPortfolio({
    this.totalInvested,
    this.portfolioValue,
    this.verifiedProfit,
    this.currency,
    this.activeCount,
    this.nextReviewAt,
    this.valuedAt,
  });

  final double? totalInvested;
  final double? portfolioValue;
  final double? verifiedProfit;
  final String? currency;
  final int? activeCount;
  final DateTime? nextReviewAt;
  final DateTime? valuedAt;
}

class InvestmentProduct {
  const InvestmentProduct({
    required this.id,
    required this.name,
    required this.availability,
    this.description,
    this.currencies = const [],
    this.networks = const [],
    this.profitSharingModel,
    this.periodTerms,
    this.riskTier,
    this.updatedAt,
  });

  final String id;
  final String name;
  final InvestmentAvailability availability;
  final String? description;
  final List<String> currencies;
  final List<String> networks;
  final String? profitSharingModel;
  final String? periodTerms;
  final String? riskTier;
  final DateTime? updatedAt;
}

class CustomerInvestment {
  const CustomerInvestment({
    required this.id,
    required this.code,
    required this.productName,
    required this.status,
    this.amount,
    this.currency,
    this.network,
    this.startAt,
    this.maturityAt,
    this.nextReviewAt,
    this.progress,
    this.periodLabel,
    this.customerSharePercent,
    this.companySharePercent,
    this.highWaterMark,
    this.lossCarryForward,
    this.principalSettlementStatus,
    this.payoutWalletStatus,
    this.maskedPayoutWallet,
    this.lifecycle = const [],
  });

  final String id;
  final String code;
  final String productName;
  final InvestmentStatus status;
  final double? amount;
  final String? currency;
  final String? network;
  final DateTime? startAt;
  final DateTime? maturityAt;
  final DateTime? nextReviewAt;
  final double? progress;
  final String? periodLabel;
  final double? customerSharePercent;
  final double? companySharePercent;
  final double? highWaterMark;
  final double? lossCarryForward;
  final InvestmentRecordStatus? principalSettlementStatus;
  final InvestmentRecordStatus? payoutWalletStatus;
  final String? maskedPayoutWallet;
  final List<InvestmentLifecycleStep> lifecycle;
}

class InvestmentLifecycleStep {
  const InvestmentLifecycleStep({
    required this.label,
    required this.completed,
    this.current = false,
    this.confirmedAt,
  });

  final String label;
  final bool completed;
  final bool current;
  final DateTime? confirmedAt;
}

class InvestmentProfitPeriod {
  const InvestmentProfitPeriod({
    required this.id,
    required this.label,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.openingValue,
    this.closingValue,
    this.grossProfitLoss,
    this.customerShare,
    this.companyShare,
    this.highWaterMark,
    this.lossCarryForward,
    this.payoutStatus,
    this.currency,
    this.verified = false,
  });

  final String id;
  final String label;
  final InvestmentRecordStatus status;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double? openingValue;
  final double? closingValue;
  final double? grossProfitLoss;
  final double? customerShare;
  final double? companyShare;
  final double? highWaterMark;
  final double? lossCarryForward;
  final InvestmentRecordStatus? payoutStatus;
  final String? currency;
  final bool verified;
}

class InvestmentTransaction {
  const InvestmentTransaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.status,
    this.amount,
    this.currency,
    this.network,
    this.createdAt,
    this.verifiedAt,
    this.verificationStatus,
    this.maskedTransactionHash,
    this.maskedWallet,
    this.referenceCopyAllowed = false,
  });

  final String id;
  final String reference;
  final String type;
  final InvestmentRecordStatus status;
  final double? amount;
  final String? currency;
  final String? network;
  final DateTime? createdAt;
  final DateTime? verifiedAt;
  final InvestmentRecordStatus? verificationStatus;
  final String? maskedTransactionHash;
  final String? maskedWallet;
  final bool referenceCopyAllowed;
}

class InvestmentAgreement {
  const InvestmentAgreement({
    this.riskAccepted = false,
    this.disclosureVersion,
    this.riskAcceptedAt,
    this.agreementVersion,
    this.status,
    this.generatedAt,
    this.signedAt,
    this.verifiedAt,
    this.authorizedViewPath,
    this.authorizedDownloadPath,
  });

  final bool riskAccepted;
  final String? disclosureVersion;
  final DateTime? riskAcceptedAt;
  final String? agreementVersion;
  final InvestmentRecordStatus? status;
  final DateTime? generatedAt;
  final DateTime? signedAt;
  final DateTime? verifiedAt;
  final String? authorizedViewPath;
  final String? authorizedDownloadPath;
}

class InvestmentDashboard {
  const InvestmentDashboard({
    required this.portfolio,
    this.products = const [],
    this.investments = const [],
    this.profitPeriods = const [],
    this.transactions = const [],
    this.agreement,
    this.cachedAt,
    this.isStale = false,
  });

  final InvestmentPortfolio portfolio;
  final List<InvestmentProduct> products;
  final List<CustomerInvestment> investments;
  final List<InvestmentProfitPeriod> profitPeriods;
  final List<InvestmentTransaction> transactions;
  final InvestmentAgreement? agreement;
  final DateTime? cachedAt;
  final bool isStale;
}
