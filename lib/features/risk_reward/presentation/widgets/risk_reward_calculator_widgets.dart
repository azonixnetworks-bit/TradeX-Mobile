part of '../risk_reward_module.dart';

class _InstrumentSearchField extends StatefulWidget {
  const _InstrumentSearchField({
    super.key,
    required this.selected,
    required this.instruments,
    required this.onQueryChanged,
    required this.onSelected,
  });

  final RiskRewardInstrument? selected;
  final List<RiskRewardInstrument> instruments;
  final VoidCallback onQueryChanged;
  final ValueChanged<RiskRewardInstrument> onSelected;

  @override
  State<_InstrumentSearchField> createState() => _InstrumentSearchFieldState();
}

class _InstrumentSearchFieldState extends State<_InstrumentSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selected?.symbol ?? '');
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _InstrumentSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.selected?.symbol ?? '';
    if (next.isNotEmpty && _controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  List<RiskRewardInstrument> get _suggestions {
    final query = _controller.text.trim().toLowerCase();
    if (!_focusNode.hasFocus || query.isEmpty) {
      return const <RiskRewardInstrument>[];
    }
    return widget.instruments
        .where(
          (item) =>
              item.symbol.toLowerCase().contains(query) ||
              item.name.toLowerCase().contains(query),
        )
        .take(8)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('forex-deriv-symbol-search'),
          controller: _controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) {
            widget.onQueryChanged();
            setState(() {});
          },
          decoration:
              _inputDecoration(
                'Type symbol or market name',
                Icons.search_rounded,
              ).copyWith(
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear symbol',
                        onPressed: () {
                          _controller.clear();
                          widget.onQueryChanged();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: suggestions.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  key: ValueKey(_controller.text.toLowerCase()),
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 288),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.palette.border),
                    boxShadow: TradeXElevation.floating(
                      brightness: Theme.of(context).brightness,
                      palette: context.palette,
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          key: ValueKey('symbol-suggestion-${item.symbol}'),
                          dense: true,
                          leading: const Icon(
                            Icons.show_chart_rounded,
                            color: TradeXColors.gold,
                          ),
                          title: Text(
                            item.symbol,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _controller.value = TextEditingValue(
                              text: item.symbol,
                              selection: TextSelection.collapsed(
                                offset: item.symbol.length,
                              ),
                            );
                            _focusNode.unfocus();
                            widget.onSelected(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _LivePriceStatus extends StatelessWidget {
  const _LivePriceStatus({
    required this.loading,
    required this.quote,
    required this.error,
    required this.onRefresh,
  });

  final bool loading;
  final RiskRewardQuote? quote;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final color = error != null
        ? TradeXColors.error
        : quote != null
        ? TradeXColors.success
        : TradeXColors.secondaryText;
    final message = loading
        ? 'Loading current market price…'
        : error ??
              (quote == null
                  ? 'Select a symbol to load its current price.'
                  : 'Live ${quote!.symbol}: ${quote!.displayPrice} • Entry price remains editable');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              error != null
                  ? Icons.cloud_off_rounded
                  : Icons.currency_exchange_rounded,
              size: 18,
              color: color,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!loading && onRefresh != null)
            IconButton(
              tooltip: 'Refresh live price',
              visualDensity: VisualDensity.compact,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 19),
            ),
        ],
      ),
    );
  }
}

class _StockDropdown extends StatelessWidget {
  const _StockDropdown({
    required this.value,
    required this.stocks,
    required this.onChanged,
    this.compact = false,
  });

  final String? value;
  final List<StockInstrument> stocks;
  final ValueChanged<String?> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: stocks.any((item) => item.symbol == value) ? value : null,
    isExpanded: true,
    dropdownColor: TradeXColors.surfaceRaised,
    decoration: _inputDecoration(
      compact ? 'Stock' : 'Stock / Symbol',
      Icons.business_rounded,
    ),
    items: stocks
        .map(
          (item) => DropdownMenuItem(
            value: item.symbol,
            child: Text(
              '${item.symbol}  •  ${item.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(growable: false),
    onChanged: stocks.isEmpty ? null : onChanged,
  );
}

class _StockSearchField extends StatelessWidget {
  const _StockSearchField({
    super.key,
    required this.selected,
    required this.stocks,
    required this.onSelected,
  });

  final StockInstrument? selected;
  final List<StockInstrument> stocks;
  final ValueChanged<StockInstrument> onSelected;

  @override
  Widget build(BuildContext context) => Autocomplete<StockInstrument>(
    initialValue: TextEditingValue(
      text: selected == null ? '' : '${selected!.symbol} • ${selected!.name}',
    ),
    displayStringForOption: (stock) => '${stock.symbol} • ${stock.name}',
    optionsBuilder: (value) {
      final query = value.text.trim().toLowerCase();
      if (query.isEmpty) return stocks;
      return stocks.where(
        (stock) =>
            stock.symbol.toLowerCase().contains(query) ||
            stock.name.toLowerCase().contains(query),
      );
    },
    onSelected: onSelected,
    fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmitted(),
          decoration: _inputDecoration(
            'Search symbol or company',
            Icons.search_rounded,
          ),
        ),
    optionsViewBuilder: (context, select, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: TradeXColors.surfaceRaised,
        elevation: 10,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 260),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final item = options.elementAt(index);
              return ListTile(
                dense: true,
                title: Text(item.symbol),
                subtitle: Text(item.name),
                onTap: () => select(item),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _TradeSideControl extends StatelessWidget {
  const _TradeSideControl({required this.selected, this.onSelected});

  final String selected;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _sideButton('BUY', TradeXColors.success)),
      const SizedBox(width: 10),
      Expanded(child: _sideButton('SELL', TradeXColors.error)),
    ],
  );

  Widget _sideButton(String value, Color color) {
    final active = selected == value;
    final enabled = onSelected != null || active;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: .15)
            : TradeXColors.surfaceRaised,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: active ? color : TradeXColors.borderStrong),
      ),
      child: InkWell(
        onTap: enabled && onSelected != null ? () => onSelected!(value) : null,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? color : TradeXColors.tertiaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorField extends StatelessWidget {
  const _CalculatorField({
    required this.label,
    required this.controller,
    required this.icon,
    this.numeric = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool numeric;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: false)
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      onChanged: onChanged,
      style: const TextStyle(
        color: TradeXColors.primaryText,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(label, icon),
    ),
  );
}

class _CalculateButton extends StatelessWidget {
  const _CalculateButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<RiskRewardCubit>().state.submitting;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.calculate_rounded),
        label: Text(busy ? 'Calculating…' : 'Calculate'),
      ),
    );
  }
}

