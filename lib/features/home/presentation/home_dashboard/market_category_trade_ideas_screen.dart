part of '../home_dashboard_screen.dart';

enum _TradeIdeaMode { longTerm, daily }

enum _TradeIdeaAge { today, thisWeek, oldTrades }

enum _StockMarketRegion { cse, india, international }

class _MarketCategoryTradeIdeasScreen extends StatefulWidget {
  const _MarketCategoryTradeIdeasScreen({
    required this.category,
    required this.repository,
  });

  final String category;
  final DashboardTradeIdeasRepository repository;

  @override
  State<_MarketCategoryTradeIdeasScreen> createState() =>
      _MarketCategoryTradeIdeasScreenState();
}

class _MarketCategoryTradeIdeasScreenState
    extends State<_MarketCategoryTradeIdeasScreen> {
  late Future<List<DashboardTradeIdea>> _ideas = _load();
  _TradeIdeaMode _mode = _TradeIdeaMode.daily;
  _TradeIdeaAge _age = _TradeIdeaAge.today;
  _StockMarketRegion _stockRegion = _StockMarketRegion.cse;

  Future<List<DashboardTradeIdea>> _load() =>
      widget.repository.latestByCategory(_marketApiCategory(widget.category));

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _ideas = next);
    await next;
  }

  List<DashboardTradeIdea> _filtered(List<DashboardTradeIdea> ideas) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 7));
    return ideas
        .where((idea) {
          final timeframe = idea.timeframe.toUpperCase().replaceAll(' ', '');
          final longTerm =
              timeframe.contains('D') ||
              timeframe.contains('W') ||
              timeframe.contains('MN') ||
              timeframe.contains('MONTH');
          if (_mode == _TradeIdeaMode.longTerm ? !longTerm : longTerm) {
            return false;
          }

          if (widget.category.toUpperCase() == 'STOCKS' &&
              !_matchesStockRegion(idea.marketRegion, _stockRegion)) {
            return false;
          }

          final published = idea.publishedAt?.toLocal();
          if (published == null) return _age == _TradeIdeaAge.oldTrades;
          return switch (_age) {
            _TradeIdeaAge.today => !published.isBefore(today),
            _TradeIdeaAge.thisWeek => !published.isBefore(weekStart),
            _TradeIdeaAge.oldTrades => published.isBefore(weekStart),
          };
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.category} Trade Ideas',
          style: TextStyle(
            color: context.palette.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryFilterChip(
                          label: 'Long Term Trade Ideas',
                          selected: _mode == _TradeIdeaMode.longTerm,
                          onTap: () =>
                              setState(() => _mode = _TradeIdeaMode.longTerm),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CategoryFilterChip(
                          label: 'Daily Trade Ideas',
                          selected: _mode == _TradeIdeaMode.daily,
                          onTap: () =>
                              setState(() => _mode = _TradeIdeaMode.daily),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryFilterChip(
                          label: 'Today',
                          selected: _age == _TradeIdeaAge.today,
                          onTap: () =>
                              setState(() => _age = _TradeIdeaAge.today),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CategoryFilterChip(
                          label: 'This Week',
                          selected: _age == _TradeIdeaAge.thisWeek,
                          onTap: () =>
                              setState(() => _age = _TradeIdeaAge.thisWeek),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CategoryFilterChip(
                          label: 'Old Trades',
                          selected: _age == _TradeIdeaAge.oldTrades,
                          onTap: () =>
                              setState(() => _age = _TradeIdeaAge.oldTrades),
                        ),
                      ),
                    ],
                  ),
                  if (widget.category.toUpperCase() == 'STOCKS') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryFilterChip(
                            label: 'CSE',
                            selected: _stockRegion == _StockMarketRegion.cse,
                            onTap: () => setState(
                              () => _stockRegion = _StockMarketRegion.cse,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CategoryFilterChip(
                            label: 'India',
                            selected: _stockRegion == _StockMarketRegion.india,
                            onTap: () => setState(
                              () => _stockRegion = _StockMarketRegion.india,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CategoryFilterChip(
                            label: 'International',
                            selected:
                                _stockRegion ==
                                _StockMarketRegion.international,
                            onTap: () => setState(
                              () => _stockRegion =
                                  _StockMarketRegion.international,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<DashboardTradeIdea>>(
                future: _ideas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: TradeXColors.goldBright,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _CategoryIdeasMessage(
                      icon: Icons.cloud_off_rounded,
                      message: 'Trade ideas are temporarily unavailable.',
                      onTap: _refresh,
                    );
                  }
                  final ideas = _filtered(
                    snapshot.data ?? const <DashboardTradeIdea>[],
                  );
                  if (ideas.isEmpty) {
                    return _CategoryIdeasMessage(
                      icon: Icons.insights_rounded,
                      message: 'No trade ideas in this filter yet.',
                      onTap: _refresh,
                    );
                  }
                  return RefreshIndicator(
                    color: TradeXColors.goldBright,
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: ideas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => SizedBox(
                        height: 535,
                        child: _LiveTradeIdeaCard(
                          idea: ideas[index],
                          position: index,
                          repository: widget.repository,
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
    );
  }
}

bool _matchesStockRegion(String rawRegion, _StockMarketRegion selected) {
  final region = rawRegion.trim().toUpperCase().replaceAll('-', '_');
  final isCse = region == 'CSE' || region == 'COLOMBO_STOCK_EXCHANGE';
  final isSriLanka =
      region == 'SRI_LANKA' || region == 'SRI LANKA' || region == 'LK';
  final isIndia =
      region == 'INDIA' || region == 'IN' || region == 'NSE' || region == 'BSE';
  return switch (selected) {
    _StockMarketRegion.cse => isCse || isSriLanka,
    _StockMarketRegion.india => isIndia,
    _StockMarketRegion.international => !isCse && !isSriLanka && !isIndia,
  };
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
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
      foregroundColor: const Color(0xFF171308),
      backgroundColor: selected ? context.palette.gold : Colors.white,
      side: BorderSide(color: context.palette.gold, width: 1.15),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
    ),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

class _CategoryIdeasMessage extends StatelessWidget {
  const _CategoryIdeasMessage({
    required this.icon,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.palette.goldText, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.secondaryText),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onTap, child: const Text('Refresh')),
        ],
      ),
    ),
  );
}
