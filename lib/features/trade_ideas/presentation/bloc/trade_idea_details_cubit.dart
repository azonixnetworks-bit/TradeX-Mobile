import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/user_facing_exception.dart';
import '../../domain/entities/trade_idea_entities.dart';
import '../../domain/repositories/trade_idea_repository.dart';

enum TradeIdeaLoadStatus { initial, loading, ready, failure }

enum TradeIdeaChartTab { analysis, live }

enum TradeIdeaAnalysisStatus { idle, loading, loaded, empty, failure }

class TradeIdeaDetailsState {
  const TradeIdeaDetailsState({
    this.status = TradeIdeaLoadStatus.initial,
    this.detail,
    this.message,
    this.chartTab = TradeIdeaChartTab.analysis,
    this.analysisStatus = TradeIdeaAnalysisStatus.idle,
    this.analysisBytes,
    this.analysisMessage,
    this.reactionBusy = false,
    this.reactionMessage,
  });

  final TradeIdeaLoadStatus status;
  final TradeIdeaDetail? detail;
  final String? message;
  final TradeIdeaChartTab chartTab;
  final TradeIdeaAnalysisStatus analysisStatus;
  final Uint8List? analysisBytes;
  final String? analysisMessage;
  final bool reactionBusy;
  final String? reactionMessage;

  TradeIdeaDetailsState copyWith({
    TradeIdeaLoadStatus? status,
    TradeIdeaDetail? detail,
    String? message,
    bool clearMessage = false,
    TradeIdeaChartTab? chartTab,
    TradeIdeaAnalysisStatus? analysisStatus,
    Uint8List? analysisBytes,
    bool clearAnalysisBytes = false,
    String? analysisMessage,
    bool clearAnalysisMessage = false,
    bool? reactionBusy,
    String? reactionMessage,
    bool clearReactionMessage = false,
  }) => TradeIdeaDetailsState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    message: clearMessage ? null : message ?? this.message,
    chartTab: chartTab ?? this.chartTab,
    analysisStatus: analysisStatus ?? this.analysisStatus,
    analysisBytes: clearAnalysisBytes
        ? null
        : analysisBytes ?? this.analysisBytes,
    analysisMessage: clearAnalysisMessage
        ? null
        : analysisMessage ?? this.analysisMessage,
    reactionBusy: reactionBusy ?? this.reactionBusy,
    reactionMessage: clearReactionMessage
        ? null
        : reactionMessage ?? this.reactionMessage,
  );
}

class TradeIdeaDetailsCubit extends Cubit<TradeIdeaDetailsState> {
  TradeIdeaDetailsCubit({required this.repository, required this.uuid})
    : super(const TradeIdeaDetailsState());

  final TradeIdeaRepositoryContract repository;
  final String uuid;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: TradeIdeaLoadStatus.loading,
        clearMessage: true,
        clearReactionMessage: true,
      ),
    );
    try {
      final detail = await repository.detail(uuid);
      emit(
        state.copyWith(
          status: TradeIdeaLoadStatus.ready,
          detail: detail,
          clearMessage: true,
          analysisStatus: detail.summary.chartAvailable
              ? TradeIdeaAnalysisStatus.idle
              : TradeIdeaAnalysisStatus.empty,
          clearAnalysisBytes: true,
          clearAnalysisMessage: true,
        ),
      );
      if (state.chartTab == TradeIdeaChartTab.analysis &&
          detail.summary.chartAvailable) {
        await loadAnalysis();
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: TradeIdeaLoadStatus.failure,
          message: _message(error, detailRequest: true),
        ),
      );
    }
  }

  void selectChartTab(TradeIdeaChartTab tab) {
    if (state.chartTab == tab) return;
    emit(state.copyWith(chartTab: tab));
    if (tab == TradeIdeaChartTab.analysis &&
        state.analysisStatus == TradeIdeaAnalysisStatus.idle) {
      unawaited(loadAnalysis());
    }
  }

  Future<void> loadAnalysis() async {
    final detail = state.detail;
    if (detail == null) return;
    if (!detail.summary.chartAvailable) {
      emit(
        state.copyWith(
          analysisStatus: TradeIdeaAnalysisStatus.empty,
          clearAnalysisBytes: true,
          clearAnalysisMessage: true,
        ),
      );
      return;
    }
    if (state.analysisStatus == TradeIdeaAnalysisStatus.loading ||
        state.analysisStatus == TradeIdeaAnalysisStatus.loaded) {
      return;
    }
    emit(
      state.copyWith(
        analysisStatus: TradeIdeaAnalysisStatus.loading,
        clearAnalysisMessage: true,
      ),
    );
    try {
      final bytes = await repository.analysisChart(uuid);
      emit(
        state.copyWith(
          analysisStatus: bytes.isEmpty
              ? TradeIdeaAnalysisStatus.empty
              : TradeIdeaAnalysisStatus.loaded,
          analysisBytes: bytes.isEmpty ? null : bytes,
          clearAnalysisMessage: true,
        ),
      );
    } catch (error) {
      final apiError = error is UserFacingException ? error : null;
      emit(
        state.copyWith(
          analysisStatus: apiError?.statusCode == 404
              ? TradeIdeaAnalysisStatus.empty
              : TradeIdeaAnalysisStatus.failure,
          clearAnalysisBytes: true,
          analysisMessage: _message(error),
        ),
      );
    }
  }

  Future<void> react(String reaction) async {
    final detail = state.detail;
    if (detail == null || state.reactionBusy) return;
    final previous = detail.summary.reactions;
    final next = previous.viewerReaction == reaction ? null : reaction;
    emit(
      state.copyWith(
        detail: detail.copyWith(reactions: previous.optimistic(next)),
        reactionBusy: true,
        clearReactionMessage: true,
      ),
    );
    try {
      final confirmed = await repository.react(uuid, next);
      emit(
        state.copyWith(
          detail: state.detail?.copyWith(reactions: confirmed),
          reactionBusy: false,
          clearReactionMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          detail: state.detail?.copyWith(reactions: previous),
          reactionBusy: false,
          reactionMessage: _message(error),
        ),
      );
    }
  }

  String _message(Object error, {bool detailRequest = false}) {
    if (error is UserFacingException) {
      if (error.statusCode == 401) {
        return 'Your TradeX session has ended. Please sign in again.';
      }
      if (error.statusCode == 403) {
        return detailRequest
            ? 'Premium access is required to view Trade Ideas.'
            : 'Premium access is required to view this private analysis.';
      }
      if (error.statusCode == 404) {
        return detailRequest
            ? 'This Trade Idea is no longer available.'
            : 'The admin analysis chart has not been uploaded.';
      }
      return error.message;
    }
    if (error is FormatException) return error.message;
    return 'Trade Idea data is temporarily unavailable. Please try again.';
  }
}
