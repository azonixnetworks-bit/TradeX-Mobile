import '../domain/user_facing_exception.dart';

class ApiException implements UserFacingException {
  // Keep the public `message` parameter while storing only the raw private
  // value; every consumer must receive the sanitized getter below.
  const ApiException({
    required String message,
    this.statusCode,
    this.code,
    this.validationErrors,
    // ignore: prefer_initializing_formals
  }) : _message = message;

  final String _message;
  @override
  final int? statusCode;
  @override
  final String? code;

  final Map<String, List<String>>? validationErrors;

  /// A safe message for presentation surfaces.
  ///
  /// Backend routes, URLs, SQL errors and stack details must never be exposed
  /// in the customer application. The original value remains private so every
  /// existing UI consumer automatically receives the sanitized message.
  @override
  String get message {
    final value = _message.trim();
    if (value.isEmpty || _containsTechnicalDetail(value)) {
      if (statusCode == 404) {
        return 'This information is not available yet.';
      }
      if ((statusCode ?? 0) >= 500) {
        return 'The service is temporarily unavailable. Please try again.';
      }
      return 'The request could not be completed. Please try again.';
    }
    return value;
  }

  static bool _containsTechnicalDetail(String value) {
    final lower = value.toLowerCase();
    return lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('sqlstate') ||
        lower.contains('stack trace') ||
        lower.contains('illuminate\\') ||
        RegExp(
          r'(^|[\s(])/?api/v\d+(/|[\s).,]|$)',
          caseSensitive: false,
        ).hasMatch(value) ||
        RegExp(
          r'\b(route|endpoint)\b.*\b(not found|not defined|missing)\b',
          caseSensitive: false,
        ).hasMatch(value);
  }

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
