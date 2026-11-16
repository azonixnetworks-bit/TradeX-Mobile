import '../entities/market_screener_entities.dart';

abstract interface class MarketScreenerRepositoryContract {
  Future<MarketScreenerSnapshot> load({
    required String market,
    String stockRegion = '',
  });
}
