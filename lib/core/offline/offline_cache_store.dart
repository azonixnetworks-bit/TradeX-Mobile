import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class OfflineCacheStore {
  OfflineCacheStore({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;
  Future<void> _writeTail = Future<void>.value();

  Future<void> put({
    required String accountKey,
    required String requestKey,
    required Map<String, dynamic> payload,
    required Duration maxAge,
  }) => _serialWrite(() async {
    final now = DateTime.now().toUtc();
    final file = await _entryFile(accountKey, requestKey);
    await file.parent.create(recursive: true);
    await _writeJson(file, <String, dynamic>{
      'version': 1,
      'request_key': requestKey,
      'cached_at': now.toIso8601String(),
      'expires_at': now.add(maxAge).toIso8601String(),
      'payload': payload,
    });
    await _trim(file.parent);
  });

  Future<OfflineCacheEntry?> get({
    required String accountKey,
    required String requestKey,
  }) async {
    try {
      final file = await _entryFile(accountKey, requestKey);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded);
      final payload = data['payload'];
      final cachedAt = DateTime.tryParse(data['cached_at']?.toString() ?? '');
      final expiresAt = DateTime.tryParse(data['expires_at']?.toString() ?? '');
      if (payload is! Map || cachedAt == null || expiresAt == null) return null;
      return OfflineCacheEntry(
        payload: Map<String, dynamic>.from(payload),
        cachedAt: cachedAt,
        expiresAt: expiresAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> enqueue({
    required String accountKey,
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) => _serialWrite(() async {
    final file = await _queueFile(accountKey);
    final items = await _readQueue(file);
    final key = '$method $path';
    items.removeWhere((item) => item.key == key);
    items.add(
      OfflineMutation(
        key: key,
        method: method,
        path: path,
        body: body,
        queuedAt: DateTime.now().toUtc(),
      ),
    );
    await file.parent.create(recursive: true);
    await _writeJson(file, <String, dynamic>{
      'version': 1,
      'items': items.map((item) => item.toJson()).toList(),
    });
  });

  Future<List<OfflineMutation>> queued(String accountKey) async {
    try {
      return await _readQueue(await _queueFile(accountKey));
    } catch (_) {
      return const [];
    }
  }

  Future<void> removeQueued(String accountKey, String key) =>
      _serialWrite(() async {
        final file = await _queueFile(accountKey);
        final items = await _readQueue(file)
          ..removeWhere((item) => item.key == key);
        if (items.isEmpty) {
          if (await file.exists()) await file.delete();
          return;
        }
        await _writeJson(file, <String, dynamic>{
          'version': 1,
          'items': items.map((item) => item.toJson()).toList(),
        });
      });

  Future<void> clearAccount(String accountKey) => _serialWrite(() async {
    final directory = await _accountDirectory(accountKey);
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<List<OfflineMutation>> _readQueue(File file) async {
    if (!await file.exists()) return <OfflineMutation>[];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map || decoded['items'] is! List) {
      return <OfflineMutation>[];
    }
    return (decoded['items'] as List)
        .whereType<Map>()
        .map(
          (item) => OfflineMutation.fromJson(Map<String, dynamic>.from(item)),
        )
        .whereType<OfflineMutation>()
        .toList();
  }

  Future<File> _entryFile(String accountKey, String requestKey) async {
    final directory = await _accountDirectory(accountKey);
    return File(
      '${directory.path}${Platform.pathSeparator}${_hash(requestKey)}.json',
    );
  }

  Future<File> _queueFile(String accountKey) async {
    final directory = await _accountDirectory(accountKey);
    return File(
      '${directory.path}${Platform.pathSeparator}safe-mutations.json',
    );
  }

  Future<Directory> _accountDirectory(String accountKey) async {
    final root = await _directoryProvider();
    return Directory(
      '${root.path}${Platform.pathSeparator}tradex-offline-v1${Platform.pathSeparator}${_hash(accountKey)}',
    );
  }

  Future<void> _writeJson(File file, Map<String, dynamic> value) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(value), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<void> _trim(Directory directory) async {
    final files = await directory
        .list()
        .where((entry) => entry is File && entry.path.endsWith('.json'))
        .cast<File>()
        .toList();
    final dated = <({File file, DateTime modified, int size})>[];
    for (final file in files) {
      if (file.path.endsWith('safe-mutations.json')) continue;
      final stat = await file.stat();
      dated.add((file: file, modified: stat.modified, size: stat.size));
    }
    dated.sort((a, b) => b.modified.compareTo(a.modified));
    var total = 0;
    for (var index = 0; index < dated.length; index++) {
      total += dated[index].size;
      if (index >= 79 || total > 8 * 1024 * 1024) {
        await dated[index].file.delete();
      }
    }
  }

  Future<void> _serialWrite(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.catchError((_) {});
    return next;
  }

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
}

class OfflineCacheEntry {
  const OfflineCacheEntry({
    required this.payload,
    required this.cachedAt,
    required this.expiresAt,
  });

  final Map<String, dynamic> payload;
  final DateTime cachedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
}

class OfflineMutation {
  const OfflineMutation({
    required this.key,
    required this.method,
    required this.path,
    required this.body,
    required this.queuedAt,
  });

  final String key;
  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'method': method,
    'path': path,
    'body': body,
    'queued_at': queuedAt.toIso8601String(),
  };

  static OfflineMutation? fromJson(Map<String, dynamic> json) {
    final key = json['key']?.toString();
    final method = json['method']?.toString();
    final path = json['path']?.toString();
    final queuedAt = DateTime.tryParse(json['queued_at']?.toString() ?? '');
    if (key == null || method == null || path == null || queuedAt == null) {
      return null;
    }
    final body = json['body'];
    return OfflineMutation(
      key: key,
      method: method,
      path: path,
      body: body is Map ? Map<String, dynamic>.from(body) : null,
      queuedAt: queuedAt,
    );
  }
}
