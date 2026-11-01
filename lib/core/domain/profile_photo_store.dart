import 'dart:typed_data';

abstract interface class ProfilePhotoStore {
  Future<CachedProfilePhoto?> read(String accountEmail);
  Future<Uint8List> saveBytes({
    required String accountEmail,
    required Uint8List bytes,
    required int version,
  });
  Future<void> remove(String accountEmail);
}

class CachedProfilePhoto {
  const CachedProfilePhoto({required this.bytes, required this.version});
  final Uint8List bytes;
  final int version;
}
