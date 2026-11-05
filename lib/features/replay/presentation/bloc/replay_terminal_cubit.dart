import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

/// The app owns the terminal lifecycle. The embedded chart owns its replay clock.
/// No user balance, broker token or Python execution state crosses this bridge.
enum ReplayTerminalPhase { loading, ready, unavailable, error }

class ReplayTerminalState {
  const ReplayTerminalState({
    this.phase = ReplayTerminalPhase.loading,
    this.playback = 'PAUSED',
    this.timeframe = 'M15',
    this.revealedTime,
    this.speed = 1,
    this.message,
    this.isSynthetic = true,
    this.executionEnabled = false,
  });

  final ReplayTerminalPhase phase;
  final String playback;
  final String timeframe;
  final int? revealedTime;
  final int speed;
  final String? message;
  final bool isSynthetic;

  /// Must stay disabled until an independently verified Python/mobile parity
  /// implementation and licensed historical-data delivery are integrated.
  final bool executionEnabled;

  ReplayTerminalState copyWith({
    ReplayTerminalPhase? phase,
    String? playback,
    String? timeframe,
    int? revealedTime,
    int? speed,
    String? message,
    bool clearMessage = false,
    bool? isSynthetic,
  }) => ReplayTerminalState(
    phase: phase ?? this.phase,
    playback: playback ?? this.playback,
    timeframe: timeframe ?? this.timeframe,
    revealedTime: revealedTime ?? this.revealedTime,
    speed: speed ?? this.speed,
    message: clearMessage ? null : (message ?? this.message),
    isSynthetic: isSynthetic ?? this.isSynthetic,
    executionEnabled: false,
  );
}

class ReplayTerminalCubit extends Cubit<ReplayTerminalState> {
  ReplayTerminalCubit() : super(const ReplayTerminalState());

  static const allowedCommands = <String>{
    'PLAY', 'PAUSE', 'STEP', 'GET_STATE', 'SET_TIMEFRAME', 'SET_SPEED',
  };
  static const timeframes = <String>{
    'M1', 'M3', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1',
  };
  static const playbackStates = <String>{'PLAYING', 'PAUSED', 'COMPLETE'};
  int _sequence = 0;

  void missingBundle() => emit(state.copyWith(
    phase: ReplayTerminalPhase.unavailable,
    message: 'Replay chart assets are not bundled. Build and export the '
        'TradeX Replay Terminal before running this feature.',
  ));

  void failed(String message) => emit(state.copyWith(
    phase: ReplayTerminalPhase.error,
    message: message,
  ));

  /// Terminal -> Flutter: restricted, versioned, informational events only.
  void receiveMessage(String raw) {
    if (raw.length > 8192) return;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1 ||
        decoded['type'] is! String ||
        decoded['payload'] is! Map<String, dynamic>) {
      return;
    }
    final event = decoded['type'] as String;
    final payload = decoded['payload'] as Map<String, dynamic>;
    switch (event) {
      case 'TERMINAL_READY':
        if (payload['contractVersion'] != 1 ||
            payload['mode'] != 'VISUAL_ONLY' ||
            payload['executionEnabled'] != false) {
          failed('The replay terminal protocol is incompatible.');
          return;
        }
        emit(state.copyWith(phase: ReplayTerminalPhase.ready, clearMessage: true));
        return;
      case 'REPLAY_STATE_CHANGED':
        final status = payload['status'];
        final timeframe = payload['timeframe'];
        final time = payload['time'];
        final speed = payload['speed'];
        if (!playbackStates.contains(status) || !timeframes.contains(timeframe) ||
            time is! int || time < 0 || speed is! int ||
            !<int>{1, 2, 5, 10}.contains(speed)) {
          return;
        }
        emit(state.copyWith(
          playback: status as String,
          timeframe: timeframe as String,
          revealedTime: time,
          speed: speed,
          clearMessage: true,
        ));
        return;
      case 'DATA_GAP':
        emit(state.copyWith(
          playback: 'PAUSED',
          message: 'Historical M1 gap detected. Playback paused.',
        ));
        return;
      case 'DATASET_LOADED':
        // A reported provider is not an authenticated market-data provenance.
        emit(state.copyWith(isSynthetic: payload['providerAsserted'] == 'SYNTHETIC_DEMO'));
        return;
      case 'COMMAND_ERROR':
        final detail = payload['message'];
        emit(state.copyWith(
          message: detail is String && detail.length <= 150
              ? detail
              : 'Replay command was rejected.',
        ));
      case 'DRAFT_PREVIEWED':
        // Deliberately no virtual order execution or account event.
        return;
      default:
        return;
    }
  }

  /// Flutter -> Terminal. NEVER expose SUBMIT_ORDER or broker endpoints here.
  Map<String, Object?> nextCommand(String type, [Object? payload]) {
    if (!allowedCommands.contains(type)) {
      throw ArgumentError.value(type, 'type', 'Unsupported replay command');
    }
    if (type == 'SET_TIMEFRAME' && !timeframes.contains(payload)) {
      throw ArgumentError.value(payload, 'payload', 'Unsupported timeframe');
    }
    if (type == 'SET_SPEED' &&
        (payload is! int || !<int>{1, 2, 5, 10}.contains(payload))) {
      throw ArgumentError.value(payload, 'payload', 'Unsupported speed');
    }
    _sequence++;
    final command = <String, Object?>{
      'version': 1,
      'id': 'flutter-$_sequence',
      'type': type,
    };
    if (payload != null) command['payload'] = payload;
    return command;
  }
}
