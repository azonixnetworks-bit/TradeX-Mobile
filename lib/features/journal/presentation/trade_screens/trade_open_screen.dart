part of '../trade_journal_trade_screens.dart';

class TradeJournalOpenScreen extends StatefulWidget {
  const TradeJournalOpenScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepositoryContract repository;
  final TradeJournalEntry entry;

  @override
  State<TradeJournalOpenScreen> createState() => _TradeJournalOpenScreenState();
}

class _TradeJournalOpenScreenState extends State<TradeJournalOpenScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _entry;
  late final TextEditingController _sl;
  late final TextEditingController _tp;
  late final TextEditingController _position;
  late final TextEditingController _note;
  var _date = DateTime.now();
  var _time = TimeOfDay.now();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _entry = TextEditingController(
      text: widget.entry.prices['planned_entry']?.toString() ?? '',
    );
    _sl = TextEditingController(
      text: widget.entry.prices['planned_sl']?.toString() ?? '',
    );
    _tp = TextEditingController(
      text: widget.entry.prices['planned_tp']?.toString() ?? '',
    );
    _position = TextEditingController(
      text: widget.entry.risk['position_size']?.toString() ?? '',
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _entry.dispose();
    _sl.dispose();
    _tp.dispose();
    _position.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Open Trade',
    subtitle: widget.entry.symbol,
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TradeHeader(entry: widget.entry),
          const SizedBox(height: 12),
          JournalPanel(
            borderColor: TradeXColors.goldBright.withValues(alpha: .45),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: TradeXColors.goldBright,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Confirm the real execution details before opening this planned trade.',
                    style: TextStyle(color: TradeXColors.secondaryText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          JournalPanel(
            child: Column(
              children: [
                _numberField(_entry, 'Actual Entry Price', required: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Entry Date',
                        value: _dateText(_date),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.schedule_rounded,
                        label: 'Entry Time',
                        value: _timeText(_time),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _numberField(_sl, 'Current Stop Loss'),
                const SizedBox(height: 12),
                _numberField(_tp, 'Current Take Profit'),
                const SizedBox(height: 12),
                _numberField(_position, 'Position Size'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Execution Note',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          JournalPrimaryButton(
            label: 'Confirm Open Trade',
            icon: Icons.play_arrow_rounded,
            busy: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _date,
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _time);
    if (result != null) setState(() => _time = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = await widget.repository.open(widget.entry.uuid, {
        'actual_entry': double.parse(_entry.text.trim()),
        'entry_date': _dateText(_date),
        'entry_time': _timeText(_time),
        'timezone': await widget.repository.timezone(),
        if (_double(_sl) != null) 'current_sl': _double(_sl),
        if (_double(_tp) != null) 'current_tp': _double(_tp),
        if (_double(_position) != null) 'position_size': _double(_position),
        if (_note.text.trim().isNotEmpty) 'execution_note': _note.text.trim(),
      });
      if (mounted) Navigator.pop(context, result);
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}
