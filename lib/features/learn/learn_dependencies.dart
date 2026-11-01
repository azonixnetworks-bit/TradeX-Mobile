import '../../core/network/tradex_api_client.dart';
import 'data/repositories/learn_repository_impl.dart';
import 'domain/repositories/learn_repository.dart';

final class LearnDependencies {
  LearnDependencies(TradeXApiClient apiClient)
    : repository = LearnRepositoryImpl(apiClient);
  final LearnRepository repository;
}
