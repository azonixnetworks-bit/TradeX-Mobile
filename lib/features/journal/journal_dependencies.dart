import '../../core/network/tradex_api_client.dart';
import 'data/repositories/trade_journal_repository_impl.dart';
import 'domain/repositories/trade_journal_repository.dart';

final class JournalDependencies {
  JournalDependencies(TradeXApiClient apiClient)
    : repository = TradeJournalRepositoryImpl(apiClient);
  final TradeJournalRepositoryContract repository;
}
