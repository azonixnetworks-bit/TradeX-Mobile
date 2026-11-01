import 'package:bloc/bloc.dart';

import '../../domain/entities/risk_reward_entities.dart';
import '../../domain/repositories/risk_reward_repository.dart';

enum RiskRewardStatus { initial, loading, ready, failure }

class RiskRewardState {
  const RiskRewardState({
    this.status = RiskRewardStatus.initial,
    this.catalog,
    this.result,
    this.dividendResult,
    this.saved = const [],
    this.submitting = false,
    this.saving = false,
    this.error,
  });

  final RiskRewardStatus status;
  final RiskRewardCatalog? catalog;
  final RiskRewardResult? result;
  final DividendResult? dividendResult;
  final List<SavedCalculation> saved;
  final bool submitting;
  final bool saving;
  final String? error;

  RiskRewardState copyWith({
    RiskRewardStatus? status,
    RiskRewardCatalog? catalog,
    RiskRewardResult? result,
    DividendResult? dividendResult,
    List<SavedCalculation>? saved,
    bool? submitting,
    bool? saving,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) => RiskRewardState(
    status: status ?? this.status,
    catalog: catalog ?? this.catalog,
    result: clearResult ? null : result ?? this.result,
    dividendResult: clearResult ? null : dividendResult ?? this.dividendResult,
    saved: saved ?? this.saved,
    submitting: submitting ?? this.submitting,
    saving: saving ?? this.saving,
    error: clearError ? null : error ?? this.error,
  );
}

class RiskRewardCubit extends Cubit<RiskRewardState> {
  RiskRewardCubit(this.repository) : super(const RiskRewardState());

  final RiskRewardRepository repository;

  Future<void> initialize({bool forceRefresh = false}) async {
    if (state.catalog == null) {
      emit(state.copyWith(status: RiskRewardStatus.loading, clearError: true));
    }
    try {
      final catalog = await repository.catalog(forceRefresh: forceRefresh);
      List<SavedCalculation> saved = state.saved;
      try {
        saved = await repository.saved();
      } catch (_) {
        // Catalog and calculators remain usable when saved history is offline.
      }
      emit(
        state.copyWith(
          status: RiskRewardStatus.ready,
          catalog: catalog,
          saved: saved,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: RiskRewardStatus.failure,
          error: _message(error),
        ),
      );
    }
  }

  Future<RiskRewardResult?> calculate(Map<String, dynamic> input) async {
    if (state.submitting) return null;
    emit(state.copyWith(submitting: true, clearError: true, clearResult: true));
    try {
      final result = await repository.calculate(input);
      emit(state.copyWith(result: result, submitting: false));
      return result;
    } catch (error) {
      emit(state.copyWith(submitting: false, error: _message(error)));
      return null;
    }
  }

  Future<DividendResult?> calculateDividend(Map<String, dynamic> input) async {
    if (state.submitting) return null;
    emit(state.copyWith(submitting: true, clearError: true, clearResult: true));
    try {
      final result = await repository.calculateDividend(input);
      emit(state.copyWith(dividendResult: result, submitting: false));
      return result;
    } catch (error) {
      emit(state.copyWith(submitting: false, error: _message(error)));
      return null;
    }
  }

  Future<bool> saveCurrent({
    required String type,
    required Map<String, dynamic> input,
  }) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final item = await repository.save(type: type, input: input);
      emit(state.copyWith(saving: false, saved: [item, ...state.saved]));
      return true;
    } catch (error) {
      emit(state.copyWith(saving: false, error: _message(error)));
      return false;
    }
  }

  void clearResult() =>
      emit(state.copyWith(clearResult: true, clearError: true));

  String _message(Object error) =>
      'The calculator is temporarily unavailable. Please try again.';
}
