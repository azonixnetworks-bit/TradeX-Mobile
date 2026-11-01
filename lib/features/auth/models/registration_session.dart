import '../domain/entities/registration_session.dart' as domain;

class RegistrationSession extends domain.RegistrationSession {
  const RegistrationSession({
    required super.id,
    required super.token,
    required super.expiresAt,
  });

  factory RegistrationSession.fromJson(Map<String, dynamic> json) {
    return RegistrationSession(
      id: json['registration_id'] as String,
      token: json['registration_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class RegistrationTotpSetup extends domain.RegistrationTotpSetup {
  const RegistrationTotpSetup({
    required super.secret,
    required super.otpauthUri,
    required super.issuer,
    required super.accountName,
    required super.digits,
    required super.periodSeconds,
  });

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

class RegistrationRecoveryCodes extends domain.RegistrationRecoveryCodes {
  const RegistrationRecoveryCodes({required super.codes});

  factory RegistrationRecoveryCodes.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['recovery_codes'];

    if (rawCodes is! List) {
      throw const FormatException('TradeX returned invalid recovery codes.');
    }

    final codes = rawCodes
        .whereType<String>()
        .map((code) => code.trim())
        .where((code) => code.isNotEmpty)
        .toList(growable: false);

    if (codes.isEmpty) {
      throw const FormatException('TradeX returned empty recovery codes.');
    }

    return RegistrationRecoveryCodes(codes: codes);
  }
}
