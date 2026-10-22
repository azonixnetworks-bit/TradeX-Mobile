import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/crypto_market_repository.dart';
import '../../data/trade_ideas_repository.dart';

enum CryptoMarketStatus { initial, loading, success, failure }

enum CryptoMarketFilter { overview, gainers, losers, watchlist }

class CryptoMarketState {
  const CryptoMarketState({
    this.status = CryptoMarketStatus.initial,
    this.filter = CryptoMarketFilter.overview,
    this.summary = CryptoMarketSummary.empty,
    this.assets = const [],
    this.bubbles = const [],
    this.tradeIdeas = const [],
    this.watchlist = const {},
    this.provider = 'BINANCE',
    this.stale = false,
    this.updatedAt,
  });

  final CryptoMarketStatus status;
  final CryptoMarketFilter filter;
  final CryptoMarketSummary summary;
  final List<CryptoScreenerAsset> assets;
  final List<CryptoBubbleAsset> bubbles;
  final List<DashboardTradeIdea> tradeIdeas;
  final Set<String> watchlist;
  final String provider;
  final bool stale;
  final DateTime? updatedAt;

  List<CryptoScreenerAsset> get visibleAssets {
    final values = switch (filter) {
      CryptoMarketFilter.overview => [...assets],
      CryptoMarketFilter.gainers =>
        assets.where((asset) => asset.changePercent > 0).toList(),
      CryptoMarketFilter.losers =>
        assets.where((asset) => asset.changePercent < 0).toList(),
      CryptoMarketFilter.watchlist =>
        assets.where((asset) => watchlist.contains(asset.symbol)).toList(),
    };

    values.sort((left, right) {
      if (filter == CryptoMarketFilter.overview) {
        return right.quoteVolume.compareTo(left.quoteVolume);
      }
      if (filter == CryptoMarketFilter.losers) {
        return left.changePercent.compareTo(right.changePercent);
      }
      return right.changePercent.compareTo(left.changePercent);
    });

    return filter == CryptoMarketFilter.watchlist
        ? List.unmodifiable(values)
        : List.unmodifiable(values.take(5));
  }

  CryptoMarketState copyWith({
    CryptoMarketStatus? status,
    CryptoMarketFilter? filter,
    CryptoMarketSummary? summary,
    List<CryptoScreenerAsset>? assets,
    List<CryptoBubbleAsset>? bubbles,
    List<DashboardTradeIdea>? tradeIdeas,
    Set<String>? watchlist,
    String? provider,
    bool? stale,
    DateTime? updatedAt,
  }) => CryptoMarketState(
    status: status ?? this.status,
    filter: filter ?? this.filter,
    summary: summary ?? this.summary,
    assets: assets ?? this.assets,
    bubbles: bubbles ?? this.bubbles,
    tradeIdeas: tradeIdeas ?? this.tradeIdeas,
    watchlist: watchlist ?? this.watchlist,
    provider: provider ?? this.provider,
    stale: stale ?? this.stale,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class CryptoMarketCubit extends Cubit<CryptoMarketState> {
  CryptoMarketCubit(this._repository, this._tradeIdeasRepository)
    : super(const CryptoMarketState()) {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(load(silent: true)),
    );
  }

  final CryptoMarketRepository _repository;
  final TradeIdeasRepository _tradeIdeasRepository;
  late final Timer _refreshTimer;

  Future<void> load({bool silent = false}) async {
    if (!silent && state.assets.isEmpty) {
      emit(state.copyWith(status: CryptoMarketStatus.loading));
    }

    final results = await Future.wait<Object?>([
      _attempt(_repository.screener()),
      _attempt(_repository.bubbles()),
      _attempt(_repository.watchlist()),
      _attempt(_tradeIdeasRepository.latestCrypto()),
    ]);
    if (isClosed) return;

    final screener = results[0] as CryptoScreenerDataset?;
    final bubbles = results[1] as CryptoBubbleDataset?;
    final watchlist = results[2] as Set<String>?;
    final tradeIdeas = results[3] as List<DashboardTradeIdea>?;
    final liveBySymbol = <String, CryptoBubbleAsset>{
      for (final asset in bubbles?.assets ?? const <CryptoBubbleAsset>[])
        asset.symbol: asset,
    };
    final mergedAssets = screener?.assets
        .map(
          (asset) => liveBySymbol[asset.symbol] == null
              ? asset
              : asset.withLiveData(liveBySymbol[asset.symbol]!),
        )
        .toList(growable: false);

    if (screener == null && bubbles == null && state.assets.isEmpty) {
      emit(state.copyWith(status: CryptoMarketStatus.failure));
      return;
    }

    emit(
      state.copyWith(
        status: CryptoMarketStatus.success,
        summary: bubbles?.summary ?? state.summary,
        assets: mergedAssets ?? state.assets,
        bubbles: bubbles?.assets ?? state.bubbles,
        tradeIdeas: tradeIdeas ?? state.tradeIdeas,
        watchlist: watchlist ?? state.watchlist,
        provider: bubbles?.provider ?? screener?.provider ?? state.provider,
        stale: (screener?.stale ?? false) || (bubbles?.stale ?? false),
        updatedAt:
            bubbles?.generatedAt ?? screener?.generatedAt ?? state.updatedAt,
      ),
    );
  }

  void selectFilter(CryptoMarketFilter filter) {
    if (state.filter != filter) emit(state.copyWith(filter: filter));
  }

  Future<void> toggleWatchlist(String symbol) async {
    final updated = await _repository.toggleWatchlist(symbol);
    if (!isClosed) emit(state.copyWith(watchlist: updated));
  }

  Future<void> clearWatchlist() async {
    await _repository.clearWatchlist();
    if (!isClosed) emit(state.copyWith(watchlist: <String>{}));
  }

  @override
  Future<void> close() {
    _refreshTimer.cancel();
    return super.close();
  }
}

Future<T?> _attempt<T>(Future<T> request) async {
  try {
    return await request;
  } catch (_) {
    return null;
  }
}
