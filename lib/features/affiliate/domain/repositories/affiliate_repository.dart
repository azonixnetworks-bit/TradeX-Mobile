import 'dart:convert';

typedef JsonMap = Map<String, dynamic>;

final class AffiliateException implements Exception {
  const AffiliateException({required this.message, this.code});
  final String message;
  final String? code;
}

abstract interface class AffiliateRepository {
  Future<JsonMap> overview();
  Future<JsonMap> referrals({
    int page = 1,
    int perPage = 20,
    String search = '',
    String? qualification,
  });
  Future<JsonMap> commissions({int page = 1, int perPage = 20});
  Future<JsonMap> earningsSeries({int months = 12});
  Future<JsonMap> stages();
  Future<JsonMap> milestones();
  Future<JsonMap> payoutSummary();
  Future<JsonMap> payoutMethods();
  Future<JsonMap> payoutHistory({int page = 1, int perPage = 20});
  Future<JsonMap> shareAction(String channel);
  Future<JsonMap> requestPayout({
    required String method,
    required String amount,
  });

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
  static double money(Object? value) => decimal(mapOf(value)['amount']);
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
