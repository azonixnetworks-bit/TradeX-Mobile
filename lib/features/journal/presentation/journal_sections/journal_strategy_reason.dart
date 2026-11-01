part of '../trade_journal_strategy_section.dart';

class StrategyReasonSection extends StatelessWidget {
  const StrategyReasonSection({
    super.key,
    required this.tradeSetup,
    required this.htfTrends,
    required this.ltfTrends,
    required this.htfZones,
    required this.ltfZones,
    required this.zoneFinding,
    required this.confirmationFinding,
    required this.direction,
    required this.entryType,
    required this.entryStatus,
    required this.showEntryStatus,
    required this.strategyController,
    required this.onHtfChanged,
    required this.onLtfChanged,
    required this.onHtfZoneChanged,
    required this.onLtfZoneChanged,
    required this.onZoneChanged,
    required this.onConfirmationChanged,
    required this.onDirectionChanged,
    required this.onEntryTypeChanged,
    required this.onEntryStatusChanged,
  });

  final Widget tradeSetup;
  final Map<String, String> htfTrends;
  final Map<String, String> ltfTrends;
  final Set<String> htfZones;
  final Set<String> ltfZones;
  final Map<String, Set<String>> zoneFinding;
  final Map<String, Set<String>> confirmationFinding;
  final String? direction;
  final String entryType;
  final String entryStatus;
  final bool showEntryStatus;
  final TextEditingController strategyController;
  final void Function(String timeframe, String? trend) onHtfChanged;
  final void Function(String timeframe, String? trend) onLtfChanged;
  final ValueChanged<String> onHtfZoneChanged;
  final ValueChanged<String> onLtfZoneChanged;
  final void Function(String timeframe, String option) onZoneChanged;
  final void Function(String timeframe, String option) onConfirmationChanged;
  final ValueChanged<String?> onDirectionChanged;
  final ValueChanged<String> onEntryTypeChanged;
  final ValueChanged<String> onEntryStatusChanged;

