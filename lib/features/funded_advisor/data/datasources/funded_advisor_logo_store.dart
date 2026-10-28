import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/tradex_api_client.dart';

abstract interface class FundedAdvisorLogoStore {
  Future<Uint8List?> read(String cacheKey);

  Future<void> write(String cacheKey, Uint8List bytes);
}

final class DiskFundedAdvisorLogoStore implements FundedAdvisorLogoStore {
  DiskFundedAdvisorLogoStore(
    this._apiClient, {
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final TradeXApiClient _apiClient;
  final Future<Directory> Function() _directoryProvider;

  @override
  Future<Uint8List?> read(String cacheKey) async {
    try {
      final file = await _file(cacheKey);
      if (file == null || !await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String cacheKey, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 3 * 1024 * 1024) return;
    try {
      final file = await _file(cacheKey);
      if (file == null) return;
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
      await _trim(file.parent);
    } catch (_) {
      // A logo cache failure must never block the funded advisor screens.
    }
  }

  Future<File?> _file(String cacheKey) async {
    final accountKey = await _apiClient.currentAccountStorageKey();
    if (accountKey == null) return null;
    final root = await _directoryProvider();
    final accountHash = sha256.convert(accountKey.codeUnits).toString();
    final keyHash = sha256.convert(cacheKey.codeUnits).toString();
    return File(
      '${root.path}${Platform.pathSeparator}tradex-funded-logos-v1'
      '${Platform.pathSeparator}$accountHash${Platform.pathSeparator}$keyHash.img',
    );
  }

  Future<void> _trim(Directory directory) async {
    final files = await directory
        .list()
        .where((entry) => entry is File && entry.path.endsWith('.img'))
        .cast<File>()
        .toList();
    final dated = <({File file, DateTime modified, int size})>[];
    for (final file in files) {
      final stat = await file.stat();
      dated.add((file: file, modified: stat.modified, size: stat.size));
    }
    dated.sort((a, b) => b.modified.compareTo(a.modified));
    var total = 0;
    for (var index = 0; index < dated.length; index++) {
      total += dated[index].size;
      if (index >= 24 || total > 12 * 1024 * 1024) {
        await dated[index].file.delete();
      }
    }
  }
}
