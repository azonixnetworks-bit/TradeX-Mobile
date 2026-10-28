import 'dart:typed_data';

import '../../domain/entities/funded_advisor_entities.dart';
import '../../domain/repositories/funded_advisor_repository.dart';
import '../datasources/funded_advisor_local_data_source.dart';
import '../datasources/funded_advisor_logo_store.dart';
import '../datasources/funded_advisor_remote_data_source.dart';
import '../models/funded_advisor_models.dart';

final class FundedAdvisorRepositoryImpl implements FundedAdvisorRepository {
  FundedAdvisorRepositoryImpl(this._remote, this._local, this._logoStore);

  final FundedAdvisorRemoteDataSource _remote;
  final FundedAdvisorLocalDataSource _local;
  final FundedAdvisorLogoStore _logoStore;
  final Map<String, Uint8List> _logoMemoryCache = <String, Uint8List>{};
  String _catalogVersion = 'unknown';

  @override
  Future<FundedAdvisorCachedCatalog?> loadCached() async {
    final cached = await _local.read();
    if (cached == null) return null;
    _catalogVersion = cached.catalog.version;
    return FundedAdvisorCachedCatalog(
      catalog: cached.catalog.toEntity(),
      cachedAt: cached.cachedAt,
      lastCheckedAt: cached.lastCheckedAt,
      lastCheckedLocalDay: cached.lastCheckedLocalDay,
    );
  }

  @override
  Future<String> fetchVersion() => _remote.fetchVersion();

  @override
  Future<FundedAdvisorCatalog> fetchCatalog() async {
    final catalog = (await _remote.fetchCatalog()).toEntity();
    _catalogVersion = catalog.version;
    return catalog;
  }

  @override
  Future<void> saveCatalog(
    FundedAdvisorCatalog catalog, {
    required DateTime checkedAt,
  }) {
    _catalogVersion = catalog.version;
    return _local.write(
      FundedAdvisorCatalogModel(
        version: catalog.version,
        generatedAt: catalog.generatedAt,
        partners: catalog.partners.map(_partnerModel).toList(),
      ),
      checkedAt: checkedAt,
    );
  }

  @override
  Future<Uint8List> loadLogo(String path) async {
    final cacheKey = '$_catalogVersion|$path';
    final cached = _logoMemoryCache[cacheKey];
    if (cached != null) return cached;
    final disk = await _logoStore.read(cacheKey);
    if (disk != null) {
      _logoMemoryCache[cacheKey] = disk;
      return disk;
    }
    final bytes = await _remote.loadLogo(path);
    _logoMemoryCache[cacheKey] = bytes;
    await _logoStore.write(cacheKey, bytes);
    return bytes;
  }
}

FundedPartnerModel _partnerModel(FundedPartner partner) =>
    FundedPartnerModel.fromJson(<String, dynamic>{
      'uuid': partner.uuid,
      'name': partner.name,
      'website_url': partner.websiteUrl,
      'affiliate_url': partner.affiliateUrl,
      'promo_code': partner.promoCode,
      'offer_text': partner.offerText,
      'disclosure': partner.disclosure,
      'supported_countries': partner.supportedCountries,
      'account_sizes': partner.accountSizes,
      'challenge_types': partner.challengeTypes,
      'logo_url': partner.logoUrl,
      'is_featured': partner.isFeatured,
      'priority': partner.priority,
      'rules': partner.rules.map(_ruleJson).toList(),
    });

Map<String, dynamic> _ruleJson(FundedRule rule) => <String, dynamic>{
  'uuid': rule.uuid,
  'program_name': rule.programName,
  'phase': rule.phase,
  'policy': rule.policy,
  'enforcement_type': rule.enforcementType,
  'impact_levels': rule.impactLevels,
  'event_keywords': rule.eventKeywords,
  'minutes_before': rule.minutesBefore,
  'minutes_after': rule.minutesAfter,
  'affected_instruments_only': rule.affectedInstrumentsOnly,
  'restricted_currencies': rule.restrictedCurrencies,
  'restricted_instruments': rule.restrictedInstruments,
  'block_open_new_trades': rule.blockOpenNewTrades,
  'block_close_trades': rule.blockCloseTrades,
  'block_pending_orders': rule.blockPendingOrders,
  'rule_summary': rule.summary,
  'source_url': rule.sourceUrl,
  'source_reference': rule.sourceReference,
  'verified_at': rule.verifiedAt?.toUtc().toIso8601String(),
  'effective_from': rule.effectiveFrom?.toUtc().toIso8601String(),
  'expires_at': rule.expiresAt?.toUtc().toIso8601String(),
  'priority': rule.priority,
};