  static const _htf = <(String, String)>[
    ('Monthly', 'MN'),
    ('Weekly', 'W1'),
    ('Daily', 'D1'),
  ];
  static const _ltf = <(String, String)>[
    ('Hour 4', 'H4'),
    ('Hour 2', 'H2'),
    ('Hour 1', 'H1'),
    ('M45', 'M45'),
  ];
  static const _zoneFrames = ['M30', 'M15', 'M10', 'M7'];
  static const _confirmationFrames = ['M5', 'M3', 'M2', 'M1', '30s'];

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('strategy-reason-section'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_strategySurfaceRaised, _strategyBackground],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _strategyBorder.withValues(alpha: .85)),
      boxShadow: [
        BoxShadow(
          color: _strategyBlue.withValues(alpha: .08),
          blurRadius: 22,
          spreadRadius: -6,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StrategyHeader(),
        const SizedBox(height: 14),
        TradeSectionCard(
          key: const ValueKey('strategy-trade-setup-card'),
          title: 'Trade Setup',
          subtitle: 'Market, symbol and execution',
          icon: Icons.tune_rounded,
          accent: _strategyGold,
          child: tradeSetup,
        ),
        const SizedBox(height: 10),
        TradeSectionCard(
          title: 'HTF Trend',
          subtitle: 'Main Trend',
          icon: Icons.trending_up_rounded,
          accent: _strategyGold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResponsiveCards(
                preferredWidth: 150,
                maxColumns: 3,
                children: [
                  for (final frame in _htf)
                    TimeframeTrendCard(
                      key: ValueKey('strategy-htf-${frame.$2}'),
                      title: frame.$1,
                      timeframe: frame.$2,
                      icon: Icons.calendar_month_rounded,
                      selected: htfTrends[frame.$2],
                      onChanged: (trend) => onHtfChanged(frame.$2, trend),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TrendZoneSelector(
                key: const ValueKey('strategy-htf-zone'),
                keyPrefix: 'strategy-htf-zone',
                options: const ['Supply / Demand', 'OB / Hidden OB', 'Wick'],
                selected: htfZones,
                onChanged: onHtfZoneChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TradeSectionCard(
          title: 'LTF Trend',
          subtitle: 'Lower Timeframe Trend',
          icon: Icons.candlestick_chart_rounded,
          accent: _strategyGold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResponsiveCards(
                preferredWidth: 150,
                maxColumns: 4,
                children: [
                  for (final frame in _ltf)
                    TimeframeTrendCard(
                      key: ValueKey('strategy-ltf-${frame.$2}'),
                      title: frame.$1,
                      timeframe: frame.$2,
                      icon: Icons.candlestick_chart_rounded,
                      selected: ltfTrends[frame.$2],
                      onChanged: (trend) => onLtfChanged(frame.$2, trend),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TrendZoneSelector(
                key: const ValueKey('strategy-ltf-zone'),
                keyPrefix: 'strategy-ltf-zone',
                options: const [
                  'Supply / Demand',
                  'OB / Hidden OB',
                  'Wick',
                  'FVG',
                  'Bank Trap Entry',
                ],
                selected: ltfZones,
                onChanged: onLtfZoneChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TradeSectionCard(
          title: 'Zone Finding',
          icon: Icons.gps_fixed_rounded,
          accent: _strategyPurple,
          child: _ResponsiveCards(
            preferredWidth: 150,
            maxColumns: 4,
            children: [
              for (final timeframe in _zoneFrames)
                ZoneFindingCard(
                  key: ValueKey('strategy-zone-$timeframe'),
                  timeframe: timeframe,
                  selected: zoneFinding[timeframe] ?? const {},
                  onChanged: (option) => onZoneChanged(timeframe, option),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TradeSectionCard(
          title: 'Confirmation Finding',
          icon: Icons.search_rounded,
          accent: _strategyCyan,
          child: _ResponsiveCards(
            preferredWidth: 150,
            maxColumns: 5,
            children: [
              for (final timeframe in _confirmationFrames)
                ConfirmationFindingCard(
                  key: ValueKey('strategy-confirmation-$timeframe'),
                  timeframe: timeframe,
                  selected: confirmationFinding[timeframe] ?? const {},
                  onChanged: (option) =>
                      onConfirmationChanged(timeframe, option),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 620;
            final directionSelector = DirectionSelector(
              value: direction,
              onChanged: onDirectionChanged,
            );
            final entrySelector = EntryTypeSelector(
              value: entryType,
              status: entryStatus,
              showStatusChoices: showEntryStatus,
              onChanged: onEntryTypeChanged,
              onStatusChanged: onEntryStatusChanged,
            );
            if (stacked) {
              return Column(
                children: [
                  directionSelector,
                  const SizedBox(height: 10),
                  entrySelector,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: directionSelector),
                const SizedBox(width: 10),
                Expanded(child: entrySelector),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        StrategySetupTextArea(controller: strategyController),
      ],
    ),
  );
}

class _StrategyHeader extends StatelessWidget {
  const _StrategyHeader();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const identity = Row(
        children: [
          _TargetIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strategy & Reason',
                  style: TextStyle(
                    color: _strategyText,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Define your analysis and setup clearly',
                  style: TextStyle(color: _strategyMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
      if (constraints.maxWidth < 410) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            identity,
            SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: _TemplateLabel()),
          ],
        );
      }
      return const Row(
        children: [
          Expanded(child: identity),
          SizedBox(width: 8),
          _TemplateLabel(),
        ],
      );
    },
  );
}

class _TargetIcon extends StatelessWidget {
  const _TargetIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFE4BD61), Color(0xFFD4AF37)],
      ),
      boxShadow: [
        BoxShadow(color: _strategyGold.withValues(alpha: .35), blurRadius: 16),
      ],
    ),
    child: const Icon(Icons.adjust_rounded, color: Color(0xFF11151B)),
  );
}

class _TemplateLabel extends StatelessWidget {
  const _TemplateLabel();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Strategy templates are not configured yet',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _strategySurface.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _strategyGold.withValues(alpha: .45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, color: _strategyGold, size: 18),
          SizedBox(width: 6),
          Text(
            'Template',
            style: TextStyle(
              color: _strategyText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
