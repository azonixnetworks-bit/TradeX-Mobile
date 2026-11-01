import '../repositories/affiliate_repository.dart';

final class LoadAffiliateOverview {
  const LoadAffiliateOverview(this._repository);
  final AffiliateRepository _repository;
  Future<JsonMap> call() => _repository.overview();
}
