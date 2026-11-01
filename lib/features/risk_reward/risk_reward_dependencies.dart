import '../../core/network/tradex_api_client.dart';
import 'data/repositories/risk_reward_repository_impl.dart';
import 'domain/repositories/risk_reward_repository.dart';

final class RiskRewardDependencies {
  RiskRewardDependencies(TradeXApiClient apiClient)
    : repository = RiskRewardRepositoryImpl(apiClient);

  final RiskRewardRepository repository;
}
