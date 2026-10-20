import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  static const _themeKey = 'tradex.theme_mode';
  static const _languageKey = 'tradex.course_language';
  static const _learnLanguageSeenKey = 'tradex.learn_language_selected';

  ThemeMode _themeMode = ThemeMode.system;
  String _courseLanguage = 'en';
  bool _learnLanguageSelected = false;

  ThemeMode get themeMode => _themeMode;
  String get courseLanguage => _courseLanguage;
  bool get learnLanguageSelected => _learnLanguageSelected;

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
}
