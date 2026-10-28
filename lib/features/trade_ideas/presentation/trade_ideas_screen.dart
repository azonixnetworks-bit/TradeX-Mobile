import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../shared/widgets/no_trade_zone_warning.dart';
import '../../home/domain/no_trade_zone_warning.dart';
import '../data/trade_idea_repository.dart';
import '../models/trade_idea_models.dart';
import 'trade_idea_details_screen.dart';

class TradeIdeasScreen extends StatefulWidget {
  const TradeIdeasScreen({
    super.key,
    required this.repository,
    required this.warningSource,
  });

  final TradeIdeaDataSource repository;
  final NoTradeWarningSource warningSource;

  @override
  State<TradeIdeasScreen> createState() => _TradeIdeasScreenState();
}

class _TradeIdeasScreenState extends State<TradeIdeasScreen> {
  static const _filters = ['ALL', 'FOREX', 'CRYPTO', 'DERIV', 'STOCKS'];
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final List<TradeIdeaSummary> _items = [];
  Timer? _debounce;
  String _category = 'ALL';
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
    color: TradeXColors.background,
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
                  const Text(
                    'Trade Ideas',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Institutional market analysis',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  if (_category == 'FOREX') ...[
                    const SizedBox(height: 14),
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
                          selectedColor: TradeXColors.goldBright,
                          backgroundColor: TradeXColors.surfaceRaised,
                          side: BorderSide(
                            color: selected
                                ? TradeXColors.goldBright
                                : TradeXColors.borderStrong,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.black
                                : TradeXColors.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: TradeXColors.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Search symbols, e.g. XAUUSD, BTCUSDT',
                      hintStyle: const TextStyle(
                        color: TradeXColors.secondaryText,
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
                      fillColor: TradeXColors.surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: TradeXColors.borderStrong,
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
                      if (_items.isNotEmpty)
                        Text(
                          '${_items.length} loaded',
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
            else if (_items.isEmpty)
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
                  itemCount: _items.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: TradeXColors.goldBright,
                          ),
                        ),
                      );
                    }
                    return _TradeIdeaCard(
                      idea: _items[index],
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => TradeIdeaDetailsScreen(
                            repository: widget.repository,
                            uuid: _items[index].uuid,
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

class _TradeIdeaCard extends StatelessWidget {
  const _TradeIdeaCard({required this.idea, required this.onTap});

  final TradeIdeaSummary idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final buy = idea.direction == 'BUY';
    final accent = buy ? TradeXColors.success : TradeXColors.error;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TradeXColors.surfaceRaised,
                accent.withValues(alpha: .055),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: .42)),
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
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
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
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                          ),
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
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [TradeXColors.goldBright, TradeXColors.goldDeep],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: TradeXColors.gold.withValues(alpha: .18),
          blurRadius: 14,
        ),
      ],
    ),
    child: Text(
      idea.symbol
          .substring(0, idea.symbol.length.clamp(0, 3).toInt())
          .toUpperCase(),
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: TradeXColors.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: TradeXColors.borderStrong),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: TradeXColors.secondaryText,
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

String _label(String raw) => switch (raw.toUpperCase()) {
  'ALL' => 'All',
  'FOREX' => 'Forex',
  'CRYPTO' => 'Crypto',
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
