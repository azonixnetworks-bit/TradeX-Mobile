import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/replay/presentation/bloc/replay_terminal_cubit.dart';

String event(String type, Map<String, Object?> payload) => jsonEncode({
  'version': 1,
  'type': type,
  'payload': payload,
});

void main() {
  test('visual-only ready handshake does not enable trade execution', () async {
    final cubit = ReplayTerminalCubit();
    cubit.receiveMessage(event('TERMINAL_READY', {
      'contractVersion': 1,
      'mode': 'VISUAL_ONLY',
      'executionEnabled': false,
    }));
    expect(cubit.state.phase, ReplayTerminalPhase.ready);
    expect(cubit.state.executionEnabled, isFalse);
    await cubit.close();
  });

  test('rejects a terminal claiming trade execution', () async {
    final cubit = ReplayTerminalCubit();
    cubit.receiveMessage(event('TERMINAL_READY', {
      'contractVersion': 1,
      'mode': 'LIVE_TRADING',
      'executionEnabled': true,
    }));
    expect(cubit.state.phase, ReplayTerminalPhase.error);
    expect(cubit.state.executionEnabled, isFalse);
    await cubit.close();
  });

  test('state follows existing terminal clock without owning a second timer', () async {
    final cubit = ReplayTerminalCubit();
    cubit.receiveMessage(event('REPLAY_STATE_CHANGED', {
      'status': 'PAUSED',
      'timeframe': 'M5',
      'time': 1736161200,
      'speed': 2,
    }));
    expect(cubit.state.timeframe, 'M5');
    expect(cubit.state.revealedTime, 1736161200);
    expect(cubit.state.speed, 2);
    await cubit.close();
  });

  test('untrusted protocol and malformed payloads ignored', () async {
    final cubit = ReplayTerminalCubit();
    cubit.receiveMessage('{broken json');
    cubit.receiveMessage(event('REPLAY_STATE_CHANGED', {
      'status': 'BOGUS', 'timeframe': 'M15', 'time': 5, 'speed': 1,
    }));
    cubit.receiveMessage(jsonEncode({
      'version': 2, 'type': 'TERMINAL_READY', 'payload': {},
    }));
    expect(cubit.state.phase, ReplayTerminalPhase.loading);
    expect(cubit.state.playback, 'PAUSED');
    await cubit.close();
  });

  test('command IDs increase and unsafe trading commands fail closed', () async {
    final cubit = ReplayTerminalCubit();
    final first = cubit.nextCommand('STEP');
    final second = cubit.nextCommand('PAUSE');
    expect(first['id'], isNot(second['id']));
    expect(() => cubit.nextCommand('SUBMIT_ORDER'), throwsArgumentError);
    expect(() => cubit.nextCommand('LOAD_DATASET'), throwsArgumentError);
    expect(() => cubit.nextCommand('SET_SPEED', 3), throwsArgumentError);
    expect(() => cubit.nextCommand('SET_TIMEFRAME', 'M2'), throwsArgumentError);
    await cubit.close();
  });

  test('missing bundles display an explicit unavailable state', () async {
    final cubit = ReplayTerminalCubit();
    cubit.missingBundle();
    expect(cubit.state.phase, ReplayTerminalPhase.unavailable);
    expect(cubit.state.message, contains('not bundled'));
    await cubit.close();
  });
}
