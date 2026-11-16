part of '../crypto_market_screen.dart';

const _screenerMarkets = <(String, String)>[
  ('CRYPTO', 'Crypto'),
  ('FOREX', 'Forex'),
  ('STOCKS', 'Stocks'),
  ('DERIV', 'Deriv'),
  ('COMMODITY', 'Commodity'),
  ('INDICES', 'Indices'),
];

String _marketLabel(String market) {
  for (final item in _screenerMarkets) {
    if (item.$1 == market) return item.$2;
  }
  return market;
}

class _MarketTypeSelector extends StatelessWidget {
  const _MarketTypeSelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    color: context.palette.background,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: Wrap(
      key: const ValueKey('market-screener-categories'),
      spacing: 8,
      runSpacing: 7,
      children: [
        for (final item in _screenerMarkets)
          ChoiceChip(
            key: ValueKey('market-screener-${item.$1.toLowerCase()}'),
            label: Text(item.$2),
            selected: selected == item.$1,
            showCheckmark: false,
            selectedColor: context.palette.gold,
            backgroundColor: context.palette.surfaceRaised,
            side: BorderSide(
              color: selected == item.$1
                  ? context.palette.gold
                  : context.palette.borderStrong,
            ),
            labelStyle: TextStyle(
              color: selected == item.$1
                  ? Colors.black
                  : context.palette.primaryText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            onSelected: (_) => onSelected(item.$1),
          ),
      ],
    ),
  );
}

class _StockRegionSelector extends StatelessWidget {
  const _StockRegionSelector({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const regions = <(String, String)>[
      ('SRI_LANKA', 'Sri Lanka (CSE)'),
      ('INDIA', 'India'),
      ('INTERNATIONAL', 'International'),
    ];
    return Container(
      color: context.palette.background,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: [
          for (var index = 0; index < regions.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton(
                  key: ValueKey(
                    'market-screener-stock-${regions[index].$1.toLowerCase()}',
                  ),
                  onPressed: () => onSelected(regions[index].$1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selected == regions[index].$1
                        ? Colors.black
                        : context.palette.primaryText,
                    backgroundColor: selected == regions[index].$1
                        ? context.palette.gold
                        : context.palette.surfaceRaised,
                    side: BorderSide(
                      color: selected == regions[index].$1
                          ? context.palette.gold
                          : context.palette.borderStrong,
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    regions[index].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MultiMarketScreenerBody extends StatelessWidget {
  const _MultiMarketScreenerBody({
    required this.market,
    required this.snapshot,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final String market;
  final MarketScreenerSnapshot? snapshot;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading && snapshot == null) {
      return const Center(
        child: CircularProgressIndicator(color: TradeXColors.goldBright),
      );
    }
    if (snapshot == null) {
      return _MarketErrorState(
        message: error ?? '${_marketLabel(market)} data is unavailable.',
        onRetry: onRefresh,
      );
    }
    final quotes = snapshot!.quotes;
    return RefreshIndicator(
      color: TradeXColors.goldBright,
      onRefresh: onRefresh,
      child: ListView(
        key: ValueKey('market-screener-list-${market.toLowerCase()}'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ScreenerMarketHeader(snapshot: snapshot!),
          const SizedBox(height: 12),
          if (quotes.isEmpty)
            const SizedBox(
              height: 260,
              child: Center(
                child: Text('No live instruments are available right now.'),
              ),
            )
          else
            for (var index = 0; index < quotes.length; index++) ...[
              _ScreenerQuoteCard(quote: quotes[index]),
              if (index != quotes.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ScreenerMarketHeader extends StatelessWidget {
  const _ScreenerMarketHeader({required this.snapshot});

  final MarketScreenerSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_marketLabel(snapshot.market)} · ${snapshot.timeframe}',
              style: TextStyle(
                color: context.palette.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Latest ${snapshot.quotes.length} live instruments',
              style: TextStyle(
                color: context.palette.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: context.palette.success.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: context.palette.success.withValues(alpha: .45),
          ),
        ),
        child: Text(
          'LIVE · 15S',
          style: TextStyle(
            color: context.palette.success,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _ScreenerQuoteCard extends StatelessWidget {
  const _ScreenerQuoteCard({required this.quote});

  final MarketScreenerQuote quote;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final positive = quote.changePercent >= 0;
    final movement = positive ? palette.success : palette.error;
    return Container(
      key: ValueKey('market-screener-quote-${quote.symbol}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: TradeXRadii.control,
        border: Border.all(color: palette.gold.withValues(alpha: .55)),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              quote.symbol.substring(0, math.min(3, quote.symbol.length)),
              style: TextStyle(
                color: palette.goldText,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (quote.name.isNotEmpty) quote.name,
                    if (quote.exchange.isNotEmpty) quote.exchange,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.secondaryText, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _marketPrice(quote.price),
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${positive ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: movement,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                quote.rsi > 0
                    ? '${quote.trend} · RSI ${quote.rsi.toStringAsFixed(1)}'
                    : quote.trend,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketErrorState extends StatelessWidget {
  const _MarketErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: context.palette.goldText),
          const SizedBox(height: 9),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _marketPrice(double value) {
  if (value == 0) return '—';
  if (value.abs() >= 1000) return value.toStringAsFixed(2);
  if (value.abs() >= 1) return value.toStringAsFixed(4);
  return value.toStringAsFixed(6);
}
