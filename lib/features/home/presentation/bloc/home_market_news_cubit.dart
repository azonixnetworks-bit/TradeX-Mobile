import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/market_news_repository.dart';

enum HomeMarketNewsStatus { initial, loading, success, failure }

class HomeMarketNewsState {
  const HomeMarketNewsState({
    this.status = HomeMarketNewsStatus.initial,
    this.items = const [],
  });

  final HomeMarketNewsStatus status;
  final List<MarketNewsItem> items;
}

class HomeMarketNewsCubit extends Cubit<HomeMarketNewsState> {
  HomeMarketNewsCubit(this._repository) : super(const HomeMarketNewsState()) {
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(load(forceRefresh: true)),
    );
  }

  final MarketNewsRepository _repository;
  late final Timer _refreshTimer;

  Future<void> load({bool forceRefresh = false}) async {
    if (state.items.isEmpty) {
      emit(
        HomeMarketNewsState(
          status: HomeMarketNewsStatus.loading,
          items: state.items,
        ),
      );
    }
    try {
      final items = await _repository.latest(forceRefresh: forceRefresh);
      if (!isClosed) {
        emit(
          HomeMarketNewsState(
            status: HomeMarketNewsStatus.success,
            items: items,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          HomeMarketNewsState(
            status: HomeMarketNewsStatus.failure,
            items: state.items,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _refreshTimer.cancel();
    return super.close();
  }
}
