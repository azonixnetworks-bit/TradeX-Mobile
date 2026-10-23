import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../home/data/trade_ideas_repository.dart';
import '../data/crypto_market_repository.dart';
import '../data/crypto_watchlist_store.dart';
import 'crypto_bubble_field.dart';
import 'crypto_bubble_map_screen.dart';
import 'crypto_market_cubit.dart';
import 'crypto_watchlist_screen.dart';
import 'trading_view_chart_screen.dart';

class CryptoMarketScreen extends StatefulWidget {
  const CryptoMarketScreen({
    super.key,
    required this.apiClient,
    this.enableDirectBubbleStream = true,
  });

  final TradeXApiClient apiClient;
  final bool enableDirectBubbleStream;

  @override
  State<CryptoMarketScreen> createState() => _CryptoMarketScreenState();
}

class _CryptoMarketScreenState extends State<CryptoMarketScreen>
    with WidgetsBindingObserver {
  late final CryptoMarketCubit _cubit;
  late final CryptoMarketRepository _cryptoRepository;
  late final TradeIdeasRepository _tradeIdeasRepository;
  final _search = TextEditingController();
  Timer? _searchDebounce;
  Timer? _liveRefreshTimer;
  var _appIsActive = true;
  var _typedQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cryptoRepository = CryptoMarketRepository(widget.apiClient);
    _cubit = CryptoMarketCubit(
      _cryptoRepository,
      watchlistStore: CryptoWatchlistStore(
        accountKey: widget.apiClient.currentAccountStorageKey(),
      ),
    );
    _tradeIdeasRepository = TradeIdeasRepository(widget.apiClient);
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
            apiClient: widget.apiClient,
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

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({required this.market, required this.fromCache});
  final CryptoMarketSnapshot market;
  final bool fromCache;

  @override
  Widget build(BuildContext context) {
    final time = market.generatedAt?.toLocal();
    final stamp = time == null
        ? 'Live Binance data'
        : 'Updated ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: market.stale || fromCache || market.partialData
                ? Colors.orange
                : const Color(0xFF35D49A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    (market.stale || fromCache || market.partialData
                            ? Colors.orange
                            : const Color(0xFF35D49A))
                        .withValues(alpha: .45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            market.partialData
                ? 'Limited market data · server update required'
                : market.stale || fromCache
                ? 'Saved market snapshot'
                : stamp,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.summary});
  final CryptoMarketSummary summary;

  @override
  Widget build(BuildContext context) {
    final movers = math.max(1, summary.gainers + summary.losers);
    final gainersShare = summary.gainers / movers * 100;
    final losersShare = summary.losers / movers * 100;
    final averageIsPositive = summary.averageChange >= 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.52,
      children: [
        _MarketMetricCard(
          label: '24h Volume',
          value: _compact(summary.totalVolume),
          supportingText: 'Live Binance volume',
          iconAsset: 'assets/crypto_market/cards/volume_coins.svg',
          chartAsset: 'assets/crypto_market/cards/volume_sparkline.svg',
          accent: const Color(0xFF28A8FF),
          gradient: const [Color(0xFF073B72), Color(0xFF0A1E34)],
        ),
        _MarketMetricCard(
          label: 'Average Change',
          value:
              '${averageIsPositive ? '+' : ''}${summary.averageChange.toStringAsFixed(2)}%',
          supportingText: averageIsPositive
              ? 'Positive movement'
              : 'Negative movement',
          iconAsset: 'assets/crypto_market/cards/average_change.svg',
          chartAsset: 'assets/crypto_market/cards/change_sparkline.svg',
          accent: averageIsPositive
              ? const Color(0xFF00E6A5)
              : const Color(0xFFFF4869),
          gradient: averageIsPositive
              ? const [Color(0xFF064F4B), Color(0xFF082421)]
              : const [Color(0xFF561629), Color(0xFF260E1A)],
          trendUp: averageIsPositive,
        ),
        _MarketMetricCard(
          label: 'Gainers',
          value: summary.gainers.toString(),
          supportingText: '${gainersShare.toStringAsFixed(1)}% of movers',
          iconAsset: 'assets/crypto_market/cards/gainers.svg',
          chartAsset: 'assets/crypto_market/cards/gainers_bars.svg',
          accent: const Color(0xFF00E6A5),
          gradient: const [Color(0xFF064F4B), Color(0xFF082421)],
        ),
        _MarketMetricCard(
          label: 'Losers',
          value: summary.losers.toString(),
          supportingText: '${losersShare.toStringAsFixed(1)}% of movers',
          iconAsset: 'assets/crypto_market/cards/losers.svg',
          chartAsset: 'assets/crypto_market/cards/losers_bars.svg',
          accent: const Color(0xFFFF4869),
          gradient: const [Color(0xFF561629), Color(0xFF260E1A)],
          trendUp: false,
        ),
      ],
    );
  }
}

