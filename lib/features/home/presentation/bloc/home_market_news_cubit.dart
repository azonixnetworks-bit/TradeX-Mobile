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
  HomeMarketNewsCubit(this._repository) : super(const HomeMarketNewsState());

  final MarketNewsRepository _repository;

  Future<void> load() async {
    emit(
      HomeMarketNewsState(
        status: HomeMarketNewsStatus.loading,
        items: state.items,
      ),
    );
    try {
      final items = await _repository.latest();
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
}