class _AutoLeverageCard extends StatelessWidget {
  const _AutoLeverageCard({
    required this.leverage,
    required this.stopDistancePercent,
  });

  final int? leverage;
  final double? stopDistancePercent;

  @override
  Widget build(BuildContext context) => _GoldCard(
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: TradeXColors.gold.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TradeXColors.goldSoft.withValues(alpha: .55),
            ),
          ),
          child: const Icon(
            Icons.auto_graph_rounded,
            color: TradeXColors.goldBright,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calculated Leverage',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                leverage == null
                    ? 'Enter a valid Entry and Stop Loss to calculate leverage.'
                    : '${stopDistancePercent!.toStringAsFixed(2)}% stop distance • safety buffer included',
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          leverage == null ? '--' : '${leverage}x',
          style: TextStyle(
            color: leverage == null
                ? TradeXColors.tertiaryText
                : TradeXColors.goldBright,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    dropdownColor: TradeXColors.surfaceRaised,
    decoration: _inputDecoration(
      'Payments per Year',
      Icons.calendar_month_rounded,
    ),
    items: const [1, 2, 4, 12]
        .map(
          (item) =>
              DropdownMenuItem(value: item, child: Text('$item payments')),
        )
        .toList(growable: false),
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.text,
    this.icon = Icons.cloud_off_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TradeXColors.gold.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: TradeXColors.goldSoft.withValues(alpha: .5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: TradeXColors.goldBright),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TradeXColors.error.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: TradeXColors.error.withValues(alpha: .7)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: TradeXColors.error),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: TradeXColors.primaryText),
          ),
        ),
      ],
    ),
  );
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(compact ? 18 : 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: TradeXColors.goldBright),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
        ],
      ),
    ),
  );
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: TradeXColors.goldBright,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: TradeXColors.primaryText,
      fontSize: 18,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _EmptyProviderState extends StatelessWidget {
  const _EmptyProviderState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => _GoldCard(
    child: Column(
      children: [
        const _AssetImage('22_clock_calendar_tile.png', size: 74),
        const SizedBox(height: 10),
        const Text(
          'Verified provider unavailable',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _JsonDetailCard extends StatelessWidget {
  const _JsonDetailCard({required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 10),
          for (final entry in data.entries)
            if (entry.value != null && entry.value.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _labelize(entry.key),
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _displayValue(entry.value),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    ),
  );
}

class _SideBadge extends StatelessWidget {
  const _SideBadge(this.side);

  final String side;

  @override
  Widget build(BuildContext context) {
    final buy = side.toUpperCase() == 'BUY';
    final color = buy ? TradeXColors.success : TradeXColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        side.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: TradeXColors.warning,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SavedCalculationTile extends StatelessWidget {
  const _SavedCalculationTile({required this.item});

  final SavedCalculation item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _GoldCard(
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded, color: TradeXColors.goldBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.type.replaceAll('_', ' ')}${item.createdAt == null ? '' : '  •  ${_shortDate(item.createdAt!)}'}',
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: TradeXColors.secondaryText),
      prefixIcon: Icon(icon, color: TradeXColors.goldBright),
      filled: true,
      fillColor: TradeXColors.surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TradeXColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: TradeXColors.goldBright,
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );

Future<void> _open(BuildContext context, Widget screen) {
  final cubit = context.read<RiskRewardCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(value: cubit, child: screen),
    ),
  );
}

StockInstrument? _findStock(List<StockInstrument> stocks, String? symbol) {
  for (final stock in stocks) {
    if (stock.symbol == symbol) return stock;
  }
  return null;
}

double _metricWidth(double available) =>
    available >= 520 ? (available - 10) / 2 : available;

String _formatNumber(num? value) {
  if (value == null) return '—';
  final number = value.toDouble();
  if (number == number.roundToDouble()) return number.toStringAsFixed(0);
  return number
      .toStringAsFixed(number.abs() < 1 ? 6 : 2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _money(num? value) => value == null ? '—' : '\$${_formatNumber(value)}';

String _currency(num? value, String currency) =>
    value == null ? '—' : '$currency ${_formatNumber(value)}';

String _labelize(String value) => value
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _displayValue(Object? value) {
  if (value is Map || value is List) return value.toString();
  return value?.toString() ?? '—';
}

String _shortDate(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
