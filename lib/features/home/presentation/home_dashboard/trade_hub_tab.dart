part of '../home_dashboard_screen.dart';

class _TradeHubTab extends StatelessWidget {
  const _TradeHubTab({super.key});

  static const _items = <_TradeHubItem>[
    _TradeHubItem(
      'trade-journal',
      'Trade Journal',
      'Track plans, trades and performance',
      Icons.menu_book_rounded,
    ),
    _TradeHubItem(
      'investments',
      'Investments',
      'View portfolio and investment records',
      Icons.diamond_outlined,
    ),
    _TradeHubItem(
      'funded-advisor',
      'Funded Account Adviser',
      'Explore funded account guidance',
      Icons.account_balance_rounded,
    ),
    _TradeHubItem(
      'trading-routine',
      'Trade Routine',
      'Follow your daily trading checklist',
      Icons.checklist_rounded,
    ),
    _TradeHubItem(
      'trade-entry-form',
      'Plan a Trade',
      'Prepare setup, entry and risk',
      Icons.add_chart_rounded,
    ),
    _TradeHubItem(
      'risk-reward-calculator',
      'Risk Reward Calculator',
      'Calculate position size and reward',
      Icons.balance_rounded,
    ),
    _TradeHubItem(
      'copy-dashboard',
      'Copy Trade Dashboard',
      'Manage connected trading accounts',
      Icons.copy_all_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.background, palette.surfaceMuted],
        ),
      ),
      child: ListView(
        key: const ValueKey('trade-hub-scroll'),
        padding: const EdgeInsets.fromLTRB(
          TradeXSpacing.lg,
          TradeXSpacing.lg,
          TradeXSpacing.lg,
          TradeXSpacing.xxl,
        ),
        children: [
          Text(
            'Trade',
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: TradeXSpacing.xxs),
          Text(
            'Plan, manage and improve your trading journey',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: TradeXSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = TradeXSpacing.sm;
              final columns = constraints.maxWidth >= 680 ? 3 : 2;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in _items)
                    SizedBox(
                      width: width,
                      child: _TradeHubCard(
                        item: item,
                        onTap: () => _open(context, item),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, _TradeHubItem item) {
    ActivityTrackingScope.maybeOf(context)?.openedFeature(item.featureId);
    openTradeXFeature(
      context,
      CatalogDependenciesRegistry.current,
      featureById(item.featureId),
    );
  }
}

class _TradeHubCard extends StatelessWidget {
  const _TradeHubCard({required this.item, required this.onTap});

  final _TradeHubItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TradeXRadii.card,
        child: Ink(
          padding: const EdgeInsets.all(TradeXSpacing.sm),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: TradeXRadii.card,
            border: Border.all(
              color: palette.gold.withValues(alpha: .72),
              width: 1.1,
            ),
            boxShadow: TradeXElevation.surface(
              brightness: Theme.of(context).brightness,
              palette: palette,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: TradeXSpacing.xxxl,
                height: TradeXSpacing.xxxl,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.gold.withValues(alpha: .12),
                  borderRadius: TradeXRadii.control,
                  border: Border.all(
                    color: palette.gold.withValues(alpha: .32),
                  ),
                ),
                child: Icon(item.icon, color: palette.goldText),
              ),
              const SizedBox(height: TradeXSpacing.sm),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: palette.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TradeXSpacing.xxs),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: palette.secondaryText, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeHubItem {
  const _TradeHubItem(this.featureId, this.title, this.subtitle, this.icon);

  final String featureId;
  final String title;
  final String subtitle;
  final IconData icon;
}
