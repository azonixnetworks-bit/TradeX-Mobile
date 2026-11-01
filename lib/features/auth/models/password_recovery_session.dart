import '../domain/entities/password_recovery_session.dart' as domain;

class PasswordRecoverySession extends domain.PasswordRecoverySession {
  const PasswordRecoverySession({required super.id, required super.token});

  factory PasswordRecoverySession.fromJson(Map<String, dynamic> json) {
    return PasswordRecoverySession(
      id: json['recovery_id'] as String,
      token: json['recovery_token'] as String,
    );
  }
}
