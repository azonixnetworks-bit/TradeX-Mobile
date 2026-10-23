import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/crypto_market_repository.dart';
import '../data/crypto_watchlist_store.dart';

class CryptoMarketState {
  const CryptoMarketState({
    this.snapshot,
    this.segment = 'SPOT',
    this.page = 1,
    this.search = '',
    this.loading = false,
    this.refreshing = false,
    this.fromCache = false,
    this.watchlistSymbols = const <String>{},
    this.errorMessage,
  });

  final CryptoMarketSnapshot? snapshot;
  final String segment;
  final int page;
  final String search;
  final bool loading;
  final bool refreshing;
  final bool fromCache;
  final Set<String> watchlistSymbols;
  final String? errorMessage;

  CryptoMarketState copyWith({
    CryptoMarketSnapshot? snapshot,
    String? segment,
    int? page,
    String? search,
    bool? loading,
    bool? refreshing,
    bool? fromCache,
    Set<String>? watchlistSymbols,
    String? errorMessage,
    bool clearError = false,
  }) => CryptoMarketState(
    snapshot: snapshot ?? this.snapshot,
    segment: segment ?? this.segment,
    page: page ?? this.page,
    search: search ?? this.search,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    fromCache: fromCache ?? this.fromCache,
    watchlistSymbols: watchlistSymbols ?? this.watchlistSymbols,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class CryptoMarketCubit extends Cubit<CryptoMarketState> {
  CryptoMarketCubit(this._repository, {CryptoWatchlistStore? watchlistStore})
    : _watchlistStore = watchlistStore ?? CryptoWatchlistStore(),
      super(const CryptoMarketState());

  final CryptoMarketRepository _repository;
  final CryptoWatchlistStore _watchlistStore;
  var _requestVersion = 0;
  var _refreshingBubbles = false;

  Future<void> initialize() async {
    final watchlist = await _watchlistStore.load();
    if (isClosed) return;
    emit(state.copyWith(watchlistSymbols: Set.unmodifiable(watchlist)));
    await _load(useCache: true);
  }

  Future<void> refresh() => _load(useCache: false);

  Future<void> refreshBubbles() async {
    if (state.snapshot == null || _refreshingBubbles) return;
    _refreshingBubbles = true;
    try {
      final snapshot = state.snapshot!;
      final segments = <String>{
        state.segment,
        for (final asset in snapshot.assets) asset.segment,
      };
      final responses = await Future.wait(segments.map(_loadLiveSegmentSafely));
      final updates = responses
          .whereType<MapEntry<String, CryptoBubbleUpdate>>()
          .toList(growable: false);
      if (isClosed || state.snapshot == null) return;
      if (updates.isEmpty) return;

      CryptoBubbleUpdate? primaryUpdate;
      final liveByMarket = <String, CryptoAsset>{};
      for (final entry in updates) {
        if (entry.key == state.segment) primaryUpdate = entry.value;
        for (final asset in entry.value.marketAssets) {
          liveByMarket[asset.marketKey] = asset;
        }
      }
      final current = state.snapshot!;
      final refreshedAssets = current.assets
          .map((asset) => asset.withLiveMarket(liveByMarket[asset.marketKey]))
          .toList(growable: false);
      final refreshedTopAssets = current.topAssets
          .map((asset) => asset.withLiveMarket(liveByMarket[asset.marketKey]))
          .toList(growable: false);
      emit(
        state.copyWith(
          snapshot: current.copyWith(
            summary: primaryUpdate?.summary,
            assets: refreshedAssets,
            bubbleAssets: primaryUpdate?.assets,
            topAssets: refreshedTopAssets,
            generatedAt: primaryUpdate?.generatedAt,
            stale: primaryUpdate?.stale,
          ),
          fromCache: false,
        ),
      );
    } catch (_) {
      // Retain the last successful live bubble set until the next refresh.
    } finally {
      _refreshingBubbles = false;
    }
  }

  Future<MapEntry<String, CryptoBubbleUpdate>?> _loadLiveSegmentSafely(
    String segment,
  ) async {
    try {
      final update = await _repository.loadBubbleUpdate(segment: segment);
      return MapEntry(segment, update);
    } catch (_) {
      return null;
    }
  }

  Future<void> selectSegment(String segment) async {
    if (segment == state.segment) return;
    emit(state.copyWith(segment: segment, page: 1, clearError: true));
    await _load(useCache: true);
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    if (normalized == state.search && state.page == 1) return;
    emit(state.copyWith(search: normalized, page: 1, clearError: true));
    await _load(useCache: true);
  }

  Future<void> nextPage() async {
    final pagination = state.snapshot?.pagination;
    if (pagination == null || !pagination.hasMore || state.refreshing) return;
    emit(state.copyWith(page: state.page + 1, clearError: true));
    await _load(useCache: true, append: true);
  }

  Future<void> previousPage() async {
    if (state.page <= 1 || state.refreshing) return;
    emit(state.copyWith(page: state.page - 1, clearError: true));
    await _load(useCache: true);
  }

  bool isWatchlisted(CryptoAsset asset) =>
      state.watchlistSymbols.contains(asset.marketKey) ||
      (asset.segment == 'SPOT' &&
          state.watchlistSymbols.contains(asset.symbol));

  Future<void> toggleWatchlist(String symbol, {String segment = 'SPOT'}) async {
    final normalizedSymbol = symbol.trim().toUpperCase();
    if (normalizedSymbol.isEmpty) return;
    final normalized = cryptoMarketKey(normalizedSymbol, segment);
    final updated = {...state.watchlistSymbols};
    final legacySpotKey = segment == 'SPOT' ? normalizedSymbol : null;
    if (updated.contains(normalized) ||
        (legacySpotKey != null && updated.contains(legacySpotKey))) {
      updated
        ..remove(normalized)
        ..remove(legacySpotKey);
    } else {
      updated.add(normalized);
    }
    emit(state.copyWith(watchlistSymbols: Set.unmodifiable(updated)));
    await _watchlistStore.save(updated);
  }

  Future<void> _load({required bool useCache, bool append = false}) async {
    final version = ++_requestVersion;
    final segment = state.segment;
    final page = state.page;
    final search = state.search;
    CryptoMarketSnapshot? cached;
    if (useCache) {
      cached = await _repository.loadCached(
        segment: segment,
        page: page,
        search: search,
      );
      if (version != _requestVersion || isClosed) return;
    }
    if (cached != null) {
      final snapshot = append && state.snapshot != null
          ? _appendPage(state.snapshot!, cached)
          : cached;
      emit(
        state.copyWith(
          snapshot: snapshot,
          loading: false,
          refreshing: true,
          fromCache: true,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loading: state.snapshot == null,
          refreshing: state.snapshot != null,
          clearError: true,
        ),
      );
    }
    try {
      final live = await _repository.load(
        segment: segment,
        page: page,
        search: search,
      );
      if (version != _requestVersion || isClosed) return;
      final snapshot = append && state.snapshot != null
          ? _appendPage(state.snapshot!, live)
          : live;
      emit(
        state.copyWith(
          snapshot: snapshot,
          loading: false,
          refreshing: false,
          fromCache: false,
          clearError: true,
        ),
      );
    } catch (_) {
      if (version != _requestVersion || isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          errorMessage: state.snapshot == null
              ? 'Live crypto market is temporarily unavailable.'
              : 'Live refresh failed. Showing saved market data.',
        ),
      );
    }
  }

  CryptoMarketSnapshot _appendPage(
    CryptoMarketSnapshot current,
    CryptoMarketSnapshot next,
  ) {
    final assetsByMarket = <String, CryptoAsset>{
      for (final asset in current.assets)
        '${asset.segment}:${asset.symbol}': asset,
      for (final asset in next.assets)
        '${asset.segment}:${asset.symbol}': asset,
    };
    return CryptoMarketSnapshot(
      summary: next.summary,
      assets: assetsByMarket.values.toList(growable: false),
      bubbleAssets: next.bubbleAssets,
      topAssets: current.topAssets,
      generatedAt: next.generatedAt,
      stale: next.stale,
      pagination: next.pagination,
      partialData: next.partialData,
    );
  }
}

class CryptoBubbleMapState {
  const CryptoBubbleMapState({
    this.mode = CryptoBubbleMode.gainers,
    this.assets = const <CryptoAsset>[],
    this.loading = false,
    this.refreshing = false,
    this.errorMessage,
  });

