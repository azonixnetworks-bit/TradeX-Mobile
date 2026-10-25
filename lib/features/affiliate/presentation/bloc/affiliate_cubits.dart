import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/affiliate_repository.dart';

enum AffiliateLoadStatus { initial, loading, ready, empty, failure, premium }

class AffiliateLoadState {
  const AffiliateLoadState({
    this.status = AffiliateLoadStatus.initial,
    this.data = const {},
    this.message,
  });

  final AffiliateLoadStatus status;
  final JsonMap data;
  final String? message;

  AffiliateLoadState copyWith({
    AffiliateLoadStatus? status,
    JsonMap? data,
    String? message,
  }) => AffiliateLoadState(
    status: status ?? this.status,
    data: data ?? this.data,
    message: message,
  );
}

class AffiliateLoadCubit extends Cubit<AffiliateLoadState> {
  AffiliateLoadCubit(this._loader) : super(const AffiliateLoadState());

  final Future<JsonMap> Function() _loader;

  Future<void> load() async {
    emit(state.copyWith(status: AffiliateLoadStatus.loading));
    try {
      final data = await _loader();
      emit(
        AffiliateLoadState(
          status: data.isEmpty
              ? AffiliateLoadStatus.empty
              : AffiliateLoadStatus.ready,
          data: data,
        ),
      );
    } on ApiException catch (error) {
      emit(
        AffiliateLoadState(
          status:
              error.code == 'AFFILIATE_PREMIUM_REQUIRED' ||
                  error.code == 'PAYOUT_PREMIUM_REQUIRED'
              ? AffiliateLoadStatus.premium
              : AffiliateLoadStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        const AffiliateLoadState(
          status: AffiliateLoadStatus.failure,
          message: 'This information is unavailable right now.',
        ),
      );
    }
  }
}

enum ReferralFilter { all, qualified, noSale }

class ReferralState {
  const ReferralState({
    this.status = AffiliateLoadStatus.initial,
    this.items = const [],
    this.search = '',
    this.filter = ReferralFilter.all,
    this.page = 1,
    this.lastPage = 1,
    this.loadingMore = false,
    this.message,
  });

  final AffiliateLoadStatus status;
  final List<JsonMap> items;
  final String search;
  final ReferralFilter filter;
  final int page;
  final int lastPage;
  final bool loadingMore;
  final String? message;

  ReferralState copyWith({
    AffiliateLoadStatus? status,
    List<JsonMap>? items,
    String? search,
    ReferralFilter? filter,
    int? page,
    int? lastPage,
    bool? loadingMore,
    String? message,
  }) => ReferralState(
    status: status ?? this.status,
    items: items ?? this.items,
    search: search ?? this.search,
    filter: filter ?? this.filter,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
    loadingMore: loadingMore ?? this.loadingMore,
    message: message,
  );
}

class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit(this._repository) : super(const ReferralState());

  final AffiliateRepository _repository;
  Timer? _debounce;

  String? get _qualification => switch (state.filter) {
    ReferralFilter.qualified => 'QUALIFIED',
    ReferralFilter.noSale => 'NO_QUALIFIED_SALE',
    ReferralFilter.all => null,
  };

  void search(String value) {
    emit(state.copyWith(search: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  void filter(ReferralFilter value) {
    if (value == state.filter) return;
    emit(state.copyWith(filter: value));
    unawaited(load());
  }

  Future<void> load() async {
    emit(state.copyWith(status: AffiliateLoadStatus.loading));
    await _fetch(1, append: false);
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.page >= state.lastPage) return;
    emit(state.copyWith(loadingMore: true));
    await _fetch(state.page + 1, append: true);
  }

  Future<void> _fetch(int page, {required bool append}) async {
    try {
      final data = await _repository.referrals(
        page: page,
        search: state.search,
        qualification: _qualification,
      );
      final incoming = AffiliateRepository.listOf(data['items']);
      final pagination = AffiliateRepository.mapOf(data['pagination']);
      final items = append ? [...state.items, ...incoming] : incoming;
      emit(
        state.copyWith(
          status: items.isEmpty
              ? AffiliateLoadStatus.empty
              : AffiliateLoadStatus.ready,
          items: items,
          page: AffiliateRepository.integer(pagination['current_page']),
          lastPage: AffiliateRepository.integer(pagination['last_page']),
          loadingMore: false,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: error.code == 'AFFILIATE_PREMIUM_REQUIRED'
              ? AffiliateLoadStatus.premium
              : AffiliateLoadStatus.failure,
          loadingMore: false,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AffiliateLoadStatus.failure,
          loadingMore: false,
          message: 'Referrals are unavailable right now.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

class PayoutState extends AffiliateLoadState {
  const PayoutState({
    super.status,
    super.data,
    super.message,
    this.submitting = false,
  });

  final bool submitting;
}

class PayoutCubit extends Cubit<PayoutState> {
  PayoutCubit(this._repository) : super(const PayoutState());

  final AffiliateRepository _repository;

  Future<void> load() async {
    emit(const PayoutState(status: AffiliateLoadStatus.loading));
    try {
      final values = await Future.wait([
        _repository.payoutSummary(),
        _repository.payoutMethods(),
        _repository.payoutHistory(),
      ]);
      emit(
        PayoutState(
          status: AffiliateLoadStatus.ready,
          data: {
            'summary': values[0],
            'methods': values[1],
            'history': values[2],
          },
        ),
      );
    } on ApiException catch (error) {
      emit(
        PayoutState(
          status: error.code == 'PAYOUT_PREMIUM_REQUIRED'
              ? AffiliateLoadStatus.premium
              : AffiliateLoadStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        const PayoutState(
          status: AffiliateLoadStatus.failure,
          message: 'Payout information is unavailable right now.',
        ),
      );
    }
  }

  Future<String?> submit(String method, String amount) async {
    if (state.submitting) return null;
    emit(PayoutState(status: state.status, data: state.data, submitting: true));
    try {
      await _repository.requestPayout(method: method, amount: amount);
      await load();
      return null;
    } on ApiException catch (error) {
      emit(
        PayoutState(
          status: state.status,
          data: state.data,
          message: error.message,
        ),
      );
      return error.message;
    } catch (_) {
      const message = 'The withdrawal request could not be submitted.';
      emit(
        PayoutState(status: state.status, data: state.data, message: message),
      );
      return message;
    }
  }
}
