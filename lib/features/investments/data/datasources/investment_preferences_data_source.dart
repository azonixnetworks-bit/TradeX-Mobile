import 'package:shared_preferences/shared_preferences.dart';

abstract interface class InvestmentPreferencesDataSource {
  Future<bool> hideValues();
  Future<void> setHideValues(bool value);
}

final class SharedPreferencesInvestmentPreferencesDataSource
    implements InvestmentPreferencesDataSource {
  static const _hiddenKey = 'tradex.investments.hide_values';

  @override
  Future<bool> hideValues() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_hiddenKey) ?? false;
  }

  @override
  Future<void> setHideValues(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hiddenKey, value);
  }
}
