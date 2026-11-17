part of '../trade_journal_trade_screens.dart';

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
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.palette.background, context.palette.surfaceMuted],
        ),
      ),
      child: ListView(
        key: const ValueKey('trade-plan-scroll'),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
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
              color: context.palette.surfaceRaised,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: context.palette.border),
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
                    Divider(height: 1, color: context.palette.border),
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
              style: TextStyle(
                color: context.palette.secondaryText,
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
                        style: TextStyle(
                          color: context.palette.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                color: context.palette.secondaryText,
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
      ActivityTrackingScope.maybeOf(context)
          ?.track('journal', 'journal_saved', subjectId: saved.uuid);
      Navigator.pop(context, saved);
    } on UserFacingException catch (error) {
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
      final decoded = decodeStructuredText(
        value.substring(_strategyReasonPrefix.length),
      );
      if (decoded is! JournalData) return;
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
      '$_strategyReasonPrefix${encodeStructuredText({
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
