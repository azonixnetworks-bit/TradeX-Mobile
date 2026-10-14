class RegistrationSession {
  const RegistrationSession({
    required this.id,
    required this.token,
    required this.expiresAt,
  });

  final String id;
  final String token;
  final DateTime expiresAt;

  factory RegistrationSession.fromJson(Map<String, dynamic> json) {
    return RegistrationSession(
      id: json['registration_id'] as String,
      token: json['registration_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class RegistrationTotpSetup {
  const RegistrationTotpSetup({
    required this.secret,
    required this.otpauthUri,
    required this.issuer,
    required this.accountName,
    required this.digits,
    required this.periodSeconds,
  });

  final String secret;
  final String otpauthUri;
  final String issuer;
  final String accountName;
  final int digits;
  final int periodSeconds;

  factory RegistrationTotpSetup.fromJson(Map<String, dynamic> json) {
    return RegistrationTotpSetup(
      secret: json['secret'] as String,
      otpauthUri: json['otpauth_uri'] as String,
      issuer: json['issuer'] as String,
      accountName: json['account_name'] as String,
      digits: (json['digits'] as num).toInt(),
      periodSeconds: (json['period_seconds'] as num).toInt(),
    );
  }
}
