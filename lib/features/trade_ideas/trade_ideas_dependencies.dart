import '../../core/network/tradex_api_client.dart';
import 'data/repositories/trade_idea_repository_impl.dart';
import 'domain/repositories/trade_idea_repository.dart';

final class TradeIdeasDependencies {
  TradeIdeasDependencies(TradeXApiClient apiClient)
    : repository = TradeIdeaRepository(apiClient);
  final TradeIdeaRepositoryContract repository;
}
