import 'dart:typed_data';

import '../../../../core/domain/user_facing_exception.dart';
import '../entities/trade_journal_entities.dart';

typedef TradeJournalLivePriceLoader = Future<double?> Function(String symbol);

abstract interface class TradeJournalRepositoryContract {
  Future<String> timezone();
  Future<TradeJournalHome> home({bool forceRefresh = false});
  Future<TradeJournalMeta> meta({bool forceRefresh = false});
  Future<List<TradeJournalSymbolSuggestion>> symbolSuggestions({
    required String market,
    required String search,
    String? stockRegion,
  });
  Future<double?> livePrice({
    required String market,
    required String symbol,
    String? stockRegion,
  });
  Future<TradeJournalPage> entries({
    Map<String, String> filters = const {},
    int page = 1,
    bool forceRefresh = false,
  });
  Future<TradeJournalEntry> entry(String uuid, {bool forceRefresh = false});
  Future<TradeJournalEntry> create(Map<String, dynamic> body);
  Future<TradeJournalEntry> update(String uuid, Map<String, dynamic> body);
  Future<TradeJournalEntry> open(String uuid, Map<String, dynamic> body);
  Future<TradeJournalEntry> close(String uuid, Map<String, dynamic> body);
  Future<void> cancel(String uuid, {String? reason});
  Future<void> delete(String uuid);
  Future<Map<String, dynamic>> analytics({
    String period = 'month',
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  });
  Future<Map<String, dynamic>> review(
    String type, {
    DateTime? date,
    bool forceRefresh = false,
  });
  Future<Map<String, dynamic>> saveReview(
    String type,
    Map<String, dynamic> body, {
    DateTime? date,
  });
  Future<void> uploadScreenshot(String uuid, String type, String filePath);
  Future<Uint8List> screenshot(String uuid, String type);
  Future<void> deleteScreenshot(String uuid, String type);
}

final class JournalValidationException implements UserFacingException {
  const JournalValidationException(this.message);
  @override
  final String message;
  @override
  int? get statusCode => null;
  @override
  String? get code => null;
}
