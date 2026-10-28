import 'dart:typed_data';

class FundedAdvisorCatalog {
  const FundedAdvisorCatalog({
    required this.version,
    required this.generatedAt,
    required this.partners,
  });

  final String version;
  final DateTime? generatedAt;
  final List<FundedPartner> partners;
}

class FundedPartner {
  const FundedPartner({
    required this.uuid,
    required this.name,
    required this.websiteUrl,
    required this.affiliateUrl,
    required this.promoCode,
    required this.offerText,
    required this.disclosure,
    required this.supportedCountries,
    required this.accountSizes,
    required this.challengeTypes,
    required this.logoUrl,
    required this.isFeatured,
    required this.priority,
    required this.rules,
  });

  final String uuid;
  final String name;
  final String? websiteUrl;
  final String? affiliateUrl;
  final String? promoCode;
  final String? offerText;
  final String? disclosure;
  final List<String> supportedCountries;
  final List<String> accountSizes;
  final List<String> challengeTypes;
  final String? logoUrl;
  final bool isFeatured;
  final int priority;
  final List<FundedRule> rules;

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'FA';
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }
}

class FundedRule {
  const FundedRule({
    required this.uuid,
    required this.programName,
    required this.phase,
    required this.policy,
    required this.enforcementType,
    required this.impactLevels,
    required this.eventKeywords,
    required this.minutesBefore,
    required this.minutesAfter,
    required this.affectedInstrumentsOnly,
    required this.restrictedCurrencies,
    required this.restrictedInstruments,
    required this.blockOpenNewTrades,
    required this.blockCloseTrades,
    required this.blockPendingOrders,
    required this.summary,
    required this.sourceUrl,
    required this.sourceReference,
    required this.verifiedAt,
    required this.effectiveFrom,
    required this.expiresAt,
    required this.priority,
  });

  final String uuid;
  final String? programName;
  final String phase;
  final String policy;
  final String enforcementType;
  final List<String> impactLevels;
  final List<String> eventKeywords;
  final int minutesBefore;
  final int minutesAfter;
  final bool affectedInstrumentsOnly;
  final List<String> restrictedCurrencies;
  final List<String> restrictedInstruments;
  final bool blockOpenNewTrades;
  final bool blockCloseTrades;
  final bool blockPendingOrders;
  final String? summary;
  final String? sourceUrl;
  final String? sourceReference;
  final DateTime? verifiedAt;
  final DateTime? effectiveFrom;
  final DateTime? expiresAt;
  final int priority;
}

class FundedAdvisorCachedCatalog {
  const FundedAdvisorCachedCatalog({
    required this.catalog,
    required this.cachedAt,
    required this.lastCheckedAt,
    required this.lastCheckedLocalDay,
  });

  final FundedAdvisorCatalog catalog;
  final DateTime cachedAt;
  final DateTime? lastCheckedAt;
  final String? lastCheckedLocalDay;
}

typedef FundedAdvisorLogoBytes = Uint8List;