class _MarketMetricCard extends StatelessWidget {
  const _MarketMetricCard({
    required this.label,
    required this.value,
    required this.supportingText,
    required this.iconAsset,
    required this.chartAsset,
    required this.accent,
    required this.gradient,
    this.trendUp = true,
  });

  final String label;
  final String value;
  final String supportingText;
  final String iconAsset;
  final String chartAsset;
  final Color accent;
  final List<Color> gradient;
  final bool trendUp;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label, $value, $supportingText',
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: .75), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .13),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 7,
            bottom: 10,
            child: IgnorePointer(
              child: Opacity(
                opacity: .88,
                child: SvgPicture.asset(
                  chartAsset,
                  width: 72,
                  height: 43,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      iconAsset,
                      width: 30,
                      height: 30,
                      semanticsLabel: '$label icon',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFDCE8F5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accent.withValues(alpha: .9),
                      size: 18,
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: label == '24h Volume' ? Colors.white : accent,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      trendUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: accent,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        supportingText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: const TextStyle(color: TradeXColors.secondaryText, fontSize: 12),
      ),
    ],
  );
}

class _BubbleSectionHeader extends StatelessWidget {
  const _BubbleSectionHeader({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: _SectionHeading(
          title: 'Top Gainers Bubble Screener',
          subtitle: 'Top 50 live 24h gainers · refreshes every 15 seconds',
        ),
      ),
      TextButton.icon(
        onPressed: onOpen,
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.open_in_full_rounded, size: 17),
        label: const Text('Open map'),
      ),
    ],
  );
}

class _BubblePanel extends StatelessWidget {
  const _BubblePanel({required this.assets, required this.onTap});
  final List<CryptoAsset> assets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open live crypto bubble map',
    child: Container(
      height: 270,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0C1420),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TradeXColors.goldBright.withValues(alpha: .18),
        ),
      ),
      child: CryptoBubbleField(
        assets: assets,
        minRadius: 17,
        maxRadius: 39,
        padding: 8,
        speed: 7,
        onBubbleTap: (_) => onTap(),
      ),
    ),
  );
}

class _CryptoTradeIdeasSection extends StatefulWidget {
  const _CryptoTradeIdeasSection({required this.repository});

  final TradeIdeasRepository repository;

  @override
  State<_CryptoTradeIdeasSection> createState() =>
      _CryptoTradeIdeasSectionState();
}

