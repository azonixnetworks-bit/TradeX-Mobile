class RegistrationSession {
  const RegistrationSession({
    required this.id,
    required this.token,
    required this.expiresAt,
  });

  final String id;
  final String token;
  final DateTime expiresAt;
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
}

class RegistrationRecoveryCodes {
  const RegistrationRecoveryCodes({required this.codes});

  final List<String> codes;
}
