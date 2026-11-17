import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/market_news_repository.dart';

enum EconomicNewsStatus { initial, loading, success, failure }

enum EconomicNewsFilter {
  overview('Overview', null),
  high('High Impact', 'HIGH'),
  medium('Medium Impact', 'MEDIUM'),
  low('Low Impact', 'LOW'),
  lastSevenDays('Last 7 Days', null);

  const EconomicNewsFilter(this.label, this.impact);

  final String label;
  final String? impact;
}

class EconomicNewsState {
  const EconomicNewsState({
    this.status = EconomicNewsStatus.initial,
    this.items = const [],
    this.pastItems = const [],
    this.filter = EconomicNewsFilter.overview,
    required this.now,
  });

  final EconomicNewsStatus status;
  final List<MarketNewsItem> items;
  final List<MarketNewsItem> pastItems;
  final EconomicNewsFilter filter;
  final DateTime now;

  List<MarketNewsItem> get visibleItems {
    if (filter == EconomicNewsFilter.lastSevenDays) return pastItems;
    final impact = filter.impact;
    if (impact == null) return items;
    return items
        .where((item) => item.impact.toUpperCase() == impact)
        .toList(growable: false);
  }

  EconomicNewsState copyWith({
    EconomicNewsStatus? status,
    List<MarketNewsItem>? items,
    List<MarketNewsItem>? pastItems,
    EconomicNewsFilter? filter,
    DateTime? now,
  }) => EconomicNewsState(
    status: status ?? this.status,
    items: items ?? this.items,
    pastItems: pastItems ?? this.pastItems,
    filter: filter ?? this.filter,
    now: now ?? this.now,
  );
}

class EconomicNewsCubit extends Cubit<EconomicNewsState> {
  EconomicNewsCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(EconomicNewsState(now: (now ?? DateTime.now)())) {
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => emit(state.copyWith(now: _now())),
    );
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(load(forceRefresh: true)),
    );
  }

  final MarketNewsRepositoryContract _repository;
  final DateTime Function() _now;
  late final Timer _clock;
  late final Timer _refreshTimer;

  Future<void> load({bool forceRefresh = false}) async {
    if (state.items.isEmpty) {
      emit(state.copyWith(status: EconomicNewsStatus.loading, now: _now()));
    }
    try {
      final currentNow = _now();
      final results = await Future.wait([
        _repository.today(now: currentNow, forceRefresh: forceRefresh),
        _repository.pastSevenDays(now: currentNow),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: EconomicNewsStatus.success,
          items: results[0],
          pastItems: results[1],
          now: _now(),
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(status: EconomicNewsStatus.failure, now: _now()));
      }
    }
  }

  Future<void> refresh() => load(forceRefresh: true);

  void selectFilter(EconomicNewsFilter filter) {
    if (filter != state.filter) emit(state.copyWith(filter: filter));
  }

  @override
  Future<void> close() {
    _clock.cancel();
    _refreshTimer.cancel();
    return super.close();
  }
}
