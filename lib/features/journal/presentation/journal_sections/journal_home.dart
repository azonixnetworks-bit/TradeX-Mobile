part of '../trade_journal_home_screen.dart';

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
            colors: [Color(0xFF0B1017), Color(0xFF0B1017)],
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
        color: gold ? TradeXColors.goldBright : const Color(0xFF1B2633),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gold ? TradeXColors.goldBright : const Color(0xFF293342),
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
