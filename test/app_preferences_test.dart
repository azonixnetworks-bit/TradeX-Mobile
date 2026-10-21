import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/preferences/app_preferences.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';

void main() {
  test('quick unlock background lock defaults to thirty minutes', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();

    expect(AppPreferences.instance.quickUnlockBackgroundLockSeconds, 1800);
  });

  test('two-minute installs migrate to thirty minutes', () async {
    SharedPreferences.setMockInitialValues({
      'tradex.quick_unlock.background_lock_seconds': 120,
    });
    await AppPreferences.instance.load();

    expect(AppPreferences.instance.quickUnlockBackgroundLockSeconds, 1800);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('tradex.quick_unlock.background_lock_seconds'),
      1800,
    );
  });

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

  test('selected dashboard tab persists across app restoration', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();
    await AppPreferences.instance.setDashboardTab(3);
    await AppPreferences.instance.load();
    expect(AppPreferences.instance.dashboardTab, 3);
  });

  test('background resume timestamp and server lock policy persist', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();
    final backgroundedAt = DateTime.utc(2026, 10, 20, 12, 30);
    await AppPreferences.instance.markBackgrounded(backgroundedAt);
    await AppPreferences.instance.setQuickUnlockBackgroundLockSeconds(45);

    await AppPreferences.instance.load();
    expect(AppPreferences.instance.lastBackgroundedAt, backgroundedAt);
    expect(AppPreferences.instance.quickUnlockBackgroundLockSeconds, 45);

    await AppPreferences.instance.clearBackgroundedAt();
    await AppPreferences.instance.load();
    expect(AppPreferences.instance.lastBackgroundedAt, isNull);
  });
}
