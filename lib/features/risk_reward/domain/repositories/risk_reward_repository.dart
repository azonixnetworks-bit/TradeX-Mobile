import '../entities/risk_reward_entities.dart';

abstract interface class RiskRewardRepository {
  Future<RiskRewardCatalog> catalog({bool forceRefresh = false});
  Future<RiskRewardQuote> quote({
    required String market,
    required String symbol,
    required String side,
  });
  Future<RiskRewardResult> calculate(Map<String, dynamic> input);
  Future<DividendResult> calculateDividend(Map<String, dynamic> input);
  Future<DividendHistory> dividendHistory(String symbol);
  Future<List<SavedCalculation>> saved();
  Future<SavedCalculation> save({
    required String type,
    required Map<String, dynamic> input,
    String? title,
  });
  Future<Map<String, dynamic>?> loadDraft(String key);
  Future<void> saveDraft(String key, Map<String, dynamic> value);
  Future<void> clearDraft(String key);
}

abstract interface class RiskRewardDataSource implements RiskRewardRepository {}
