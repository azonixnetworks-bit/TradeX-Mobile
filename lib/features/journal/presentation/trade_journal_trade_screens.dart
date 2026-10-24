import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';
import '../data/trade_journal_repository.dart';
import 'trade_journal_close_sections.dart';
import 'trade_journal_risk_psychology_sections.dart';
import 'trade_journal_strategy_section.dart';
import 'trade_journal_ui.dart';

const _strategyReasonPrefix = 'TRADEX_STRATEGY_REASON_V1:';

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
  var _session = 'asia';
  Map<String, String> _htfTrends = const {};
  Map<String, String> _ltfTrends = const {};
  Set<String> _htfZones = const {};
  Set<String> _ltfZones = const {};
  Map<String, Set<String>> _zoneFinding = const {};
  Map<String, Set<String>> _confirmationFinding = const {};
  String? _strategyDirection;
  String? _legacyEntryReason;
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
  Timer? _symbolDebounce;
  Timer? _livePriceTimer;
  List<TradeJournalSymbolSuggestion> _symbolSuggestions = const [];
  double? _selectedSymbolPrice;
  var _livePriceLoading = false;
  var _symbolLoading = false;
  var _symbolLookupFailed = false;
  var _selectingSymbol = false;
  var _updatingPricePlan = false;
  var _symbolRequestId = 0;
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
    _controllers['risk_currency']!.text = 'USD';
    final entry = widget.entry;
    if (entry != null) {
      _market = entry.market;
      _direction = entry.direction;
      _status = entry.status;
      _session = _sessionChoice(entry.sessionLabel);
      _stockRegion = entry.stockRegion;
      _emotion = entry.psychologyBefore['emotion']?.toString();
      _timeframes.addAll(entry.timeframes);
      _checklist.addAll(
        entry.checklist.map((key, value) => MapEntry(key, value.toString())),
      );
      _tradeDate = entry.tradeAt?.toLocal() ?? _tradeDate;
      _tradeTime = TimeOfDay.fromDateTime(_tradeDate);
      _set('symbol', entry.symbol);
      if (_session == 'other') _set('session_label', entry.sessionLabel);
      _set('broker', entry.broker);
      _set('account_label', entry.accountLabel);
      _set('setup_strategy', entry.setupStrategy);
      _set('entry_reason', entry.entryReason);
      _restoreStrategyReason(entry.entryReason);
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
    _controllers['symbol']!.addListener(_onSymbolChanged);
    _controllers['planned_entry']!.addListener(_onPlannedEntryChanged);
    if (_controllers['symbol']!.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startLivePriceTracking();
      });
    }
  }

  void _set(String name, Object? value) {
    if (value != null) _controllers[name]!.text = value.toString();
  }

  @override
  void dispose() {
    _symbolDebounce?.cancel();
    _livePriceTimer?.cancel();
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
            onRetry: () => setState(
              () => _metaRequest = widget.repository.meta(forceRefresh: true),
            ),
          );
        }
        return _buildForm(snapshot.data!);
      },
    ),
  );

  Widget _buildForm(TradeJournalMeta meta) => Form(
    key: _formKey,
    child: ListView(
      key: const ValueKey('trade-plan-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const JournalSectionTitle(title: 'Timing & Session'),
        const SizedBox(height: 10),
        JournalPanel(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      key: const ValueKey('trade-time-picker'),
                      icon: Icons.schedule_rounded,
                      label: 'Trade Time',
                      value: MaterialLocalizations.of(context)
                          .formatTimeOfDay(_tradeTime),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const ValueKey('trade-time-now'),
                  onPressed: () => setState(() {
                    final now = DateTime.now();
                    _tradeTime = TimeOfDay.fromDateTime(now);
                  }),
                  icon: const Icon(Icons.bolt_rounded, size: 17),
                  label: const Text('Use current time'),
                ),
              ),
              _dropdown(
                key: const ValueKey('trade-session-dropdown'),
                label: 'Session',
                value: _session,
                values: const ['asia', 'london', 'new_york', 'other'],
                onChanged: (value) => setState(() {
                  _session = value;
                  if (value != 'other') {
                    _controllers['session_label']!.clear();
                  }
                }),
              ),
              if (_session == 'other') ...[
                const SizedBox(height: 12),
                _textField('session_label', 'Other Session (Optional)'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        StrategyReasonSection(
          tradeSetup: _tradeSetupFields(meta),
          htfTrends: _htfTrends,
          ltfTrends: _ltfTrends,
          htfZones: _htfZones,
          ltfZones: _ltfZones,
          zoneFinding: _zoneFinding,
          confirmationFinding: _confirmationFinding,
          direction: _strategyDirection,
          entryType: _direction,
          entryStatus: _status,
          showEntryStatus: !_editing,
          strategyController: _controllers['setup_strategy']!,
          onHtfChanged: (timeframe, trend) =>
              _setTrend(htf: true, timeframe: timeframe, trend: trend),
          onLtfChanged: (timeframe, trend) =>
              _setTrend(htf: false, timeframe: timeframe, trend: trend),
          onHtfZoneChanged: (option) =>
              _toggleTrendZone(htf: true, option: option),
          onLtfZoneChanged: (option) =>
              _toggleTrendZone(htf: false, option: option),
          onZoneChanged: (timeframe, option) => _toggleFinding(
            confirmation: false,
            timeframe: timeframe,
            option: option,
          ),
          onConfirmationChanged: (timeframe, option) => _toggleFinding(
            confirmation: true,
            timeframe: timeframe,
            option: option,
          ),
          onDirectionChanged: (value) =>
              setState(() => _strategyDirection = value),
          onEntryTypeChanged: _changeEntryType,
          onEntryStatusChanged: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 18),
        PriceRiskPlanSection(
          plannedEntryController: _controllers['planned_entry']!,
          stopLossController: _controllers['planned_sl']!,
          takeProfitController: _controllers['planned_tp']!,
          riskAmountController: _controllers['risk_amount']!,
          direction: _direction,
          symbol: _controller('symbol'),
          livePrice: _selectedSymbolPrice,
          livePriceLoading: _livePriceLoading,
          entryRequired: _status == 'open',
          onUseLivePrice: _selectedSymbolPrice == null
              ? null
              : _applyLivePricePlan,
        ),
        const SizedBox(height: 18),
        PsychologyChecklistSection(
          emotion: _emotion,
          emotions: meta.emotionsBefore,
          confidence: _int('confidence_before'),
          mentalStateController: _controllers['mental_state_note']!,
          checklist: _checklist,
          onEmotionChanged: (value) => setState(() => _emotion = value),
          onConfidenceChanged: (value) => setState(
            () => _controllers['confidence_before']!.text = '$value',
          ),
          onChecklistChanged: (key, selected) =>
              setState(() => _checklist[key] = selected ? 'yes' : 'no'),
        ),
        const SizedBox(height: 18),
        SaveTradeButton(
          label: _editing ? 'Update Trade Plan' : 'Save Trade',
          onPressed: () => _save(meta),
          busy: _saving,
        ),
      ],
    ),
  );

  Widget _tradeSetupFields(TradeJournalMeta meta) => Column(
    children: [
      _dropdown(
        label: 'Market',
        value: _market,
        values: meta.markets,
        onChanged: (value) => setState(() {
          _market = value;
          if (value != 'stocks') _stockRegion = null;
          _symbolDebounce?.cancel();
          _symbolRequestId++;
          _selectingSymbol = true;
          _controllers['symbol']!.clear();
          _selectingSymbol = false;
          _symbolSuggestions = const [];
          _symbolLoading = false;
          _symbolLookupFailed = false;
          _selectedSymbolPrice = null;
          _livePriceLoading = false;
          _livePriceTimer?.cancel();
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
      _symbolField(),
    ],
  );

  void _onSymbolChanged() {
    if (_selectingSymbol) return;
    _symbolDebounce?.cancel();
    _livePriceTimer?.cancel();
    final query = _controllers['symbol']!.text.trim();
    final requestId = ++_symbolRequestId;
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _symbolSuggestions = const [];
          _symbolLoading = false;
          _symbolLookupFailed = false;
          _selectedSymbolPrice = null;
          _livePriceLoading = false;
        });
      }
      return;
    }
    setState(() {
      _symbolSuggestions = const [];
      _symbolLoading = true;
      _symbolLookupFailed = false;
      _selectedSymbolPrice = null;
      _livePriceLoading = false;
    });
    _symbolDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final suggestions = await widget.repository.symbolSuggestions(
          market: _market,
          search: query,
          stockRegion: _stockRegion,
        );
        if (!mounted || requestId != _symbolRequestId) return;
        setState(() {
          _symbolSuggestions = suggestions.take(6).toList(growable: false);
          _symbolLoading = false;
        });
      } catch (_) {
        if (!mounted || requestId != _symbolRequestId) return;
        setState(() {
          _symbolSuggestions = const [];
          _symbolLoading = false;
          _symbolLookupFailed = true;
        });
      }
    });
  }

  Widget _symbolField() {
    final query = _controllers['symbol']!.text.trim();
    final showEmpty =
        query.isNotEmpty &&
        !_symbolLoading &&
        !_symbolLookupFailed &&
        _symbolSuggestions.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const ValueKey('trade-symbol-field'),
          controller: _controllers['symbol'],
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Symbol',
            hintText: _symbolHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _symbolLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Symbol is required.' : null,
        ),
        if (_symbolSuggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            key: const ValueKey('trade-symbol-suggestions'),
            decoration: BoxDecoration(
              color: journalPanelRaised,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: .1)),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < _symbolSuggestions.length;
                  index++
                ) ...[
                  _symbolSuggestionTile(_symbolSuggestions[index]),
                  if (index < _symbolSuggestions.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: .07),
                    ),
                ],
              ],
            ),
          ),
        ] else if (_symbolLookupFailed || showEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _symbolLookupFailed
                  ? 'Suggestions unavailable. You can enter the symbol manually.'
                  : 'No matching symbol found. You can still enter it manually.',
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String get _symbolHint => switch (_market) {
    'forex' => 'Search EURUSD, GBPUSD…',
    'crypto' => 'Search BTCUSDT, ETHUSDT…',
    'deriv' => 'Search Volatility, Boom, Crash…',
    'stocks' => 'Search stock name or symbol…',
    _ => 'Search symbol…',
  };

  Widget _symbolSuggestionTile(TradeJournalSymbolSuggestion suggestion) =>
      InkWell(
        key: ValueKey('trade-symbol-${suggestion.symbol}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _symbolDebounce?.cancel();
          _symbolRequestId++;
          _selectingSymbol = true;
          _controllers['symbol']!.value = TextEditingValue(
            text: suggestion.symbol,
            selection: TextSelection.collapsed(
              offset: suggestion.symbol.length,
            ),
          );
          _selectingSymbol = false;
          FocusScope.of(context).unfocus();
          setState(() {
            _symbolSuggestions = const [];
            _symbolLoading = false;
            _symbolLookupFailed = false;
            _selectedSymbolPrice = suggestion.price;
            _livePriceLoading = suggestion.price == null;
          });
          _startLivePriceTracking();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TradeXColors.goldBright.withValues(alpha: .12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TradeXColors.goldBright.withValues(alpha: .32),
                  ),
                ),
                child: Text(
                  suggestion.symbol.length > 3
                      ? suggestion.symbol.substring(0, 3)
                      : suggestion.symbol,
                  style: const TextStyle(
                    color: TradeXColors.goldBright,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.symbol,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (suggestion.name.isNotEmpty)
                      Text(
                        suggestion.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.north_west_rounded,
                color: TradeXColors.secondaryText,
                size: 17,
              ),
            ],
          ),
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
    Key? key,
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String> onChanged,
    bool optional = false,
  }) {
    final items = <String>{...values};
    if (value?.isNotEmpty == true) items.add(value!);
    return DropdownButtonFormField<String>(
      key: key,
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

  void _startLivePriceTracking() {
    _livePriceTimer?.cancel();
    final symbol = _controller('symbol').toUpperCase();
    if (symbol.isEmpty) return;
    unawaited(_refreshSelectedSymbolPrice(showLoading: true));
    _livePriceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_refreshSelectedSymbolPrice()),
    );
  }

  Future<void> _refreshSelectedSymbolPrice({bool showLoading = false}) async {
    final symbol = _controller('symbol').toUpperCase();
    if (symbol.isEmpty) return;
    if (showLoading && mounted && _selectedSymbolPrice == null) {
      setState(() => _livePriceLoading = true);
    }
    try {
      final price = await widget.repository.livePrice(
        market: _market,
        symbol: symbol,
        stockRegion: _stockRegion,
      );
      if (!mounted || _controller('symbol').toUpperCase() != symbol) return;
      setState(() {
        _selectedSymbolPrice = price;
        _livePriceLoading = false;
      });
    } catch (_) {
      if (!mounted || _controller('symbol').toUpperCase() != symbol) return;
      setState(() => _livePriceLoading = false);
    }
  }

  void _applyLivePricePlan() {
    final entry = _selectedSymbolPrice;
    if (entry == null || entry <= 0) return;
    _applyDefaultRiskPlan(entry, includeEntry: true);
  }

  void _onPlannedEntryChanged() {
    if (_updatingPricePlan || !mounted) return;
    final entry = double.tryParse(_controller('planned_entry'));
    if (entry == null || entry <= 0) return;
    _applyDefaultRiskPlan(entry);
  }

  void _changeEntryType(String value) {
    setState(() => _direction = value);
    final entry = double.tryParse(_controller('planned_entry'));
    if (entry != null && entry > 0) _applyDefaultRiskPlan(entry);
  }

  void _applyDefaultRiskPlan(double entry, {bool includeEntry = false}) {
    final pipSize = _defaultPipSize(entry);
    final riskDistance = pipSize * 10;
    final rewardDistance = riskDistance * 5;
    final buy = _direction.toLowerCase() != 'sell';
    final stopLoss = buy ? entry - riskDistance : entry + riskDistance;
    final takeProfit = buy ? entry + rewardDistance : entry - rewardDistance;
    if (stopLoss <= 0 || takeProfit <= 0) return;
    final decimals = _pipDecimals(pipSize);

    _updatingPricePlan = true;
    try {
      setState(() {
        if (includeEntry) {
          _setPriceController('planned_entry', entry, decimals);
        }
        _setPriceController('planned_sl', stopLoss, decimals);
        _setPriceController('planned_tp', takeProfit, decimals);
      });
    } finally {
      _updatingPricePlan = false;
    }
  }

  double _defaultPipSize(double price) {
    final symbol = _controller('symbol').toUpperCase();
    if (_market == 'forex') return symbol.contains('JPY') ? .01 : .0001;
    if (_market == 'crypto') {
      if (price >= 1) return .01;
      if (price >= .01) return .0001;
      if (price >= .0001) return .000001;
      return .00000001;
    }
    return price >= 1 ? .01 : .0001;
  }

  int _pipDecimals(double pipSize) {
    if (pipSize >= .01) return 2;
    if (pipSize >= .0001) return 4;
    if (pipSize >= .000001) return 6;
    return 8;
  }

  void _setPriceController(String name, double value, int decimals) {
    final controller = _controllers[name]!;
    controller.text = value.toStringAsFixed(decimals);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
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

  Future<void> _save(TradeJournalMeta meta) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'market': _market,
        if (_market == 'stocks') 'stock_region': _stockRegion,
        'symbol': _controller('symbol').toUpperCase(),
        'direction': _direction,
        'session_label': _selectedSessionLabel,
        'broker': _nullText('broker'),
        'account_label': _nullText('account_label'),
        'setup_strategy': _backendSetupStrategy,
        'timeframes': _persistedTimeframes(meta),
        'entry_reason': _strategyReasonPayload,
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
          if (_status == 'open') 'actual_entry': _number('planned_entry'),
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

  void _setTrend({
    required bool htf,
    required String timeframe,
    required String? trend,
  }) {
    setState(() {
      final updated = Map<String, String>.of(htf ? _htfTrends : _ltfTrends);
      if (trend == null) {
        updated.remove(timeframe);
      } else {
        updated[timeframe] = trend;
      }
      if (htf) {
        _htfTrends = Map.unmodifiable(updated);
      } else {
        _ltfTrends = Map.unmodifiable(updated);
      }
    });
  }

  void _toggleFinding({
    required bool confirmation,
    required String timeframe,
    required String option,
  }) {
    setState(() {
      final source = confirmation ? _confirmationFinding : _zoneFinding;
      final updated = <String, Set<String>>{
        for (final entry in source.entries)
          entry.key: Set.unmodifiable(entry.value),
      };
      final selected = Set<String>.of(updated[timeframe] ?? const {});
      selected.contains(option)
          ? selected.remove(option)
          : selected.add(option);
      if (selected.isEmpty) {
        updated.remove(timeframe);
      } else {
        updated[timeframe] = Set.unmodifiable(selected);
      }
      if (confirmation) {
        _confirmationFinding = Map.unmodifiable(updated);
      } else {
        _zoneFinding = Map.unmodifiable(updated);
      }
    });
  }

  void _toggleTrendZone({required bool htf, required String option}) {
    setState(() {
      final updated = Set<String>.of(htf ? _htfZones : _ltfZones);
      updated.contains(option) ? updated.remove(option) : updated.add(option);
      if (htf) {
        _htfZones = Set.unmodifiable(updated);
      } else {
        _ltfZones = Set.unmodifiable(updated);
      }
    });
  }

  void _restoreStrategyReason(String value) {
    if (!value.startsWith(_strategyReasonPrefix)) {
      _legacyEntryReason = value.trim().isEmpty ? null : value;
      return;
    }
    try {
      final decoded = jsonDecode(value.substring(_strategyReasonPrefix.length));
      if (decoded is! Map<String, dynamic>) return;
      _htfTrends = _stringMap(decoded['htf']);
      _ltfTrends = _stringMap(decoded['ltf']);
      _htfZones = _stringSet(decoded['htf_zones']);
      _ltfZones = _stringSet(decoded['ltf_zones']);
      _zoneFinding = _selectionMap(decoded['zone_finding']);
      _confirmationFinding = _selectionMap(decoded['confirmation_finding']);
      final strategyDirection = decoded['direction']?.toString();
      if (strategyDirection == 'PRO' || strategyDirection == 'COUNTER') {
        _strategyDirection = strategyDirection;
      }
      final entryType = decoded['entry_type']?.toString();
      if (entryType == 'buy' || entryType == 'sell') _direction = entryType!;
      final setup = decoded['strategy_setup']?.toString();
      if (setup?.isNotEmpty == true) _set('setup_strategy', setup);
      final legacy = decoded['legacy_entry_reason']?.toString();
      _legacyEntryReason = legacy?.trim().isEmpty == false ? legacy : null;
    } catch (_) {
      _legacyEntryReason = value;
    }
  }

  Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    return Map.unmodifiable({
      for (final entry in value.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    });
  }

  Map<String, Set<String>> _selectionMap(Object? value) {
    if (value is! Map) return const {};
    return Map.unmodifiable({
      for (final entry in value.entries)
        if (entry.key is String && entry.value is List)
          entry.key as String: Set.unmodifiable(
            (entry.value as List).map((item) => item.toString()),
          ),
    });
  }

  Set<String> _stringSet(Object? value) {
    if (value is! List) return const {};
    return Set.unmodifiable(value.map((item) => item.toString()));
  }

  List<String> _persistedTimeframes(TradeJournalMeta meta) {
    final selected = <String>{..._timeframes};
    selected.addAll(_htfTrends.keys);
    selected.addAll(_ltfTrends.keys);
    selected.addAll(
      _zoneFinding.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => entry.key),
    );
    selected.addAll(
      _confirmationFinding.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => entry.key),
    );
    return selected
        .where(meta.timeframes.contains)
        .take(8)
        .toList(growable: false);
  }

  String? get _backendSetupStrategy {
    final value = _controller('setup_strategy');
    if (value.isEmpty) return null;
    return value.length <= 160 ? value : value.substring(0, 160);
  }

  String get _strategyReasonPayload =>
      '$_strategyReasonPrefix${jsonEncode({
        'htf': _htfTrends,
        'ltf': _ltfTrends,
        'htf_zones': _htfZones.toList(growable: false),
        'ltf_zones': _ltfZones.toList(growable: false),
        'zone_finding': {for (final entry in _zoneFinding.entries) entry.key: entry.value.toList(growable: false)},
        'confirmation_finding': {for (final entry in _confirmationFinding.entries) entry.key: entry.value.toList(growable: false)},
        'direction': _strategyDirection,
        'entry_type': _direction,
        'strategy_setup': _controller('setup_strategy'),
        if (_legacyEntryReason != null) 'legacy_entry_reason': _legacyEntryReason,
      })}';

  String _sessionChoice(String label) {
    final normalized = label.trim().toLowerCase().replaceAll(' ', '_');
    return const {'asia', 'london', 'new_york'}.contains(normalized)
        ? normalized
        : normalized.isEmpty
        ? 'asia'
        : 'other';
  }

  String? get _selectedSessionLabel => switch (_session) {
    'asia' => 'Asia',
    'london' => 'London',
    'new_york' => 'New York',
    _ => _nullText('session_label'),
  };

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
  late Future<({TradeJournalMeta meta, TradeJournalEntry entry})> _request;
  late TradeJournalEntry _entry;
  final _controllers = <String, TextEditingController>{};
  var _result = 'win';
  var _followed = 'yes';
  String? _emotion;
  final _mistakes = <String>{};
  var _date = DateTime.now();
  var _time = TimeOfDay.now();
  var _rating = 0;
  var _saving = false;
  var _hydrated = false;
  Timer? _livePriceTimer;
  double? _liveExitPrice;
  var _liveExitPriceLoading = false;
  var _livePriceTrackingStarted = false;
  var _exitPriceManuallyEdited = false;

  static const _currencies = ['USD', 'USDT', 'EUR', 'GBP', 'LKR'];

  static const _fields = [
    'exit_price',
    'gross_pnl',
    'pnl_currency',
    'went_well',
    'went_wrong',
    'lesson_learned',
    'improvement_next_trade',
    'emotion_after_other',
  ];

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    for (final item in _fields) {
      _controllers[item] = TextEditingController();
    }
    _request = _load();
  }

  @override
  void dispose() {
    _livePriceTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Close Trade',
    subtitle: 'Complete execution and record your review',
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020B1B), Color(0xFF031222)],
        ),
      ),
      child: FutureBuilder<({TradeJournalMeta meta, TradeJournalEntry entry})>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const JournalLoading();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return JournalError(
              error: snapshot.error,
              onRetry: () => setState(() {
                _livePriceTimer?.cancel();
                _livePriceTrackingStarted = false;
                _liveExitPrice = null;
                _liveExitPriceLoading = false;
                _hydrated = false;
                _request = _load(forceRefresh: true);
              }),
            );
          }
          final data = snapshot.data!;
          if (!_hydrated) {
            _hydrate(data.entry);
            _hydrated = true;
          }
          if (!_livePriceTrackingStarted) {
            _livePriceTrackingStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startLivePriceTracking();
            });
          }
          return _form(data.meta);
        },
      ),
    ),
  );

  Widget _form(TradeJournalMeta meta) => Form(
    key: _formKey,
    child: ListView(
      key: const ValueKey('close-trade-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        CloseTradeSummaryCard(entry: _entry),
        const SizedBox(height: 13),
        CloseTradeExitDetailsCard(
          exitPriceController: _controllers['exit_price']!,
          exitPriceValidator: _validateExitPrice,
          date: _dateText(_date),
          time: _timeText(_time),
          onPickDate: _pickDate,
          onPickTime: _pickTime,
          result: _result,
          onResultChanged: (value) => setState(() => _result = value),
          livePrice: _liveExitPrice,
          livePriceLoading: _liveExitPriceLoading,
          onRefreshLivePrice: () =>
              unawaited(_refreshLiveExitPrice(showLoading: true)),
          onUseLivePrice: _liveExitPrice == null ? null : _applyLiveExitPrice,
          onExitPriceChanged: (_) => _exitPriceManuallyEdited = true,
        ),
        const SizedBox(height: 13),
        CloseTradeProfitLossCard(
          grossController: _controllers['gross_pnl']!,
          currency: _value('pnl_currency'),
          currencies: _currencyOptions,
          onCurrencyChanged: (value) => setState(
            () => _controllers['pnl_currency']!.text = value ?? 'USD',
          ),
          numberValidator: _validateOptionalNumber,
        ),
        const SizedBox(height: 13),
        CloseTradeAdditionalInfoCard(
          emotion: _emotion,
          emotions: meta.emotionsAfter,
          onEmotionChanged: (value) => setState(() => _emotion = value),
          followedPlan: _followed,
          followedPlanOptions: meta.followedPlanAfter,
          onFollowedPlanChanged: (value) =>
              setState(() => _followed = value ?? 'yes'),
          otherEmotionController: _controllers['emotion_after_other']!,
        ),
        const SizedBox(height: 13),
        CloseTradeMistakesLessonsCard(
          options: meta.mistakeTags,
          selected: _mistakes,
          onToggle: (item) => setState(() {
            _mistakes.contains(item)
                ? _mistakes.remove(item)
                : _mistakes.add(item);
          }),
          wentWellController: _controllers['went_well']!,
          wentWrongController: _controllers['went_wrong']!,
          lessonController: _controllers['lesson_learned']!,
          improvementController: _controllers['improvement_next_trade']!,
          rating: _rating,
          onRatingChanged: (value) => setState(() => _rating = value),
        ),
        if (!_canClose) ...[
          const SizedBox(height: 13),
          Container(
            key: const ValueKey('close-trade-ineligible'),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: closeTradeGold.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: closeTradeGold.withValues(alpha: .45)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: closeTradeGold),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'This trade is not currently eligible to be closed.',
                    style: TextStyle(color: closeTradeMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        CloseTradeSaveButton(
          busy: _saving,
          enabled: _canClose,
          onPressed: _submit,
        ),
      ],
    ),
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
    if (_saving) return;
    if (_entry.uuid.trim().isEmpty) {
      _message('The selected trade is invalid. Please reopen the trade.');
      return;
    }
    if (!_canClose) {
      _message('This trade can no longer be closed. Refresh and try again.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final exitAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final openedAt = (_entry.openedAt ?? _entry.tradeAt)?.toLocal();
    if (exitAt.isAfter(DateTime.now())) {
      _message('Exit time cannot be in the future.');
      return;
    }
    if (openedAt != null && exitAt.isBefore(openedAt)) {
      _message('Exit time must be after the trade entry time.');
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'exit_price': double.parse(_value('exit_price')),
        'exit_date': _dateText(_date),
        'exit_time': _timeText(_time),
        'timezone': await widget.repository.timezone(),
        'result': _result,
        'followed_plan_after': _followed,
        'mistake_tags': _mistakes.toList(growable: false)..sort(),
        if (_rating > 0) 'rating': _rating,
        if (_emotion != null) 'emotion_after': _emotion,
        if (_emotion == 'other')
          'emotion_after_other': _value('emotion_after_other'),
      };
      final grossPnl = double.tryParse(_value('gross_pnl'));
      if (grossPnl != null) body['gross_pnl'] = grossPnl;
      for (final item in const [
        'pnl_currency',
        'went_well',
        'went_wrong',
        'lesson_learned',
        'improvement_next_trade',
      ]) {
        if (_value(item).isNotEmpty) body[item] = _value(item);
      }
      final result = await widget.repository.close(_entry.uuid, body);
      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _value(String name) => _controllers[name]!.text.trim();

  bool get _canClose =>
      _entry.uuid.trim().isNotEmpty &&
      _entry.status.toLowerCase() == 'open' &&
      _entry.canClose;

  List<String> get _currencyOptions {
    final current = _value('pnl_currency').toUpperCase();
    return current.isEmpty || _currencies.contains(current)
        ? _currencies
        : [current, ..._currencies];
  }

  Future<({TradeJournalMeta meta, TradeJournalEntry entry})> _load({
    bool forceRefresh = false,
  }) async {
    if (widget.entry.uuid.trim().isEmpty) {
      throw const ApiException(message: 'The selected trade is invalid.');
    }
    final values = await Future.wait<Object>([
      widget.repository.meta(forceRefresh: forceRefresh),
      widget.repository.entry(widget.entry.uuid, forceRefresh: forceRefresh),
    ]);
    return (
      meta: values[0] as TradeJournalMeta,
      entry: values[1] as TradeJournalEntry,
    );
  }

  void _hydrate(TradeJournalEntry entry) {
    _entry = entry;
    final review = entry.review;
    final pnl = entry.pnl;
    _setText('exit_price', entry.prices['exit_price']);
    _exitPriceManuallyEdited = _value('exit_price').isNotEmpty;
    _setText('gross_pnl', pnl['gross']);
    _setText('pnl_currency', pnl['currency'] ?? 'USD');
    _setText('emotion_after_other', review['emotion_after_other']);
    _setText('went_well', review['went_well']);
    _setText('went_wrong', review['went_wrong']);
    _setText('lesson_learned', review['lesson_learned']);
    _setText('improvement_next_trade', review['improvement_next_trade']);

    final restoredResult = entry.result?.trim();
    if (const {
      'win',
      'loss',
      'breakeven',
      'partial',
    }.contains(restoredResult)) {
      _result = restoredResult!;
    }
    final restoredFollowed = review['followed_plan']?.toString();
    if (const {'yes', 'partially', 'no'}.contains(restoredFollowed)) {
      _followed = restoredFollowed!;
    }
    final restoredEmotion = review['emotion_after']?.toString().trim();
    _emotion = restoredEmotion?.isNotEmpty == true ? restoredEmotion : null;
    _mistakes
      ..clear()
      ..addAll(journalStrings(review['mistake_tags']));
    final restoredRating = journalNumber(review['rating'])?.round();
    _rating =
        restoredRating != null && restoredRating >= 1 && restoredRating <= 5
        ? restoredRating
        : 0;

    final exitAt = entry.exitAt?.toLocal();
    if (exitAt != null) {
      _date = DateTime(exitAt.year, exitAt.month, exitAt.day);
      _time = TimeOfDay.fromDateTime(exitAt);
    }
  }

  void _setText(String name, Object? value) {
    final text = value?.toString().trim() ?? '';
    _controllers[name]!.text = text;
  }

  void _startLivePriceTracking() {
    _livePriceTimer?.cancel();
    unawaited(_refreshLiveExitPrice(showLoading: true));
    _livePriceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_refreshLiveExitPrice()),
    );
  }

  Future<void> _refreshLiveExitPrice({bool showLoading = false}) async {
    final symbol = _entry.symbol.trim().toUpperCase();
    if (symbol.isEmpty) return;
    if (showLoading && mounted && _liveExitPrice == null) {
      setState(() => _liveExitPriceLoading = true);
    }
    try {
      final price = await widget.repository.livePrice(
        market: _entry.market,
        symbol: symbol,
        stockRegion: _entry.stockRegion,
      );
      if (!mounted || _entry.symbol.trim().toUpperCase() != symbol) return;
      setState(() {
        _liveExitPrice = price;
        _liveExitPriceLoading = false;
        if (price != null && price > 0 && !_exitPriceManuallyEdited) {
          _setLiveExitPrice(price);
        }
      });
    } catch (_) {
      if (!mounted || _entry.symbol.trim().toUpperCase() != symbol) return;
      setState(() => _liveExitPriceLoading = false);
    }
  }

  void _applyLiveExitPrice() {
    final price = _liveExitPrice;
    if (price == null || price <= 0) return;
    setState(() {
      _exitPriceManuallyEdited = false;
      _setLiveExitPrice(price);
    });
  }

  void _setLiveExitPrice(double price) {
    final controller = _controllers['exit_price']!;
    controller.text = formatCloseTradePrice(price);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  String? _validateExitPrice(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null) return 'Exit Price is required.';
    if (!number.isFinite || number <= 0) return 'Enter a valid price above 0.';
    return null;
  }

  String? _validateOptionalNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    return number == null || !number.isFinite ? 'Enter a valid number.' : null;
  }

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
    super.key,
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
