import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/tradex_api_client.dart';
import '../models/risk_reward_models.dart';

abstract interface class RiskRewardDataSource {
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

final class RiskRewardRepository implements RiskRewardDataSource {
  RiskRewardRepository(this._apiClient);

  final TradeXApiClient _apiClient;
  static const _base = '/api/v1/trading-tools/risk-reward';

  @override
  Future<RiskRewardCatalog> catalog({bool forceRefresh = false}) async {
    final response = forceRefresh
        ? await _apiClient.getJson('$_base/catalog')
        : await _apiClient.getJsonCacheFirst('$_base/catalog');
    return RiskRewardCatalog.fromResponse(response);
  }

  @override
  Future<RiskRewardQuote> quote({
    required String market,
    required String symbol,
    required String side,
  }) async => RiskRewardQuote.fromResponse(
    await _apiClient.getJson(
      '$_base/quote?market=${Uri.encodeQueryComponent(market)}&symbol=${Uri.encodeQueryComponent(symbol)}&side=${Uri.encodeQueryComponent(side)}',
    ),
  );

  @override
  Future<RiskRewardResult> calculate(Map<String, dynamic> input) async =>
      RiskRewardResult.fromResponse(
        await _apiClient.postJson('$_base/calculate', input),
      );

  @override
  Future<DividendResult> calculateDividend(Map<String, dynamic> input) async =>
      DividendResult.fromResponse(
        await _apiClient.postJson('$_base/dividends/calculate', input),
      );

  @override
  Future<DividendHistory> dividendHistory(String symbol) async =>
      DividendHistory.fromResponse(
        await _apiClient.getJson(
          '$_base/dividends/${Uri.encodeComponent(symbol)}',
        ),
      );

  @override
  Future<List<SavedCalculation>> saved() async {
    final response = await _apiClient.getJson('$_base/saved');
    final data = response['data'];
    final items = data is Map ? data['items'] : null;
    return items is List
        ? items.map(SavedCalculation.fromJson).toList(growable: false)
        : const <SavedCalculation>[];
  }

  @override
  Future<SavedCalculation> save({
    required String type,
    required Map<String, dynamic> input,
    String? title,
  }) async => SavedCalculation.fromJson(
    (await _apiClient.postJson('$_base/saved', <String, dynamic>{
      'calculator_type': type,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      'input': input,
    }))['data'],
  );

  @override
  Future<Map<String, dynamic>?> loadDraft(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final account = await _apiClient.currentAccountStorageKey();
    final raw = preferences.getString(_draftKey(account, key));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDraft(String key, Map<String, dynamic> value) async {
    final preferences = await SharedPreferences.getInstance();
    final account = await _apiClient.currentAccountStorageKey();
    await preferences.setString(_draftKey(account, key), jsonEncode(value));
  }

  @override
  Future<void> clearDraft(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final account = await _apiClient.currentAccountStorageKey();
    await preferences.remove(_draftKey(account, key));
  }

  String _draftKey(String? account, String key) =>
      'risk_reward_draft:${account ?? 'anonymous'}:$key';
}
