part of '../trade_journal_home_screen.dart';

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
