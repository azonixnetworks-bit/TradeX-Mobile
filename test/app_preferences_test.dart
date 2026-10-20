import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'first installation defaults to system theme and language prompt',
    () async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences.instance.load();
      expect(AppPreferences.instance.themeMode, ThemeMode.system);
      expect(AppPreferences.instance.learnLanguageSelected, isFalse);
      expect(AppPreferences.instance.courseLanguage, 'en');
    },
  );

  test('theme and course language selections persist', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();
    await AppPreferences.instance.setThemeMode(ThemeMode.light);
    await AppPreferences.instance.setCourseLanguage('ta');
    await AppPreferences.instance.load();
    expect(AppPreferences.instance.themeMode, ThemeMode.light);
    expect(AppPreferences.instance.courseLanguage, 'ta');
    expect(AppPreferences.instance.learnLanguageSelected, isTrue);
  });

  test('light and dark TradeX themes expose matching brightness', () {
    expect(TradeXTheme.light.brightness, Brightness.light);
    expect(TradeXTheme.dark.brightness, Brightness.dark);
  });
}
