import '../entities/trade_idea_entities.dart';
import '../repositories/trade_idea_repository.dart';

final class LoadTradeIdeas {
  const LoadTradeIdeas(this._repository);
  final TradeIdeaRepositoryContract _repository;
  Future<TradeIdeaPage> call({String? category, String? symbol}) =>
      _repository.list(category: category, symbol: symbol);
}
