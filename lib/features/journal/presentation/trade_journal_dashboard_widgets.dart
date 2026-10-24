import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/trade_journal_models.dart';
import 'trade_journal_ui.dart';

const _dashboardBackground = Color(0xFF020B1B);
const _dashboardSurface = Color(0xFF061A32);
const _dashboardSurfaceRaised = Color(0xFF09213D);
const _dashboardBorder = Color(0xFF225186);
const _dashboardGold = Color(0xFFFFC94D);
const _dashboardGreen = Color(0xFF00D5A5);
const _dashboardRed = Color(0xFFFF4658);
const _dashboardBlue = Color(0xFF248EFF);
const _dashboardText = Color(0xFFF5F8FF);
const _dashboardMuted = Color(0xFF9EB3D1);

class JournalPeriodSelector extends StatelessWidget {
  const JournalPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsets.only(left: 10, right: 4),
    decoration: BoxDecoration(
      color: _dashboardBackground.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _dashboardBorder.withValues(alpha: .85)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        borderRadius: BorderRadius.circular(12),
        dropdownColor: _dashboardSurfaceRaised,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _dashboardMuted,
          size: 18,
        ),
        style: const TextStyle(
          color: _dashboardText,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
        items: const [
          DropdownMenuItem(value: 'today', child: Text('Today')),
          DropdownMenuItem(value: 'week', child: Text('This Week')),
          DropdownMenuItem(value: 'month', child: Text('This Month')),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    ),
  );
}

class JournalDashboardMetricGrid extends StatelessWidget {
  const JournalDashboardMetricGrid({
    super.key,
    required this.summary,
    required this.discipline,
    required this.curve,
    required this.period,
    required this.onPeriodChanged,
    required this.reviewedCount,
    required this.followedCount,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> discipline;
  final List<double> curve;
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final int reviewedCount;
  final int followedCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 520 ? 2 : 1;
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(
            width: width,
            child: NetPnlCard(
              summary: summary,
              curve: curve,
              period: period,
              onPeriodChanged: onPeriodChanged,
            ),
          ),
          SizedBox(
            width: width,
            child: WinRateCard(
              summary: summary,
              period: period,
              onPeriodChanged: onPeriodChanged,
            ),
          ),
          SizedBox(
            width: width,
            child: OpenTradesCard(summary: summary),
          ),
          SizedBox(
            width: width,
            child: PlanFollowedCard(
              percent: journalNumber(discipline['plan_followed_percent']),
              reviewedCount: reviewedCount,
              followedCount: followedCount,
            ),
          ),
        ],
      );
    },
  );
}

class NetPnlCard extends StatelessWidget {
  const NetPnlCard({
    super.key,
    required this.summary,
    required this.curve,
    required this.period,
    required this.onPeriodChanged,
  });

