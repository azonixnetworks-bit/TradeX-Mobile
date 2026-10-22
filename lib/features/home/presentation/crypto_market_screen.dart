import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/crypto_market_repository.dart';
import '../data/trade_ideas_repository.dart';
import 'bloc/crypto_market_cubit.dart';
import 'crypto_bubble_screen.dart';
import 'tradingview_chart_screen.dart';

class CryptoMarketScreen extends StatefulWidget {
  const CryptoMarketScreen({
    super.key,
    required this.apiClient,
    required this.tradeIdeasRepository,
    this.repository,
  });

  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;
  final CryptoMarketRepository? repository;

  @override
  State<CryptoMarketScreen> createState() => _CryptoMarketScreenState();
}

class _CryptoMarketScreenState extends State<CryptoMarketScreen>
    with WidgetsBindingObserver {
  late final CryptoMarketCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = CryptoMarketCubit(
      widget.repository ?? CryptoMarketRepository(widget.apiClient),
      widget.tradeIdeasRepository,
    )..load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_cubit.load(silent: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocBuilder<CryptoMarketCubit, CryptoMarketState>(
      builder: (context, state) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 4,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Crypto Market', style: TextStyle(fontSize: 18)),
              Text(
                'Live screener and recent TradeX ideas',
                style: TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => _cubit.load(silent: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: switch (state.status) {
            CryptoMarketStatus.initial ||
            CryptoMarketStatus.loading => const Center(
              child: CircularProgressIndicator(
                color: TradeXColors.goldBright,
                strokeWidth: 2.4,
              ),
            ),
            CryptoMarketStatus.failure when state.assets.isEmpty =>
              _CryptoFailure(onRetry: _cubit.load),
            _ => RefreshIndicator(
              color: TradeXColors.goldBright,
              backgroundColor: TradeXColors.surfaceRaised,
              onRefresh: () => _cubit.load(silent: true),
              child: ListView(
                key: const ValueKey('crypto-market-content'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _LiveSummaryCard(state: state),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const ValueKey('open-crypto-bubbles'),
                      onPressed: state.bubbles.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CryptoBubbleScreen(assets: state.bubbles),
                              ),
                            ),
                      icon: const Icon(Icons.bubble_chart_rounded),
                      label: const Text('Bubble Screener'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TradeXColors.goldBright,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: TradeXColors.gold.withValues(alpha: .55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _CryptoFilterBar(
                    selected: state.filter,
                    onSelected: _cubit.selectFilter,
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: state.filter == CryptoMarketFilter.watchlist
                        ? 'My Watchlist'
                        : 'Top Cryptos',
                    trailing: state.filter == CryptoMarketFilter.watchlist
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                key: const ValueKey('manage-crypto-watchlist'),
                                onPressed: () =>
                                    _manageWatchlist(context, state),
                                child: const Text('Manage'),
                              ),
                              if (state.watchlist.isNotEmpty)
                                IconButton(
                                  tooltip: 'Clear watchlist',
                                  onPressed: () =>
                                      _confirmClearWatchlist(context),
                                  icon: const Icon(
                                    Icons.delete_sweep_outlined,
                                    color: TradeXColors.error,
                                    size: 20,
                                  ),
                                ),
                            ],
                          )
                        : Text(
                            '${state.provider}${state.stale ? ' · Cached' : ' · Live'}',
                            style: const TextStyle(
                              color: TradeXColors.secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 9),
                  if (state.visibleAssets.isEmpty)
                    _WatchlistEmpty(
                      isWatchlist: state.filter == CryptoMarketFilter.watchlist,
                      onOverview: () =>
                          _cubit.selectFilter(CryptoMarketFilter.overview),
                    )
                  else
                    Container(
                      decoration: _panelDecoration(),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < state.visibleAssets.length;
                            index++
                          ) ...[
                            _CryptoAssetRow(
                              asset: state.visibleAssets[index],
                              watched: state.watchlist.contains(
                                state.visibleAssets[index].symbol,
                              ),
                              onWatchlist: () => _cubit.toggleWatchlist(
                                state.visibleAssets[index].symbol,
                              ),
                              onTap: () => _openChart(
                                context,
                                state.visibleAssets[index].symbol,
                              ),
                            ),
                            if (index != state.visibleAssets.length - 1)
                              const Divider(
                                height: 1,
                                indent: 64,
                                color: TradeXColors.border,
                              ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Recent Crypto Trade Ideas'),
                  const SizedBox(height: 9),
                  if (state.tradeIdeas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _panelDecoration(),
                      child: const Text(
                        'No published crypto trade ideas right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: TradeXColors.secondaryText),
                      ),
                    )
                  else
                    SizedBox(
                      height: 158,
                      child: ListView.separated(
                        key: const ValueKey('recent-crypto-trade-ideas'),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.tradeIdeas.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) =>
                            _CryptoIdeaCard(idea: state.tradeIdeas[index]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Market data and trade ideas are for information and education only. Prices may be delayed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TradeXColors.tertiaryText,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    ),
  );

  Future<void> _confirmClearWatchlist(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear watchlist?'),
        content: const Text(
          'All locally saved crypto symbols will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _cubit.clearWatchlist();
  }

  Future<void> _manageWatchlist(
    BuildContext context,
    CryptoMarketState state,
  ) async {
    var selected = {...state.watchlist};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TradeXColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Watchlist',
                              style: TextStyle(
                                color: TradeXColors.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Selections are stored only on this device.',
                              style: TextStyle(
                                color: TradeXColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: TradeXColors.border),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.assets.length,
                    itemBuilder: (context, index) {
                      final asset = state.assets[index];
                      return CheckboxListTile(
                        key: ValueKey('manage-crypto-watch-${asset.symbol}'),
                        value: selected.contains(asset.symbol),
                        activeColor: TradeXColors.goldBright,
                        checkColor: TradeXColors.background,
                        title: Text(
                          asset.baseCurrency,
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${asset.baseCurrency}/${asset.quoteCurrency}',
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                          ),
                        ),
                        secondary: _CoinAvatar(asset: asset),
                        onChanged: (_) async {
                          await _cubit.toggleWatchlist(asset.symbol);
                          setModalState(
                            () => selected = {..._cubit.state.watchlist},
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChart(BuildContext context, String symbol) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TradingViewChartScreen(symbol: symbol),
      ),
    );
  }
}

class _LiveSummaryCard extends StatelessWidget {
  const _LiveSummaryCard({required this.state});

  final CryptoMarketState state;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('crypto-live-summary'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: TradeXColors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .5)),
      boxShadow: [
        BoxShadow(
          color: TradeXColors.gold.withValues(alpha: .06),
          blurRadius: 18,
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.currency_bitcoin_rounded,
              color: TradeXColors.goldBright,
              size: 20,
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'Live Market Snapshot',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (state.stale ? TradeXColors.warning : TradeXColors.success)
                        .withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color:
                      (state.stale
                              ? TradeXColors.warning
                              : TradeXColors.success)
                          .withValues(alpha: .55),
                ),
              ),
              child: Text(
                state.stale ? 'CACHED' : 'LIVE',
                style: TextStyle(
                  color: state.stale
                      ? TradeXColors.warning
                      : TradeXColors.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryMetric(
                  width: width,
                  label: '24h Volume',
                  value: _compactMoney(state.summary.totalQuoteVolume),
                  icon: Icons.bar_chart_rounded,
                ),
                _SummaryMetric(
                  width: width,
                  label: 'Average Change',
                  value: _signedPercent(state.summary.averageChange),
                  icon: Icons.show_chart_rounded,
                  valueColor: _changeColor(state.summary.averageChange),
                ),
                _SummaryMetric(
                  width: width,
                  label: 'Gainers',
                  value: '${state.summary.gainers}',
                  icon: Icons.trending_up_rounded,
                  valueColor: TradeXColors.success,
                ),
                _SummaryMetric(
                  width: width,
                  label: 'Losers',
                  value: '${state.summary.losers}',
                  icon: Icons.trending_down_rounded,
                  valueColor: TradeXColors.error,
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = TradeXColors.primaryText,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: TradeXColors.background.withValues(alpha: .66),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: TradeXColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: TradeXColors.goldBright, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CryptoFilterBar extends StatelessWidget {
  const _CryptoFilterBar({required this.selected, required this.onSelected});

  final CryptoMarketFilter selected;
  final ValueChanged<CryptoMarketFilter> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      key: const ValueKey('crypto-market-filters'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: CryptoMarketFilter.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final filter = CryptoMarketFilter.values[index];
        final active = filter == selected;
        return ChoiceChip(
          key: ValueKey('crypto-filter-${filter.name}'),
          selected: active,
          showCheckmark: false,
          onSelected: (_) => onSelected(filter),
          label: Text(_filterLabel(filter)),
          selectedColor: TradeXColors.goldBright,
          backgroundColor: TradeXColors.surfaceRaised,
          side: BorderSide(
            color: active ? TradeXColors.goldBright : TradeXColors.border,
          ),
          labelStyle: TextStyle(
            color: active ? const Color(0xFF171308) : TradeXColors.primaryText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        );
      },
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: TradeXColors.goldBright,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 8),
      ?trailing,
    ],
  );
}

class _CryptoAssetRow extends StatelessWidget {
  const _CryptoAssetRow({
    required this.asset,
    required this.watched,
    required this.onWatchlist,
    required this.onTap,
  });

  final CryptoScreenerAsset asset;
  final bool watched;
  final VoidCallback onWatchlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _changeColor(asset.changePercent);
    return InkWell(
      key: ValueKey('crypto-asset-${asset.symbol}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        child: Row(
          children: [
            _CoinAvatar(asset: asset),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.baseCurrency.isEmpty
                        ? asset.symbol
                        : asset.baseCurrency,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${asset.baseCurrency}/${asset.quoteCurrency} · ${_titleCase(asset.trend)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
                  _price(asset.price),
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _signedPercent(asset.changePercent),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            IconButton(
              key: ValueKey('crypto-watch-${asset.symbol}'),
              tooltip: watched ? 'Remove from watchlist' : 'Add to watchlist',
              onPressed: onWatchlist,
              icon: Icon(
                watched ? Icons.star_rounded : Icons.star_border_rounded,
                color: watched
                    ? TradeXColors.goldBright
                    : TradeXColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinAvatar extends StatelessWidget {
  const _CoinAvatar({required this.asset});

  final CryptoScreenerAsset asset;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TradeXColors.gold.withValues(alpha: .15),
        border: Border.all(color: TradeXColors.gold.withValues(alpha: .5)),
      ),
      child: Text(
        asset.baseCurrency.isEmpty ? '₿' : asset.baseCurrency[0],
        style: const TextStyle(
          color: TradeXColors.goldBright,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (asset.logoUrl == null) return fallback;
    return ClipOval(
      child: Image.network(
        asset.logoUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _CryptoIdeaCard extends StatelessWidget {
  const _CryptoIdeaCard({required this.idea});

  final DashboardTradeIdea idea;

  @override
  Widget build(BuildContext context) {
    final buy = idea.direction.toUpperCase() == 'BUY';
    final color = buy ? TradeXColors.success : TradeXColors.error;
    final target = idea.targets.isEmpty ? '—' : idea.targets.first.price;
    return Container(
      key: ValueKey('crypto-idea-${idea.uuid}'),
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TradeXColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: .55)),
                ),
                child: Text(
                  idea.direction,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  idea.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                idea.timeframe,
                style: const TextStyle(
                  color: TradeXColors.goldBright,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _IdeaValue(label: 'Entry', value: idea.entry),
          _IdeaValue(label: 'Target', value: target),
          _IdeaValue(
            label: 'Stop Loss',
            value: idea.stopLoss,
            valueColor: TradeXColors.error,
          ),
        ],
      ),
    );
  }
}

class _IdeaValue extends StatelessWidget {
  const _IdeaValue({
    required this.label,
    required this.value,
    this.valueColor = TradeXColors.primaryText,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _WatchlistEmpty extends StatelessWidget {
  const _WatchlistEmpty({required this.isWatchlist, required this.onOverview});

  final bool isWatchlist;
  final VoidCallback onOverview;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: _panelDecoration(),
    child: Column(
      children: [
        Icon(
          isWatchlist ? Icons.star_border_rounded : Icons.query_stats_rounded,
          color: TradeXColors.goldBright,
          size: 32,
        ),
        const SizedBox(height: 10),
        Text(
          isWatchlist
              ? 'Your watchlist is empty. Tap the star beside any coin to save it locally.'
              : 'No coins match this filter right now.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            height: 1.35,
          ),
        ),
        if (isWatchlist) ...[
          const SizedBox(height: 10),
          TextButton(onPressed: onOverview, child: const Text('Browse coins')),
        ],
      ],
    ),
  );
}

class _CryptoFailure extends StatelessWidget {
  const _CryptoFailure({required this.onRetry});

  final Future<void> Function({bool silent}) onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: TradeXColors.goldBright,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Crypto market data is temporarily unavailable.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TradeXColors.secondaryText),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(silent: false),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

BoxDecoration _panelDecoration() => BoxDecoration(
  color: TradeXColors.surfaceRaised,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: TradeXColors.border),
);

String _filterLabel(CryptoMarketFilter filter) => switch (filter) {
  CryptoMarketFilter.overview => 'Overview',
  CryptoMarketFilter.gainers => 'Gainers',
  CryptoMarketFilter.losers => 'Losers',
  CryptoMarketFilter.watchlist => 'Watchlist',
};

String _compactMoney(double value) {
  if (value >= 1000000000000) {
    return '\$${(value / 1000000000000).toStringAsFixed(2)}T';
  }
  if (value >= 1000000000) {
    return '\$${(value / 1000000000).toStringAsFixed(2)}B';
  }
  if (value >= 1000000) {
    return '\$${(value / 1000000).toStringAsFixed(2)}M';
  }
  return '\$${value.toStringAsFixed(0)}';
}

String _price(double value) {
  final digits = value >= 1000
      ? 2
      : value >= 1
      ? 4
      : 6;
  return '\$${value.toStringAsFixed(digits)}';
}

String _signedPercent(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

Color _changeColor(double value) =>
    value >= 0 ? TradeXColors.success : TradeXColors.error;

String _titleCase(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'Sideways';
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
