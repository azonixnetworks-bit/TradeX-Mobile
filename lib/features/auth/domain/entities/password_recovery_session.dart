class PasswordRecoverySession {
  const PasswordRecoverySession({
    required this.id,
    required this.token,
    this.nextAction = 'VERIFY_EMAIL_OTP',
  });

  final String id;
  final String token;
  /// Initial verification channel, selected from the supplied contact.
  final String nextAction;
}
