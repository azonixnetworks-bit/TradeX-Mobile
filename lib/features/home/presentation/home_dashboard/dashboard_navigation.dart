part of '../home_dashboard_screen.dart';

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final palette = TradeXPalette.of(context);
    return Container(
      key: const ValueKey('dashboard-top-bar'),
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
          bottom: BorderSide(color: palette.gold.withValues(alpha: .18)),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/branding/trade_x_wordmark.png',
            width: 136,
            height: 36,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          IconButton(
            key: const ValueKey('dashboard-notifications-button'),
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: Badge(
              smallSize: 9,
              backgroundColor: TradeXColors.goldBright,
              child: Icon(
                Icons.notifications_none_rounded,
                color: palette.goldText,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardNavBar extends StatefulWidget {
  const _DashboardNavBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<_DashboardNavBar> createState() => _DashboardNavBarState();
}

class _DashboardNavBarState extends State<_DashboardNavBar> {
  late double _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant _DashboardNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _tabItems.length;
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            tween: Tween<double>(
              begin: _previousIndex,
              end: widget.selectedIndex.toDouble(),
            ),
            builder: (context, activeIndex, child) {
              final activeCenter = (activeIndex + .5) * itemWidth;
              return SizedBox(
                key: const ValueKey('dashboard-nav-root'),
                height: 82,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 17,
                      child: ClipPath(
                        clipper: _TradeXNavNotchClipper(
                          notchCenter: activeCenter,
                        ),
                        child: Container(
                          key: const ValueKey('dashboard-nav-surface'),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF0A100E)
                                : theme.colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .38),
                                blurRadius: 18,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: activeCenter - 27,
                      // About 60% of the active circle floats above the bar.
                      top: -15,
                      child: Container(
                        key: ValueKey(
                          'dashboard-nav-selected-${widget.selectedIndex}',
                        ),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFE58E), TradeXColors.gold],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFF1AD),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TradeXColors.goldBright.withValues(
                                alpha: .45,
                              ),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          _tabItems[widget.selectedIndex].icon,
                          color: const Color(0xFF171308),
                          size: 29,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 15,
                      child: Row(
                        children: List.generate(_tabItems.length, (index) {
                          final item = _tabItems[index];
                          final selected = index == widget.selectedIndex;
                          return Expanded(
                            child: Semantics(
                              label: item.label,
                              selected: selected,
                              button: true,
                              child: InkWell(
                                key: ValueKey('dashboard-nav-item-$index'),
                                onTap: () => widget.onChanged(index),
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        opacity: selected ? 0 : 1,
                                        child: Icon(
                                          item.icon,
                                          size: 24,
                                          color: dark
                                              ? TradeXColors.secondaryText
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                      ),
                                      SizedBox(height: selected ? 19 : 3),
                                      ClipRect(
                                        child: AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOut,
                                          child: selected
                                              ? Text(
                                                  item.label,
                                                  key: ValueKey(
                                                    'dashboard-nav-label-$index',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color:
                                                        TradeXColors.goldBright,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TradeXNavNotchClipper extends CustomClipper<Path> {
  const _TradeXNavNotchClipper({required this.notchCenter});

  final double notchCenter;

  @override
  Path getClip(Size size) {
    const radius = 36.0;
    const depth = 27.0;
    final start = (notchCenter - radius).clamp(0.0, size.width).toDouble();
    final end = (notchCenter + radius).clamp(0.0, size.width).toDouble();
    final path = Path()..lineTo(start, 0);
    path.cubicTo(start + 10, 0, notchCenter - 19, depth, notchCenter, depth);
    path.cubicTo(notchCenter + 19, depth, end - 10, 0, end, 0);
    path
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TradeXNavNotchClipper oldClipper) {
    return oldClipper.notchCenter != notchCenter;
  }
}