  final CryptoBubbleMode mode;
  final List<CryptoAsset> assets;
  final bool loading;
  final bool refreshing;
  final String? errorMessage;

  CryptoBubbleMapState copyWith({
    CryptoBubbleMode? mode,
    List<CryptoAsset>? assets,
    bool? loading,
    bool? refreshing,
    String? errorMessage,
    bool clearError = false,
  }) => CryptoBubbleMapState(
    mode: mode ?? this.mode,
    assets: assets ?? this.assets,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class CryptoBubbleMapCubit extends Cubit<CryptoBubbleMapState> {
  CryptoBubbleMapCubit(
    this._repository, {
    required this.segment,
    List<CryptoAsset> initialGainers = const <CryptoAsset>[],
  }) : _cache = {
         if (initialGainers.isNotEmpty)
           CryptoBubbleMode.gainers: List.unmodifiable(initialGainers),
       },
       super(
         CryptoBubbleMapState(
           assets: List.unmodifiable(initialGainers),
           loading: initialGainers.isEmpty,
         ),
       );

  final CryptoMarketRepository _repository;
  final String segment;
  final Map<CryptoBubbleMode, List<CryptoAsset>> _cache;
  var _requestVersion = 0;

  Future<void> initialize() => refresh();

  Future<void> selectMode(CryptoBubbleMode mode) async {
    if (mode == state.mode) return;
    final cached = _cache[mode] ?? const <CryptoAsset>[];
    emit(
      state.copyWith(
        mode: mode,
        assets: cached,
        loading: cached.isEmpty,
        refreshing: cached.isNotEmpty,
        clearError: true,
      ),
    );
    await refresh();
  }

  Future<void> refresh() async {
    final mode = state.mode;
    final version = ++_requestVersion;
    emit(
      state.copyWith(
        loading: state.assets.isEmpty,
        refreshing: state.assets.isNotEmpty,
        clearError: true,
      ),
    );
    try {
      final update = await _repository.loadBubbleUpdate(
        segment: segment,
        mode: mode,
      );
      _cache[mode] = List.unmodifiable(update.assets);
      if (isClosed || version != _requestVersion || state.mode != mode) return;
      emit(
        state.copyWith(
          assets: _cache[mode],
          loading: false,
          refreshing: false,
          clearError: true,
        ),
      );
    } catch (_) {
      if (isClosed || version != _requestVersion || state.mode != mode) return;
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          errorMessage: state.assets.isEmpty
              ? 'Live bubble data is temporarily unavailable.'
              : 'Bubble refresh failed. Showing the last live update.',
        ),
      );
    }
  }
}
