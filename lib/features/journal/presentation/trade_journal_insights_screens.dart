import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';
import '../data/trade_journal_repository.dart';
import 'trade_journal_ui.dart';

class TradeJournalAnalyticsScreen extends StatefulWidget {
  const TradeJournalAnalyticsScreen({super.key, required this.repository});

  final TradeJournalRepository repository;

  @override
  State<TradeJournalAnalyticsScreen> createState() =>
      _TradeJournalAnalyticsScreenState();
}

class _TradeJournalAnalyticsScreenState
    extends State<TradeJournalAnalyticsScreen> {
  var _period = 'month';
  late Future<Map<String, dynamic>> _request;

  @override
  void initState() {
    super.initState();
    _request = widget.repository.analytics(period: _period);
  }

  void _select(String period, {bool forceRefresh = false}) {
    setState(() {
      _period = period;
      _request = widget.repository.analytics(
        period: period,
        forceRefresh: forceRefresh,
      );
    });
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Trade Analytics',
    subtitle: 'Analyze performance and discipline',
    actions: [
      IconButton(
        tooltip: 'Refresh analytics',
        onPressed: () => _select(_period, forceRefresh: true),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: FutureBuilder<Map<String, dynamic>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const JournalLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return JournalError(
            error: snapshot.error,
            onRetry: () => _select(_period, forceRefresh: true),
          );
        }
        return _content(snapshot.data!);
      },
    ),
  );

  Widget _content(Map<String, dynamic> data) {
    final overview = journalMap(data['overview']);
    final risk = journalMap(data['risk']);
    final performance = journalMap(data['performance']);
    final discipline = journalMap(data['discipline']);
    final curves = journalMaps(performance['equity_curves']);
    final points = curves.isEmpty
        ? const <Map<String, dynamic>>[]
        : journalMaps(curves.first['points']);
    final values = points
        .map((point) => journalNumber(point['cumulative_pnl']))
        .whereType<double>()
        .toList(growable: false);
    final sessions = journalMaps(data['sessions']);
    final symbols = journalMaps(data['symbols']);
    final currency = overview['pnl_currency']?.toString();
    return RefreshIndicator(
      color: TradeXColors.goldBright,
      onRefresh: () async => _select(_period, forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('7D')),
                ButtonSegment(value: 'month', label: Text('30D')),
                ButtonSegment(value: '3months', label: Text('3M')),
                ButtonSegment(value: '6months', label: Text('6M')),
                ButtonSegment(value: 'year', label: Text('1Y')),
              ],
              selected: {_period},
              onSelectionChanged: (value) => _select(value.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              JournalMetricCard(
                label: 'Net P&L',
                value: formatMoney(
                  journalNumber(overview['net_pnl']),
                  currency,
                ),
                icon: Icons.payments_outlined,
                accent: (journalNumber(overview['net_pnl']) ?? 0) >= 0
                    ? journalGreen
                    : journalRed,
              ),
              JournalMetricCard(
                label: 'Win Rate',
                value: formatPercent(overview['win_rate']),
                icon: Icons.track_changes_rounded,
                accent: journalGreen,
              ),
              JournalMetricCard(
                label: 'Profit Factor',
                value: formatNumber(performance['profit_factor']),
                icon: Icons.insights_rounded,
                accent: journalBlue,
              ),
              JournalMetricCard(
                label: 'Average R',
                value: formatNumber(risk['average_realized_r']),
                icon: Icons.balance_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          JournalPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Equity Curve',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      currency ?? 'By currency',
                      style: const TextStyle(
                        color: TradeXColors.goldBright,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                JournalMiniChart(values: values),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const JournalSectionTitle(title: 'Performance Snapshot'),
          const SizedBox(height: 9),
          JournalPanel(
            child: Column(
              children: [
                JournalValueRow(
                  label: 'Executed Trades',
                  value: '${overview['total_executed'] ?? 0}',
                ),
                JournalValueRow(
                  label: 'Wins / Losses',
                  value:
                      '${overview['wins'] ?? 0} / ${overview['losses'] ?? 0}',
                ),
                JournalValueRow(
                  label: 'Average Win',
                  value: formatMoney(
                    journalNumber(performance['average_win']),
                    currency,
                  ),
                  valueColor: journalGreen,
                ),
                JournalValueRow(
                  label: 'Average Loss',
                  value: formatMoney(
                    journalNumber(performance['average_loss']),
                    currency,
                  ),
                  valueColor: journalRed,
                ),
                JournalValueRow(
                  label: 'Max Win Streak',
                  value: '${performance['max_win_streak'] ?? 0}',
                ),
                JournalValueRow(
                  label: 'Max Loss Streak',
                  value: '${performance['max_loss_streak'] ?? 0}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ranking('Performance by Session', sessions),
          const SizedBox(height: 14),
          _ranking('Performance by Symbol', symbols),
          const SizedBox(height: 18),
          const JournalSectionTitle(title: 'Discipline'),
          const SizedBox(height: 9),
          JournalPanel(
            child: Column(
              children: [
                JournalValueRow(
                  label: 'Plan Followed',
                  value: formatPercent(discipline['plan_followed_percent']),
                ),
                JournalValueRow(
                  label: 'Session Checked',
                  value: formatPercent(discipline['session_checked_percent']),
                ),
                JournalValueRow(
                  label: 'News Checked',
                  value: formatPercent(discipline['news_checked_percent']),
                ),
                JournalValueRow(
                  label: 'Risk Checked',
                  value: formatPercent(discipline['risk_checked_percent']),
                ),
                JournalValueRow(
                  label: 'Most Common Mistake',
                  value: titleCase(
                    discipline['most_common_mistake']?.toString() ?? 'None',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ranking(String title, List<Map<String, dynamic>> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      JournalSectionTitle(title: title),
      const SizedBox(height: 9),
      JournalPanel(
        child: rows.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'Complete more trades to unlock this breakdown.',
                    style: TextStyle(color: TradeXColors.secondaryText),
                  ),
                ),
              )
            : Column(
                children: [
                  for (final row in rows.take(6))
                    JournalValueRow(
                      label: titleCase(row['key']?.toString() ?? 'Other'),
                      value:
                          '${row['trades'] ?? 0} trades · ${formatPercent(row['win_rate'])}',
                      valueColor: journalGreen,
                    ),
                ],
              ),
      ),
    ],
  );
}

class TradeJournalReviewScreen extends StatefulWidget {
  const TradeJournalReviewScreen({
    super.key,
    required this.repository,
    required this.type,
  }) : assert(type == 'weekly' || type == 'monthly');

  final TradeJournalRepository repository;
  final String type;

  @override
  State<TradeJournalReviewScreen> createState() =>
      _TradeJournalReviewScreenState();
}

class _TradeJournalReviewScreenState extends State<TradeJournalReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late Future<Map<String, dynamic>> _request;
  DateTime _anchor = DateTime.now();
  var _rating = 4;
  var _saving = false;

  bool get _monthly => widget.type == 'monthly';

  List<String> get _fields => [
    'positive_reflection',
    'negative_reflection',
    'biggest_lesson',
    if (_monthly) ...[
      'biggest_achievement',
      'biggest_weakness',
      'habit_to_remove',
      'habit_to_continue',
    ] else ...[
      'stop_doing',
      'continue_doing',
    ],
    'next_focus',
  ];

  @override
  void initState() {
    super.initState();
    for (final item in _fields) {
      _controllers[item] = TextEditingController();
    }
    _load();
  }

  void _load({bool forceRefresh = false}) {
    _request = widget.repository.review(
      widget.type,
      date: _anchor,
      forceRefresh: forceRefresh,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: _monthly ? 'Monthly Review' : 'Weekly Review',
    subtitle: 'Reflect, learn and set your next focus',
    actions: [
      IconButton(
        tooltip: 'Choose review date',
        onPressed: _pickAnchor,
        icon: const Icon(Icons.calendar_month_rounded),
      ),
    ],
    body: FutureBuilder<Map<String, dynamic>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const JournalLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return JournalError(
            error: snapshot.error,
            onRetry: () => setState(() => _load(forceRefresh: true)),
          );
        }
        _seed(snapshot.data!);
        return _form(snapshot.data!);
      },
    ),
  );

  void _seed(Map<String, dynamic> data) {
    final review = journalMap(data['review']);
    if (review.isEmpty) return;
    for (final item in _fields) {
      if (_controllers[item]!.text.isEmpty && review[item] != null) {
        _controllers[item]!.text = review[item].toString();
      }
    }
    final rating = (review['rating'] as num?)?.toInt();
    if (rating != null) _rating = rating;
  }

  Widget _form(Map<String, dynamic> data) {
    final summary = journalMap(data['summary']);
    final range = '${data['period_start'] ?? ''} – ${data['period_end'] ?? ''}';
    final pnl = journalNumber(summary['net_pnl']);
    final currency = summary['pnl_currency']?.toString();
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          JournalPanel(
            borderColor: TradeXColors.goldBright.withValues(alpha: .32),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: TradeXColors.goldBright,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        range,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _summaryValue(
                        'Net P&L',
                        formatMoney(pnl, currency),
                        (pnl ?? 0) >= 0 ? journalGreen : journalRed,
                      ),
                    ),
                    Expanded(
                      child: _summaryValue(
                        'Win Rate',
                        formatPercent(summary['win_rate']),
                        journalGreen,
                      ),
                    ),
                    Expanded(
                      child: _summaryValue(
                        'Trades',
                        '${summary['total_executed'] ?? 0}',
                        journalBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_monthly) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _weekCard(
                    'Best Week',
                    summary['best_week'],
                    journalGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _weekCard(
                    'Worst Week',
                    summary['worst_week'],
                    journalRed,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          JournalPanel(
            child: Column(
              children: [
                for (var index = 0; index < _fields.length; index++) ...[
                  TextFormField(
                    controller: _controllers[_fields[index]],
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: titleCase(_fields[index]),
                      prefixIcon: Icon(_fieldIcon(_fields[index])),
                    ),
                  ),
                  if (index < _fields.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Review Rating'),
                    const Spacer(),
                    for (var index = 1; index <= 5; index++)
                      GestureDetector(
                        onTap: () => setState(() => _rating = index),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            index <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: TradeXColors.goldBright,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          JournalPrimaryButton(
            label: _monthly ? 'Save Monthly Review' : 'Save Weekly Review',
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _summaryValue(String label, String value, Color color) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(color: TradeXColors.secondaryText, fontSize: 10),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    ],
  );

  Widget _weekCard(String title, Object? raw, Color color) {
    final row = journalMap(raw);
    return JournalPanel(
      borderColor: color.withValues(alpha: .3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            row.isEmpty ? '—' : row['period']?.toString() ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            formatMoney(
              journalNumber(row['net_pnl']),
              row['currency']?.toString(),
            ),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  IconData _fieldIcon(String field) => switch (field) {
    'positive_reflection' => Icons.wb_sunny_outlined,
    'negative_reflection' => Icons.warning_amber_rounded,
    'biggest_lesson' => Icons.menu_book_rounded,
    'biggest_achievement' => Icons.emoji_events_outlined,
    'biggest_weakness' => Icons.trending_down_rounded,
    'habit_to_remove' || 'stop_doing' => Icons.remove_circle_outline_rounded,
    'habit_to_continue' ||
    'continue_doing' => Icons.check_circle_outline_rounded,
    _ => Icons.flag_outlined,
  };

  Future<void> _pickAnchor() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (value == null) return;
    for (final controller in _controllers.values) {
      controller.clear();
    }
    setState(() {
      _anchor = value;
      _load();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        for (final item in _fields)
          if (_controllers[item]!.text.trim().isNotEmpty)
            item: _controllers[item]!.text.trim(),
        'rating': _rating,
      };
      await widget.repository.saveReview(widget.type, body, date: _anchor);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_monthly ? 'Monthly' : 'Weekly'} review saved.'),
        ),
      );
      setState(_load);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
