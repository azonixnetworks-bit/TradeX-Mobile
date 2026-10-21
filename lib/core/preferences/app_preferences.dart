import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  static const _themeKey = 'tradex.theme_mode';
  static const _languageKey = 'tradex.course_language';
  static const _learnLanguageSeenKey = 'tradex.learn_language_selected';
  static const _dashboardTabKey = 'tradex.dashboard.selected_tab';
  static const _backgroundedAtKey = 'tradex.session.backgrounded_at_ms';
  static const _quickUnlockBackgroundLockKey =
      'tradex.quick_unlock.background_lock_seconds';

  ThemeMode _themeMode = ThemeMode.system;
  String _courseLanguage = 'en';
  bool _learnLanguageSelected = false;
  int _dashboardTab = 0;
  DateTime? _lastBackgroundedAt;
  int _quickUnlockBackgroundLockSeconds = 1800;

  ThemeMode get themeMode => _themeMode;
  String get courseLanguage => _courseLanguage;
  bool get learnLanguageSelected => _learnLanguageSelected;
  int get dashboardTab => _dashboardTab;
  DateTime? get lastBackgroundedAt => _lastBackgroundedAt;
  int get quickUnlockBackgroundLockSeconds => _quickUnlockBackgroundLockSeconds;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = switch (preferences.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _courseLanguage = preferences.getString(_languageKey) ?? 'en';
    _learnLanguageSelected =
        preferences.getBool(_learnLanguageSeenKey) ?? false;
    _dashboardTab = (preferences.getInt(_dashboardTabKey) ?? 0).clamp(0, 4);
    final backgroundedAtMs = preferences.getInt(_backgroundedAtKey);
    _lastBackgroundedAt = backgroundedAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(backgroundedAtMs, isUtc: true);
    final savedBackgroundLockSeconds = preferences.getInt(
      _quickUnlockBackgroundLockKey,
    );
    _quickUnlockBackgroundLockSeconds =
        (savedBackgroundLockSeconds == null ||
            savedBackgroundLockSeconds == 120)
        ? 1800
        : savedBackgroundLockSeconds.clamp(0, 86400);
    if (savedBackgroundLockSeconds == 120) {
      await preferences.setInt(_quickUnlockBackgroundLockKey, 1800);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, mode.name);
  }

  Future<void> setCourseLanguage(String languageCode) async {
    _courseLanguage = languageCode.trim().toLowerCase();
    _learnLanguageSelected = true;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, _courseLanguage);
    await preferences.setBool(_learnLanguageSeenKey, true);
  }

  Future<void> setDashboardTab(int index) async {
    final normalized = index.clamp(0, 4);
    if (_dashboardTab == normalized) return;
    _dashboardTab = normalized;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_dashboardTabKey, normalized);
  }

  Future<void> markBackgrounded(DateTime value) async {
    _lastBackgroundedAt = value.toUtc();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _backgroundedAtKey,
      _lastBackgroundedAt!.millisecondsSinceEpoch,
    );
  }

  Future<void> clearBackgroundedAt() async {
    _lastBackgroundedAt = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_backgroundedAtKey);
  }

  Future<void> setQuickUnlockBackgroundLockSeconds(int value) async {
    _quickUnlockBackgroundLockSeconds = value.clamp(0, 86400);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _quickUnlockBackgroundLockKey,
      _quickUnlockBackgroundLockSeconds,
    );
  }
}
