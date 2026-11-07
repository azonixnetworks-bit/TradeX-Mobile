import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

typedef MarketAssetFetcher = Future<Uint8List?> Function(Uri uri);

class MarketAssetDiskCache {
  MarketAssetDiskCache({
    Future<Directory> Function()? directoryProvider,
    MarketAssetFetcher? fetcher,
    this.maximumBytes = 150 * 1024 * 1024,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _fetcher = fetcher ?? _fetchHttps;

  static final instance = MarketAssetDiskCache();

  final Future<Directory> Function() _directoryProvider;
  final MarketAssetFetcher _fetcher;
  final int maximumBytes;
  final Map<String, Future<Uint8List?>> _inFlight = {};

  Future<Uint8List?> resolve({required String assetKey, required String url}) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      return Future<Uint8List?>.value();
    }
    final cacheKey = '$assetKey|$url';
    return _inFlight.putIfAbsent(cacheKey, () async {
      try {
        final file = await _file(cacheKey);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            await file.setLastModified(DateTime.now());
            return bytes;
          }
        }
        final bytes = await _fetcher(uri);
        if (bytes == null || bytes.isEmpty || bytes.length > 3 * 1024 * 1024) {
          return null;
        }
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsBytes(bytes, flush: true);
        if (await file.exists()) await file.delete();
        await temporary.rename(file.path);
        unawaited(_trim(file.parent));
        return bytes;
      } catch (_) {
        return null;
      } finally {
        _inFlight.remove(cacheKey);
      }
    });
  }

  Future<File> _file(String cacheKey) async {
    final root = await _directoryProvider();
    final digest = sha256.convert(utf8.encode(cacheKey));
    return File(
      '${root.path}${Platform.pathSeparator}tradex-market-assets-v1'
      '${Platform.pathSeparator}$digest.img',
    );
  }

  Future<void> _trim(Directory directory) async {
    try {
      final files = await directory
          .list()
          .where((entry) => entry is File && entry.path.endsWith('.img'))
          .cast<File>()
          .toList();
      final entries = <({File file, DateTime modified, int size})>[];
      for (final file in files) {
        final stat = await file.stat();
        entries.add((file: file, modified: stat.modified, size: stat.size));
      }
      entries.sort((left, right) => right.modified.compareTo(left.modified));
      var total = 0;
      for (var index = 0; index < entries.length; index++) {
        total += entries[index].size;
        if (total > maximumBytes) await entries[index].file.delete();
      }
    } catch (_) {
      // Cache maintenance must never block a market screen.
    }
  }

  static Future<Uint8List?> _fetchHttps(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'image/*');
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != HttpStatus.ok) return null;
      final mime = response.headers.contentType?.mimeType.toLowerCase() ?? '';
      if (!mime.startsWith('image/')) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
        if (builder.length > 3 * 1024 * 1024) return null;
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }
}
