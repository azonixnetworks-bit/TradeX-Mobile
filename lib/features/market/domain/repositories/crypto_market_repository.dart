import '../entities/crypto_market_entities.dart';
import '../../../home/domain/trade_ideas_repository.dart';
import 'market_screener_repository.dart';

abstract interface class CryptoMarketRepositoryContract {
  Future<CryptoMarketSnapshot> load({
    required String segment,
    int page = 1,
    String search = '',
  });
  Future<CryptoMarketSnapshot?> loadCached({
    required String segment,
    int page = 1,
    String search = '',
  });
  Future<CryptoBubbleUpdate> loadBubbleUpdate({
    required String segment,
    CryptoBubbleMode mode = CryptoBubbleMode.gainers,
  });
  Future<List<CryptoAsset>> loadWatchlist({
    required String segment,
    required List<String> symbols,
  });
}

abstract interface class CryptoWatchlistRepository {
  Future<Set<String>> load();
  Future<void> save(Set<String> symbols);
}

class BinanceLiveTicker {
  const BinanceLiveTicker({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.quoteVolume,
  });
  final String symbol;
  final double price;
  final double changePercent;
  final double quoteVolume;
}

abstract interface class BinanceLiveTickerSource {
  Stream<Map<String, BinanceLiveTicker>> watch(String segment);
}

abstract interface class MarketFeatureDependencies {
  CryptoMarketRepositoryContract get repository;
  CryptoWatchlistRepository get watchlistRepository;
  BinanceLiveTickerSource get liveTickerSource;
  DashboardTradeIdeasRepository get tradeIdeasRepository;
  MarketScreenerRepositoryContract get screenerRepository;
}
