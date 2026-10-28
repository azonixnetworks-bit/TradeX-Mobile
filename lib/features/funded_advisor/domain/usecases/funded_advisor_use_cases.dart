import '../entities/funded_advisor_entities.dart';
import '../repositories/funded_advisor_repository.dart';

final class FundedAdvisorUseCases {
  const FundedAdvisorUseCases(this._repository);

  final FundedAdvisorRepository _repository;

  Future<FundedAdvisorCachedCatalog?> loadCached() => _repository.loadCached();

  Future<String> fetchVersion() => _repository.fetchVersion();

  Future<FundedAdvisorCatalog> fetchCatalog() => _repository.fetchCatalog();

  Future<void> saveCatalog(
    FundedAdvisorCatalog catalog, {
    required DateTime checkedAt,
  }) => _repository.saveCatalog(catalog, checkedAt: checkedAt);

  Future<FundedAdvisorLogoBytes> loadLogo(String path) =>
      _repository.loadLogo(path);
}
