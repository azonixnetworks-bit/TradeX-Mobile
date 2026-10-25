import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

typedef ProfilePhotoDirectoryProvider = Future<Directory> Function();

/// Keeps profile photos in the application's private support directory.
///
/// The email is hashed before it is used as a filename, so different TradeX
/// accounts on the same phone never share an avatar or expose their address in
/// the filesystem. The authenticated Laravel copy is authoritative; this store
/// only keeps a versioned cache so the avatar remains available offline.
class LocalProfilePhotoStore {
  const LocalProfilePhotoStore({
    this.directoryProvider = getApplicationSupportDirectory,
  });

  final ProfilePhotoDirectoryProvider directoryProvider;

  Future<CachedProfilePhoto?> read(String accountEmail) async {
    final file = await _fileFor(accountEmail);
    if (!await file.exists()) return null;
    final versionFile = await _versionFileFor(accountEmail);
    final version = await versionFile.exists()
        ? int.tryParse(await versionFile.readAsString()) ?? 0
        : 0;
    return CachedProfilePhoto(
      bytes: await file.readAsBytes(),
      version: version,
    );
  }

  Future<Uint8List> saveBytes({
    required String accountEmail,
    required Uint8List bytes,
    required int version,
  }) async {
    final destination = await _fileFor(accountEmail);
    final versionDestination = await _versionFileFor(accountEmail);
    await destination.parent.create(recursive: true);
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    if (await destination.exists()) await destination.delete();
    await temporary.rename(destination.path);
    final versionTemporary = File('${versionDestination.path}.tmp');
    await versionTemporary.writeAsString('$version', flush: true);
    if (await versionDestination.exists()) await versionDestination.delete();
    await versionTemporary.rename(versionDestination.path);
    return bytes;
  }

  Future<void> remove(String accountEmail) async {
    final file = await _fileFor(accountEmail);
    if (await file.exists()) await file.delete();
    final versionFile = await _versionFileFor(accountEmail);
    if (await versionFile.exists()) await versionFile.delete();
  }

  Future<File> _fileFor(String accountEmail) async {
    final root = await directoryProvider();
    final accountHash = sha256
        .convert(accountEmail.trim().toLowerCase().codeUnits)
        .toString();
    return File(
      '${root.path}${Platform.pathSeparator}tradex${Platform.pathSeparator}'
      'profile${Platform.pathSeparator}$accountHash.image',
    );
  }

  Future<File> _versionFileFor(String accountEmail) async {
    final file = await _fileFor(accountEmail);
    return File('${file.path}.version');
  }
}

class CachedProfilePhoto {
  const CachedProfilePhoto({required this.bytes, required this.version});

  final Uint8List bytes;
  final int version;
}
