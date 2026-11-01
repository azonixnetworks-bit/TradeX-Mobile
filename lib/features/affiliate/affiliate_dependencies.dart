import '../../core/network/tradex_api_client.dart';
import 'data/repositories/affiliate_repository_impl.dart';
import 'domain/repositories/affiliate_repository.dart';

final class AffiliateDependencies {
  AffiliateDependencies(TradeXApiClient apiClient)
    : repository = AffiliateRepositoryImpl(apiClient);
  final AffiliateRepository repository;
}
