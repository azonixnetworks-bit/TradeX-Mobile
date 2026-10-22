import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoWatchlistStore {
  CryptoWatchlistStore({
    Future<SharedPreferences>? preferences,
    Future<String?>? accountKey,
  }) : _accountKey = accountKey ?? Future<String?>.value(),
       _preferences = preferences ?? SharedPreferences.getInstance();

  static const _storageKey = 'crypto_watchlist_symbols_v1';

  final Future<SharedPreferences> _preferences;
  final Future<String?> _accountKey;

  Future<Set<String>> load() async {
    final preferences = await _preferences;
    final storageKey = await _resolvedStorageKey();
    return (preferences.getStringList(storageKey) ?? const <String>[])
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toSet();
  }

  Future<void> save(Set<String> symbols) async {
    final preferences = await _preferences;
    final storageKey = await _resolvedStorageKey();
    final normalized = symbols
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toList(growable: false);
    await preferences.setStringList(storageKey, normalized);
  }

  Future<String> _resolvedStorageKey() async {
    final accountKey = (await _accountKey)?.trim();
    if (accountKey == null || accountKey.isEmpty) return _storageKey;
    final accountHash = sha256.convert(utf8.encode(accountKey)).toString();
    return '${_storageKey}_$accountHash';
  }
}
