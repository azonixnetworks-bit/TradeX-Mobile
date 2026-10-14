class PasswordRecoverySession {
  const PasswordRecoverySession({
    required this.id,
    required this.token,
  });

  final String id;
  final String token;

  factory PasswordRecoverySession.fromJson(Map<String, dynamic> json) {
    return PasswordRecoverySession(
      id: json['recovery_id'] as String,
      token: json['recovery_token'] as String,
    );
  }
}
