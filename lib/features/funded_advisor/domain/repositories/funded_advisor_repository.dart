import '../entities/funded_advisor_entities.dart';

abstract interface class FundedAdvisorRepository {
  Future<FundedAdvisorCachedCatalog?> loadCached();

  Future<String> fetchVersion();

  Future<FundedAdvisorCatalog> fetchCatalog();

  Future<void> saveCatalog(
    FundedAdvisorCatalog catalog, {
    required DateTime checkedAt,
  });

  Future<FundedAdvisorLogoBytes> loadLogo(String path);
}