  final Map<String, dynamic> summary;
  final List<double> curve;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final pnl = journalNumber(summary['net_pnl']);
    final positive = (pnl ?? 0) >= 0;
    final accent = pnl == null
        ? _dashboardMuted
        : positive
        ? _dashboardGreen
        : _dashboardRed;
    return _DashboardCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricHeader(
            icon: Icons.bar_chart_rounded,
            title: 'Net P&L',
            accent: accent,
            trailing: JournalPeriodSelector(
              value: period,
              onChanged: onPeriodChanged,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            formatMoney(pnl, summary['pnl_currency']?.toString()),
            key: const ValueKey('journal-net-pnl'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Total Trades',
                  value: '${summary['total_executed'] ?? 0}',
                ),
              ),
              Expanded(
                child: _SmallMetric(
                  label: 'Win Rate',
                  value: formatPercent(summary['win_rate']),
                  valueColor: _dashboardGreen,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: CustomPaint(
                    painter: _SparklinePainter(curve, accent: accent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WinRateCard extends StatelessWidget {
  const WinRateCard({
    super.key,
    required this.summary,
    required this.period,
    required this.onPeriodChanged,
  });

  final Map<String, dynamic> summary;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final rate = journalNumber(summary['win_rate']);
    return _DashboardCard(
      accent: _dashboardBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricHeader(
            icon: Icons.track_changes_rounded,
            title: 'Win Rate',
            accent: _dashboardGreen,
            trailing: JournalPeriodSelector(
              value: period,
              onChanged: onPeriodChanged,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatPercent(rate),
                      key: const ValueKey('journal-win-rate'),
                      style: const TextStyle(
                        color: _dashboardText,
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallMetric(
                            label: 'Wins',
                            value: '${summary['wins'] ?? 0}',
                            valueColor: _dashboardGreen,
                          ),
                        ),
                        Expanded(
                          child: _SmallMetric(
                            label: 'Losses',
                            value: '${summary['losses'] ?? 0}',
                            valueColor: _dashboardRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: _Donut(value: rate, color: _dashboardGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OpenTradesCard extends StatelessWidget {
  const OpenTradesCard({super.key, required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final open = (summary['open'] as num?)?.toInt() ?? 0;
    return _DashboardCard(
      accent: _dashboardBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MetricHeader(
            icon: Icons.description_outlined,
            title: 'Open Trades',
            accent: _dashboardBlue,
            trailing: Icon(Icons.chevron_right_rounded, color: _dashboardText),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$open',
                      key: const ValueKey('journal-open-trades'),
                      style: const TextStyle(
                        color: _dashboardText,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Total Open',
                      style: TextStyle(color: _dashboardMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 90,
                height: 60,
                child: CustomPaint(painter: _BarSparkPainter(open)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlanFollowedCard extends StatelessWidget {
  const PlanFollowedCard({
    super.key,
    required this.percent,
    required this.reviewedCount,
    required this.followedCount,
  });

  final double? percent;
  final int reviewedCount;
  final int followedCount;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    accent: _dashboardGold,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MetricHeader(
          icon: Icons.verified_user_outlined,
          title: 'Plan Followed',
          accent: _dashboardGold,
          trailing: Icon(Icons.chevron_right_rounded, color: _dashboardText),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatPercent(percent),
                    key: const ValueKey('journal-plan-followed'),
                    style: const TextStyle(
                      color: _dashboardGold,
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reviewedCount == 0
                        ? 'No reviewed trades'
                        : '$followedCount / $reviewedCount recent reviews',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _dashboardMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              height: 70,
              child: _Donut(value: percent, color: _dashboardGold),
            ),
          ],
        ),
      ],
    ),
  );
}

class EquityCurveCard extends StatelessWidget {
  const EquityCurveCard({
    super.key,
    required this.values,
    required this.currency,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<double> values;
  final String? currency;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    key: const ValueKey('journal-equity-curve'),
    accent: _dashboardBlue,
    minHeight: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Equity Curve',
                style: TextStyle(
                  color: _dashboardText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            JournalPeriodSelector(value: period, onChanged: onPeriodChanged),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currency == null ? 'Realized P&L' : 'Realized P&L · $currency',
          style: const TextStyle(color: _dashboardMuted, fontSize: 10),
        ),
        const SizedBox(height: 14),
        if (values.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Close trades with P&L to build your equity curve.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _dashboardMuted, fontSize: 12),
              ),
            ),
          )
        else
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _EquityCurvePainter(values),
            ),
          ),
      ],
    ),
  );
}

class JournalQuickActionData {
  const JournalQuickActionData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
}

class JournalQuickActions extends StatelessWidget {
  const JournalQuickActions({super.key, required this.actions});

  final List<JournalQuickActionData> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 4 : 2;
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final action in actions)
            SizedBox(
              width: width,
              child: _QuickActionCard(action: action),
            ),
        ],
      );
    },
  );
}

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
              const Icon(
                Icons.menu_book_outlined,
                color: _dashboardMuted,
                size: 34,
              ),
              const SizedBox(height: 9),
              const Text(
                'Your first trade plan starts here.',
                style: TextStyle(color: _dashboardText),
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
                                  style: const TextStyle(
                                    color: _dashboardText,
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
                            style: const TextStyle(
                              color: _dashboardMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TradeStatusBadge(status: entry.status),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _dashboardMuted,
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
          colors: [Color(0xFFFFDD6B), _dashboardGold],
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
    this.minHeight = 154,
  });

  final Widget child;
  final Color accent;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_dashboardSurfaceRaised, _dashboardSurface],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: .62)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: .08),
                blurRadius: 18,
                spreadRadius: -7,
              ),
            ],
          ),
          child: child,
        ),
      ),
    ),
  );
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
          style: const TextStyle(
            color: _dashboardText,
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
        style: const TextStyle(color: _dashboardMuted, fontSize: 8.5),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: valueColor ?? _dashboardText,
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
        style: const TextStyle(
          color: _dashboardText,
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
    minHeight: 105,
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
                style: const TextStyle(
                  color: _dashboardText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _dashboardMuted, fontSize: 9),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: _dashboardText,
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
          colors: [Color(0x4400D5A5), Color(0x1100D5A5), Color(0x22FF4658)],
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
