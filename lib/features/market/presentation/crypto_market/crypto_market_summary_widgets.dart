part of '../crypto_market_screen.dart';

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
          accent: TradeXColors.gold,
          gradient: const [TradeXColors.surfaceRaised, TradeXColors.surface],
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
              ? const [TradeXColors.surfaceRaised, TradeXColors.surface]
              : const [TradeXColors.surfaceRaised, TradeXColors.surface],
          trendUp: averageIsPositive,
        ),
        _MarketMetricCard(
          label: 'Gainers',
          value: summary.gainers.toString(),
          supportingText: '${gainersShare.toStringAsFixed(1)}% of movers',
          iconAsset: 'assets/crypto_market/cards/gainers.svg',
          chartAsset: 'assets/crypto_market/cards/gainers_bars.svg',
          accent: const Color(0xFF00E6A5),
          gradient: const [TradeXColors.surfaceRaised, TradeXColors.surface],
        ),
        _MarketMetricCard(
          label: 'Losers',
          value: summary.losers.toString(),
          supportingText: '${losersShare.toStringAsFixed(1)}% of movers',
          iconAsset: 'assets/crypto_market/cards/losers.svg',
          chartAsset: 'assets/crypto_market/cards/losers_bars.svg',
          accent: const Color(0xFFFF4869),
          gradient: const [TradeXColors.surfaceRaised, TradeXColors.surface],
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
