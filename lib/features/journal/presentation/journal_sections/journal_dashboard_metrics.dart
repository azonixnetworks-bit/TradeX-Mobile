part of '../trade_journal_dashboard_widgets.dart';

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
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: context.palette.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        borderRadius: BorderRadius.circular(12),
        dropdownColor: context.palette.surfaceRaised,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: context.palette.secondaryText,
          size: 18,
        ),
        style: TextStyle(
          color: context.palette.primaryText,
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

  final JournalData summary;
  final JournalData discipline;
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

  final JournalData summary;
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
          const SizedBox(height: TradeXSpacing.xs),
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
          const SizedBox(height: TradeXSpacing.xs),
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
                  height: TradeXSpacing.xxxl,
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

  final JournalData summary;
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
          const SizedBox(height: TradeXSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatPercent(rate),
                      key: const ValueKey('journal-win-rate'),
                      style: TextStyle(
                        color: context.palette.primaryText,
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: TradeXSpacing.xs),
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
                width: TradeXSpacing.xxl * 2,
                height: TradeXSpacing.xxl * 2,
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

  final JournalData summary;

  @override
  Widget build(BuildContext context) {
    final open = (summary['open'] as num?)?.toInt() ?? 0;
    return _DashboardCard(
      accent: _dashboardBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricHeader(
            icon: Icons.description_outlined,
            title: 'Open Trades',
            accent: _dashboardBlue,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.palette.primaryText,
            ),
          ),
          const SizedBox(height: TradeXSpacing.xs),
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
                      style: TextStyle(
                        color: context.palette.primaryText,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: TradeXSpacing.xs),
                    Text(
                      'Total Open',
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: TradeXSpacing.xxxl * 2,
                height: TradeXSpacing.xxxl,
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
        _MetricHeader(
          icon: Icons.verified_user_outlined,
          title: 'Plan Followed',
          accent: _dashboardGold,
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: context.palette.primaryText,
          ),
        ),
        const SizedBox(height: TradeXSpacing.xs),
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
                  const SizedBox(height: TradeXSpacing.xs),
                  Text(
                    reviewedCount == 0
                        ? 'No reviewed trades'
                        : '$followedCount / $reviewedCount recent reviews',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: TradeXSpacing.xxl * 2,
              height: TradeXSpacing.xxl * 2,
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Equity Curve',
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            JournalPeriodSelector(value: period, onChanged: onPeriodChanged),
          ],
        ),
        const SizedBox(height: TradeXSpacing.xxs),
        Text(
          currency == null ? 'Realized P&L' : 'Realized P&L · $currency',
          style: TextStyle(color: context.palette.secondaryText, fontSize: 10),
        ),
        const SizedBox(height: TradeXSpacing.sm),
        SizedBox(
          height: TradeXSpacing.xxxl * 2,
          child: values.isEmpty
              ? Center(
                  child: Text(
                    'Close trades with P&L to build your equity curve.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                )
              : CustomPaint(
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
