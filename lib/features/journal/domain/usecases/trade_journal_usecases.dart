import '../entities/trade_journal_entities.dart';
import '../repositories/trade_journal_repository.dart';

final class LoadTradeJournalHome {
  const LoadTradeJournalHome(this._repository);
  final TradeJournalRepositoryContract _repository;
  Future<TradeJournalHome> call({bool forceRefresh = false}) =>
      _repository.home(forceRefresh: forceRefresh);
}
