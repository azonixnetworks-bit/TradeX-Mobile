import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/bloc/bloc_future_builder.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/features/home/presentation/bloc/home_navigation_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preferences cubit emits persisted theme changes', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();

    final next = AppPreferences.instance.stream.first;
    await AppPreferences.instance.setThemeMode(ThemeMode.dark);

    expect((await next).themeMode, ThemeMode.dark);
    final stored = await SharedPreferences.getInstance();
    expect(stored.getString('tradex.theme_mode'), 'dark');
  });

  test('dashboard navigation cubit emits and persists selected tab', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();
    final cubit = HomeNavigationCubit(preferences: AppPreferences.instance);
    addTearDown(cubit.close);

    cubit.select(4);
    expect(cubit.state, 4);
    await Future<void>.delayed(Duration.zero);

    final stored = await SharedPreferences.getInstance();
    expect(stored.getInt('tradex.dashboard.selected_tab'), 4);
  });

  test('bloc future cubit ignores an obsolete request result', () async {
    final cubit = BlocFutureCubit<int>();
    addTearDown(cubit.close);
    final oldRequest = Completer<int>();
    final newRequest = Completer<int>();

    unawaited(cubit.load(oldRequest.future));
    unawaited(cubit.load(newRequest.future));
    newRequest.complete(2);
    await Future<void>.delayed(Duration.zero);
    oldRequest.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.connectionState, ConnectionState.done);
    expect(cubit.state.requireData, 2);
  });
}
