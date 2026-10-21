import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesState {
  const AppPreferencesState({
    this.themeMode = ThemeMode.system,
    this.courseLanguage = 'en',
    this.learnLanguageSelected = false,
    this.dashboardTab = 0,
    this.lastBackgroundedAt,
    this.quickUnlockBackgroundLockSeconds = 1800,
  });

  final ThemeMode themeMode;
  final String courseLanguage;
  final bool learnLanguageSelected;
  final int dashboardTab;
  final DateTime? lastBackgroundedAt;
  final int quickUnlockBackgroundLockSeconds;
}

class AppPreferences extends Cubit<AppPreferencesState> {
  AppPreferences._() : super(const AppPreferencesState());

  static final AppPreferences instance = AppPreferences._();

  static const _themeKey = 'tradex.theme_mode';
  static const _languageKey = 'tradex.course_language';
  static const _learnLanguageSeenKey = 'tradex.learn_language_selected';
  static const _dashboardTabKey = 'tradex.dashboard.selected_tab';
  static const _backgroundedAtKey = 'tradex.session.backgrounded_at_ms';
  static const _quickUnlockBackgroundLockKey =
      'tradex.quick_unlock.background_lock_seconds';

  ThemeMode get themeMode => state.themeMode;
  String get courseLanguage => state.courseLanguage;
  bool get learnLanguageSelected => state.learnLanguageSelected;
  int get dashboardTab => state.dashboardTab;
  DateTime? get lastBackgroundedAt => state.lastBackgroundedAt;
  int get quickUnlockBackgroundLockSeconds =>
      state.quickUnlockBackgroundLockSeconds;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final themeMode = switch (preferences.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final courseLanguage = preferences.getString(_languageKey) ?? 'en';
    final learnLanguageSelected =
        preferences.getBool(_learnLanguageSeenKey) ?? false;
    final dashboardTab = (preferences.getInt(_dashboardTabKey) ?? 0).clamp(
      0,
      4,
    );
    final backgroundedAtMs = preferences.getInt(_backgroundedAtKey);
    final lastBackgroundedAt = backgroundedAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(backgroundedAtMs, isUtc: true);
    final savedBackgroundLockSeconds = preferences.getInt(
      _quickUnlockBackgroundLockKey,
    );
    final quickUnlockBackgroundLockSeconds =
        (savedBackgroundLockSeconds == null ||
            savedBackgroundLockSeconds == 120)
        ? 1800
        : savedBackgroundLockSeconds.clamp(0, 86400);
    emit(
      AppPreferencesState(
        themeMode: themeMode,
        courseLanguage: courseLanguage,
        learnLanguageSelected: learnLanguageSelected,
        dashboardTab: dashboardTab,
        lastBackgroundedAt: lastBackgroundedAt,
        quickUnlockBackgroundLockSeconds: quickUnlockBackgroundLockSeconds,
      ),
    );
    if (savedBackgroundLockSeconds == 120) {
      await preferences.setInt(_quickUnlockBackgroundLockKey, 1800);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(
      AppPreferencesState(
        themeMode: mode,
        courseLanguage: courseLanguage,
        learnLanguageSelected: learnLanguageSelected,
        dashboardTab: dashboardTab,
        lastBackgroundedAt: lastBackgroundedAt,
        quickUnlockBackgroundLockSeconds: quickUnlockBackgroundLockSeconds,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, mode.name);
  }

  Future<void> setCourseLanguage(String languageCode) async {
    final normalized = languageCode.trim().toLowerCase();
    emit(
      AppPreferencesState(
        themeMode: themeMode,
        courseLanguage: normalized,
        learnLanguageSelected: true,
        dashboardTab: dashboardTab,
        lastBackgroundedAt: lastBackgroundedAt,
        quickUnlockBackgroundLockSeconds: quickUnlockBackgroundLockSeconds,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, normalized);
    await preferences.setBool(_learnLanguageSeenKey, true);
  }

  Future<void> setDashboardTab(int index) async {
    final normalized = index.clamp(0, 4);
    if (dashboardTab == normalized) return;
    emit(
      AppPreferencesState(
        themeMode: themeMode,
        courseLanguage: courseLanguage,
        learnLanguageSelected: learnLanguageSelected,
        dashboardTab: normalized,
        lastBackgroundedAt: lastBackgroundedAt,
        quickUnlockBackgroundLockSeconds: quickUnlockBackgroundLockSeconds,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_dashboardTabKey, normalized);
  }

  Future<void> markBackgrounded(DateTime value) async {
    final backgroundedAt = value.toUtc();
    emit(
      AppPreferencesState(
        themeMode: themeMode,
        courseLanguage: courseLanguage,
        learnLanguageSelected: learnLanguageSelected,
        dashboardTab: dashboardTab,
        lastBackgroundedAt: backgroundedAt,
        quickUnlockBackgroundLockSeconds: quickUnlockBackgroundLockSeconds,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _backgroundedAtKey,
      backgroundedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> clearBackgroundedAt() async {
    emit(
      AppPreferencesState(
        themeMode: themeMode,
        courseLanguage: courseLanguage,
        learnLanguageSelected: learnLanguageSelected,
        dashboardTab: dashboardTab,
        quickUnlockBackgroundLockSeconds: quickUnlockBackgroundLockSeconds,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_backgroundedAtKey);
  }

  Future<void> setQuickUnlockBackgroundLockSeconds(int value) async {
    final normalized = value.clamp(0, 86400);
    emit(
      AppPreferencesState(
        themeMode: themeMode,
        courseLanguage: courseLanguage,
        learnLanguageSelected: learnLanguageSelected,
        dashboardTab: dashboardTab,
        lastBackgroundedAt: lastBackgroundedAt,
        quickUnlockBackgroundLockSeconds: normalized,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_quickUnlockBackgroundLockKey, normalized);
  }
}
