part of '../crypto_market_screen.dart';

class CryptoMarketScreen extends StatefulWidget {
  const CryptoMarketScreen({
    super.key,
    this.apiClient,
    this.dependencies,
    this.enableDirectBubbleStream = true,
  });

  final Object? apiClient;
  final MarketFeatureDependencies? dependencies;
  final bool enableDirectBubbleStream;

  @override
  State<CryptoMarketScreen> createState() => _CryptoMarketScreenState();
}

class _CryptoMarketScreenState extends State<CryptoMarketScreen>
    with WidgetsBindingObserver {
  late final CryptoMarketCubit _cubit;
  late final CryptoMarketRepositoryContract _cryptoRepository;
  late final DashboardTradeIdeasRepository _tradeIdeasRepository;
  late final BinanceLiveTickerSource _liveTickerSource;
  final _search = TextEditingController();
  Timer? _searchDebounce;
  Timer? _liveRefreshTimer;
  var _appIsActive = true;
  var _typedQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final dependencies =
        widget.dependencies ?? MarketDependencies(widget.apiClient as dynamic);
    _cryptoRepository = dependencies.repository;
    _liveTickerSource = dependencies.liveTickerSource;
    _cubit = CryptoMarketCubit(
      _cryptoRepository,
      watchlistStore: dependencies.watchlistRepository,
    );
    _tradeIdeasRepository = dependencies.tradeIdeasRepository;
    _cubit.initialize();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || !_appIsActive) return;
      _cubit.refreshBubbles();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveRefreshTimer?.cancel();
    _searchDebounce?.cancel();
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _reload() => _cubit.refresh();

  Future<void> _toggleWatchlist(CryptoAsset asset) async {
    final wasSaved = _cubit.isWatchlisted(asset);
    await _cubit.toggleWatchlist(asset.symbol, segment: asset.segment);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? '${asset.symbol} removed from watchlist.'
                : '${asset.symbol} added to watchlist.',
          ),
        ),
      );
  }

  void _openWatchlist(CryptoMarketState state) {
    final market = state.snapshot;
    final assetsBySymbol = <String, CryptoAsset>{};
    if (market != null) {
      for (final asset in <CryptoAsset>[
        ...market.assets,
        ...market.topAssets,
        ...market.bubbleAssets,
      ]) {
        assetsBySymbol[asset.marketKey] = asset;
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: CryptoWatchlistScreen(
            repository: _cryptoRepository,
            initialAssets: assetsBySymbol.values.toList(growable: false),
          ),
        ),
      ),
    );
  }

  void _searchCoins(String value) {
    final query = value.trim();
    setState(() => _typedQuery = query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _cubit.search(value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _search.clear();
    setState(() => _typedQuery = '');
    _cubit.search('');
  }

  void _openAssetChart(CryptoAsset asset) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          TradingViewChartScreen(symbol: asset.symbol, segment: asset.segment),
    ),
  );

  List<CryptoAsset> _matchingSuggestions(List<CryptoAsset> assets) {
    final normalized = _typedQuery.toUpperCase();
    if (normalized.isEmpty) return const [];
    final futuresOnly = normalized.endsWith('.P');
    final term = futuresOnly
        ? normalized.substring(0, normalized.length - 2)
        : normalized;
    if (term.isEmpty) return const [];
    return assets
        .where((asset) {
          if (futuresOnly && asset.segment != 'FUTURES') return false;
          final searchable =
              '${asset.symbol} ${asset.baseCurrency} ${asset.name}'
                  .toUpperCase();
          return searchable.contains(term);
        })
        .take(5)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Crypto Market'),
        actions: [
          BlocBuilder<CryptoMarketCubit, CryptoMarketState>(
            buildWhen: (previous, current) =>
                previous.watchlistSymbols != current.watchlistSymbols,
            builder: (context, state) => IconButton(
              tooltip: 'Open watchlist',
              onPressed: () => _openWatchlist(state),
              icon: _WatchlistActionIcon(count: state.watchlistSymbols.length),
            ),
          ),
          BlocBuilder<CryptoMarketCubit, CryptoMarketState>(
            buildWhen: (previous, current) =>
                previous.refreshing != current.refreshing,
            builder: (context, state) => IconButton(
              tooltip: 'Refresh live market',
              onPressed: state.refreshing ? null : _reload,
              icon: state.refreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: BlocConsumer<CryptoMarketCubit, CryptoMarketState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.snapshot != null &&
            current.errorMessage != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
        builder: (context, state) {
          if (state.loading && state.snapshot == null) {
            return const Center(
              child: CircularProgressIndicator(color: TradeXColors.goldBright),
            );
          }
          final market = state.snapshot;
          if (market == null) {
            return _MarketError(onRetry: _reload);
          }
          final visible = market.assets;
          final suggestions = _matchingSuggestions(visible);
          return RefreshIndicator(
            color: TradeXColors.goldBright,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
              children: [
                _CryptoTradeIdeasSection(repository: _tradeIdeasRepository),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _LiveHeader(
                        market: market,
                        fromCache: state.fromCache,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CryptoSegmentSwitcher(
                      segment: state.segment,
                      onChanged: _cubit.selectSegment,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: _searchCoins,
                  decoration: InputDecoration(
                    hintText: 'Search BTC, ETH, SOL...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF7F8DA1),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF91A1B7),
                      size: 20,
                    ),
                    suffixIcon: _typedQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear coin search',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: const Color(0xFF102035),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: TradeXColors.goldBright.withValues(alpha: .7),
                      ),
                    ),
                  ),
                ),
                if (_typedQuery.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  _CryptoSearchSuggestions(
                    query: _typedQuery,
                    assets: suggestions,
                    loading:
                        state.refreshing ||
                        state.search.trim() != _typedQuery.trim(),
                    onTap: _openAssetChart,
                  ),
                ],
                const SizedBox(height: 12),
                const _AllCryptoHeader(),
                if (state.search.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    state.search.trim().toUpperCase().endsWith('.P')
                        ? 'Futures results (.P)'
                        : 'Matching Spot and Futures markets',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('No matching coins found.')),
                  )
                else
                  _CryptoCoinCarousel(
                    viewKey: '${state.segment}:${state.search}',
                    assets: visible,
                    watchlistSymbols: state.watchlistSymbols,
                    loadingMore: state.refreshing,
                    hasMore: market.pagination.hasMore,
                    onLoadMore: _cubit.nextPage,
                    onWatchlistToggle: _toggleWatchlist,
                  ),
                const SizedBox(height: 24),
                _SnapshotGrid(summary: market.summary),
                const SizedBox(height: 24),
                _BubbleSectionHeader(
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: _cubit,
                        child: CryptoBubbleMapScreen(
                          assets: market.bubbleAssets,
                          repository: _cryptoRepository,
                          segment: state.segment,
                          liveTickerService: _liveTickerSource,
                          enableDirectStream: widget.enableDirectBubbleStream,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _BubblePanel(
                  assets: market.bubbleAssets,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: _cubit,
                        child: CryptoBubbleMapScreen(
                          assets: market.bubbleAssets,
                          repository: _cryptoRepository,
                          segment: state.segment,
                          liveTickerService: _liveTickerSource,
                          enableDirectStream: widget.enableDirectBubbleStream,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
