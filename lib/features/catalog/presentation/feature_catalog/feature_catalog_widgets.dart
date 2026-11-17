part of '../feature_catalog_screen.dart';

class _FeatureScaffold extends StatelessWidget {
  const _FeatureScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(child: child),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({required this.specs, required this.onOpen});

  final List<FeatureSpec> specs;
  final ValueChanged<FeatureSpec> onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: specs
              .map((spec) {
                return SizedBox(
                  width: width,
                  child: Material(
                    color: palette.surfaceRaised,
                    borderRadius: TradeXRadii.card,
                    child: InkWell(
                      borderRadius: TradeXRadii.card,
                      onTap: () => onOpen(spec),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 132),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: TradeXRadii.card,
                          border: Border.all(color: palette.border),
                          boxShadow: TradeXElevation.surface(
                            brightness: Theme.of(context).brightness,
                            palette: palette,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: palette.goldSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    spec.icon,
                                    color: palette.goldText,
                                    size: 21,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: palette.secondaryText,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              spec.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              spec.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.secondaryText,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});

  final Map<String, dynamic> record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scalars = _visibleScalars(record).take(4).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _titleFor(record),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: TradeXColors.gold,
                ),
              ],
            ),
            if (scalars.isNotEmpty) const SizedBox(height: 8),
            for (final entry in scalars)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${_label(entry.key)}: ${_display(entry.value)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.secondaryText, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ObjectPanel extends StatelessWidget {
  const _ObjectPanel({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entries = _visibleScalars(payload).toList();
    if (entries.isEmpty) {
      return const _EmptyState(
        message: 'No data is available for this account yet.',
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    _label(entries[i].key),
                    style: TextStyle(color: palette.secondaryText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Text(
                    _display(entries[i].value),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (i != entries.length - 1)
              Divider(height: 22, color: palette.border),
          ],
        ],
      ),
    );
  }
}

class _TradingRoutineView extends StatelessWidget {
  const _TradingRoutineView({
    required this.payload,
    required this.apiClient,
    required this.onEnabled,
  });

  final Map<String, dynamic> payload;
  final ApiGateway apiClient;
  final VoidCallback onEnabled;

  @override
  Widget build(BuildContext context) {
    final preference = payload['preference'];
    if (preference is Map && preference['enabled'] != true) {
      return _TradingRoutineSetup(
        payload: payload,
        apiClient: apiClient,
        onSaved: onEnabled,
      );
    }
    final sections = _routineSections(payload);
    final items = sections.expand((section) => section.$2).toList();
    final completed = items.where(_routineCompleted).length;
    final suppliedCompleted = _firstRoutineNumber(payload, const [
      'completed_count',
      'completed_steps',
      'completed',
    ]);
    final suppliedTotal = _firstRoutineNumber(payload, const [
      'total_count',
      'total_steps',
      'total',
    ]);
    final total = items.isNotEmpty ? items.length : suppliedTotal;
    final done = items.isNotEmpty ? completed : suppliedCompleted;
    final suppliedPercent = _firstRoutineNumber(payload, const [
      'completion_percent',
      'progress_percent',
      'percent',
    ]);
    final percent = suppliedPercent > 0
        ? suppliedPercent.clamp(0, 100)
        : total > 0
        ? ((done / total) * 100).round().clamp(0, 100)
        : 0;
    final streak = _firstRoutineNumber(payload, const [
      'streak_days',
      'current_streak',
      'streak',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Follow your saved daily process with discipline and consistency.',
          style: TextStyle(color: context.palette.secondaryText, height: 1.35),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _panelDecoration(context),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: context.palette.success,
                      backgroundColor: context.palette.surfaceMuted,
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Routine Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      total > 0
                          ? '$done of $total completed'
                          : 'Progress is not available yet',
                      style: TextStyle(color: context.palette.secondaryText),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 17,
                            color: context.palette.goldText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$streak day streak',
                            style: TextStyle(
                              color: context.palette.goldText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (sections.isEmpty)
          _ObjectPanel(payload: payload)
        else
          for (final section in sections) ...[
            _RoutineSectionCard(title: section.$1, items: section.$2),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _TradingRoutineSetup extends StatefulWidget {
  const _TradingRoutineSetup({
    required this.payload,
    required this.apiClient,
    required this.onSaved,
  });

  final Map<String, dynamic> payload;
  final ApiGateway apiClient;
  final VoidCallback onSaved;

  @override
  State<_TradingRoutineSetup> createState() => _TradingRoutineSetupState();
}

class _TradingRoutineSetupState extends State<_TradingRoutineSetup> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, dynamic> _preference;
  late final TextEditingController _timezone;
  late final TextEditingController _deliveryTime;
  late final TextEditingController _balance;
  late final TextEditingController _risk;
  late final TextEditingController _dailyRisk;
  late final TextEditingController _maxTrades;
  late final TextEditingController _maxLosses;
  late final TextEditingController _minimumRr;
  late final TextEditingController _focus;
  final _markets = <String>{};
  final _sessions = <String>{};
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _preference = _asStringMap(widget.payload['preference']);
    _timezone = TextEditingController(
      text: _preference['timezone']?.toString() ?? 'Asia/Colombo',
    );
    _deliveryTime = TextEditingController(
      text: _preference['delivery_time_local']?.toString() ?? '06:00',
    );
    _balance = _controller('planning_balance', 10000);
    _risk = _controller('risk_per_trade_percent', .5);
    _dailyRisk = _controller('daily_risk_cap_percent', 1);
    _maxTrades = _controller('max_trades', 3);
    _maxLosses = _controller('max_consecutive_losses', 2);
    _minimumRr = _controller('minimum_rr', 2);
    _focus = TextEditingController(
      text: _preference['focus_statement']?.toString() ?? '',
    );
    _markets.addAll(_strings(_preference['markets']));
    _sessions.addAll(_strings(_preference['sessions']));
    if (_markets.isEmpty) _markets.add('FOREX');
    if (_sessions.isEmpty) _sessions.add('LONDON');
  }

  TextEditingController _controller(String key, num fallback) =>
      TextEditingController(text: (_preference[key] ?? fallback).toString());

  @override
  void dispose() {
    for (final controller in [
      _timezone,
      _deliveryTime,
      _balance,
      _risk,
      _dailyRisk,
      _maxTrades,
      _maxLosses,
      _minimumRr,
      _focus,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set your risk limits and daily process once. TradeX will generate today’s discipline plan from these settings.',
          style: TextStyle(color: context.palette.secondaryText, height: 1.4),
        ),
        const SizedBox(height: TradeXSpacing.md),
        _setupCard(
          title: 'Account & Schedule',
          icon: Icons.schedule_rounded,
          child: Column(
            children: [
              _numberField(_balance, 'Planning balance', suffix: 'USD'),
              const SizedBox(height: TradeXSpacing.sm),
              Row(
                children: [
                  Expanded(child: _textField(_timezone, 'Timezone')),
                  const SizedBox(width: TradeXSpacing.sm),
                  Expanded(
                    child: _textField(
                      _deliveryTime,
                      'Plan time',
                      hint: '06:00',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TradeXSpacing.sm),
        _setupCard(
          title: 'Risk Guardrails',
          icon: Icons.shield_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _numberField(_risk, 'Risk / trade', suffix: '%'),
                  ),
                  const SizedBox(width: TradeXSpacing.sm),
                  Expanded(
                    child: _numberField(
                      _dailyRisk,
                      'Daily risk cap',
                      suffix: '%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TradeXSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _maxTrades,
                      'Max trades',
                      wholeNumber: true,
                    ),
                  ),
                  const SizedBox(width: TradeXSpacing.sm),
                  Expanded(
                    child: _numberField(
                      _maxLosses,
                      'Stop after losses',
                      wholeNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TradeXSpacing.sm),
              _numberField(_minimumRr, 'Minimum risk–reward', suffix: 'R'),
            ],
          ),
        ),
        const SizedBox(height: TradeXSpacing.sm),
        _setupCard(
          title: 'Markets & Sessions',
          icon: Icons.candlestick_chart_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _choiceChips(const [
                'FOREX',
                'CRYPTO',
                'COMMODITY',
                'DERIV',
                'STOCKS',
              ], _markets),
              const SizedBox(height: TradeXSpacing.sm),
              _choiceChips(const [
                'ASIA',
                'LONDON',
                'NEW_YORK',
                'CUSTOM',
              ], _sessions),
            ],
          ),
        ),
        const SizedBox(height: TradeXSpacing.sm),
        _setupCard(
          title: 'Daily Focus',
          icon: Icons.track_changes_rounded,
          child: TextFormField(
            controller: _focus,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Focus statement',
              alignLabelWithHint: true,
            ),
            validator: _required,
          ),
        ),
        const SizedBox(height: TradeXSpacing.md),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Enable Daily Trading Routine'),
        ),
        const SizedBox(height: TradeXSpacing.sm),
        Text(
          'This is a discipline and risk-planning tool. It does not provide trade signals or guarantee results.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.secondaryText, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _setupCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    padding: TradeXSpacing.card,
    decoration: _panelDecoration(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.palette.goldText),
            const SizedBox(width: TradeXSpacing.xs),
            Text(
              title,
              style: TextStyle(
                color: context.palette.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: TradeXSpacing.sm),
        child,
      ],
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: _required,
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    String? suffix,
    bool wholeNumber = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: !wholeNumber),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    validator: (value) {
      final text = value?.trim() ?? '';
      final parsed = wholeNumber ? int.tryParse(text) : double.tryParse(text);
      return parsed == null || parsed <= 0 ? 'Enter a valid value.' : null;
    },
  );

  Widget _choiceChips(List<String> values, Set<String> selected) => Wrap(
    spacing: TradeXSpacing.xs,
    runSpacing: TradeXSpacing.xs,
    children: [
      for (final value in values)
        FilterChip(
          label: Text(_label(value)),
          selected: selected.contains(value),
          onSelected: (enabled) => setState(() {
            enabled ? selected.add(value) : selected.remove(value);
          }),
        ),
    ],
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_markets.isEmpty || _sessions.isEmpty) {
      _message('Select at least one market and one session.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.apiClient.putJson('/api/v1/trading-routine/preferences', {
        'enabled': true,
        'timezone': _timezone.text.trim(),
        'delivery_time_local': _deliveryTime.text.trim(),
        'planning_balance': double.parse(_balance.text.trim()),
        'risk_per_trade_percent': double.parse(_risk.text.trim()),
        'daily_risk_cap_percent': double.parse(_dailyRisk.text.trim()),
        'max_trades': int.parse(_maxTrades.text.trim()),
        'max_consecutive_losses': int.parse(_maxLosses.text.trim()),
        'minimum_rr': double.parse(_minimumRr.text.trim()),
        'markets': _markets.toList(),
        'sessions': _sessions.toList(),
        'pre_market_checklist': _strings(_preference['pre_market_checklist']),
        'no_trade_rules': _strings(_preference['no_trade_rules']),
        'focus_statement': _focus.text.trim(),
        'whatsapp_pdf_enabled': false,
      });
      widget.onSaved();
    } catch (error) {
      _message(error is UserFacingException ? error.message : error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

Map<String, dynamic> _asStringMap(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

List<String> _strings(Object? value) => value is List
    ? value.map((item) => item.toString()).toList(growable: false)
    : const [];

class _RoutineSectionCard extends StatelessWidget {
  const _RoutineSectionCard({required this.title, required this.items});
  final String title;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _panelDecoration(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.palette.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.track_changes_rounded,
                color: context.palette.goldText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _routineCompleted(item)
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: _routineCompleted(item)
                      ? context.palette.success
                      : context.palette.secondaryText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _routineTitle(item),
                    style: TextStyle(
                      color: _routineCompleted(item)
                          ? context.palette.primaryText
                          : context.palette.secondaryText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

List<(String, List<Map<String, dynamic>>)> _routineSections(
  Map<String, dynamic> payload,
) {
  final rawSections = payload['sections'];
  if (rawSections is List) {
    final parsed = <(String, List<Map<String, dynamic>>)>[];
    for (final raw in rawSections.whereType<Map>()) {
      final section = Map<String, dynamic>.from(raw);
      final items = _routineList(section);
      if (items.isNotEmpty) {
        parsed.add((_routineTitle(section, fallback: 'Routine'), items));
      }
    }
    if (parsed.isNotEmpty) return parsed;
  }
  final direct = _routineList(payload);
  if (direct.isNotEmpty) return [('Today\'s Routine', direct)];
  return const [];
}

List<Map<String, dynamic>> _routineList(Map<String, dynamic> map) {
  for (final key in const [
    'items',
    'tasks',
    'steps',
    'checklist',
    'routines',
  ]) {
    final value = map[key];
    if (value is List) {
      final items = value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      if (items.isNotEmpty) return items;
    }
  }
  return const [];
}

String _routineTitle(
  Map<String, dynamic> item, {
  String fallback = 'Routine step',
}) {
  for (final key in const ['title', 'name', 'label', 'task', 'description']) {
    final value = item[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

bool _routineCompleted(Map<String, dynamic> item) {
  for (final key in const ['completed', 'is_completed', 'done', 'checked']) {
    final value = item[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return const {
        '1',
        'true',
        'completed',
        'done',
      }.contains(value.toLowerCase());
    }
  }
  return false;
}

int _firstRoutineNumber(Map<String, dynamic> payload, List<String> keys) {
  for (final key in keys) {
    final value = payload[key];
    if (value is num) return value.round();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  for (final nested in payload.values.whereType<Map>()) {
    final found = _firstRoutineNumber(Map<String, dynamic>.from(nested), keys);
    if (found != 0) return found;
  }
  return 0;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: TradeXColors.goldBright),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: TradeXColors.gold,
          ),
          const SizedBox(height: 12),
          Text(
            error is UserFacingException
                ? (error! as UserFacingException).message
                : 'This service is unavailable right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: _panelDecoration(context),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 38, color: TradeXColors.gold),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();
  @override
  Widget build(BuildContext context) => const _Notice(
    icon: Icons.shield_outlined,
    message: 'Values and statuses are loaded from TradeX. No transaction or broker connection is presented as successful before the backend confirms it.',
  );
}

class _FinancialNotice extends StatelessWidget {
  const _FinancialNotice();
  @override
  Widget build(BuildContext context) => const _Notice(
    icon: Icons.info_outline_rounded,
    message: 'Review amounts, destinations and status carefully. Pending does not mean paid or approved.',
  );
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({
    this.message = 'This screen is available, but submission needs a preceding account, order, or verification step. No result will be simulated.',
  });
  final String message;
  @override
  Widget build(BuildContext context) => _Notice(
    icon: Icons.link_off_rounded,
    message: message,
    color: TradeXColors.warning,
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    this.color = TradeXColors.gold,
  });
  final IconData icon;
  final String message;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _UploadPicker extends StatelessWidget {
  const _UploadPicker({
    required this.selectedFile,
    required this.onPick,
    required this.onRemove,
  });
  final PickedImage? selectedFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _panelDecoration(context),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          size: 38,
          color: TradeXColors.gold,
        ),
        const SizedBox(height: 8),
        Text(selectedFile?.name ?? 'PNG or JPEG image'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: onPick,
              child: const Text('Choose image'),
            ),
            if (selectedFile != null)
              TextButton(onPressed: onRemove, child: const Text('Remove')),
          ],
        ),
      ],
    ),
  );
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.palette.goldText,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
    ),
  );
}

class _FieldSpec {
  const _FieldSpec(
    this.name,
    this.label, {
    this.required = true,
    this.numeric = false,
    this.lines = 1,
  });
  final String name;
  final String label;
  final bool required;
  final bool numeric;
  final int lines;
}

BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
  color: context.palette.surfaceRaised,
  borderRadius: TradeXRadii.card,
  border: Border.all(color: context.palette.border),
  boxShadow: TradeXElevation.surface(
    brightness: Theme.of(context).brightness,
    palette: context.palette,
  ),
);

List<Map<String, dynamic>> _findBestRecords(Object? value) {
  if (value is List) {
    final maps = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    if (maps.isNotEmpty) return maps;
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    const preferred = [
      'items',
      'data',
      'results',
      'events',
      'notifications',
      'trade_ideas',
      'entries',
      'trades',
      'products',
      'brokers',
      'invoices',
      'payments',
      'payouts',
      'referrals',
      'sales',
      'commissions',
      'policies',
      'languages',
    ];
    for (final key in preferred) {
      final records = _findBestRecords(map[key]);
      if (records.isNotEmpty) return records;
    }
    for (final child in map.values) {
      final records = _findBestRecords(child);
      if (records.isNotEmpty) return records;
    }
  }
  return const [];
}

Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
  final data = payload['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return payload;
}

Map<String, dynamic>? _findMapNamed(Object? value, String key) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final direct = map[key];
  if (direct is Map) return Map<String, dynamic>.from(direct);
  for (final child in map.values) {
    final found = _findMapNamed(child, key);
    if (found != null) return found;
  }
  return null;
}

Iterable<MapEntry<String, dynamic>> _visibleScalars(Map<String, dynamic> map) {
  const hidden = {'id', 'uuid', 'user_id', 'created_by', 'updated_by'};
  return map.entries.where((entry) {
    if (hidden.contains(entry.key) ||
        entry.key.endsWith('_uuid') ||
        entry.value == null) {
      return false;
    }
    return entry.value is String || entry.value is num || entry.value is bool;
  });
}

String _titleFor(Map<String, dynamic> record) {
  const keys = ['title', 'name', 'symbol', 'subject', 'label', 'status'];
  for (final key in keys) {
    final value = record[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  for (final nested in record.values.whereType<Map>()) {
    final title = _titleFor(Map<String, dynamic>.from(nested));
    if (title != 'TradeX record') return title;
  }
  return 'TradeX record';
}

String? _identifier(Map<String, dynamic> record) {
  for (final key in const ['uuid', 'id', 'slug']) {
    final value = record[key]?.toString();
    if (value?.isNotEmpty == true) return value;
  }
  return null;
}

String _label(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _display(Object? value) {
  if (value is bool) return value ? 'Yes' : 'No';
  return value?.toString() ?? '—';
}

bool _supportsSearch(FeatureSpec spec) => spec.kind == FeatureKind.collection;
bool _isTradeIdea(FeatureSpec spec) => spec.id.contains('trade-idea');
bool _isNotification(FeatureSpec spec) => spec.id.contains('notification');
bool _isJournal(FeatureSpec spec) =>
    spec.id.contains('trade-journal') || spec.id.contains('trade-entry');
bool _isFinancial(FeatureSpec spec) => const {
  'copy-billing',
  'products',
  'product-details',
  'payment-method',
  'checkout',
  'payment-proof',
  'payment-history',
  'request-withdrawal',
  'withdrawal-history',
  'financial-profile',
  'commissions',
}.contains(spec.id);

bool _isSupportedMutation(String id) => const {
  'trade-entry-form',
  'request-withdrawal',
  'financial-profile',
  'preferences',
  'contact-number',
  'recovery-codes',
}.contains(id);

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;
