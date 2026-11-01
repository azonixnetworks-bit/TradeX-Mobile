part of '../trade_journal_home_screen.dart';

class TradeJournalDetailsScreen extends StatefulWidget {
  const TradeJournalDetailsScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepositoryContract repository;
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
    } on UserFacingException catch (error) {
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

  JournalData? _decode() {
    try {
      final value = decodeStructuredText(entryReason.substring(_prefix.length));
      return value is Map ? JournalData.from(value) : null;
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
