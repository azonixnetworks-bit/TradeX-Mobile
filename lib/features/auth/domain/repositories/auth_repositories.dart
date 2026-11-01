import '../../../../core/auth/auth_session.dart';
import '../entities/password_recovery_session.dart';
import '../entities/registration_session.dart';

abstract interface class AuthRepositoryContract {
  Future<AuthSession?> restoreRememberedSession();
  Future<AuthSession?> restoreSessionAfterQuickUnlock();
  Future<AuthSession> login({
    required String email,
    required String password,
    String? totpCode,
    String? recoveryCode,
    String? quickUnlockMethod,
    String? quickUnlockPin,
  });
  Future<void> logout({bool forgetDevice = false});
  Future<void> logoutAll();
  Future<QuickUnlockConfig?> quickUnlockConfiguration();
  Future<Map<String, dynamic>> quickUnlockStatus();
  Future<QuickUnlockConfig?> readLocalQuickUnlockConfig();
  Future<void> configureQuickUnlock({
    required bool enabled,
    String? method,
    required String totpCode,
    String? pin,
  });
  Future<void> configureQuickUnlockMethods({
    required bool biometricEnabled,
    required bool passcodeEnabled,
    required String totpCode,
    String? pin,
  });
  Future<AuthSession> quickLogin(QuickUnlockConfig config);
  Future<void> clearLocalQuickUnlock();
  Future<bool> hasCompletedFirstLogin();
  Future<void> markFirstLoginCompleted();
}

class QuickUnlockConfig {
  const QuickUnlockConfig({
    required this.method,
    required this.email,
    required this.credentialId,
    this.biometricEnabled = false,
    this.pinSalt,
    this.pinHash,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final String method;
  final String email;
  final String credentialId;
  final bool biometricEnabled;
  final String? pinSalt;
  final String? pinHash;
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool get hasBiometric =>
      biometricEnabled || method == 'BIOMETRIC' || method == 'BOTH';
  bool get hasPasscode => pinSalt != null && pinHash != null;

  QuickUnlockConfig copyWith({
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) => QuickUnlockConfig(
    method: method,
    email: email,
    credentialId: credentialId,
    biometricEnabled: biometricEnabled,
    pinSalt: pinSalt,
    pinHash: pinHash,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearLock ? null : lockedUntil ?? this.lockedUntil,
  );
}

abstract interface class RegistrationRepositoryContract {
  Future<RegistrationSession> start({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String passwordConfirmation,
    required String countryCode,
    required String languageCode,
    required String referralCode,
  });
  Future<void> verifyEmail(RegistrationSession session, String otpCode);
  Future<void> resendEmail(RegistrationSession session);
  Future<void> verifyWhatsApp(RegistrationSession session, String otpCode);
  Future<void> resendWhatsApp(RegistrationSession session);
  Future<RegistrationTotpSetup> setupTotp(RegistrationSession session);
  Future<void> confirmTotp(RegistrationSession session, String totpCode);
  Future<RegistrationRecoveryCodes> bootstrapRecoveryCodes(
    RegistrationSession session,
  );
}

abstract interface class PasswordRecoveryRepositoryContract {
  Future<PasswordRecoverySession> start({
    required String email,
    required String whatsappNumber,
  });
  Future<void> verifyEmail(PasswordRecoverySession session, String otpCode);
  Future<void> resendEmail(PasswordRecoverySession session);
  Future<void> verifyWhatsApp(PasswordRecoverySession session, String otpCode);
  Future<void> resendWhatsApp(PasswordRecoverySession session);
  Future<void> verifyTotp(PasswordRecoverySession session, String totpCode);
  Future<void> resendResetLink(PasswordRecoverySession session);
  Future<void> resetPassword({
    required PasswordRecoverySession session,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  });
}
