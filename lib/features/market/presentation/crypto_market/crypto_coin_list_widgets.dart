part of '../crypto_market_screen.dart';

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
      border: Border.all(color: TradeXColors.border),
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
              colors: [TradeXColors.surfaceRaised, TradeXColors.surface],
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
