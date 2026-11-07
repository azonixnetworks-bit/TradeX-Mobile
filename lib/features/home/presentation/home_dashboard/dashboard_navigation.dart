part of '../home_dashboard_screen.dart';

class _DashboardNavBar extends StatelessWidget {
  const _DashboardNavBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = TradeXPalette.of(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        TradeXSpacing.sm,
        TradeXSpacing.xs,
        TradeXSpacing.sm,
        TradeXSpacing.xs,
      ),
      child: SizedBox(
        key: const ValueKey('dashboard-nav-root'),
        height: 78,
        child: Container(
          key: const ValueKey('dashboard-nav-surface'),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          decoration: BoxDecoration(
            color: palette.navBackground,
            borderRadius: BorderRadius.circular(TradeXRadii.xl),
            boxShadow: TradeXElevation.floating(
              brightness: theme.brightness,
              palette: palette,
            ),
          ),
          child: Row(
            children: List<Widget>.generate(_tabItems.length, (index) {
              final item = _tabItems[index];
              final selected = index == selectedIndex;

              return Expanded(
                child: Semantics(
                  label: item.label,
                  selected: selected,
                  button: true,
                  child: InkWell(
                    key: ValueKey('dashboard-nav-item-$index'),
                    onTap: () => onChanged(index),
                    borderRadius: BorderRadius.circular(TradeXRadii.lg),
                    child: AnimatedContainer(
                      key: selected
                          ? ValueKey('dashboard-nav-selected-$index')
                          : null,
                      duration: TradeXMotion.standard,
                      curve: TradeXMotion.enter,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: TradeXMotion.standard,
                            curve: TradeXMotion.enter,
                            transform: Matrix4.translationValues(
                              0,
                              selected ? -10 : 0,
                              0,
                            ),
                            width: selected ? 50 : 42,
                            height: selected ? 50 : 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: selected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [palette.goldText, palette.gold],
                                    )
                                  : null,
                              color: selected ? null : Colors.transparent,
                              border: selected
                                  ? Border.all(
                                      color: palette.background,
                                      width: 4,
                                    )
                                  : null,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: palette.gold.withValues(
                                          alpha: .34,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 7),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              item.icon,
                              size: selected ? 23 : 21,
                              color: selected
                                  ? palette.primaryButtonText
                                  : palette.secondaryText,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: TradeXMotion.quick,
                            child: selected
                                ? Transform.translate(
                                    key: ValueKey('label-${item.label}'),
                                    offset: const Offset(0, -8),
                                    child: Text(
                                      item.label,
                                      key: ValueKey(
                                        'dashboard-nav-label-$index',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: palette.goldText,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0,
                                          ),
                                    ),
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
