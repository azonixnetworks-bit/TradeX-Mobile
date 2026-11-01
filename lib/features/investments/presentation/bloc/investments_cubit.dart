import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';

enum InvestmentsStatus { initial, loading, ready, empty, refreshing, error }

class InvestmentsState {
  const InvestmentsState({
    this.status = InvestmentsStatus.initial,
    this.dashboard,
    this.message,
  });

  final InvestmentsStatus status;
  final InvestmentDashboard? dashboard;
  final String? message;

  InvestmentsState copyWith({
    InvestmentsStatus? status,
    InvestmentDashboard? dashboard,
    String? message,
    bool clearMessage = false,
  }) => InvestmentsState(
    status: status ?? this.status,
    dashboard: dashboard ?? this.dashboard,
    message: clearMessage ? null : message ?? this.message,
  );
}

class InvestmentsCubit extends Cubit<InvestmentsState> {
  InvestmentsCubit(this._repository) : super(const InvestmentsState());

  final InvestmentRepository _repository;

  Future<void> load({bool refresh = false}) async {
    emit(
      state.copyWith(
        status: refresh && state.dashboard != null
            ? InvestmentsStatus.refreshing
            : InvestmentsStatus.loading,
        clearMessage: true,
      ),
    );
    try {
      final dashboard = await _repository.loadDashboard(refresh: refresh);
      final empty = dashboard.products.isEmpty && dashboard.investments.isEmpty;
      emit(
        InvestmentsState(
          status: empty ? InvestmentsStatus.empty : InvestmentsStatus.ready,
          dashboard: dashboard,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: InvestmentsStatus.error,
          message: error is InvestmentFeatureUnavailable
              ? error.message
              : 'Unable to load investments. Please try again.',
        ),
      );
    }
  }
}
