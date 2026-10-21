import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/preferences/app_preferences.dart';

class HomeNavigationCubit extends Cubit<int> {
  HomeNavigationCubit({required AppPreferences preferences, int? initialIndex})
    : _preferences = preferences,
      super((initialIndex ?? preferences.dashboardTab).clamp(0, 4));

  final AppPreferences _preferences;

  void select(int index) {
    final normalized = index.clamp(0, 4);
    if (normalized == state) return;
    emit(normalized);
    unawaited(_preferences.setDashboardTab(normalized));
  }
}
