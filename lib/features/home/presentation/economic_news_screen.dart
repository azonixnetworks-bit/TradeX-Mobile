import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/market_news_repository.dart';
import 'bloc/economic_news_cubit.dart';

class EconomicNewsScreen extends StatefulWidget {
  const EconomicNewsScreen({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  State<EconomicNewsScreen> createState() => _EconomicNewsScreenState();
}

class _EconomicNewsScreenState extends State<EconomicNewsScreen>
    with WidgetsBindingObserver {
  late final EconomicNewsCubit _cubit;
  late final PageController _pageController;
  late final Map<EconomicNewsFilter, ScrollController> _verticalControllers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = EconomicNewsCubit(MarketNewsRepository(widget.apiClient))..load();
    _pageController = PageController();
    _verticalControllers = <EconomicNewsFilter, ScrollController>{
      for (final filter in EconomicNewsFilter.values)
        filter: ScrollController(),
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    _pageController.dispose();
    for (final controller in _verticalControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectFilter(EconomicNewsFilter filter) {
    _cubit.selectFilter(filter);
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      filter.index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<EconomicNewsCubit, EconomicNewsState>(
        builder: (context, state) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 4,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Economic News', style: TextStyle(fontSize: 18)),
                Text(
                  'Upcoming Laravel economic calendar',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: switch (state.status) {
              EconomicNewsStatus.initial ||
              EconomicNewsStatus.loading => const Center(
                child: CircularProgressIndicator(
                  color: TradeXColors.goldBright,
                  strokeWidth: 2.5,
                ),
              ),
              EconomicNewsStatus.failure => _NewsState(
                icon: Icons.cloud_off_rounded,
                message: 'Economic news is temporarily unavailable.',
                action: 'Retry',
                onTap: _cubit.refresh,
              ),
              EconomicNewsStatus.success => Column(
                children: [
                  _FilterBar(selected: state.filter, onSelected: _selectFilter),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('economic-news-pages'),
                      controller: _pageController,
                      itemCount: EconomicNewsFilter.values.length,
                      onPageChanged: (index) =>
                          _cubit.selectFilter(EconomicNewsFilter.values[index]),
                      itemBuilder: (context, index) {
                        final filter = EconomicNewsFilter.values[index];
                        final items = _itemsForFilter(state.items, filter);
                        return items.isEmpty
                            ? _NewsState(
                                icon: Icons.event_available_rounded,
                                message: 'No upcoming events in this category.',
                                action: 'Refresh',
                                onTap: _cubit.refresh,
                              )
                            : _EconomicNewsCards(
                                items: items,
                                now: state.now,
                                verticalController:
                                    _verticalControllers[filter]!,
                              );
                      },
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

List<MarketNewsItem> _itemsForFilter(
  List<MarketNewsItem> items,
  EconomicNewsFilter filter,
) {
  final impact = filter.impact;
  if (impact == null) return items;
  return items
      .where((item) => item.impact.toUpperCase() == impact)
      .toList(growable: false);
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final EconomicNewsFilter selected;
  final ValueChanged<EconomicNewsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        key: const ValueKey('economic-news-filters'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: EconomicNewsFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = EconomicNewsFilter.values[index];
          final active = filter == selected;
          return ChoiceChip(
            key: ValueKey('economic-news-filter-${filter.name}'),
            selected: active,
            showCheckmark: false,
            onSelected: (_) => onSelected(filter),
            label: Text(filter.label),
            labelStyle: TextStyle(
              color: active
                  ? const Color(0xFF171308)
                  : TradeXColors.primaryText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: TradeXColors.goldBright,
            backgroundColor: TradeXColors.surfaceRaised,
            side: BorderSide(
              color: active ? TradeXColors.goldBright : TradeXColors.border,
            ),
          );
        },
      ),
    );
  }
}

class _EconomicNewsCards extends StatelessWidget {
  const _EconomicNewsCards({
    required this.items,
    required this.now,
    required this.verticalController,
  });

  final List<MarketNewsItem> items;
  final DateTime now;
  final ScrollController verticalController;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      child: ListView.separated(
        key: const ValueKey('economic-news-card-list'),
        controller: verticalController,
        padding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _EconomicNewsCard(item: items[index], now: now),
      ),
    );
  }
}

class _EconomicNewsCard extends StatefulWidget {
  const _EconomicNewsCard({required this.item, required this.now});

  final MarketNewsItem item;
  final DateTime now;

  @override
  State<_EconomicNewsCard> createState() => _EconomicNewsCardState();
}

class _EconomicNewsCardState extends State<_EconomicNewsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final now = widget.now;
    final impactColor = _impactColor(item.impact);
    final pairs = item.affectedPairs.take(4).toList(growable: false);
    final hiddenPairCount = item.affectedPairs.length - pairs.length;

    return AnimatedScale(
      key: ValueKey('economic-news-card-${item.uuid}-press-scale'),
      scale: _pressed ? .985 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          key: ValueKey('economic-news-card-${item.uuid}'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: TradeXColors.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: impactColor.withValues(alpha: .42)),
            boxShadow: [
              BoxShadow(
                color: impactColor.withValues(alpha: _pressed ? .13 : .06),
                blurRadius: _pressed ? 10 : 18,
                offset: Offset(0, _pressed ? 3 : 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: impactColor,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CountryFlagBadge(
                          flag: _countryFlag(item.countryCode, item.currency),
                        ),
                        const SizedBox(width: 7),
                        _ImpactBadge(impact: item.impact),
                        const Spacer(),
                        _RemainingTimeBadge(label: _remainingTime(item, now)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TradeXColors.primaryText,
                        fontSize: 16,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.public_rounded,
                          color: TradeXColors.secondaryText,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: TradeXColors.secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: TradeXColors.border),
                    const SizedBox(height: 12),
                    _ReleaseValues(item: item),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: [
                            _EventDetail(
                              width: tileWidth,
                              icon: Icons.payments_outlined,
                              label: 'Currency',
                              value: item.currency.isEmpty
                                  ? '—'
                                  : item.currency,
                            ),
                            _EventDetail(
                              width: tileWidth,
                              icon: Icons.calendar_month_outlined,
                              label: 'Time',
                              value: _scheduledTime(item.occurredAt),
                            ),
                            _EventDetail(
                              width: tileWidth,
                              icon: Icons.trending_up_rounded,
                              label: 'Bias',
                              value: _titleCase(item.bias),
                              valueColor: _biasColor(item.bias),
                            ),
                            _EventDetail(
                              width: tileWidth,
                              icon: Icons.verified_outlined,
                              label: 'Confidence',
                              value: '${item.confidenceScore}%',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Affected Pairs',
                      style: TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    if (pairs.isEmpty)
                      const Text(
                        '—',
                        style: TextStyle(color: TradeXColors.secondaryText),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final pair in pairs) _PairChip(label: pair),
                          if (hiddenPairCount > 0)
                            _PairChip(label: '+$hiddenPairCount'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseValues extends StatelessWidget {
  const _ReleaseValues({required this.item});

  final MarketNewsItem item;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('economic-news-values-${item.uuid}'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: TradeXColors.background.withValues(alpha: .58),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: TradeXColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: _ReleaseValue(label: 'Previous', value: item.previous ?? '—'),
        ),
        const _ReleaseValueDivider(),
        Expanded(
          child: _ReleaseValue(label: 'Forecast', value: item.forecast ?? '—'),
        ),
        const _ReleaseValueDivider(),
        Expanded(
          child: _ReleaseValue(
            label: 'Actual',
            value: item.actual ?? 'Pending',
            highlighted: item.actual != null,
          ),
        ),
      ],
    ),
  );
}

class _ReleaseValue extends StatelessWidget {
  const _ReleaseValue({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: TradeXColors.secondaryText,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: highlighted
              ? TradeXColors.goldBright
              : TradeXColors.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _ReleaseValueDivider extends StatelessWidget {
  const _ReleaseValueDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: 7),
    color: TradeXColors.border,
  );
}

class _CountryFlagBadge extends StatelessWidget {
  const _CountryFlagBadge({required this.flag});

  final String flag;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 29,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: TradeXColors.background.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: TradeXColors.border),
    ),
    child: Text(flag, style: const TextStyle(fontSize: 17, height: 1)),
  );
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.impact});

  final String impact;

  @override
  Widget build(BuildContext context) {
    final normalized = impact.toUpperCase();
    final color = _impactColor(normalized);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Text(
        '$normalized IMPACT',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RemainingTimeBadge extends StatelessWidget {
  const _RemainingTimeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: TradeXColors.gold.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 14,
          color: TradeXColors.goldBright,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: TradeXColors.goldBright,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _EventDetail extends StatelessWidget {
  const _EventDetail({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = TradeXColors.primaryText,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Row(
      children: [
        Icon(icon, size: 18, color: TradeXColors.goldBright),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PairChip extends StatelessWidget {
  const _PairChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: TradeXColors.background.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: TradeXColors.border),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: TradeXColors.primaryText,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String _remainingTime(MarketNewsItem item, DateTime now) {
  final status = item.status.toUpperCase();
  if (status == 'CANCELLED') return 'Cancelled';
  if (status == 'RELEASED' || status == 'REVISED') return 'Released';
  if (status == 'LIVE') return 'Live now';
  final scheduled = item.occurredAt;
  if (scheduled == null) return '—';
  final remaining = scheduled.difference(now);
  if (remaining.isNegative) return 'Elapsed';
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;
  final seconds = remaining.inSeconds % 60;
  final clock =
      '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
  if (remaining.inDays > 0) {
    return '${remaining.inDays}d $clock';
  }
  return clock;
}

String _countryFlag(String countryCode, String currency) {
  final explicitCountry = countryCode.trim().toUpperCase();
  final normalizedCurrency = currency.trim().toUpperCase();
  final mappedCountry =
      _currencyCountries[normalizedCurrency] ??
      (normalizedCurrency.length >= 3
          ? _currencyCountries[normalizedCurrency.substring(0, 3)]
          : null);
  final code = explicitCountry.length == 2 ? explicitCountry : mappedCountry;
  if (code == null || !RegExp(r'^[A-Z]{2}$').hasMatch(code)) return '🌐';
  return String.fromCharCodes(
    code.codeUnits.map((character) => character + 127397),
  );
}

const Map<String, String> _currencyCountries = <String, String>{
  'AED': 'AE',
  'AUD': 'AU',
  'BDT': 'BD',
  'BRL': 'BR',
  'CAD': 'CA',
  'CHF': 'CH',
  'CNH': 'CN',
  'CNY': 'CN',
  'DKK': 'DK',
  'EUR': 'EU',
  'GBP': 'GB',
  'HKD': 'HK',
  'IDR': 'ID',
  'ILS': 'IL',
  'INR': 'IN',
  'JPY': 'JP',
  'KRW': 'KR',
  'LKR': 'LK',
  'MXN': 'MX',
  'MYR': 'MY',
  'NOK': 'NO',
  'NZD': 'NZ',
  'PHP': 'PH',
  'PKR': 'PK',
  'PLN': 'PL',
  'RUB': 'RU',
  'SAR': 'SA',
  'SEK': 'SE',
  'SGD': 'SG',
  'THB': 'TH',
  'TRY': 'TR',
  'TWD': 'TW',
  'USD': 'US',
  'VND': 'VN',
  'ZAR': 'ZA',
};

String _scheduledTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
}

String _titleCase(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return '—';
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

Color _impactColor(String impact) => switch (impact.toUpperCase()) {
  'HIGH' => TradeXColors.error,
  'MEDIUM' => TradeXColors.goldBright,
  _ => TradeXColors.success,
};

Color _biasColor(String bias) => switch (bias.toUpperCase()) {
  'BULLISH' => TradeXColors.success,
  'BEARISH' => TradeXColors.error,
  _ => TradeXColors.secondaryText,
};

class _NewsState extends StatelessWidget {
  const _NewsState({
    required this.icon,
    required this.message,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: TradeXColors.goldBright, size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
            ),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onTap, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
