abstract interface class UserFacingException implements Exception {
  String get message;
  int? get statusCode;
  String? get code;
}
