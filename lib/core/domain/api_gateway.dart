import 'dart:typed_data';

/// Transport-neutral application boundary used by feature data and legacy
/// secure workflow presenters while their payload contracts remain unchanged.
abstract interface class ApiGateway {
  Future<Map<String, dynamic>> publicPost(
    String path,
    Map<String, dynamic> body,
  );
  Future<void> clearOfflineData();
  Future<Map<String, dynamic>> getJson(String path);
  Future<Map<String, dynamic>> getJsonCacheFirst(String path);
  Future<Uint8List> getBytes(String path);
  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> postJsonWithHeaders(
    String path,
    Map<String, dynamic> body,
    Map<String, String> headers,
  );
  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, dynamic> fields,
    Map<String, String> filePaths,
  );
  Future<Map<String, dynamic>> postMultipartWithHeaders(
    String path,
    Map<String, dynamic> fields,
    Map<String, String> filePaths,
    Map<String, String> headers,
  );
  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> deleteJson(String path);
}
