import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps profile photos in the application's private support directory.
///
/// The email is hashed before it is used as a filename, so different TradeX
/// accounts on the same phone never share an avatar or expose their address in
/// the filesystem. Nothing in this store is uploaded to the backend.
class LocalProfilePhotoStore {
  const LocalProfilePhotoStore();

  Future<Uint8List?> read(String accountEmail) async {
    final file = await _fileFor(accountEmail);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<Uint8List> saveFromPath({
    required String accountEmail,
    required String sourcePath,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final destination = await _fileFor(accountEmail);
    await destination.parent.create(recursive: true);
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    if (await destination.exists()) await destination.delete();
    await temporary.rename(destination.path);
    return bytes;
  }

  Future<void> remove(String accountEmail) async {
    final file = await _fileFor(accountEmail);
    if (await file.exists()) await file.delete();
  }

  Future<File> _fileFor(String accountEmail) async {
    final root = await getApplicationSupportDirectory();
    final accountHash = sha256
        .convert(accountEmail.trim().toLowerCase().codeUnits)
        .toString();
    return File(
      '${root.path}${Platform.pathSeparator}tradex${Platform.pathSeparator}'
      'profile${Platform.pathSeparator}$accountHash.image',
    );
  }
}
