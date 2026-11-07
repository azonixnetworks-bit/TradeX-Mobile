part of '../trade_journal_trade_screens.dart';

class TradeJournalCloseScreen extends StatefulWidget {
  const TradeJournalCloseScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepositoryContract repository;
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.palette.background, context.palette.surfaceMuted],
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
    } on UserFacingException catch (error) {
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
      throw const JournalValidationException('The selected trade is invalid.');
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
