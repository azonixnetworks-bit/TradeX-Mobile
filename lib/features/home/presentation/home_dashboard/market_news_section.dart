part of '../home_dashboard_screen.dart';

class _MarketNewsSection extends StatefulWidget {
  const _MarketNewsSection({required this.repository, required this.onOpenAll});

  final MarketNewsRepository repository;
  final VoidCallback onOpenAll;

  @override
  State<_MarketNewsSection> createState() => _MarketNewsSectionState();
}

class _MarketNewsSectionState extends State<_MarketNewsSection>
    with WidgetsBindingObserver {
  late final HomeMarketNewsCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = HomeMarketNewsCubit(widget.repository)..load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.load(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HomeMarketNewsCubit, HomeMarketNewsState>(
        builder: (context, state) {
          if (state.status == HomeMarketNewsStatus.initial ||
              state.status == HomeMarketNewsStatus.loading) {
            return Container(
              key: const ValueKey('market-news-section'),
              height: 178,
              decoration: _panelDecoration(context),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: TradeXColors.goldBright,
                strokeWidth: 2.4,
              ),
            );
          }

          if (state.status == HomeMarketNewsStatus.failure) {
            return _MarketNewsMessage(
              key: const ValueKey('market-news-section'),
              icon: Icons.cloud_off_rounded,
              message: 'Market news is temporarily unavailable.',
              action: 'Retry',
              onTap: _cubit.load,
            );
          }

          final items = state.items;
          if (items.isEmpty) {
            return _MarketNewsMessage(
              key: const ValueKey('market-news-section'),
              icon: Icons.event_available_rounded,
              message: 'No upcoming published economic news right now.',
              action: 'View all',
              onTap: widget.onOpenAll,
            );
          }

          final visible = items.take(4).toList(growable: false);
          return Container(
            key: const ValueKey('market-news-section'),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: _panelDecoration(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) => _MarketNewsCard(
                    key: ValueKey('market-news-card-$index'),
                    item: visible[index],
                    artworkIndex: index,
                    onTap: widget.onOpenAll,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MarketNewsMessage extends StatelessWidget {
  const _MarketNewsMessage({
    super.key,
    required this.icon,
    required this.message,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 142,
    padding: const EdgeInsets.all(16),
    decoration: _panelDecoration(context),
    child: Row(
      children: [
        Icon(icon, color: TradeXColors.goldBright, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
            ),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

class _MarketNewsCard extends StatelessWidget {
  const _MarketNewsCard({
    super.key,
    required this.item,
    required this.artworkIndex,
    required this.onTap,
  });

  final MarketNewsItem item;
  final int artworkIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final impactColor = switch (item.impact.toUpperCase()) {
      'HIGH' => const Color(0xFFFF5D5D),
      'MEDIUM' => TradeXColors.goldBright,
      _ => TradeXColors.success,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E0D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2B302D)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MarketNewsArtwork(item: item, variant: artworkIndex),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0xF2050706)],
                      stops: [.22, .82],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: impactColor.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: impactColor.withValues(alpha: .55),
                              ),
                            ),
                            child: Text(
                              item.isLiveUpdate ? 'LIVE' : item.impact,
                              style: TextStyle(
                                color: impactColor,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (item.currency.isNotEmpty)
                            Text(
                              item.currency,
                              maxLines: 1,
                              style: const TextStyle(
                                color: TradeXColors.goldBright,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TradeXColors.primaryText,
                          fontSize: 9.5,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _MarketNewsReleaseValues(item: item),
                      const SizedBox(height: 4),
                      Text(
                        _marketNewsTime(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TradeXColors.tertiaryText,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _marketNewsTime(MarketNewsItem item) {
    final timestamp = item.occurredAt;
    if (timestamp == null) {
      return item.isLiveUpdate ? 'Live update' : 'Scheduled';
    }
    final local = timestamp.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return 'Today • $hour:$minute';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} • $hour:$minute';
  }
}

class _MarketNewsArtwork extends StatelessWidget {
  const _MarketNewsArtwork({required this.item, required this.variant});

  final MarketNewsItem item;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final icon = _economicNewsIcon(item);
    final country = _countryFlag(item.countryCode);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _MarketNewsArtworkPainter(variant)),
        Positioned(
          right: 8,
          top: 24,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TradeXColors.background.withValues(alpha: .7),
              border: Border.all(
                color: TradeXColors.goldBright.withValues(alpha: .4),
              ),
              boxShadow: [
                BoxShadow(
                  color: TradeXColors.gold.withValues(alpha: .18),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(
              icon,
              key: ValueKey('market-news-artwork-icon-${item.uuid}'),
              color: TradeXColors.goldBright,
              size: 25,
            ),
          ),
        ),
        if (country.isNotEmpty)
          Positioned(
            right: 8,
            top: 70,
            child: Text(country, style: const TextStyle(fontSize: 14)),
          ),
      ],
    );
  }
}

IconData _economicNewsIcon(MarketNewsItem item) {
  final value = '${item.category} ${item.title}'.toLowerCase();
  if (value.contains('employment') ||
      value.contains('payroll') ||
      value.contains('job') ||
      value.contains('unemployment')) {
    return Icons.groups_2_rounded;
  }
  if (value.contains('inflation') ||
      value.contains('cpi') ||
      value.contains('ppi') ||
      value.contains('price index')) {
    return Icons.price_change_rounded;
  }
  if (value.contains('interest') ||
      value.contains('rate decision') ||
      value.contains('central bank') ||
      value.contains('federal reserve')) {
    return Icons.account_balance_rounded;
  }
  if (value.contains('gdp') ||
      value.contains('growth') ||
      value.contains('production')) {
    return Icons.query_stats_rounded;
  }
  if (value.contains('retail') || value.contains('consumer')) {
    return Icons.shopping_cart_rounded;
  }
  if (value.contains('housing') || value.contains('home')) {
    return Icons.home_work_rounded;
  }
  if (value.contains('manufactur') || value.contains('pmi')) {
    return Icons.precision_manufacturing_rounded;
  }
  if (value.contains('trade') ||
      value.contains('import') ||
      value.contains('export')) {
    return Icons.local_shipping_rounded;
  }
  return Icons.candlestick_chart_rounded;
}

String _countryFlag(String countryCode) {
  final code = countryCode.trim().toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) return '';
  return String.fromCharCodes(
    code.codeUnits.map((character) => character + 0x1F1A5),
  );
}

class _MarketNewsReleaseValues extends StatelessWidget {
  const _MarketNewsReleaseValues({required this.item});

  final MarketNewsItem item;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('market-news-values-${item.uuid}'),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xC9070A08),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: TradeXColors.border.withValues(alpha: .8)),
    ),
    child: Row(
      children: [
        _MarketNewsReleaseValue(label: 'Previous', value: item.previous ?? '—'),
        _MarketNewsReleaseValue(label: 'Forecast', value: item.forecast ?? '—'),
        _MarketNewsReleaseValue(
          label: 'Actual',
          value: item.actual ?? 'Pending',
          highlighted: item.actual != null,
        ),
      ],
    ),
  );
}

class _MarketNewsReleaseValue extends StatelessWidget {
  const _MarketNewsReleaseValue({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TradeXColors.tertiaryText,
            fontSize: 5.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: highlighted
                ? TradeXColors.goldBright
                : TradeXColors.primaryText,
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _MarketNewsArtworkPainter extends CustomPainter {
  const _MarketNewsArtworkPainter(this.variant);

  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: variant.isEven
            ? const [Color(0xFF152018), Color(0xFF070A08)]
            : const [Color(0xFF261A08), Color(0xFF090806)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final grid = Paint()
      ..color = TradeXColors.gold.withValues(alpha: .12)
      ..strokeWidth = .6;
    for (var x = 0.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final chart = Path()..moveTo(0, size.height * .58);
    final points = variant % 3 == 0
        ? const [.56, .47, .52, .33, .38, .19, .27]
        : variant % 3 == 1
        ? const [.31, .42, .35, .48, .29, .21, .25]
        : const [.48, .38, .43, .26, .31, .18, .12];
    for (var index = 0; index < points.length; index++) {
      chart.lineTo(
        size.width * index / (points.length - 1),
        size.height * points[index],
      );
    }
    canvas.drawPath(
      chart,
      Paint()
        ..color = TradeXColors.goldBright.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .26),
      size.shortestSide * .12,
      Paint()..color = TradeXColors.gold.withValues(alpha: .18),
    );
  }

  @override
  bool shouldRepaint(covariant _MarketNewsArtworkPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
