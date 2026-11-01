abstract interface class UserFacingException implements Exception {
  String get message;
  int? get statusCode;
  String? get code;
}

class UserFacingFailure implements UserFacingException {
  const UserFacingFailure({required this.message, this.statusCode, this.code});
  @override
  final String message;
  @override
  final int? statusCode;
  @override
  final String? code;
}
