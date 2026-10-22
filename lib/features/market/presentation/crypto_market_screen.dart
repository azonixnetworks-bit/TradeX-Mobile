import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/crypto_market_repository.dart';
import 'trading_view_chart_screen.dart';

class CryptoMarketScreen extends StatefulWidget {
  const CryptoMarketScreen({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  State<CryptoMarketScreen> createState() => _CryptoMarketScreenState();
}

class _CryptoMarketScreenState extends State<CryptoMarketScreen> {
  late final CryptoMarketRepository _repository;
  late Future<CryptoMarketSnapshot> _request;
  final _search = TextEditingController();
  String _segment = 'SPOT';
  String _query = '';
  int _page = 1;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _repository = CryptoMarketRepository(widget.apiClient);
    _reload();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(
    () => _request = _repository.load(
      segment: _segment,
      page: _page,
      search: _query,
    ),
  );

  void _selectSegment(String segment) {
    if (_segment == segment) return;
    _segment = segment;
    _page = 1;
    _reload();
  }

  void _searchCoins(String value) {
    _searchDebounce?.cancel();
    _query = value.trim();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _page = 1;
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: const Text('Crypto Market'),
      actions: [
        IconButton(
          tooltip: 'Refresh live market',
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: FutureBuilder<CryptoMarketSnapshot>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          );
        }
        if (snapshot.hasError) {
          return _MarketError(onRetry: _reload);
        }
        final market = snapshot.requireData;
        final visible = market.assets;
        return RefreshIndicator(
          color: TradeXColors.goldBright,
          onRefresh: () async {
            _reload();
            await _request;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              _LiveHeader(market: market),
              const SizedBox(height: 14),
              _SnapshotGrid(summary: market.summary),
              const SizedBox(height: 24),
              const _SectionHeading(
                title: 'Bubble Screener',
                subtitle: 'Size reflects 24h USDT volume',
              ),
              const SizedBox(height: 12),
              _BubblePanel(assets: market.bubbleAssets),
              const SizedBox(height: 24),
              _TopCryptoHeader(segment: _segment, onChanged: _selectSegment),
              const SizedBox(height: 12),
              for (final asset in market.topAssets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CoinRow(asset: asset, segment: _segment),
                ),
              const SizedBox(height: 18),
              const _SectionHeading(
                title: 'All Coins',
                subtitle: 'Search Binance USDT markets',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _search,
                onChanged: _searchCoins,
                decoration: InputDecoration(
                  hintText: 'Search coin or symbol',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            _query = '';
                            _page = 1;
                            _reload();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('No matching coins found.')),
                )
              else
                for (final asset in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _CoinRow(
                      asset: asset,
                      segment: _segment,
                      compact: true,
                    ),
                  ),
              if (visible.isNotEmpty) ...[
                const SizedBox(height: 8),
                _PaginationBar(
                  pagination: market.pagination,
                  onPrevious: market.pagination.currentPage > 1
                      ? () {
                          _page--;
                          _reload();
                        }
                      : null,
                  onNext: market.pagination.hasMore
                      ? () {
                          _page++;
                          _reload();
                        }
                      : null,
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({required this.market});
  final CryptoMarketSnapshot market;

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
            color: market.stale ? Colors.orange : const Color(0xFF35D49A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (market.stale ? Colors.orange : const Color(0xFF35D49A))
                    .withValues(alpha: .45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          market.stale ? 'Saved market snapshot' : stamp,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.72,
    children: [
      _MetricCard(label: '24h Volume', value: _compact(summary.totalVolume)),
      _MetricCard(
        label: 'Average Change',
        value:
            '${summary.averageChange >= 0 ? '+' : ''}${summary.averageChange.toStringAsFixed(2)}%',
        valueColor: _changeColor(summary.averageChange),
      ),
      _MetricCard(
        label: 'Gainers',
        value: summary.gainers.toString(),
        valueColor: const Color(0xFF35D49A),
      ),
      _MetricCard(
        label: 'Losers',
        value: summary.losers.toString(),
        valueColor: const Color(0xFFFF626B),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF111A27),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? TradeXColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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

class _BubblePanel extends StatelessWidget {
  const _BubblePanel({required this.assets});
  final List<CryptoAsset> assets;

  @override
  Widget build(BuildContext context) {
    final maxVolume = assets.fold<double>(
      1,
      (value, asset) => math.max(value, asset.quoteVolume),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1420),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TradeXColors.goldBright.withValues(alpha: .18),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: assets
            .map((asset) {
              final ratio = math.sqrt(asset.quoteVolume / maxVolume);
              final size = 54 + (ratio * 46);
              return _MarketBubble(asset: asset, size: size);
            })
            .toList(growable: false),
      ),
    );
  }
}

class _MarketBubble extends StatelessWidget {
  const _MarketBubble({required this.asset, required this.size});
  final CryptoAsset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _changeColor(asset.changePercent);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: .14),
        border: Border.all(color: color.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .12), blurRadius: 10),
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(5),
      child: FittedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              asset.baseCurrency,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCryptoHeader extends StatelessWidget {
  const _TopCryptoHeader({required this.segment, required this.onChanged});
  final String segment;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: _SectionHeading(
          title: 'Top Cryptos',
          subtitle: 'BNB, BTC, ETH, SOL and XRP',
        ),
      ),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'SPOT', label: Text('Spot')),
          ButtonSegment(value: 'FUTURES', label: Text('Futures')),
        ],
        selected: {segment},
        onSelectionChanged: (value) => onChanged(value.first),
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    ],
  );
}

class _CoinRow extends StatelessWidget {
  const _CoinRow({
    required this.asset,
    required this.segment,
    this.compact = false,
  });
  final CryptoAsset asset;
  final String segment;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 10 : 13),
    decoration: BoxDecoration(
      color: const Color(0xFF101925),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: Row(
      children: [
        _CoinLogo(
          asset: asset,
          size: compact ? 38 : 42,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TradingViewChartScreen(
                symbol: asset.symbol,
                segment: segment,
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.symbol,
                style: const TextStyle(
                  color: TradeXColors.goldBright,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (asset.name.isNotEmpty)
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (asset.price > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _price(asset.price),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: _changeColor(asset.changePercent),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
        else
          const Icon(
            Icons.candlestick_chart_rounded,
            color: TradeXColors.secondaryText,
          ),
      ],
    ),
  );
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  final CryptoPagination pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      OutlinedButton.icon(
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left_rounded),
        label: const Text('Previous'),
      ),
      Expanded(
        child: Column(
          children: [
            Text(
              'Page ${pagination.currentPage} of ${pagination.lastPage}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${pagination.total} coins',
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: onNext,
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.chevron_right_rounded),
        label: const Text('Next'),
      ),
    ],
  );
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
