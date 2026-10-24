import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';
import '../data/trade_journal_repository.dart';
import 'trade_journal_dashboard_widgets.dart';
import 'trade_journal_insights_screens.dart';
import 'trade_journal_trade_screens.dart';
import 'trade_journal_ui.dart';

class TradeJournalHomeScreen extends StatefulWidget {
  const TradeJournalHomeScreen({
    super.key,
    required this.apiClient,
    this.repository,
  });

  final TradeXApiClient apiClient;
  final TradeJournalRepository? repository;

  @override
  State<TradeJournalHomeScreen> createState() => _TradeJournalHomeScreenState();
}

class _TradeJournalHomeScreenState extends State<TradeJournalHomeScreen> {
  late final TradeJournalRepository _repository;
  late Future<({TradeJournalHome home, Map<String, dynamic> analytics})>
  _request;
  var _period = 'month';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TradeJournalRepository(widget.apiClient);
    _reload();
  }

  void _reload({bool forceRefresh = false}) {
    _request = _load(forceRefresh: forceRefresh);
  }

  Future<({TradeJournalHome home, Map<String, dynamic> analytics})> _load({
    bool forceRefresh = false,
  }) async {
    final values = await Future.wait<Object>([
      _repository.home(forceRefresh: forceRefresh),
      _repository.analytics(period: _period, forceRefresh: forceRefresh),
    ]);
    return (
      home: values[0] as TradeJournalHome,
      analytics: values[1] as Map<String, dynamic>,
    );
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Trade Journal',
    subtitle: 'Track. Learn. Improve.',
    accentLastTitleWord: true,
    actions: [
      _headerAction(
        key: const ValueKey('journal-add-trade'),
        tooltip: 'Create trade plan',
        onPressed: _create,
        icon: Icons.add_rounded,
        gold: true,
      ),
      _headerAction(
        key: const ValueKey('journal-refresh'),
        tooltip: 'Refresh journal',
        onPressed: () => setState(() => _reload(forceRefresh: true)),
        icon: Icons.refresh_rounded,
      ),
      const SizedBox(width: 7),
    ],
    body:
        FutureBuilder<
          ({TradeJournalHome home, Map<String, dynamic> analytics})
        >(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const JournalLoading();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return JournalError(
                error: snapshot.error,
                onRetry: () => setState(() => _reload(forceRefresh: true)),
              );
            }
            return _content(snapshot.data!.home, snapshot.data!.analytics);
          },
        ),
  );

  Widget _content(TradeJournalHome home, Map<String, dynamic> analytics) {
    final analyticsOverview = journalMap(analytics['overview']);
    final summary = analyticsOverview.isEmpty
        ? _homeSummary(home)
        : analyticsOverview;
    final discipline = <String, dynamic>{
      'plan_followed_percent': summary['plan_followed_percent'],
      ...journalMap(analytics['discipline']),
    };
    final curveData = _equityCurve(analytics, home);
    final reviewed = _reviewedEntries(home.recent);
    final recent =
        home.recent
            .where(
              (entry) => const {
                'planned',
                'open',
                'closed',
              }.contains(entry.status.toLowerCase()),
            )
            .toList(growable: false)
          ..sort((a, b) => _entryTime(b).compareTo(_entryTime(a)));
    return RefreshIndicator(
      color: TradeXColors.goldBright,
      onRefresh: () async => setState(() => _reload(forceRefresh: true)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF020B1B), Color(0xFF031326)],
          ),
        ),
        child: ListView(
          key: const ValueKey('journal-dashboard-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            JournalDashboardMetricGrid(
              summary: summary,
              discipline: discipline,
              curve: curveData.values,
              period: _period,
              onPeriodChanged: _selectPeriod,
              reviewedCount: reviewed.length,
              followedCount: reviewed
                  .where(
                    (entry) =>
                        entry.review['followed_plan']?.toString() == 'yes',
                  )
                  .length,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 235,
              child: EquityCurveCard(
                values: curveData.values,
                currency: curveData.currency,
                period: _period,
                onPeriodChanged: _selectPeriod,
              ),
            ),
            const SizedBox(height: 12),
            _quickActions(),
            const SizedBox(height: 20),
            RecentTradesSection(
              entries: recent.take(5).toList(growable: false),
              onViewAll: _allTrades,
              onCreate: _create,
              onEntryTap: _details,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() => JournalQuickActions(
    actions: [
      JournalQuickActionData(
        icon: Icons.list_alt_rounded,
        label: 'All Trades',
        subtitle: 'View your trading history',
        onTap: _allTrades,
      ),
      JournalQuickActionData(
        icon: Icons.analytics_outlined,
        label: 'Analytics',
        subtitle: 'Detailed performance',
        onTap: () =>
            _push(TradeJournalAnalyticsScreen(repository: _repository)),
      ),
      JournalQuickActionData(
        icon: Icons.fact_check_outlined,
        label: 'Review',
        subtitle: 'Lessons & insights',
        onTap: () => _push(
          TradeJournalReviewScreen(repository: _repository, type: 'weekly'),
        ),
      ),
      JournalQuickActionData(
        icon: Icons.calendar_month_outlined,
        label: 'Calendar',
        subtitle: 'Current month activity',
        onTap: _calendar,
      ),
    ],
  );

  Widget _headerAction({
    required Key key,
    required String tooltip,
    required VoidCallback onPressed,
    required IconData icon,
    bool gold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: gold ? TradeXColors.goldBright : const Color(0xFF09213D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gold ? TradeXColors.goldBright : const Color(0xFF225186),
        ),
        boxShadow: gold
            ? [
                BoxShadow(
                  color: TradeXColors.goldBright.withValues(alpha: .22),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: gold ? Colors.black : Colors.white, size: 22),
      ),
    ),
  );

  void _selectPeriod(String value) {
    if (_period == value) return;
    setState(() {
      _period = value;
      _reload();
    });
  }

  Map<String, dynamic> _homeSummary(TradeJournalHome home) => switch (_period) {
    'today' => home.today,
    'week' => home.week,
    _ => home.month,
  };

  ({List<double> values, String? currency}) _equityCurve(
    Map<String, dynamic> analytics,
    TradeJournalHome home,
  ) {
    final performance = journalMap(analytics['performance']);
    final curves = journalMaps(performance['equity_curves']);
    if (curves.isNotEmpty) {
      final overviewCurrency = journalMap(
        analytics['overview'],
      )['pnl_currency']?.toString();
      final selected = curves.firstWhere(
        (curve) => curve['currency']?.toString() == overviewCurrency,
        orElse: () => curves.first,
      );
      final values = journalMaps(selected['points'])
          .map((point) => journalNumber(point['cumulative_pnl']))
          .whereType<double>()
          .toList(growable: false);
      return (values: values, currency: selected['currency']?.toString());
    }

    final eligible =
        _periodEntries(home.recent)
            .where((entry) => entry.status.toLowerCase() == 'closed')
            .where((entry) => entry.netPnl != null)
            .toList(growable: false)
          ..sort((a, b) => _entryTime(a).compareTo(_entryTime(b)));
    final currencies = eligible
        .map((entry) => entry.pnlCurrency)
        .whereType<String>()
        .toList(growable: false);
    final currency = currencies.isEmpty ? null : currencies.first;
    var running = 0.0;
    final values = <double>[];
    for (final entry in eligible.where(
      (entry) => currency == null || entry.pnlCurrency == currency,
    )) {
      running += entry.netPnl!;
      values.add(running);
    }
    return (values: values, currency: currency);
  }

  List<TradeJournalEntry> _reviewedEntries(List<TradeJournalEntry> entries) =>
      _periodEntries(entries)
          .where((entry) => entry.status.toLowerCase() == 'closed')
          .where((entry) {
            final value = entry.review['followed_plan']?.toString();
            return const {'yes', 'no', 'partially'}.contains(value);
          })
          .toList(growable: false);

  Iterable<TradeJournalEntry> _periodEntries(List<TradeJournalEntry> entries) {
    final now = DateTime.now();
    return entries.where((entry) {
      final time = _entryTime(entry).toLocal();
      return switch (_period) {
        'today' =>
          time.year == now.year &&
              time.month == now.month &&
              time.day == now.day,
        'week' => !time.isBefore(
          DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1)),
        ),
        _ => time.year == now.year && time.month == now.month,
      };
    });
  }

  DateTime _entryTime(TradeJournalEntry entry) =>
      entry.openedAt ?? entry.tradeAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _create() async {
    final value = await Navigator.of(context).push<TradeJournalEntry>(
      MaterialPageRoute(
        builder: (_) => TradeJournalPlanScreen(repository: _repository),
      ),
    );
    if (value != null && mounted) setState(_reload);
  }

  Future<void> _allTrades() async {
    await _push(TradeJournalEntriesScreen(repository: _repository));
    if (mounted) setState(_reload);
  }

  Future<void> _calendar() => _push(
    TradeJournalEntriesScreen(
      repository: _repository,
      initialFilters: {
        'from': _date(DateTime(DateTime.now().year, DateTime.now().month)),
        'to': _date(DateTime.now()),
      },
    ),
  );

  Future<void> _details(TradeJournalEntry entry) async {
    await _push(
      TradeJournalDetailsScreen(repository: _repository, entry: entry),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class TradeJournalEntriesScreen extends StatefulWidget {
  const TradeJournalEntriesScreen({
    super.key,
    required this.repository,
    this.initialFilters = const {},
  });

  final TradeJournalRepository repository;
  final Map<String, String> initialFilters;

  @override
  State<TradeJournalEntriesScreen> createState() =>
      _TradeJournalEntriesScreenState();
}

class _TradeJournalEntriesScreenState extends State<TradeJournalEntriesScreen> {
  final _search = TextEditingController();
  late Map<String, String> _filters;
  late Future<TradeJournalPage> _request;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filters = {...widget.initialFilters};
    _search.text = _filters['search'] ?? '';
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload({bool forceRefresh = false}) => _request = widget.repository
      .entries(filters: _filters, forceRefresh: forceRefresh);

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'All Trades',
    subtitle: 'Search, filter and review your journal',
    actions: [
      IconButton(
        tooltip: 'Filters',
        onPressed: _openFilters,
        icon: Badge(
          isLabelVisible: _filters.entries.any(
            (item) => item.key != 'search' && item.value.isNotEmpty,
          ),
          child: const Icon(Icons.filter_alt_outlined),
        ),
      ),
      IconButton(
        tooltip: 'Plan a trade',
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
      ),
    ],
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Search symbol, setup or notes...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        _statusChips(),
        Expanded(
          child: FutureBuilder<TradeJournalPage>(
            future: _request,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const JournalLoading();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return JournalError(
                  error: snapshot.error,
                  onRetry: () => setState(() => _reload(forceRefresh: true)),
                );
              }
              return _list(snapshot.data!);
            },
          ),
        ),
      ],
    ),
  );

  Widget _statusChips() => SizedBox(
    height: 46,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final status in const [
          '',
          'planned',
          'open',
          'closed',
          'cancelled',
        ]) ...[
          ChoiceChip(
            label: Text(status.isEmpty ? 'All' : titleCase(status)),
            selected: (_filters['status'] ?? '') == status,
            onSelected: (_) => setState(() {
              if (status.isEmpty) {
                _filters.remove('status');
              } else {
                _filters['status'] = status;
              }
              _reload();
            }),
          ),
          const SizedBox(width: 7),
        ],
      ],
    ),
  );

  Widget _list(TradeJournalPage page) => RefreshIndicator(
    color: TradeXColors.goldBright,
    onRefresh: () async => setState(() => _reload(forceRefresh: true)),
    child: page.entries.isEmpty
        ? ListView(
            children: const [
              SizedBox(height: 140),
              Icon(
                Icons.search_off_rounded,
                color: TradeXColors.secondaryText,
                size: 44,
              ),
              SizedBox(height: 10),
              Center(child: Text('No matching journal trades found.')),
            ],
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            itemCount: page.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final entry = page.entries[index];
              return JournalEntryCard(
                entry: entry,
                onTap: () => _details(entry),
              );
            },
          ),
  );

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        final query = value.trim();
        query.isEmpty ? _filters.remove('search') : _filters['search'] = query;
        _reload();
      });
    });
  }

  Future<void> _openFilters() async {
    final value = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => TradeJournalFiltersScreen(
          repository: widget.repository,
          initial: _filters,
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      _filters = value;
      _search.text = value['search'] ?? '';
      _reload();
    });
  }

  Future<void> _create() async {
    final value = await Navigator.of(context).push<TradeJournalEntry>(
      MaterialPageRoute(
        builder: (_) => TradeJournalPlanScreen(repository: widget.repository),
      ),
    );
    if (value != null && mounted) setState(_reload);
  }

  Future<void> _details(TradeJournalEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TradeJournalDetailsScreen(
          repository: widget.repository,
          entry: entry,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }
}

