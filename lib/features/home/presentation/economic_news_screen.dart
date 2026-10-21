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
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = EconomicNewsCubit(MarketNewsRepository(widget.apiClient))..load();
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
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
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
                  _FilterBar(
                    selected: state.filter,
                    onSelected: _cubit.selectFilter,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: state.visibleItems.isEmpty
                        ? _NewsState(
                            icon: Icons.event_available_rounded,
                            message: 'No upcoming events in this category.',
                            action: 'Refresh',
                            onTap: _cubit.refresh,
                          )
                        : _EconomicNewsTable(
                            items: state.visibleItems,
                            now: state.now,
                            horizontalController: _horizontalController,
                            verticalController: _verticalController,
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

class _EconomicNewsTable extends StatelessWidget {
  const _EconomicNewsTable({
    required this.items,
    required this.now,
    required this.horizontalController,
    required this.verticalController,
  });

  final List<MarketNewsItem> items;
  final DateTime now;
  final ScrollController horizontalController;
  final ScrollController verticalController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TradeXColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TradeXColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Scrollbar(
            controller: verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: verticalController,
              child: Scrollbar(
                controller: horizontalController,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  key: const ValueKey('economic-news-table-scroll'),
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    key: const ValueKey('economic-news-table'),
                    headingRowHeight: 48,
                    dataRowMinHeight: 68,
                    dataRowMaxHeight: 84,
                    horizontalMargin: 14,
                    columnSpacing: 20,
                    headingRowColor: WidgetStatePropertyAll(
                      TradeXColors.gold.withValues(alpha: .12),
                    ),
                    dividerThickness: .7,
                    columns: const [
                      DataColumn(label: _Header('Event / Source', width: 210)),
                      DataColumn(label: _Header('Remaining Time', width: 112)),
                      DataColumn(label: _Header('Impact', width: 80)),
                      DataColumn(label: _Header('Bias', width: 90)),
                      DataColumn(label: _Header('Confidence', width: 88)),
                      DataColumn(label: _Header('Affected Pairs', width: 180)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(
                          key: ValueKey('economic-news-event-${item.uuid}'),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 210,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: TradeXColors.primaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.source,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: TradeXColors.secondaryText,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              _ValueCell(
                                _remainingTime(item, now),
                                width: 112,
                                color: TradeXColors.goldBright,
                              ),
                            ),
                            DataCell(_ImpactBadge(impact: item.impact)),
                            DataCell(
                              _ValueCell(
                                item.bias.toUpperCase(),
                                width: 90,
                                color: _biasColor(item.bias),
                              ),
                            ),
                            DataCell(
                              _ValueCell('${item.confidenceScore}%', width: 88),
                            ),
                            DataCell(
                              _ValueCell(
                                item.affectedPairs.isEmpty
                                    ? '—'
                                    : item.affectedPairs.join(', '),
                                width: 180,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${(remaining.inHours % 24).toString().padLeft(2, '0')}h';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours.toString().padLeft(2, '0')}h '
          '${(remaining.inMinutes % 60).toString().padLeft(2, '0')}m';
    }
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}m';
    return '<1m';
  }

  Color _biasColor(String bias) => switch (bias.toUpperCase()) {
    'BULLISH' => TradeXColors.success,
    'BEARISH' => TradeXColors.error,
    _ => TradeXColors.secondaryText,
  };
}

class _Header extends StatelessWidget {
  const _Header(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Text(
      text,
      style: const TextStyle(
        color: TradeXColors.goldBright,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ValueCell extends StatelessWidget {
  const _ValueCell(
    this.text, {
    required this.width,
    this.color = TradeXColors.primaryText,
    this.maxLines = 2,
  });

  final String text;
  final double width;
  final Color color;
  final int maxLines;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.impact});

  final String impact;

  @override
  Widget build(BuildContext context) {
    final normalized = impact.toUpperCase();
    final color = switch (normalized) {
      'HIGH' => TradeXColors.error,
      'MEDIUM' => TradeXColors.goldBright,
      _ => TradeXColors.success,
    };
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Text(
        normalized,
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
