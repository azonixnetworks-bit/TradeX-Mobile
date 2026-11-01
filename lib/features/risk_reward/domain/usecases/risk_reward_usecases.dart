import '../entities/risk_reward_entities.dart';
import '../repositories/risk_reward_repository.dart';

final class CalculateRiskReward {
  const CalculateRiskReward(this._repository);
  final RiskRewardRepository _repository;
  Future<RiskRewardResult> call(Map<String, dynamic> input) =>
      _repository.calculate(input);
}