class TradeJournalFiltersScreen extends StatefulWidget {
  const TradeJournalFiltersScreen({
    super.key,
    required this.repository,
    this.initial = const {},
  });

  final TradeJournalRepository repository;
  final Map<String, String> initial;

  @override
  State<TradeJournalFiltersScreen> createState() =>
      _TradeJournalFiltersScreenState();
}

class _TradeJournalFiltersScreenState extends State<TradeJournalFiltersScreen> {
  late Future<TradeJournalMeta> _meta;
  late Map<String, String> _values;
  late final TextEditingController _from;
  late final TextEditingController _to;
  late final TextEditingController _session;
  late final TextEditingController _setup;
  late final TextEditingController _broker;
  late final TextEditingController _account;

  @override
  void initState() {
    super.initState();
    _meta = widget.repository.meta();
    _values = {...widget.initial};
    _from = TextEditingController(text: _values['from']);
    _to = TextEditingController(text: _values['to']);
    _session = TextEditingController(text: _values['session']);
    _setup = TextEditingController(text: _values['setup']);
    _broker = TextEditingController(text: _values['broker']);
    _account = TextEditingController(text: _values['account']);
  }

  @override
  void dispose() {
    for (final controller in [
      _from,
      _to,
      _session,
      _setup,
      _broker,
      _account,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Search & Filters',
    subtitle: 'Find and analyze your trades',
    body: FutureBuilder<TradeJournalMeta>(
      future: _meta,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const JournalLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return JournalError(
            error: snapshot.error,
            onRetry: () => setState(
              () => _meta = widget.repository.meta(forceRefresh: true),
            ),
          );
        }
        return _form(snapshot.data!);
      },
    ),
  );

