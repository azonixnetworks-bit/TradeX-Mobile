import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small account-scoped, encrypted telemetry outbox. It contains only
/// allowlisted activity categories, never credentials or lesson/journal content.
class ActivityEventStore {
  ActivityEventStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const int maxEvents = 300;
  final FlutterSecureStorage _storage;
  Future<void> _tail = Future<void>.value();

  String _key(String accountId) =>
      'tradex.activity.v1.${sha256.convert(utf8.encode(accountId))}';

  Future<List<Map<String, dynamic>>> pending(String accountId) async {
    await _tail;
    return _read(accountId);
  }

  Future<void> append(String accountId, Map<String, dynamic> event) =>
      _serial(() async {
        final events = await _read(accountId);
        final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 6));
        events.removeWhere((item) {
          final occurred = DateTime.tryParse(
            item['occurred_at']?.toString() ?? '',
          );
          return occurred == null || occurred.isBefore(cutoff);
        });
        if (!events.any((item) => item['event_id'] == event['event_id'])) {
          events.add(event);
        }
        if (events.length > maxEvents) {
          events.removeRange(0, events.length - maxEvents);
        }
        await _write(accountId, events);
      });

  Future<void> remove(String accountId, Set<String> deliveredIds) =>
      _serial(() async {
        final events = await _read(accountId);
        events.removeWhere((event) => deliveredIds.contains(event['event_id']));
        await _write(accountId, events);
      });

  Future<void> clear(String accountId) =>
      _serial(() => _storage.delete(key: _key(accountId)));

  Future<List<Map<String, dynamic>>> _read(String accountId) async {
    try {
      final raw = await _storage.read(key: _key(accountId));
      if (raw == null) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      // Corrupt telemetry must never interrupt application workflows.
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _write(
    String accountId,
    List<Map<String, dynamic>> events,
  ) async {
    if (events.isEmpty) {
      await _storage.delete(key: _key(accountId));
    } else {
      await _storage.write(key: _key(accountId), value: jsonEncode(events));
    }
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.catchError((Object _) {});
    return next;
  }
}
