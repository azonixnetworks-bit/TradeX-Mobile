import 'repositories/trade_journal_repository_impl.dart';

export '../domain/repositories/trade_journal_repository.dart'
    show TradeJournalLivePriceLoader;

class TradeJournalRepository extends TradeJournalRepositoryImpl {
  TradeJournalRepository(
    super.apiClient, [
    super.timezone,
    super.livePriceLoader,
  ]);
}
