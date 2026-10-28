import '../../domain/entities/funded_advisor_entities.dart';

final class FundedAdvisorCatalogModel {
  const FundedAdvisorCatalogModel({
    required this.version,
    required this.generatedAt,
    required this.partners,
  });

  factory FundedAdvisorCatalogModel.fromJson(Map<String, dynamic> json) {
    final version = _string(json['version']);
    if (version == null || version.isEmpty) {
      throw const FormatException('Funded advisor catalog version is missing.');
    }
    final rawPartners = json['partners'];
    if (rawPartners is! List) {
      throw const FormatException('Funded advisor partners are invalid.');
    }
    return FundedAdvisorCatalogModel(
      version: version,
      generatedAt: DateTime.tryParse(_string(json['generated_at']) ?? ''),
      partners: rawPartners
          .whereType<Map>()
          .map(
            (item) =>
                FundedPartnerModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  final String version;
  final DateTime? generatedAt;
  final List<FundedPartnerModel> partners;

  FundedAdvisorCatalog toEntity() => FundedAdvisorCatalog(
    version: version,
    generatedAt: generatedAt,
    partners: partners.map((partner) => partner.toEntity()).toList(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'generated_at': generatedAt?.toUtc().toIso8601String(),
    'partners': partners.map((partner) => partner.toJson()).toList(),
  };
}

final class FundedPartnerModel {
  const FundedPartnerModel({required this.json, required this.rules});

  factory FundedPartnerModel.fromJson(Map<String, dynamic> json) {
    final uuid = _string(json['uuid']);
    final name = _string(json['name']);
    if (uuid == null || uuid.isEmpty || name == null || name.isEmpty) {
      throw const FormatException('A funded partner is missing its identity.');
    }
    final rules = json['rules'];
    if (rules is! List) {
      throw const FormatException('Funded partner rules are invalid.');
    }
    return FundedPartnerModel(
      json: <String, dynamic>{...json, 'uuid': uuid, 'name': name},
      rules: rules
          .whereType<Map>()
          .map(
            (item) => FundedRuleModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  final Map<String, dynamic> json;
  final List<FundedRuleModel> rules;

  FundedPartner toEntity() => FundedPartner(
    uuid: json['uuid'] as String,
    name: json['name'] as String,
    websiteUrl: _string(json['website_url']),
    affiliateUrl: _string(json['affiliate_url']),
    promoCode: _string(json['promo_code']),
    offerText: _string(json['offer_text']),
    disclosure: _string(json['disclosure']),
    supportedCountries: _strings(json['supported_countries']),
    accountSizes: _values(json['account_sizes']),
    challengeTypes: _strings(json['challenge_types']),
    logoUrl: _string(json['logo_url']),
    isFeatured: json['is_featured'] == true,
    priority: _integer(json['priority']),
    rules: rules.map((rule) => rule.toEntity()).toList(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...json,
    'rules': rules.map((rule) => rule.toJson()).toList(),
  };
}

final class FundedRuleModel {
  const FundedRuleModel(this.json);

  factory FundedRuleModel.fromJson(Map<String, dynamic> json) {
    final uuid = _string(json['uuid']);
    if (uuid == null || uuid.isEmpty) {
      throw const FormatException('A funded rule is missing its identity.');
    }
    return FundedRuleModel(<String, dynamic>{...json, 'uuid': uuid});
  }

  final Map<String, dynamic> json;

  FundedRule toEntity() => FundedRule(
    uuid: json['uuid'] as String,
    programName: _string(json['program_name']),
    phase: _string(json['phase']) ?? 'ALL',
    policy: _string(json['policy']) ?? 'RESTRICTED',
    enforcementType: _string(json['enforcement_type']) ?? 'BLOCKED',
    impactLevels: _strings(json['impact_levels']),
    eventKeywords: _strings(json['event_keywords']),
    minutesBefore: _integer(json['minutes_before']),
    minutesAfter: _integer(json['minutes_after']),
    affectedInstrumentsOnly: json['affected_instruments_only'] == true,
    restrictedCurrencies: _strings(json['restricted_currencies']),
    restrictedInstruments: _strings(json['restricted_instruments']),
    blockOpenNewTrades: json['block_open_new_trades'] == true,
    blockCloseTrades: json['block_close_trades'] == true,
    blockPendingOrders: json['block_pending_orders'] == true,
    summary: _string(json['rule_summary']),
    sourceUrl: _string(json['source_url']),
    sourceReference: _string(json['source_reference']),
    verifiedAt: DateTime.tryParse(_string(json['verified_at']) ?? ''),
    effectiveFrom: DateTime.tryParse(_string(json['effective_from']) ?? ''),
    expiresAt: DateTime.tryParse(_string(json['expires_at']) ?? ''),
    priority: _integer(json['priority']),
  );

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(json);
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

List<String> _strings(Object? value) => value is List
    ? value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false)
    : const <String>[];

List<String> _values(Object? value) => value is List
    ? value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false)
    : const <String>[];
