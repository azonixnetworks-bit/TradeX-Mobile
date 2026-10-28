import '../../core/network/tradex_api_client.dart';
import 'data/risk_reward_repository.dart';

final class RiskRewardDependencies {
  RiskRewardDependencies(TradeXApiClient apiClient)
    : repository = RiskRewardRepository(apiClient);

  final RiskRewardRepository repository;
}
