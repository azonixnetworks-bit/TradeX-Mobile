import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/crypto_market_repository.dart';
import 'crypto_market_cubit.dart';
import 'trading_view_chart_screen.dart';

class CryptoWatchlistScreen extends StatefulWidget {
  const CryptoWatchlistScreen({
    super.key,
    required this.apiClient,
    required this.initialAssets,
  });

  final TradeXApiClient apiClient;
  final List<CryptoAsset> initialAssets;

  @override
  State<CryptoWatchlistScreen> createState() => _CryptoWatchlistScreenState();
}

class _CryptoWatchlistScreenState extends State<CryptoWatchlistScreen> {
  late final CryptoMarketRepository _repository;
  late final Map<String, CryptoAsset> _assetsByMarket;
  var _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = CryptoMarketRepository(widget.apiClient);
    _assetsByMarket = {
      for (final asset in widget.initialAssets) asset.marketKey: asset,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final marketKeys = context.read<CryptoMarketCubit>().state.watchlistSymbols;
    if (marketKeys.isEmpty) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final groups = <String, List<String>>{'SPOT': [], 'FUTURES': []};
      for (final key in marketKeys) {
        groups[cryptoSegmentFromMarketKey(key)]!.add(
          cryptoSymbolFromMarketKey(key),
        );
      }
      final batches = await Future.wait([
        for (final entry in groups.entries)
          if (entry.value.isNotEmpty)
            _repository
                .loadWatchlist(symbols: entry.value, segment: entry.key)
                .then(
                  (assets) => assets
                      .map((asset) => asset.withSegment(entry.key))
                      .toList(growable: false),
                ),
      ]);
      final liveAssets = batches.expand((assets) => assets);
      if (!mounted) return;
      setState(() {
        for (final live in liveAssets) {
          _assetsByMarket[live.marketKey] = live.mergeMarket(
            _assetsByMarket[live.marketKey],
          );
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _assetsByMarket.isEmpty
            ? 'Could not load live watchlist data.'
            : 'Live refresh failed. Showing the latest available data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Watchlist'),
      actions: [
        IconButton(
          tooltip: 'Refresh watchlist',
          onPressed: _loading ? null : _refresh,
          icon: _loading
              ? const SizedBox.square(
                  dimension: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: BlocBuilder<CryptoMarketCubit, CryptoMarketState>(
      buildWhen: (previous, current) =>
          previous.watchlistSymbols != current.watchlistSymbols,
      builder: (context, state) {
        final symbols = state.watchlistSymbols.toList(growable: false);
        if (symbols.isEmpty) return const _EmptyWatchlist();
        return RefreshIndicator(
          color: TradeXColors.goldBright,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _WatchlistSummary(count: symbols.length),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              for (final marketKey in symbols)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WatchlistCoinCard(
                    asset:
                        _assetsByMarket[marketKey] ?? _placeholder(marketKey),
                    segment: cryptoSegmentFromMarketKey(marketKey),
                    onRemove: () =>
                        context.read<CryptoMarketCubit>().toggleWatchlist(
                          cryptoSymbolFromMarketKey(marketKey),
                          segment: cryptoSegmentFromMarketKey(marketKey),
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _WatchlistSummary extends StatelessWidget {
  const _WatchlistSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: TradeXColors.goldBright.withValues(alpha: .13),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.star_rounded,
          color: TradeXColors.goldBright,
          size: 22,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count saved ${count == 1 ? 'coin' : 'coins'}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'Live Spot and Futures prices and market movement',
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _WatchlistCoinCard extends StatelessWidget {
  const _WatchlistCoinCard({
    required this.asset,
    required this.segment,
    required this.onRemove,
  });

  final CryptoAsset asset;
  final String segment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final trend = asset.resolvedTrend;
    final changeColor = _changeColor(asset.changePercent);
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              TradingViewChartScreen(symbol: asset.symbol, segment: segment),
        ),
      ),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111D2C), Color(0xFF0D1622)],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: .07)),
        ),
        child: Row(
          children: [
            _WatchlistCoinLogo(asset: asset),
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
                  const SizedBox(height: 2),
                  Text(
                    asset.name.isEmpty ? asset.baseCurrency : asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _WatchlistTrendBadge(trend: trend),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  asset.price > 0 ? _price(asset.price) : 'Live price',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Remove ${asset.symbol} from watchlist',
              onPressed: onRemove,
              icon: const Icon(
                Icons.star_rounded,
                color: TradeXColors.goldBright,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistCoinLogo extends StatelessWidget {
  const _WatchlistCoinLogo({required this.asset});

  final CryptoAsset asset;

  @override
  Widget build(BuildContext context) {
    final logo = asset.logoUrl;
    return Container(
      width: 45,
      height: 45,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2737),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: logo == null || logo.isEmpty
          ? Text(
              asset.fallbackLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            )
          : Image.network(
              logo,
              width: 45,
              height: 45,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Text(
                asset.fallbackLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

class _WatchlistTrendBadge extends StatelessWidget {
  const _WatchlistTrendBadge({required this.trend});

  final String trend;

  @override
  Widget build(BuildContext context) {
    final color = switch (trend) {
      'BULLISH' => const Color(0xFF35D39A),
      'BEARISH' => const Color(0xFFFF5575),
      _ => const Color(0xFF9BA8B8),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        trend,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: TradeXColors.goldBright.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_border_rounded,
              color: TradeXColors.goldBright,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your watchlist is empty',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text(
            'Tap the star beside any coin to save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TradeXColors.secondaryText),
          ),
        ],
      ),
    ),
  );
}

CryptoAsset _placeholder(String marketKey) {
  final symbol = cryptoSymbolFromMarketKey(marketKey);
  final segment = cryptoSegmentFromMarketKey(marketKey);
  final base = symbol.endsWith('USDT') && symbol.length > 4
      ? symbol.substring(0, symbol.length - 4)
      : symbol;
  return CryptoAsset(
    symbol: symbol,
    name: base,
    baseCurrency: base,
    logoUrl: null,
    price: 0,
    changePercent: 0,
    quoteVolume: 0,
    segment: segment,
  );
}

Color _changeColor(double value) =>
    value >= 0 ? const Color(0xFF35D39A) : const Color(0xFFFF5575);

String _price(double price) {
  if (price >= 1000) return '\$${price.toStringAsFixed(2)}';
  if (price >= 1) return '\$${price.toStringAsFixed(4)}';
  return '\$${price.toStringAsFixed(6)}';
}