class _CryptoTradeIdeasSectionState extends State<_CryptoTradeIdeasSection> {
  late Future<List<DashboardTradeIdea>> _request;
  final PageController _pageController = PageController();
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _request = widget.repository.latestCrypto(limit: 5);
  }

  void _retry() {
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    setState(() {
      _currentPage = 0;
      _request = widget.repository.latestCrypto(limit: 5);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: _SectionHeading(
              title: 'Crypto Trade Ideas',
              subtitle: 'Recent signal · swipe for the previous 4',
            ),
          ),
          IconButton(
            tooltip: 'Refresh crypto trade ideas',
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<DashboardTradeIdea>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 184,
              child: Center(
                child: CircularProgressIndicator(
                  color: TradeXColors.goldBright,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return _CryptoTradeIdeasMessage(
              icon: Icons.cloud_off_rounded,
              message: 'Crypto trade ideas are temporarily unavailable.',
              onRetry: _retry,
            );
          }

          final ideas = (snapshot.data ?? const <DashboardTradeIdea>[])
              .where(
                (idea) => idea.category.isEmpty || idea.category == 'CRYPTO',
              )
              .take(5)
              .toList(growable: false);
          if (ideas.isEmpty) {
            return _CryptoTradeIdeasMessage(
              icon: Icons.lightbulb_outline_rounded,
              message: 'No crypto trade ideas are published right now.',
              onRetry: _retry,
            );
          }

          return Column(
            children: [
              SizedBox(
                height: 184,
                child: PageView.builder(
                  key: const ValueKey('crypto-trade-ideas-carousel'),
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: ideas.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) => _CryptoTradeIdeaCard(
                    idea: ideas[index],
                    position: index,
                    total: ideas.length,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < ideas.length; index++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _currentPage ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? TradeXColors.goldBright
                            : Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    if (index < ideas.length - 1) const SizedBox(width: 5),
                  ],
                  const SizedBox(width: 10),
                  Text(
                    '${_currentPage + 1} / ${ideas.length}',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _CryptoTradeIdeasMessage extends StatelessWidget {
  const _CryptoTradeIdeasMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF101925),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: TradeXColors.secondaryText, size: 28),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: TradeXColors.secondaryText),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _CryptoTradeIdeaCard extends StatelessWidget {
  const _CryptoTradeIdeaCard({
    required this.idea,
    required this.position,
    required this.total,
  });

  final DashboardTradeIdea idea;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final direction = idea.direction.toUpperCase();
    final directionColor = direction == 'BUY'
        ? const Color(0xFF35D49A)
        : direction == 'SELL'
        ? const Color(0xFFFF626B)
        : TradeXColors.goldBright;
    final target = idea.targets.isEmpty ? '—' : idea.targets.first.price;
    final symbol = _tradeIdeaSymbol(idea.symbol);
    final segment = idea.symbol.trim().toUpperCase().endsWith('.P')
        ? 'FUTURES'
        : 'SPOT';
    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('crypto-trade-idea-${idea.uuid}'),
          onTap: symbol.isEmpty
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TradingViewChartScreen(
                      symbol: symbol,
                      segment: segment,
                    ),
                  ),
                ),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF132132), Color(0xFF0C151F)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: directionColor.withValues(alpha: .35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: directionColor.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: directionColor.withValues(alpha: .45),
                        ),
                      ),
                      child: Text(
                        direction,
                        style: TextStyle(
                          color: directionColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        position == 0
                            ? 'RECENT SIGNAL'
                            : 'PREVIOUS ${position + 1} / $total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: position == 0
                              ? TradeXColors.goldBright
                              : TradeXColors.secondaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      idea.timeframe,
                      style: const TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  idea.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (idea.instrumentName.isNotEmpty)
                  Text(
                    idea.instrumentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _TradeIdeaValue(label: 'ENTRY', value: idea.entry),
                    ),
                    Expanded(
                      child: _TradeIdeaValue(
                        label: 'STOP LOSS',
                        value: idea.stopLoss,
                      ),
                    ),
                    Expanded(
                      child: _TradeIdeaValue(
                        label: idea.targets.isEmpty
                            ? 'TARGET'
                            : idea.targets.first.label,
                        value: target,
                        color: const Color(0xFF35D49A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.candlestick_chart_rounded,
                      color: TradeXColors.goldBright,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Open TradingView chart',
                      style: TextStyle(
                        color: TradeXColors.goldBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: .5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TradeIdeaValue extends StatelessWidget {
  const _TradeIdeaValue({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: TradeXColors.secondaryText,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

String _tradeIdeaSymbol(String raw) {
  var symbol = raw.trim().toUpperCase();
  if (symbol.contains(':')) symbol = symbol.split(':').last;
  if (symbol.endsWith('.P')) symbol = symbol.substring(0, symbol.length - 2);
  return symbol.replaceAll('/', '');
}

class _CryptoSegmentSwitcher extends StatelessWidget {
  const _CryptoSegmentSwitcher({
    required this.segment,
    required this.onChanged,
  });

  final String segment;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF102035),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SegmentChoice(
          label: 'Spot',
          selected: segment == 'SPOT',
          onTap: () => onChanged('SPOT'),
        ),
        _SegmentChoice(
          label: 'Futures',
          selected: segment == 'FUTURES',
          onTap: () => onChanged('FUTURES'),
        ),
      ],
    ),
  );
}

class _SegmentChoice extends StatelessWidget {
  const _SegmentChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? TradeXColors.goldBright.withValues(alpha: .13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? TradeXColors.goldBright
              : TradeXColors.secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _AllCryptoHeader extends StatelessWidget {
  const _AllCryptoHeader();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: Text(
          'All Crypto Coins',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      Text(
        '24h Volume  ⌄',
        style: TextStyle(color: TradeXColors.secondaryText, fontSize: 10),
      ),
    ],
  );
}

class _CryptoSearchSuggestions extends StatelessWidget {
  const _CryptoSearchSuggestions({
    required this.query,
    required this.assets,
    required this.loading,
    required this.onTap,
  });

  final String query;
  final List<CryptoAsset> assets;
  final bool loading;
  final ValueChanged<CryptoAsset> onTap;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('crypto-search-suggestions'),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF0D1928),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFF273A52)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: assets.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                if (loading) ...[
                  const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(
                      color: TradeXColors.goldBright,
                      strokeWidth: 1.8,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  const Icon(
                    Icons.search_off_rounded,
                    color: TradeXColors.secondaryText,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                ],
                Expanded(
                  child: Text(
                    loading
                        ? 'Searching live coin list...'
                        : 'No coins found for "$query"',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < assets.length; index++) ...[
                _CryptoSearchSuggestionRow(
                  asset: assets[index],
                  onTap: () => onTap(assets[index]),
                ),
                if (index < assets.length - 1)
                  const Divider(
                    height: 1,
                    indent: 55,
                    color: Color(0xFF213149),
                  ),
              ],
            ],
          ),
  );
}

class _CryptoSearchSuggestionRow extends StatelessWidget {
  const _CryptoSearchSuggestionRow({required this.asset, required this.onTap});

  final CryptoAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = _changeColor(asset.changePercent);
    return Semantics(
      button: true,
      label:
          'Open ${asset.symbol} ${_segmentLabel(asset.segment)} chart from search',
      child: InkWell(
        key: ValueKey('crypto-search-suggestion-${asset.marketKey}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            children: [
              _CoinLogo(asset: asset, size: 34, onTap: onTap),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            asset.symbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _MarketSegmentBadge(segment: asset.segment),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.name.isNotEmpty
                          ? asset.name
                          : '${asset.baseCurrency} / USDT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF91A1B7),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    asset.price > 0 ? _price(asset.price) : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: TradeXColors.secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CryptoCoinCarousel extends StatelessWidget {
  const _CryptoCoinCarousel({
    required this.viewKey,
    required this.assets,
    required this.watchlistSymbols,
    required this.loadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onWatchlistToggle,
  });

  final String viewKey;
  final List<CryptoAsset> assets;
  final Set<String> watchlistSymbols;
  final bool loadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<CryptoAsset> onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    const batchSize = 5;
    const cardHeight = 74.0;
    const cardSpacing = 10.0;
    final visibleCount = math.min(batchSize, assets.length);
    final batchCount = (assets.length / batchSize).ceil();
    final trailingPage = hasMore || loadingMore;
    return SizedBox(
      height:
          (visibleCount * cardHeight) +
          (math.max(0, visibleCount - 1) * cardSpacing),
      child: PageView.builder(
        key: PageStorageKey('crypto-coin-carousel:$viewKey'),
        physics: const BouncingScrollPhysics(),
        itemCount: batchCount + (trailingPage ? 1 : 0),
        onPageChanged: (page) {
          if (page >= batchCount && hasMore && !loadingMore) {
            onLoadMore();
          }
        },
        itemBuilder: (context, batchIndex) {
          if (batchIndex >= batchCount) {
            return Center(
              child: loadingMore
                  ? const CircularProgressIndicator(
                      color: TradeXColors.goldBright,
                      strokeWidth: 2,
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe_left_rounded,
                          color: TradeXColors.goldBright,
                          size: 30,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Swipe to load next 5 coins',
                          style: TextStyle(
                            color: TradeXColors.secondaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            );
          }

          final start = batchIndex * batchSize;
          final end = math.min(start + batchSize, assets.length);
          return Column(
            key: ValueKey('crypto-coin-batch-$batchIndex'),
            children: [
              for (var index = start; index < end; index++) ...[
                SizedBox(
                  height: cardHeight,
                  width: double.infinity,
                  child: _CoinRow(
                    asset: assets[index],
                    segment: assets[index].segment,
                    isWatchlisted:
                        watchlistSymbols.contains(assets[index].marketKey) ||
                        (assets[index].segment == 'SPOT' &&
                            watchlistSymbols.contains(assets[index].symbol)),
                    onWatchlistToggle: () => onWatchlistToggle(assets[index]),
                  ),
                ),
                if (index < end - 1) const SizedBox(height: cardSpacing),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({
    required this.asset,
    required this.segment,
    required this.isWatchlisted,
    required this.onWatchlistToggle,
  });
  final CryptoAsset asset;
  final String segment;
  final bool isWatchlisted;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) => _topCryptoCard(context);

  Widget _topCryptoCard(BuildContext context) {
    final changeColor = _changeColor(asset.changePercent);
    return Semantics(
      button: true,
      label: 'Open ${asset.symbol} ${_segmentLabel(segment)} chart',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openChart(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102034), Color(0xFF0D1A2A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF273A52)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _CoinLogo(
                asset: asset,
                size: 42,
                onTap: () => _openChart(context),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            asset.symbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _MarketSegmentBadge(segment: segment),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      asset.name.isNotEmpty
                          ? asset.name
                          : '${asset.baseCurrency} / USDT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF91A1B7),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 48,
                height: 28,
                child: CustomPaint(
                  painter: _CoinTrendPainter(
                    positive: asset.changePercent >= 0,
                    seed: asset.symbol.hashCode,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      asset.price > 0 ? _price(asset.price) : '—',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              _WatchlistStarButton(
                symbol: asset.symbol,
                selected: isWatchlisted,
                onPressed: onWatchlistToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChart(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          TradingViewChartScreen(symbol: asset.symbol, segment: segment),
    ),
  );
}

class _WatchlistStarButton extends StatelessWidget {
  const _WatchlistStarButton({
    required this.symbol,
    required this.selected,
    required this.onPressed,
  });

  final String symbol;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: selected
        ? 'Remove $symbol from watchlist'
        : 'Add $symbol to watchlist',
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    icon: Icon(
      selected ? Icons.star_rounded : Icons.star_border_rounded,
      color: selected ? TradeXColors.goldBright : TradeXColors.secondaryText,
      size: 23,
    ),
  );
}

class _WatchlistActionIcon extends StatelessWidget {
  const _WatchlistActionIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      const Icon(Icons.star_rounded, color: TradeXColors.goldBright),
      if (count > 0)
        Positioned(
          right: -7,
          top: -7,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE63F65),
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
    ],
  );
}

class _MarketSegmentBadge extends StatelessWidget {
  const _MarketSegmentBadge({required this.segment});

  final String segment;

  @override
  Widget build(BuildContext context) {
    final futures = segment == 'FUTURES';
    final color = futures ? const Color(0xFFB98CFF) : const Color(0xFF42D7A4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Text(
        futures ? 'FUTURES' : 'SPOT',
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
    );
  }
}

String _segmentLabel(String segment) =>
    segment == 'FUTURES' ? 'Futures' : 'Spot';

class _CoinTrendPainter extends CustomPainter {
  const _CoinTrendPainter({required this.positive, required this.seed});

  final bool positive;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final color = positive ? const Color(0xFF20D8A0) : const Color(0xFFFF626B);
    final path = Path();
    const points = 7;
    for (var index = 0; index < points; index++) {
      final progress = index / (points - 1);
      final direction = positive ? 1 - progress : progress;
      final jitter = (random.nextDouble() - .5) * size.height * .24;
      final point = Offset(
        progress * size.width,
        (size.height * (.2 + direction * .58) + jitter).clamp(
          2,
          size.height - 2,
        ),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinTrendPainter oldDelegate) =>
      oldDelegate.positive != positive || oldDelegate.seed != seed;
}

class _CoinLogo extends StatelessWidget {
  const _CoinLogo({
    required this.asset,
    required this.size,
    required this.onTap,
  });
  final CryptoAsset asset;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TradeXColors.goldBright.withValues(alpha: .15),
        shape: BoxShape.circle,
        border: Border.all(
          color: TradeXColors.goldBright.withValues(alpha: .55),
        ),
      ),
      child: Text(
        asset.fallbackLabel,
        style: const TextStyle(
          color: TradeXColors.goldBright,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final url = asset.logoUrl;
    final logo = url == null || url.isEmpty
        ? fallback
        : ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          );
    return Semantics(
      button: true,
      label: 'Open ${asset.symbol} TradingView chart',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: logo,
      ),
    );
  }
}

class _MarketError extends StatelessWidget {
  const _MarketError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: TradeXColors.secondaryText,
          ),
          const SizedBox(height: 12),
          const Text('Live crypto market is temporarily unavailable.'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

Color _changeColor(double value) =>
    value >= 0 ? const Color(0xFF35D49A) : const Color(0xFFFF626B);

String _compact(double value) {
  if (value >= 1000000000000) {
    return '\$${(value / 1000000000000).toStringAsFixed(2)}T';
  }
  if (value >= 1000000000) {
    return '\$${(value / 1000000000).toStringAsFixed(2)}B';
  }
  if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(2)}M';
  return '\$${value.toStringAsFixed(0)}';
}

String _price(double value) {
  if (value >= 1000) return '\$${value.toStringAsFixed(2)}';
  if (value >= 1) return '\$${value.toStringAsFixed(4)}';
  return '\$${value.toStringAsFixed(8)}';
}
