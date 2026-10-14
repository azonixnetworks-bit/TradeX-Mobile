class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.sessionUuid,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;

  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  final String sessionUuid;

  final Map<String, dynamic> user;

  bool get accessTokenExpired {
    final safetyTime = accessExpiresAt.subtract(const Duration(seconds: 30));

    return DateTime.now().isAfter(safetyTime);
  }

  bool get refreshTokenExpired {
    return DateTime.now().isAfter(refreshExpiresAt);
  }

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? accessExpiresAt,
    DateTime? refreshExpiresAt,
    String? sessionUuid,
    Map<String, dynamic>? user,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
      sessionUuid: sessionUuid ?? this.sessionUuid,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'access_expires_at': accessExpiresAt.toIso8601String(),
      'refresh_expires_at': refreshExpiresAt.toIso8601String(),
      'session_uuid': sessionUuid,
      'user': user,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
      refreshExpiresAt: DateTime.parse(json['refresh_expires_at'] as String),
      sessionUuid: json['session_uuid'] as String,
      user: Map<String, dynamic>.from(json['user'] as Map),
    );
  }
}
