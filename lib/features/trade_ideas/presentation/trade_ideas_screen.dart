import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/market_assets/market_asset_widget.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../../../shared/widgets/no_trade_zone_warning.dart';
import '../../home/domain/no_trade_zone_warning.dart';
import '../domain/entities/trade_idea_entities.dart';
import '../domain/repositories/trade_idea_repository.dart';
import 'trade_idea_details_screen.dart';

enum _TradeIdeaStockRegion { sriLanka, india, international }

enum _TradeIdeaPeriod { all, today, thisWeek, thisMonth }

class TradeIdeasScreen extends StatefulWidget {
  const TradeIdeasScreen({
    super.key,
    required this.repository,
    required this.warningSource,
    this.onNotifications,
    this.onRiskCalculator,
  });

  final TradeIdeaRepositoryContract repository;
  final NoTradeWarningSource warningSource;
  final VoidCallback? onNotifications;
  final VoidCallback? onRiskCalculator;

  @override
  State<TradeIdeasScreen> createState() => _TradeIdeasScreenState();
}

class _TradeIdeasScreenState extends State<TradeIdeasScreen> {
  static const _filters = [
    'FOREX',
    'CRYPTO',
    'COMMODITY',
    'INDICES',
    'DERIV',
    'STOCKS',
  ];
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final List<TradeIdeaSummary> _items = [];
  Timer? _debounce;
  String _category = 'FOREX';
  _TradeIdeaStockRegion _stockRegion = _TradeIdeaStockRegion.sriLanka;
  _TradeIdeaPeriod _period = _TradeIdeaPeriod.today;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 360 && _hasMore && !_loadingMore) {
      _load();
    }
  }

  List<TradeIdeaSummary> get _visibleItems {
    Iterable<TradeIdeaSummary> visible = _items.where(
      (idea) => _matchesTradeIdeaCategory(idea.category, _category),
    );
    if (_category == 'STOCKS') {
      visible = visible.where(
        (idea) => _matchesTradeIdeaStockRegion(idea, _stockRegion),
      );
    }
    return visible
        .where((idea) => _matchesTradeIdeaPeriod(idea.publishedAt, _period))
        .toList(growable: false);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final result = await widget.repository.list(
        page: reset ? 1 : _page + 1,
        perPage: 10,
        category: _category,
        symbol: _search.text,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(
          result.items.where(
            (incoming) => !_items.any((item) => item.uuid == incoming.uuid),
          ),
        );
        _items.sort((left, right) {
          final leftDate = left.publishedAt;
          final rightDate = right.publishedAt;
          if (leftDate == null && rightDate == null) return 0;
          if (leftDate == null) return 1;
          if (rightDate == null) return -1;
          return rightDate.compareTo(leftDate);
        });
        _page = result.currentPage;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Trade Ideas are temporarily unavailable.';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: TradeXColors.goldBright,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PeriodButton(
                          key: const ValueKey('trade-ideas-period-all'),
                          label: 'All',
                          selected: _period == _TradeIdeaPeriod.all,
                          onTap: () =>
                              setState(() => _period = _TradeIdeaPeriod.all),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trade Ideas',
                          style: TextStyle(
                            color: context.palette.primaryText,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (widget.onRiskCalculator != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          key: const ValueKey(
                            'trade-ideas-risk-calculator-button',
                          ),
                          onPressed: widget.onRiskCalculator,
                          icon: const Icon(Icons.calculate_outlined, size: 17),
                          label: const Text('Risk Calculator'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.palette.goldText,
                            side: BorderSide(color: context.palette.gold),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      if (widget.onNotifications != null)
                        IconButton(
                          key: const ValueKey(
                            'trade-ideas-notifications-button',
                          ),
                          onPressed: widget.onNotifications,
                          tooltip: 'Notifications',
                          color: TradeXColors.goldBright,
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Institutional market analysis',
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  if (_category == 'FOREX') ...[
                    NoTradeZoneWarningBanner(
                      source: widget.warningSource,
                      applicableSymbolsOrCurrencies: _items
                          .where((idea) => idea.category == 'FOREX')
                          .map((idea) => idea.symbol),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final selected = filter == _category;
                        return ChoiceChip(
                          label: Text(_label(filter)),
                          selected: selected,
                          onSelected: (_) {
                            if (selected) return;
                            setState(() => _category = filter);
                            _load(reset: true);
                          },
                          selectedColor: context.palette.gold,
                          backgroundColor: context.palette.surfaceRaised,
                          side: BorderSide(
                            color: selected
                                ? TradeXColors.goldBright
                                : context.palette.borderStrong,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.black
                                : context.palette.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                  if (_category == 'STOCKS') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StockRegionButton(
                            label: 'Sri Lanka (CSE)',
                            selected:
                                _stockRegion == _TradeIdeaStockRegion.sriLanka,
                            onTap: () => setState(
                              () =>
                                  _stockRegion = _TradeIdeaStockRegion.sriLanka,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StockRegionButton(
                            label: 'India',
                            selected:
                                _stockRegion == _TradeIdeaStockRegion.india,
                            onTap: () => setState(
                              () => _stockRegion = _TradeIdeaStockRegion.india,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StockRegionButton(
                            label: 'International',
                            selected:
                                _stockRegion ==
                                _TradeIdeaStockRegion.international,
                            onTap: () => setState(
                              () => _stockRegion =
                                  _TradeIdeaStockRegion.international,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PeriodButton(
                          key: const ValueKey('trade-ideas-period-today'),
                          label: 'Today',
                          selected: _period == _TradeIdeaPeriod.today,
                          onTap: () =>
                              setState(() => _period = _TradeIdeaPeriod.today),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PeriodButton(
                          key: const ValueKey('trade-ideas-period-week'),
                          label: 'This Week',
                          selected: _period == _TradeIdeaPeriod.thisWeek,
                          onTap: () => setState(
                            () => _period = _TradeIdeaPeriod.thisWeek,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PeriodButton(
                          key: const ValueKey('trade-ideas-period-month'),
                          label: 'This Month',
                          selected: _period == _TradeIdeaPeriod.thisMonth,
                          onTap: () => setState(
                            () => _period = _TradeIdeaPeriod.thisMonth,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: context.palette.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Search symbols, e.g. XAUUSD, BTCUSDT',
                      hintStyle: TextStyle(
                        color: context.palette.secondaryText,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                _load(reset: true);
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: context.palette.surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.palette.borderStrong,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 350),
                        () => _load(reset: true),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Latest Trade Ideas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: TradeXColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (_visibleItems.isNotEmpty)
                        Text(
                          '${_visibleItems.length} loaded',
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: TradeXColors.goldBright,
                  ),
                ),
              )
            else if (_error != null && _items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Message(
                  icon: Icons.cloud_off_rounded,
                  message: _error!,
                  onRetry: () => _load(reset: true),
                ),
              )
            else if (_visibleItems.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _Message(
                  icon: Icons.insights_outlined,
                  message: 'No published ideas match this search.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
                sliver: SliverList.separated(
                  itemCount: _visibleItems.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _visibleItems.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: TradeXColors.goldBright,
                          ),
                        ),
                      );
                    }
                    final idea = _visibleItems[index];
                    return _TradeIdeaCard(
                      idea: idea,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => TradeIdeaDetailsScreen(
                            repository: widget.repository,
                            uuid: idea.uuid,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: OutlinedButton(
      onPressed: selected ? null : onTap,
      style: OutlinedButton.styleFrom(
        disabledBackgroundColor: context.palette.gold,
        backgroundColor: context.palette.surfaceRaised,
        foregroundColor: context.palette.primaryText,
        disabledForegroundColor: Colors.black,
        side: BorderSide(
          color: selected
              ? TradeXColors.goldBright
              : context.palette.borderStrong,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    ),
  );
}

class _TradeIdeaCard extends StatelessWidget {
  const _TradeIdeaCard({required this.idea, required this.onTap});

  final TradeIdeaSummary idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final buy = idea.direction == 'BUY';
    final palette = context.palette;
    final accent = buy ? palette.success : palette.error;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TradeXRadii.card,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.goldSoft,
                palette.surfaceRaised,
                palette.surface,
              ],
            ),
            borderRadius: TradeXRadii.card,
            border: Border.all(color: palette.gold.withValues(alpha: .5)),
            boxShadow: TradeXElevation.surface(
              brightness: Theme.of(context).brightness,
              palette: palette,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SymbolAvatar(idea: idea),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _Pill(text: _label(idea.category)),
                            _Pill(text: idea.timeframe),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          idea.symbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primaryText,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          idea.instrumentName.isEmpty
                              ? idea.title
                              : idea.instrumentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: palette.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent),
                    ),
                    child: Text(
                      idea.direction,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Value(
                      label: 'Entry Zone',
                      value: idea.entry.display,
                    ),
                  ),
                  Expanded(
                    child: _Value(
                      label: 'Stop Loss',
                      value: idea.stopLoss.display,
                      color: TradeXColors.error,
                    ),
                  ),
                  Expanded(
                    child: _Value(
                      label: 'Targets',
                      value: '${idea.targetsHit}/${idea.targetsTotal}',
                      color: TradeXColors.success,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: TradeXColors.secondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _relative(idea.publishedAt),
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    idea.chartAvailable
                        ? Icons.image_outlined
                        : Icons.image_not_supported_outlined,
                    size: 16,
                    color: TradeXColors.secondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    idea.chartAvailable ? 'Analysis chart' : 'No chart',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 17,
                    color: TradeXColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${idea.reactions.likes}',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymbolAvatar extends StatelessWidget {
  const _SymbolAvatar({required this.idea});
  final TradeIdeaSummary idea;
  @override
  Widget build(BuildContext context) => MarketInstrumentAvatar(
    market: idea.category,
    symbol: idea.symbol,
    size: 58,
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: context.palette.borderStrong),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: context.palette.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value({
    required this.label,
    required this.value,
    this.color = TradeXColors.primaryText,
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
        style: const TextStyle(color: TradeXColors.secondaryText, fontSize: 10),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message, this.onRetry});
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: TradeXColors.secondaryText),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
          if (onRetry != null)
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

class _StockRegionButton extends StatelessWidget {
  const _StockRegionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: selected ? Colors.black : context.palette.primaryText,
      backgroundColor: selected
          ? context.palette.gold
          : context.palette.surfaceRaised,
      side: BorderSide(
        color: selected
            ? TradeXColors.goldBright
            : context.palette.borderStrong,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
    ),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

bool _matchesTradeIdeaStockRegion(
  TradeIdeaSummary idea,
  _TradeIdeaStockRegion selected,
) {
  final region = idea.marketRegion.trim().toUpperCase().replaceAll('-', '_');
  final sriLanka =
      region == 'SRI_LANKA' ||
      region == 'SRI LANKA' ||
      region == 'LK' ||
      region == 'CSE' ||
      region == 'COLOMBO_STOCK_EXCHANGE';
  final india =
      region == 'INDIA' || region == 'IN' || region == 'NSE' || region == 'BSE';
  return switch (selected) {
    _TradeIdeaStockRegion.sriLanka => sriLanka,
    _TradeIdeaStockRegion.india => india,
    _TradeIdeaStockRegion.international => !sriLanka && !india,
  };
}

bool _matchesTradeIdeaCategory(String rawCategory, String selectedCategory) {
  final category = rawCategory.trim().toUpperCase();
  return switch (selectedCategory) {
    'COMMODITY' => category == 'COMMODITY' || category == 'COMMODITIES',
    'INDICES' => category == 'INDICES' || category == 'INDEX',
    _ => category == selectedCategory,
  };
}

bool _matchesTradeIdeaPeriod(DateTime? publishedAt, _TradeIdeaPeriod selected) {
  if (selected == _TradeIdeaPeriod.all) return true;
  // Keep legacy ideas that predate the mandatory publication timestamp.
  if (publishedAt == null) return true;
  final now = DateTime.now();
  final localPublishedAt = publishedAt.toLocal();
  final start = switch (selected) {
    _TradeIdeaPeriod.all => DateTime.fromMillisecondsSinceEpoch(0),
    _TradeIdeaPeriod.today => DateTime(now.year, now.month, now.day),
    _TradeIdeaPeriod.thisWeek => DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - DateTime.monday),
    ),
    _TradeIdeaPeriod.thisMonth => DateTime(now.year, now.month),
  };
  return !localPublishedAt.isBefore(start);
}

String _label(String raw) => switch (raw.toUpperCase()) {
  'FOREX' => 'Forex',
  'CRYPTO' => 'Crypto',
  'COMMODITY' => 'Commodity',
  'INDICES' => 'Indices',
  'DERIV' => 'Deriv',
  'STOCKS' => 'Stocks',
  _ => raw,
};

String _relative(DateTime? value) {
  if (value == null) return 'Recently';
  final difference = DateTime.now().difference(value);
  if (difference.isNegative) return 'Recently';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
