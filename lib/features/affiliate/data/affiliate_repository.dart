import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/network/tradex_api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class AffiliateRepository {
  AffiliateRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  Future<JsonMap> overview() => _get('/api/v1/affiliate/overview');

  Future<JsonMap> referrals({
    int page = 1,
    int perPage = 20,
    String search = '',
    String? qualification,
  }) {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    if (qualification != null) {
      query['qualification'] = qualification;
    }
    return _get(
      '/api/v1/affiliate/referrals?${Uri(queryParameters: query).query}',
    );
  }

  Future<JsonMap> commissions({int page = 1, int perPage = 20}) =>
      _get('/api/v1/affiliate/commissions?page=$page&per_page=$perPage');

  Future<JsonMap> earningsSeries({int months = 12}) =>
      _get('/api/v1/affiliate/earnings-series?months=$months');

  Future<JsonMap> stages() => _get('/api/v1/affiliate/stages');

  Future<JsonMap> milestones() => _get('/api/v1/affiliate/milestones');

  Future<JsonMap> payoutSummary() => _get('/api/v1/payouts/summary');

  Future<JsonMap> payoutMethods() => _get('/api/v1/payouts/methods');

  Future<JsonMap> payoutHistory({int page = 1, int perPage = 20}) =>
      _get('/api/v1/payouts/history?page=$page&per_page=$perPage');

  Future<JsonMap> shareAction(String channel) async {
    final response = await _apiClient.postJson(
      '/api/v1/affiliate/share-action',
      {'channel': channel},
    );
    return dataOf(response);
  }

  Future<JsonMap> requestPayout({
    required String method,
    required String amount,
  }) async {
    final response = await _apiClient.postJsonWithHeaders(
      '/api/v1/payouts',
      {'method': method, 'amount': amount},
      {'Idempotency-Key': const Uuid().v4()},
    );
    return dataOf(response);
  }

  Future<JsonMap> _get(String path) async {
    final response = await _apiClient.getJson(path);
    return dataOf(response);
  }

  static JsonMap dataOf(JsonMap response) => mapOf(response['data']);

  static JsonMap mapOf(Object? value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};

  static List<JsonMap> listOf(Object? value) => value is List
      ? value.map(mapOf).toList(growable: false)
      : const <JsonMap>[];

  static String text(Object? value, [String fallback = '—']) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static int integer(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String number => int.tryParse(number) ?? 0,
    _ => 0,
  };

  static double decimal(Object? value) => switch (value) {
    num number => number.toDouble(),
    String number => double.tryParse(number) ?? 0,
    _ => 0,
  };

  static bool boolean(Object? value) => value == true || value == 1;

  static double money(Object? value) {
    final map = mapOf(value);
    return decimal(map['amount']);
  }

  static String moneyText(Object? value, {String symbol = r'$'}) {
    final map = mapOf(value);
    final amount = money(value);
    final currency = text(map['currency'], 'USD');
    return currency == 'USD'
        ? '$symbol${amount.toStringAsFixed(2)}'
        : '$currency ${amount.toStringAsFixed(2)}';
  }

  static String prettyJson(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);
}
