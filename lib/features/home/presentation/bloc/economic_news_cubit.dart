import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/market_news_repository.dart';

enum EconomicNewsStatus { initial, loading, success, failure }

enum EconomicNewsFilter {
  overview('Overview', null),
  high('High Impact', 'HIGH'),
  medium('Medium Impact', 'MEDIUM'),
  low('Low Impact', 'LOW');

  const EconomicNewsFilter(this.label, this.impact);

  final String label;
  final String? impact;
}

class EconomicNewsState {
  const EconomicNewsState({
    this.status = EconomicNewsStatus.initial,
    this.items = const [],
    this.filter = EconomicNewsFilter.overview,
    required this.now,
  });

  final EconomicNewsStatus status;
  final List<MarketNewsItem> items;
  final EconomicNewsFilter filter;
  final DateTime now;

  List<MarketNewsItem> get visibleItems {
    final impact = filter.impact;
    if (impact == null) return items;
    return items
        .where((item) => item.impact.toUpperCase() == impact)
        .toList(growable: false);
  }

  EconomicNewsState copyWith({
    EconomicNewsStatus? status,
    List<MarketNewsItem>? items,
    EconomicNewsFilter? filter,
    DateTime? now,
  }) => EconomicNewsState(
    status: status ?? this.status,
    items: items ?? this.items,
    filter: filter ?? this.filter,
    now: now ?? this.now,
  );
}

class EconomicNewsCubit extends Cubit<EconomicNewsState> {
  EconomicNewsCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(EconomicNewsState(now: (now ?? DateTime.now)())) {
    _clock = Timer.periodic(
      const Duration(minutes: 1),
      (_) => emit(state.copyWith(now: _now())),
    );
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(load(forceRefresh: true)),
    );
  }

  final MarketNewsRepository _repository;
  final DateTime Function() _now;
  late final Timer _clock;
  late final Timer _refreshTimer;

  Future<void> load({bool forceRefresh = false}) async {
    if (state.items.isEmpty) {
      emit(state.copyWith(status: EconomicNewsStatus.loading, now: _now()));
    }
    try {
      final items = await _repository.today(
        now: _now(),
        forceRefresh: forceRefresh,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: EconomicNewsStatus.success,
          items: items,
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
