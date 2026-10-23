import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';
import '../data/trade_journal_repository.dart';
import 'trade_journal_ui.dart';

class TradeJournalPlanScreen extends StatefulWidget {
  const TradeJournalPlanScreen({
    super.key,
    required this.repository,
    this.entry,
  });

  final TradeJournalRepository repository;
  final TradeJournalEntry? entry;

  @override
  State<TradeJournalPlanScreen> createState() => _TradeJournalPlanScreenState();
}

class _TradeJournalPlanScreenState extends State<TradeJournalPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late Future<TradeJournalMeta> _metaRequest;
  var _market = 'crypto';
  var _direction = 'buy';
  var _status = 'planned';
  String? _stockRegion;
  String? _emotion;
  final _timeframes = <String>{};
  final _checklist = <String, String>{
    'followed_trading_plan': 'yes',
    'sl_planned': 'yes',
    'tp_planned': 'yes',
    'session_checked': 'yes',
    'news_checked': 'yes',
    'risk_checked': 'yes',
    'setup_confirmed': 'yes',
  };
  DateTime _tradeDate = DateTime.now();
  TimeOfDay _tradeTime = TimeOfDay.now();
  var _saving = false;

  static const _fields = [
    'symbol',
    'session_label',
    'broker',
    'account_label',
    'setup_strategy',
    'entry_reason',
    'notes_before',
    'planned_entry',
    'actual_entry',
    'planned_sl',
    'planned_tp',
    'position_size',
    'risk_amount',
    'risk_currency',
    'risk_percent',
    'confidence_before',
    'mental_state_note',
  ];

  bool get _editing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _metaRequest = widget.repository.meta();
    for (final name in _fields) {
      _controllers[name] = TextEditingController();
    }
    final entry = widget.entry;
    if (entry != null) {
      _market = entry.market;
      _direction = entry.direction;
      _status = entry.status;
      _stockRegion = entry.stockRegion;
      _emotion = entry.psychologyBefore['emotion']?.toString();
      _timeframes.addAll(entry.timeframes);
      _checklist.addAll(
        entry.checklist.map((key, value) => MapEntry(key, value.toString())),
      );
      _tradeDate = entry.tradeAt?.toLocal() ?? _tradeDate;
      _tradeTime = TimeOfDay.fromDateTime(_tradeDate);
      _set('symbol', entry.symbol);
      _set(
        'session_label',
        entry.sessionSource == 'manual' ? entry.sessionLabel : null,
      );
      _set('broker', entry.broker);
      _set('account_label', entry.accountLabel);
      _set('setup_strategy', entry.setupStrategy);
      _set('entry_reason', entry.entryReason);
      _set('notes_before', entry.notesBefore);
      for (final key in const [
        'planned_entry',
        'actual_entry',
        'planned_sl',
        'planned_tp',
      ]) {
        _set(key, entry.prices[key]);
      }
      for (final key in const [
        'position_size',
        'risk_amount',
        'risk_currency',
        'risk_percent',
      ]) {
        _set(key, entry.risk[key]);
      }
      _set('confidence_before', entry.psychologyBefore['confidence']);
      _set('mental_state_note', entry.psychologyBefore['note']);
    }
  }

  void _set(String name, Object? value) {
    if (value != null) _controllers[name]!.text = value.toString();
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
    title: _editing ? 'Edit Planned Trade' : 'Plan a Trade',
    subtitle: _editing
        ? 'Update your setup and risk plan'
        : 'Prepare the trade before execution',
    body: FutureBuilder<TradeJournalMeta>(
      future: _metaRequest,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const JournalLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return JournalError(
            error: snapshot.error,
            onRetry: () =>
                setState(() => _metaRequest = widget.repository.meta()),
          );
        }
        return _buildForm(snapshot.data!);
      },
    ),
  );

  Widget _buildForm(TradeJournalMeta meta) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const JournalSectionTitle(
          title: 'Trade Setup',
          subtitle: 'Market, instrument and execution direction',
        ),
        const SizedBox(height: 10),
        JournalPanel(
          child: Column(
            children: [
              _dropdown(
                label: 'Market',
                value: _market,
                values: meta.markets,
                onChanged: (value) => setState(() {
                  _market = value;
                  if (value != 'stocks') _stockRegion = null;
                }),
              ),
              if (_market == 'stocks') ...[
                const SizedBox(height: 12),
                _dropdown(
                  label: 'Stock Region',
                  value: _stockRegion,
                  values: meta.stockRegions,
                  onChanged: (value) => setState(() => _stockRegion = value),
                ),
              ],
              const SizedBox(height: 12),
              _textField('symbol', 'Symbol', required: true),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'buy',
                    label: Text('BUY'),
                    icon: Icon(Icons.trending_up_rounded),
                  ),
                  ButtonSegment(
                    value: 'sell',
                    label: Text('SELL'),
                    icon: Icon(Icons.trending_down_rounded),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (value) =>
                    setState(() => _direction = value.first),
                showSelectedIcon: false,
              ),
              if (!_editing) ...[
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'planned', label: Text('PLAN')),
                    ButtonSegment(value: 'open', label: Text('OPEN NOW')),
                  ],
                  selected: {_status},
                  onSelectionChanged: (value) =>
                      setState(() => _status = value.first),
                  showSelectedIcon: false,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const JournalSectionTitle(title: 'Timing & Session'),
        const SizedBox(height: 10),
        JournalPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Trade Date',
                      value: _date(_tradeDate),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.schedule_rounded,
                      label: 'Trade Time',
                      value: _time(_tradeTime),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _textField('session_label', 'Session (blank = automatic)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _textField('broker', 'Broker')),
                  const SizedBox(width: 10),
                  Expanded(child: _textField('account_label', 'Account')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const JournalSectionTitle(title: 'Strategy & Reason'),
        const SizedBox(height: 10),
        JournalPanel(
          child: Column(
            children: [
              _textField('setup_strategy', 'Strategy / Setup'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    for (final timeframe in meta.timeframes)
                      FilterChip(
                        label: Text(timeframe),
                        selected: _timeframes.contains(timeframe),
                        onSelected: (selected) => setState(() {
                          selected
                              ? _timeframes.add(timeframe)
                              : _timeframes.remove(timeframe);
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _textField(
                'entry_reason',
                'Entry Reason',
                required: true,
                lines: 3,
              ),
              const SizedBox(height: 12),
              _textField('notes_before', 'Notes', lines: 3),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const JournalSectionTitle(title: 'Price & Risk Plan'),
        const SizedBox(height: 10),
        JournalPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      'planned_entry',
                      'Planned Entry',
                      numeric: true,
                    ),
                  ),
                  if (_status == 'open' && !_editing) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        'actual_entry',
                        'Actual Entry',
                        required: true,
                        numeric: true,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _textField('planned_sl', 'Stop Loss', numeric: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _textField(
                      'planned_tp',
                      'Take Profit',
                      numeric: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      'position_size',
                      'Position Size',
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _textField('risk_percent', 'Risk %', numeric: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      'risk_amount',
                      'Risk Amount',
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _textField('risk_currency', 'Currency')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const JournalSectionTitle(title: 'Psychology & Checklist'),
        const SizedBox(height: 10),
        JournalPanel(
          child: Column(
            children: [
              _dropdown(
                label: 'Emotion Before',
                value: _emotion,
                values: meta.emotionsBefore,
                onChanged: (value) => setState(() => _emotion = value),
                optional: true,
              ),
              const SizedBox(height: 12),
              _textField(
                'confidence_before',
                'Confidence (1–5)',
                numeric: true,
              ),
              const SizedBox(height: 12),
              _textField('mental_state_note', 'Mental-state Note', lines: 2),
              const SizedBox(height: 10),
              for (final item in const {
                'followed_trading_plan': 'Trading plan prepared',
                'sl_planned': 'Stop loss planned',
                'tp_planned': 'Take profit planned',
                'session_checked': 'Session checked',
                'news_checked': 'News checked',
                'risk_checked': 'Risk checked',
                'setup_confirmed': 'Setup confirmed',
              }.entries)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _checklist[item.key] == 'yes',
                  onChanged: (value) => setState(
                    () => _checklist[item.key] = value ? 'yes' : 'no',
                  ),
                  title: Text(item.value),
                  activeThumbColor: journalGreen,
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        JournalPrimaryButton(
          label: _editing ? 'Update Trade Plan' : 'Save Trade Plan',
          onPressed: _save,
          busy: _saving,
        ),
      ],
    ),
  );

  Widget _textField(
    String name,
    String label, {
    bool required = false,
    bool numeric = false,
    int lines = 1,
  }) => TextFormField(
    controller: _controllers[name],
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : lines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    maxLines: lines,
    textCapitalization: name == 'symbol'
        ? TextCapitalization.characters
        : TextCapitalization.sentences,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (value) =>
              value?.trim().isEmpty == true ? '$label is required.' : null
        : null,
  );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String> onChanged,
    bool optional = false,
  }) {
    final items = <String>{...values};
    if (value?.isNotEmpty == true) items.add(value!);
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        if (optional)
          const DropdownMenuItem(value: '', child: Text('Not selected')),
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(titleCase(item))),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _tradeDate,
    );
    if (result != null) setState(() => _tradeDate = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _tradeTime,
    );
    if (result != null) setState(() => _tradeTime = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'market': _market,
        if (_market == 'stocks') 'stock_region': _stockRegion,
        'symbol': _controller('symbol').toUpperCase(),
        'direction': _direction,
        'session_label': _nullText('session_label'),
        'broker': _nullText('broker'),
        'account_label': _nullText('account_label'),
        'setup_strategy': _nullText('setup_strategy'),
        'timeframes': _timeframes.toList(growable: false),
        'entry_reason': _controller('entry_reason'),
        'notes_before': _nullText('notes_before'),
        'emotion_before': _emotion?.isEmpty == true ? null : _emotion,
        'confidence_before': _int('confidence_before'),
        'mental_state_note': _nullText('mental_state_note'),
        'checklist': _checklist,
      };
      for (final key in const [
        'planned_entry',
        'planned_sl',
        'planned_tp',
        'position_size',
        'risk_amount',
        'risk_percent',
      ]) {
        if (_number(key) != null) payload[key] = _number(key);
      }
      final riskCurrency = _nullText('risk_currency');
      if (riskCurrency != null) payload['risk_currency'] = riskCurrency;

      TradeJournalEntry saved;
      if (_editing) {
        saved = await widget.repository.update(widget.entry!.uuid, payload);
      } else {
        payload.addAll({
          'status': _status,
          'trade_date': _date(_tradeDate),
          'trade_time': _time(_tradeTime),
          'timezone': await widget.repository.timezone(),
          if (_status == 'open') 'actual_entry': _number('actual_entry'),
        });
        saved = await widget.repository.create(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The trade plan could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _controller(String name) => _controllers[name]!.text.trim();
  String? _nullText(String name) {
    final value = _controller(name);
    return value.isEmpty ? null : value;
  }

  double? _number(String name) => double.tryParse(_controller(name));
  int? _int(String name) => int.tryParse(_controller(name));

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class TradeJournalOpenScreen extends StatefulWidget {
  const TradeJournalOpenScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepository repository;
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
    } on ApiException catch (error) {
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

class TradeJournalCloseScreen extends StatefulWidget {
  const TradeJournalCloseScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepository repository;
  final TradeJournalEntry entry;

  @override
  State<TradeJournalCloseScreen> createState() =>
      _TradeJournalCloseScreenState();
}

class _TradeJournalCloseScreenState extends State<TradeJournalCloseScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<TradeJournalMeta> _metaRequest;
  final _controllers = <String, TextEditingController>{};
  var _result = 'win';
  var _followed = 'yes';
  String? _emotion;
  final _mistakes = <String>{};
  var _date = DateTime.now();
  var _time = TimeOfDay.now();
  var _rating = 4;
  var _saving = false;

  static const _fields = [
    'exit_price',
    'gross_pnl',
    'fees',
    'pnl_currency',
    'pnl_percent',
    'went_well',
    'went_wrong',
    'lesson_learned',
    'improvement_next_trade',
  ];

  @override
  void initState() {
    super.initState();
    _metaRequest = widget.repository.meta();
    for (final item in _fields) {
      _controllers[item] = TextEditingController();
    }
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
    title: 'Close Trade',
    subtitle: 'Complete execution and record your review',
    body: FutureBuilder<TradeJournalMeta>(
      future: _metaRequest,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const JournalLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return JournalError(
            error: snapshot.error,
            onRetry: () =>
                setState(() => _metaRequest = widget.repository.meta()),
          );
        }
        return _form(snapshot.data!);
      },
    ),
  );

  Widget _form(TradeJournalMeta meta) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TradeHeader(entry: widget.entry),
        const SizedBox(height: 12),
        JournalPanel(
          child: Column(
            children: [
              _number('exit_price', 'Exit Price', required: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Exit Date',
                      value: _dateText(_date),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.schedule_rounded,
                      label: 'Exit Time',
                      value: _timeText(_time),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'win', label: Text('WIN')),
                  ButtonSegment(value: 'loss', label: Text('LOSS')),
                  ButtonSegment(value: 'breakeven', label: Text('BE')),
                  ButtonSegment(value: 'partial', label: Text('PARTIAL')),
                ],
                selected: {_result},
                onSelectionChanged: (value) =>
                    setState(() => _result = value.first),
                showSelectedIcon: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        JournalPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _number('gross_pnl', 'Gross P&L')),
                  const SizedBox(width: 10),
                  Expanded(child: _number('fees', 'Fees')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _text('pnl_currency', 'P&L Currency')),
                  const SizedBox(width: 10),
                  Expanded(child: _number('pnl_percent', 'P&L %')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _emotion,
                decoration: const InputDecoration(labelText: 'Emotion After'),
                items: [
                  for (final item in meta.emotionsAfter)
                    DropdownMenuItem(value: item, child: Text(titleCase(item))),
                ],
                onChanged: (value) => setState(() => _emotion = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _followed,
                decoration: const InputDecoration(labelText: 'Followed Plan?'),
                items: [
                  for (final item in meta.followedPlanAfter)
                    DropdownMenuItem(value: item, child: Text(titleCase(item))),
                ],
                onChanged: (value) =>
                    setState(() => _followed = value ?? 'yes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const JournalSectionTitle(title: 'Mistakes & Lessons'),
        const SizedBox(height: 8),
        JournalPanel(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    for (final item in meta.mistakeTags)
                      FilterChip(
                        label: Text(titleCase(item)),
                        selected: _mistakes.contains(item),
                        onSelected: (value) => setState(() {
                          value ? _mistakes.add(item) : _mistakes.remove(item);
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _text('went_well', 'What went well?', lines: 3),
              const SizedBox(height: 12),
              _text('went_wrong', 'What went wrong?', lines: 3),
              const SizedBox(height: 12),
              _text('lesson_learned', 'Lesson learned', lines: 3),
              const SizedBox(height: 12),
              _text(
                'improvement_next_trade',
                'Improvement for next trade',
                lines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Trade Rating'),
                  const Spacer(),
                  for (var index = 1; index <= 5; index++)
                    GestureDetector(
                      onTap: () => setState(() => _rating = index),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          index <= _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: TradeXColors.goldBright,
                          size: 25,
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
          label: 'Close & Save Review',
          busy: _saving,
          onPressed: _submit,
        ),
      ],
    ),
  );

  Widget _text(String name, String label, {int lines = 1}) => TextFormField(
    controller: _controllers[name],
    maxLines: lines,
    decoration: InputDecoration(labelText: label),
  );

  Widget _number(String name, String label, {bool required = false}) =>
      TextFormField(
        controller: _controllers[name],
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) =>
                  value?.trim().isEmpty == true ? '$label is required.' : null
            : null,
      );

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: widget.entry.openedAt?.toLocal() ?? DateTime(2020),
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
      final body = <String, dynamic>{
        'exit_price': double.parse(_value('exit_price')),
        'exit_date': _dateText(_date),
        'exit_time': _timeText(_time),
        'timezone': await widget.repository.timezone(),
        'result': _result,
        'followed_plan_after': _followed,
        'mistake_tags': _mistakes.toList(growable: false),
        'rating': _rating,
        if (_emotion != null) 'emotion_after': _emotion,
      };
      for (final item in const ['gross_pnl', 'fees', 'pnl_percent']) {
        final parsed = double.tryParse(_value(item));
        if (parsed != null) body[item] = parsed;
      }
      for (final item in const [
        'pnl_currency',
        'went_well',
        'went_wrong',
        'lesson_learned',
        'improvement_next_trade',
      ]) {
        if (_value(item).isNotEmpty) body[item] = _value(item);
      }
      final result = await widget.repository.close(widget.entry.uuid, body);
      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _value(String name) => _controllers[name]!.text.trim();

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class TradeJournalScreenshotsScreen extends StatefulWidget {
  const TradeJournalScreenshotsScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepository repository;
  final TradeJournalEntry entry;

  @override
  State<TradeJournalScreenshotsScreen> createState() =>
      _TradeJournalScreenshotsScreenState();
}

class _TradeJournalScreenshotsScreenState
    extends State<TradeJournalScreenshotsScreen> {
  late TradeJournalEntry _entry;
  final _picker = ImagePicker();
  String? _workingType;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Trade Screenshots',
    subtitle: '${_entry.symbol} · private and secure',
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TradeHeader(entry: _entry),
        const SizedBox(height: 14),
        _screenshotCard(
          'before',
          'Before Trade',
          _entry.beforeScreenshotAvailable,
        ),
        const SizedBox(height: 14),
        _screenshotCard(
          'after',
          'After Trade',
          _entry.afterScreenshotAvailable,
        ),
      ],
    ),
  );

  Widget _screenshotCard(
    String type,
    String title,
    bool available,
  ) => JournalPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    type == 'before'
                        ? 'Entry overview and setup'
                        : 'Exit and final result',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const JournalBadge(label: 'Private & Secure', color: journalGreen),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 190,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF07111C),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: available
              ? FutureBuilder<Uint8List>(
                  future: widget.repository.screenshot(_entry.uuid, type),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return GestureDetector(
                        onTap: () => _preview(snapshot.data!),
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Unable to load image'));
                    }
                    return const JournalLoading();
                  },
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 38,
                        color: TradeXColors.secondaryText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type == 'after' && _entry.status != 'closed'
                            ? 'Close the trade before adding the after screenshot.'
                            : 'No screenshot added yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _workingType != null ||
                        (type == 'after' && _entry.status != 'closed')
                    ? null
                    : () => _upload(type),
                icon: _workingType == type
                    ? const SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined),
                label: Text(available ? 'Replace' : 'Upload'),
              ),
            ),
            if (available &&
                !['closed', 'cancelled'].contains(_entry.status)) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Delete screenshot',
                onPressed: _workingType == null ? () => _delete(type) : null,
                color: journalRed,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
      ],
    ),
  );

  Future<void> _upload(String type) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (file == null) return;
    setState(() => _workingType = type);
    try {
      await widget.repository.uploadScreenshot(_entry.uuid, type, file.path);
      _entry = await widget.repository.entry(_entry.uuid);
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _workingType = null);
    }
  }

  Future<void> _delete(String type) async {
    setState(() => _workingType = type);
    try {
      await widget.repository.deleteScreenshot(_entry.uuid, type);
      _entry = await widget.repository.entry(_entry.uuid);
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _workingType = null);
    }
  }

  void _preview(Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Center(child: Image.memory(bytes)),
          ),
        ),
      ),
    );
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class _TradeHeader extends StatelessWidget {
  const _TradeHeader({required this.entry});

  final TradeJournalEntry entry;

  @override
  Widget build(BuildContext context) => JournalPanel(
    borderColor: statusColor(entry.status).withValues(alpha: .35),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: TradeXColors.goldBright,
            shape: BoxShape.circle,
          ),
          child: Text(
            entry.symbol.length >= 3
                ? entry.symbol.substring(0, 3)
                : entry.symbol,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.symbol,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${titleCase(entry.market)} · ${titleCase(entry.direction)}',
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        JournalBadge(label: entry.status, color: statusColor(entry.status)),
      ],
    ),
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Ink(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF091522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: TradeXColors.secondaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _numberField(
  TextEditingController controller,
  String label, {
  bool required = false,
}) => TextFormField(
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  ),
  decoration: InputDecoration(labelText: label),
  validator: required
      ? (value) => value?.trim().isEmpty == true ? '$label is required.' : null
      : null,
);

double? _double(TextEditingController controller) =>
    double.tryParse(controller.text.trim());

String _date(DateTime value) => _dateText(value);

String _dateText(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _time(TimeOfDay value) => _timeText(value);

String _timeText(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
