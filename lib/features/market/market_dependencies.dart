import '../../core/network/tradex_api_client.dart';
import '../home/domain/trade_ideas_repository.dart';
import 'data/datasources/binance_live_ticker_service.dart';
import 'data/datasources/crypto_watchlist_store.dart';
import 'data/repositories/crypto_market_repository_impl.dart';
import 'data/repositories/market_screener_repository_impl.dart';
import 'domain/repositories/crypto_market_repository.dart';
import 'domain/repositories/market_screener_repository.dart';

final class MarketDependencies implements MarketFeatureDependencies {
  MarketDependencies(
    TradeXApiClient apiClient, {
    required this.tradeIdeasRepository,
  }) : repository = CryptoMarketRepository(apiClient),
       watchlistRepository = CryptoWatchlistStore(
         accountKey: apiClient.currentAccountStorageKey(),
       ),
       liveTickerSource = BinanceLiveTickerService(),
       screenerRepository = MarketScreenerRepository(apiClient);
  @override
  final CryptoMarketRepositoryContract repository;
  @override
  final CryptoWatchlistRepository watchlistRepository;
  @override
  final BinanceLiveTickerSource liveTickerSource;
  @override
  final DashboardTradeIdeasRepository tradeIdeasRepository;
  @override
  final MarketScreenerRepositoryContract screenerRepository;
}
