import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';
import '../data/trade_journal_repository.dart';
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
  late Future<TradeJournalHome> _request;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TradeJournalRepository(widget.apiClient);
    _reload();
  }

  void _reload() => _request = _repository.home();

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Trade Journal',
    subtitle: 'Track. Learn. Improve.',
    actions: [
      IconButton(
        tooltip: 'Create trade plan',
        onPressed: _create,
        icon: const Icon(
          Icons.add_circle_rounded,
          color: TradeXColors.goldBright,
        ),
      ),
      IconButton(
        tooltip: 'Refresh journal',
        onPressed: () => setState(_reload),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: FutureBuilder<TradeJournalHome>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const JournalLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return JournalError(
            error: snapshot.error,
            onRetry: () => setState(_reload),
          );
        }
        return _content(snapshot.data!);
      },
    ),
  );

  Widget _content(TradeJournalHome home) {
    final month = home.month;
    final pnl = journalNumber(month['net_pnl']);
    final currency = month['pnl_currency']?.toString();
    final curve = <double>[];
    var running = 0.0;
    for (final entry in home.recent.reversed) {
      final net = entry.netPnl;
      if (net != null) {
        running += net;
        curve.add(running);
      }
    }
    return RefreshIndicator(
      color: TradeXColors.goldBright,
      onRefresh: () async => setState(_reload),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.48,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              JournalMetricCard(
                label: 'Net P&L',
                value: formatMoney(pnl, currency),
                icon: Icons.candlestick_chart_rounded,
                accent: (pnl ?? 0) >= 0 ? journalGreen : journalRed,
                caption: 'This month',
              ),
              JournalMetricCard(
                label: 'Win Rate',
                value: formatPercent(month['win_rate']),
                icon: Icons.track_changes_rounded,
                accent: journalGreen,
                caption:
                    '${month['wins'] ?? 0} wins · ${month['losses'] ?? 0} losses',
              ),
              JournalMetricCard(
                label: 'Open Trades',
                value: '${month['open'] ?? 0}',
                icon: Icons.receipt_long_rounded,
                accent: journalBlue,
                caption: '${month['total_executed'] ?? 0} executed',
              ),
              JournalMetricCard(
                label: 'Plan Followed',
                value: formatPercent(month['plan_followed_percent']),
                icon: Icons.verified_user_outlined,
                caption: 'Discipline score',
              ),
            ],
          ),
          const SizedBox(height: 14),
          JournalPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Equity Curve',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                JournalMiniChart(values: curve, height: 125),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _quickActions(),
          const SizedBox(height: 20),
          JournalSectionTitle(
            title: 'Recent Trades',
            subtitle: 'Latest journal activity',
            action: 'View all',
            onAction: _allTrades,
          ),
          const SizedBox(height: 9),
          if (home.recent.isEmpty)
            JournalPanel(
              child: Column(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    color: TradeXColors.secondaryText,
                    size: 34,
                  ),
                  const SizedBox(height: 9),
                  const Text('Your first trade plan starts here.'),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Plan a Trade'),
                  ),
                ],
              ),
            )
          else
            for (final entry in home.recent.take(5)) ...[
              JournalEntryCard(entry: entry, onTap: () => _details(entry)),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }

  Widget _quickActions() => Row(
    children: [
      Expanded(
        child: _QuickAction(
          icon: Icons.list_alt_rounded,
          label: 'All Trades',
          onTap: _allTrades,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.analytics_outlined,
          label: 'Analytics',
          onTap: () =>
              _push(TradeJournalAnalyticsScreen(repository: _repository)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.fact_check_outlined,
          label: 'Weekly',
          onTap: () => _push(
            TradeJournalReviewScreen(repository: _repository, type: 'weekly'),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _QuickAction(
          icon: Icons.calendar_month_outlined,
          label: 'Monthly',
          onTap: () => _push(
            TradeJournalReviewScreen(repository: _repository, type: 'monthly'),
          ),
        ),
      ),
    ],
  );

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

  Future<void> _details(TradeJournalEntry entry) async {
    await _push(
      TradeJournalDetailsScreen(repository: _repository, entry: entry),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));
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

  void _reload() => _request = widget.repository.entries(filters: _filters);

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
                  onRetry: () => setState(_reload),
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
    onRefresh: () async => setState(_reload),
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
            onRetry: () => setState(() => _meta = widget.repository.meta()),
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

  void _reload() => _request = widget.repository.entry(_currentEntry.uuid);

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
            onRetry: () => setState(_reload),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: journalPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .07)),
        ),
        child: Column(
          children: [
            Icon(icon, color: TradeXColors.goldBright, size: 21),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}
