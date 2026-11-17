part of '../trade_journal_dashboard_widgets.dart';

class RecentTradesSection extends StatelessWidget {
  const RecentTradesSection({
    super.key,
    required this.entries,
    required this.onViewAll,
    required this.onCreate,
    required this.onEntryTap,
  });

  final List<TradeJournalEntry> entries;
  final VoidCallback onViewAll;
  final VoidCallback onCreate;
  final ValueChanged<TradeJournalEntry> onEntryTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      JournalSectionTitle(
        title: 'Recent Trades',
        subtitle: 'Latest 5 saved trade plans',
        action: 'View all ›',
        onAction: onViewAll,
      ),
      const SizedBox(height: 9),
      if (entries.isEmpty)
        _DashboardCard(
          accent: _dashboardGold,
          child: Column(
            children: [
              Icon(
                Icons.menu_book_outlined,
                color: context.palette.secondaryText,
                size: 34,
              ),
              const SizedBox(height: 9),
              Text(
                'Your first trade plan starts here.',
                style: TextStyle(color: context.palette.primaryText),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Plan a Trade'),
              ),
            ],
          ),
        )
      else
        for (final entry in entries) ...[
          RecentTradeCard(entry: entry, onTap: () => onEntryTap(entry)),
          const SizedBox(height: 9),
        ],
    ],
  );
}

class RecentTradeCard extends StatelessWidget {
  const RecentTradeCard({super.key, required this.entry, required this.onTap});

