class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.validationErrors,
  });

  final String message;
  final int? statusCode;
  final String? code;

  final Map<String, List<String>>? validationErrors;

  bool get isAuthenticationFailure {
    return statusCode == 401 ||
        code == 'INVALID_CREDENTIALS' ||
        code == 'INVALID_REFRESH_TOKEN' ||
        code == 'REFRESH_TOKEN_EXPIRED' ||
        code == 'REFRESH_TOKEN_REUSED' ||
        code == 'DEVICE_BINDING_MISMATCH' ||
        code == 'DEVICE_SESSION_REVOKED' ||
        code == 'DEVICE_REVOKED';
  }

  bool get shouldClearSession {
    return isAuthenticationFailure ||
        code == 'ACCOUNT_NOT_ACTIVE' ||
        code == 'DEVICE_NOT_TRUSTED';
  }

  @override
  String toString() => message;
}
