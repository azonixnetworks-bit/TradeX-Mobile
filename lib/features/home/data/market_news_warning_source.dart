import '../domain/no_trade_zone_warning.dart';
import 'market_news_repository.dart';

final class MarketNewsWarningSource implements NoTradeWarningSource {
  const MarketNewsWarningSource(this._repository);

  final MarketNewsRepository _repository;

  @override
  Future<List<EconomicNewsSnapshot>> load({bool forceRefresh = false}) async {
    final items = await _repository.today(forceRefresh: forceRefresh);
    return items
        .map((item) => item.toWarningSnapshot())
        .toList(growable: false);
  }
}