  final TradeJournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entryPrice =
        entry.prices['actual_entry'] ?? entry.prices['planned_entry'];
    final exitPrice = entry.status.toLowerCase() == 'closed'
        ? entry.prices['exit_price']
        : null;
    final riskAmount = journalNumber(entry.risk['risk_amount']);
    final riskCurrency = entry.risk['risk_currency']?.toString();
    final buying = entry.direction.toLowerCase() == 'buy';
    return Semantics(
      button: true,
      label: 'Open ${entry.symbol} trade details',
      child: _DashboardCard(
        key: ValueKey('journal-recent-${entry.uuid}'),
        accent: _dashboardBlue,
        onTap: onTap,
        minHeight: 118,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return Column(
              children: [
                Row(
                  children: [
                    SymbolAvatar(entry: entry),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.symbol,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.palette.primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              TradeDirectionBadge(direction: entry.direction),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${titleCase(entry.market)} · ${entry.sessionLabel.isEmpty ? 'No session' : entry.sessionLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.palette.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TradeStatusBadge(status: entry.status),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.palette.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _TradeValue(
                        label: 'Entry',
                        value: _displayPrice(entryPrice),
                      ),
                    ),
                    Expanded(
                      child: _TradeValue(
                        label: 'Exit',
                        value: _displayPrice(exitPrice),
                      ),
                    ),
                    if (!compact)
                      Expanded(
                        child: _TradeValue(
                          label: 'Risk Amount',
                          value: formatMoney(riskAmount, riskCurrency),
                          valueColor: buying ? _dashboardGreen : _dashboardRed,
                          alignEnd: true,
                        ),
                      ),
                  ],
                ),
                if (compact) ...[
                  const SizedBox(height: 8),
                  _TradeValue(
                    label: 'Risk Amount',
                    value: formatMoney(riskAmount, riskCurrency),
                    valueColor: buying ? _dashboardGreen : _dashboardRed,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class SymbolAvatar extends StatelessWidget {
  const SymbolAvatar({super.key, required this.entry, this.size = 46});

  final TradeJournalEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = entry.raw['logo_url']?.toString().trim();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4BD61), _dashboardGold],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _dashboardGold.withValues(alpha: .2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        _symbolLetters(entry.symbol),
        style: const TextStyle(
          color: _dashboardBackground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (logo == null || logo.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class TradeDirectionBadge extends StatelessWidget {
  const TradeDirectionBadge({super.key, required this.direction});

  final String direction;

  @override
  Widget build(BuildContext context) {
    final buying = direction.toLowerCase() == 'buy';
    return JournalBadge(
      label: buying ? 'BUY' : 'SELL',
      color: buying ? _dashboardGreen : _dashboardRed,
    );
  }
}

class TradeStatusBadge extends StatelessWidget {
  const TradeStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) =>
      JournalBadge(label: status, color: statusColor(status));
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    super.key,
    required this.child,
    required this.accent,
    this.onTap,
    this.minHeight,
  });

  final Widget child;
  final Color accent;
  final VoidCallback? onTap;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TradeXRadii.card,
        child: ConstrainedBox(
          constraints: minHeight == null
              ? const BoxConstraints()
              : BoxConstraints(minHeight: minHeight!),
          child: Ink(
            padding: const EdgeInsets.all(TradeXSpacing.sm),
            decoration: BoxDecoration(
              color: palette.surface,
              gradient: context.isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [palette.surfaceRaised, palette.surface],
                    )
                  : null,
              borderRadius: TradeXRadii.card,
              border: Border.all(color: accent.withValues(alpha: .34)),
              boxShadow: TradeXElevation.surface(
                brightness: Theme.of(context).brightness,
                palette: palette,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MetricHeader extends StatelessWidget {
  const _MetricHeader({
    required this.icon,
    required this.title,
    required this.accent,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: accent, size: 24),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.palette.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 5),
      trailing,
    ],
  );
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.palette.secondaryText, fontSize: 8.5),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: valueColor ?? context.palette.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _Donut extends StatelessWidget {
  const _Donut({required this.value, required this.color});

  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DonutPainter(value: value, color: color),
    child: Center(
      child: Text(
        value == null ? '—' : '${value!.clamp(0, 100).round()}%',
        style: TextStyle(
          color: context.palette.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final JournalQuickActionData action;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    accent: _dashboardGold,
    onTap: action.onTap,
    child: Row(
      children: [
        Icon(action.icon, color: _dashboardGold, size: 27),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.label,
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: context.palette.primaryText,
          size: 19,
        ),
      ],
    ),
  );
}

class _TradeValue extends StatelessWidget {
  const _TradeValue({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: _dashboardMuted, fontSize: 9)),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: valueColor ?? _dashboardText,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.value, required this.color});

  final double? value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = _dashboardBorder.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);
    if (value != null) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * (value!.clamp(0, 100) / 100),
        false,
        progress,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values, {required this.accent});

  final List<double> values;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(.0001, maxValue - minValue);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final point = Offset(
        size.width * index / (values.length - 1),
        size.height - ((values[index] - minValue) / range * size.height),
      );
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: .35), accent.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.accent != accent;
}

class _BarSparkPainter extends CustomPainter {
  const _BarSparkPainter(this.openCount);

  final int openCount;

  @override
  void paint(Canvas canvas, Size size) {
    const levels = [.35, .55, .48, .72, .42, .64, .79, .56, .7, .9, .68];
    final gap = size.width / (levels.length * 2 - 1);
    final barWidth = gap;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_dashboardBlue, Color(0x001262B6)],
      ).createShader(Offset.zero & size);
    for (var index = 0; index < levels.length; index++) {
      final height = size.height * levels[index];
      final left = index * gap * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, barWidth, height),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarSparkPainter oldDelegate) =>
      oldDelegate.openCount != openCount;
}

class _EquityCurvePainter extends CustomPainter {
  const _EquityCurvePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.length == 1 ? <double>[0, values.first] : values;
    final minValue = math.min(0, data.reduce(math.min));
    final maxValue = math.max(0, data.reduce(math.max));
    final range = math.max(.0001, maxValue - minValue);
    double yFor(double value) =>
        size.height - ((value - minValue) / range * size.height);

    final grid = Paint()
      ..color = _dashboardBorder.withValues(alpha: .38)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final zeroY = yFor(0);
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = _dashboardMuted.withValues(alpha: .45)
        ..strokeWidth = 1,
    );

    final points = <Offset>[];
    for (var index = 0; index < data.length; index++) {
      points.add(
        Offset(size.width * index / (data.length - 1), yFor(data[index])),
      );
    }
    final fill = Path()..moveTo(points.first.dx, zeroY);
    for (final point in points) {
      fill.lineTo(point.dx, point.dy);
    }
    fill
      ..lineTo(points.last.dx, zeroY)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x4449D6A2), Color(0x1149D6A2), Color(0x22FF7575)],
        ).createShader(Offset.zero & size),
    );
    for (var index = 1; index < points.length; index++) {
      canvas.drawLine(
        points[index - 1],
        points[index],
        Paint()
          ..color = data[index] >= 0 ? _dashboardGreen : _dashboardRed
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      points.last,
      4,
      Paint()..color = data.last >= 0 ? _dashboardGreen : _dashboardRed,
    );
  }

  @override
  bool shouldRepaint(covariant _EquityCurvePainter oldDelegate) =>
      oldDelegate.values != values;
}

String _displayPrice(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  return text.isEmpty ? '—' : text;
}

String _symbolLetters(String symbol) {
  final clean = symbol.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  return clean.isEmpty ? '?' : clean.substring(0, math.min(3, clean.length));
}