  Widget _form(TradeJournalMeta meta) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
    children: [
      JournalPanel(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _from,
                    readOnly: true,
                    onTap: () => _pickDate(_from),
                    decoration: const InputDecoration(
                      labelText: 'From Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _to,
                    readOnly: true,
                    onTap: () => _pickDate(_to),
                    decoration: const InputDecoration(
                      labelText: 'To Date',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _dropdown('market', 'Market', meta.markets),
            const SizedBox(height: 12),
            _dropdown('status', 'Status', meta.statuses),
            const SizedBox(height: 12),
            _dropdown('result', 'Result', meta.results),
            const SizedBox(height: 12),
            _dropdown('direction', 'Direction', meta.directions),
            const SizedBox(height: 12),
            TextField(
              controller: _session,
              decoration: const InputDecoration(
                labelText: 'Session',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _setup,
              decoration: const InputDecoration(
                labelText: 'Strategy / Setup',
                prefixIcon: Icon(Icons.account_tree_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _broker,
              decoration: const InputDecoration(
                labelText: 'Broker',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _account,
              decoration: const InputDecoration(
                labelText: 'Account',
                prefixIcon: Icon(Icons.wallet_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _dropdown('sort', 'Sort By', const [
              'newest',
              'oldest',
              'highest_pnl',
              'lowest_pnl',
              'best_rating',
            ]),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: JournalPrimaryButton(
              label: 'Apply Filters',
              icon: Icons.filter_alt_rounded,
              onPressed: _apply,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _dropdown(String key, String label, List<String> options) {
    final value = _values[key];
    return DropdownButtonFormField<String>(
      initialValue: value?.isEmpty == true ? null : value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Any')),
        for (final item in options)
          DropdownMenuItem(value: item, child: Text(titleCase(item))),
      ],
      onChanged: (next) => setState(() {
        next?.isEmpty == true ? _values.remove(key) : _values[key] = next ?? '';
      }),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final parsed = DateTime.tryParse(controller.text);
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: parsed ?? DateTime.now(),
    );
    if (result != null) {
      controller.text =
          '${result.year}-${result.month.toString().padLeft(2, '0')}-'
          '${result.day.toString().padLeft(2, '0')}';
    }
  }

  void _reset() {
    setState(() {
      final search = _values['search'];
      _values = {if (search?.isNotEmpty == true) 'search': search!};
      for (final controller in [
        _from,
        _to,
        _session,
        _setup,
        _broker,
        _account,
      ]) {
        controller.clear();
      }
    });
  }

  void _apply() {
    final result = <String, String>{..._values};
    for (final item in {
      'from': _from,
      'to': _to,
      'session': _session,
      'setup': _setup,
      'broker': _broker,
      'account': _account,
    }.entries) {
      final value = item.value.text.trim();
      value.isEmpty ? result.remove(item.key) : result[item.key] = value;
    }
    Navigator.pop(context, result);
  }
}

class TradeJournalDetailsScreen extends StatefulWidget {
  const TradeJournalDetailsScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepository repository;
  final TradeJournalEntry entry;

  @override
  State<TradeJournalDetailsScreen> createState() =>
      _TradeJournalDetailsScreenState();
}

class _TradeJournalDetailsScreenState extends State<TradeJournalDetailsScreen> {
  late Future<TradeJournalEntry> _request;
  late TradeJournalEntry _currentEntry;
  var _working = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _reload();
  }

  void _reload({bool forceRefresh = false}) => _request = widget.repository
      .entry(_currentEntry.uuid, forceRefresh: forceRefresh);

  void _showSavedEntry(TradeJournalEntry entry) {
    setState(() {
      _currentEntry = entry;
      _request = Future.value(entry);
    });
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Trade Details',
    subtitle: _currentEntry.symbol,
    actions: [
      PopupMenuButton<String>(
        onSelected: _menu,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'screenshots', child: Text('Trade Screenshots')),
          PopupMenuItem(value: 'cancel', child: Text('Cancel Planned Trade')),
          PopupMenuItem(value: 'delete', child: Text('Delete Journal Entry')),
        ],
      ),
    ],
    body: FutureBuilder<TradeJournalEntry>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const JournalLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return JournalError(
            error: snapshot.error,
            onRetry: () => setState(() => _reload(forceRefresh: true)),
          );
        }
        return _content(snapshot.data!);
      },
    ),
  );

  Widget _content(TradeJournalEntry entry) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
    children: [
      JournalPanel(
        borderColor: statusColor(entry.status).withValues(alpha: .35),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.symbol,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${titleCase(entry.market)} · ${titleCase(entry.direction)}',
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                JournalBadge(
                  label: entry.status,
                  color: statusColor(entry.status),
                ),
              ],
            ),
            const Divider(height: 24),
            JournalValueRow(
              label: 'Trade Time',
              value: formatDate(entry.openedAt ?? entry.tradeAt),
              icon: Icons.schedule_rounded,
            ),
            JournalValueRow(
              label: 'Session',
              value: entry.sessionLabel.isEmpty ? '—' : entry.sessionLabel,
              icon: Icons.public_rounded,
            ),
            JournalValueRow(
              label: 'Strategy',
              value: entry.setupStrategy ?? '—',
              icon: Icons.account_tree_outlined,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const JournalSectionTitle(title: 'Execution'),
      const SizedBox(height: 8),
      JournalPanel(
        child: Column(
          children: [
            JournalValueRow(
              label: 'Planned Entry',
              value: formatNumber(entry.prices['planned_entry'], decimals: 6),
            ),
            JournalValueRow(
              label: 'Actual Entry',
              value: formatNumber(entry.prices['actual_entry'], decimals: 6),
              valueColor: journalGreen,
            ),
            JournalValueRow(
              label: 'Stop Loss',
              value: formatNumber(
                entry.prices['current_sl'] ?? entry.prices['planned_sl'],
                decimals: 6,
              ),
              valueColor: journalRed,
            ),
            JournalValueRow(
              label: 'Take Profit',
              value: formatNumber(
                entry.prices['current_tp'] ?? entry.prices['planned_tp'],
                decimals: 6,
              ),
              valueColor: journalGreen,
            ),
            JournalValueRow(
              label: 'Exit Price',
              value: formatNumber(entry.prices['exit_price'], decimals: 6),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: JournalMetricCard(
              label: 'Planned R:R',
              value: formatNumber(entry.plannedRr),
              icon: Icons.balance_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: JournalMetricCard(
              label: 'Realized R',
              value: formatNumber(entry.realizedR),
              icon: Icons.insights_rounded,
              accent: (entry.realizedR ?? 0) >= 0 ? journalGreen : journalRed,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const JournalSectionTitle(title: 'Trade Plan'),
      const SizedBox(height: 8),
      JournalPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TradePlanSummary(entryReason: entry.entryReason),
            if (entry.notesBefore?.isNotEmpty == true) ...[
              const Divider(height: 22),
              Text(
                entry.notesBefore!,
                style: const TextStyle(color: TradeXColors.secondaryText),
              ),
            ],
            if (entry.checklist.isNotEmpty) ...[
              const Divider(height: 22),
              for (final item in entry.checklist.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.value == 'yes'
                            ? Icons.check_circle_rounded
                            : Icons.cancel_outlined,
                        size: 18,
                        color: item.value == 'yes' ? journalGreen : journalRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(titleCase(item.key))),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      if (entry.status == 'closed') ...[
        const SizedBox(height: 14),
        const JournalSectionTitle(title: 'Outcome & Review'),
        const SizedBox(height: 8),
        JournalPanel(
          child: Column(
            children: [
              JournalValueRow(
                label: 'Result',
                value: titleCase(entry.result ?? '—'),
                valueColor: entry.result == 'win' ? journalGreen : journalRed,
              ),
              JournalValueRow(
                label: 'Net P&L',
                value: formatMoney(entry.netPnl, entry.pnlCurrency),
                valueColor: (entry.netPnl ?? 0) >= 0
                    ? journalGreen
                    : journalRed,
              ),
              JournalValueRow(
                label: 'Followed Plan',
                value: titleCase(
                  entry.review['followed_plan']?.toString() ?? '—',
                ),
              ),
              JournalValueRow(
                label: 'Lesson Learned',
                value: entry.review['lesson_learned']?.toString() ?? '—',
              ),
              JournalValueRow(
                label: 'Rating',
                value: '${entry.review['rating'] ?? '—'} / 5',
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (entry.canEdit)
            OutlinedButton.icon(
              onPressed: _working ? null : () => _edit(entry),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Plan'),
            ),
          if (entry.canOpen)
            FilledButton.icon(
              onPressed: _working ? null : () => _open(entry),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Open Trade'),
            ),
          if (entry.canClose)
            FilledButton.icon(
              onPressed: _working ? null : () => _close(entry),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Close Trade'),
              style: FilledButton.styleFrom(backgroundColor: journalRed),
            ),
          OutlinedButton.icon(
            onPressed: _working ? null : () => _screenshots(entry),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Screenshots'),
          ),
        ],
      ),
    ],
  );

  Future<void> _edit(TradeJournalEntry entry) async {
    final value = await Navigator.of(context).push<TradeJournalEntry>(
      MaterialPageRoute(
        builder: (_) =>
            TradeJournalPlanScreen(repository: widget.repository, entry: entry),
      ),
    );
    if (value != null && mounted) _showSavedEntry(value);
  }

  Future<void> _open(TradeJournalEntry entry) async {
    final value = await Navigator.of(context).push<TradeJournalEntry>(
      MaterialPageRoute(
        builder: (_) =>
            TradeJournalOpenScreen(repository: widget.repository, entry: entry),
      ),
    );
    if (value != null && mounted) _showSavedEntry(value);
  }

  Future<void> _close(TradeJournalEntry entry) async {
    final value = await Navigator.of(context).push<TradeJournalEntry>(
      MaterialPageRoute(
        builder: (_) => TradeJournalCloseScreen(
          repository: widget.repository,
          entry: entry,
        ),
      ),
    );
    if (value != null && mounted) _showSavedEntry(value);
  }

  Future<void> _screenshots(TradeJournalEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TradeJournalScreenshotsScreen(
          repository: widget.repository,
          entry: entry,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _menu(String value) async {
    TradeJournalEntry entry;
    try {
      entry = await _request;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    if (value == 'screenshots') {
      await _screenshots(entry);
      return;
    }
    if (value == 'cancel' && !entry.canCancel) {
      _message('Only planned trades can be cancelled.');
      return;
    }
    if (value == 'cancel') {
      final controller = TextEditingController();
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancel planned trade?'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep Trade'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Cancel Trade'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (reason == null) return;
      await _run(() => widget.repository.cancel(entry.uuid, reason: reason));
      if (mounted) setState(_reload);
      return;
    }
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete journal entry?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _run(() => widget.repository.delete(entry.uuid));
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _working = true);
    try {
      await operation();
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class _TradePlanSummary extends StatelessWidget {
  const _TradePlanSummary({required this.entryReason});

  static const _prefix = 'TRADEX_STRATEGY_REASON_V1:';

  final String entryReason;

  @override
  Widget build(BuildContext context) {
    if (!entryReason.startsWith(_prefix)) {
      return Text(
        entryReason.isEmpty ? 'No trade plan recorded.' : entryReason,
      );
    }

    final plan = _decode();
    if (plan == null) {
      return const Text(
        'Trade plan details could not be read.',
        key: ValueKey('trade-plan-decode-error'),
        style: TextStyle(color: TradeXColors.secondaryText),
      );
    }

    final rows = <(String, String)>[];
    _add(rows, 'HTF Trend', _mapText(plan['htf']));
    _add(rows, 'HTF Zone', _listText(plan['htf_zones']));
    _add(rows, 'LTF Trend', _mapText(plan['ltf']));
    _add(rows, 'LTF Zone', _listText(plan['ltf_zones']));
    _add(rows, 'Zone Finding', _selectionText(plan['zone_finding']));
    _add(rows, 'Confirmation', _selectionText(plan['confirmation_finding']));
    _add(rows, 'Direction', _directionText(plan['direction']));
    _add(rows, 'Entry Type', _entryTypeText(plan['entry_type']));
    _add(rows, 'Strategy / Setup', _text(plan['strategy_setup']));
    _add(rows, 'Reason', _text(plan['legacy_entry_reason']));

    if (rows.isEmpty) {
      return const Text(
        'No strategy selections recorded.',
        key: ValueKey('trade-plan-empty'),
        style: TextStyle(color: TradeXColors.secondaryText),
      );
    }

    return Column(
      key: const ValueKey('trade-plan-decoded'),
      children: [
        for (final row in rows) JournalValueRow(label: row.$1, value: row.$2),
      ],
    );
  }

  Map<String, dynamic>? _decode() {
    try {
      final value = jsonDecode(entryReason.substring(_prefix.length));
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } catch (_) {
      return null;
    }
  }

  static void _add(List<(String, String)> rows, String label, String? value) {
    if (value?.isNotEmpty == true) rows.add((label, value!));
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _mapText(Object? value) {
    if (value is! Map || value.isEmpty) return null;
    final items = <String>[];
    for (final entry in value.entries) {
      final key = _text(entry.key);
      final item = _text(entry.value);
      if (key != null && item != null) {
        items.add('$key: ${titleCase(item)}');
      }
    }
    return items.isEmpty ? null : items.join(' · ');
  }

  static String? _listText(Object? value) {
    if (value is! List) return null;
    final items = value
        .map(_text)
        .whereType<String>()
        .map(titleCase)
        .toList(growable: false);
    return items.isEmpty ? null : items.join(' · ');
  }

  static String? _selectionText(Object? value) {
    if (value is! Map || value.isEmpty) return null;
    final groups = <String>[];
    for (final entry in value.entries) {
      final timeframe = _text(entry.key);
      final selections = _listText(entry.value);
      if (timeframe != null && selections != null) {
        groups.add('$timeframe: $selections');
      }
    }
    return groups.isEmpty ? null : groups.join(' · ');
  }

  static String? _directionText(Object? value) =>
      switch (_text(value)?.toUpperCase()) {
        'PRO' => 'Pro (With Trend)',
        'COUNTER' => 'Counter (Against Trend)',
        final direction? => titleCase(direction),
        null => null,
      };

  static String? _entryTypeText(Object? value) =>
      switch (_text(value)?.toLowerCase()) {
        'buy' => 'Buy / Long',
        'sell' => 'Sell / Short',
        final entryType? => titleCase(entryType),
        null => null,
      };
}
