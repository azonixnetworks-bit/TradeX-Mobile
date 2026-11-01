part of '../trade_journal_home_screen.dart';

class TradeJournalEntriesScreen extends StatefulWidget {
  const TradeJournalEntriesScreen({
    super.key,
    required this.repository,
    this.initialFilters = const {},
  });

  final TradeJournalRepositoryContract repository;
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
