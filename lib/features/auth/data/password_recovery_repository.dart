import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../models/password_recovery_session.dart';

class PasswordRecoveryRepository {
  PasswordRecoveryRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  Future<PasswordRecoverySession> start({
    required String email,
    required String whatsappNumber,
  }) async {
    final response = await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/start',
      <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'whatsapp_number': whatsappNumber.trim(),
      },
    );

    return PasswordRecoverySession.fromJson(_data(response));
  }

  Future<void> verifyEmail(
    PasswordRecoverySession session,
    String otpCode,
  ) async {
    await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/email/verify',
      <String, dynamic>{
        ..._sessionPayload(session),
        'otp_code': otpCode.trim(),
      },
    );
  }

  Future<void> resendEmail(PasswordRecoverySession session) async {
    await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/email/resend',
      _sessionPayload(session),
    );
  }

  Future<void> verifyWhatsApp(
    PasswordRecoverySession session,
    String otpCode,
  ) async {
    await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/whatsapp/verify',
      <String, dynamic>{
        ..._sessionPayload(session),
        'otp_code': otpCode.trim(),
      },
    );
  }

  Future<void> resendWhatsApp(PasswordRecoverySession session) async {
    await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/whatsapp/resend',
      _sessionPayload(session),
    );
  }

  Future<void> verifyTotp(
    PasswordRecoverySession session,
    String totpCode,
  ) async {
    final response = await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/totp/verify',
      <String, dynamic>{
        ..._sessionPayload(session),
        'totp_code': totpCode.trim(),
      },
    );

    final data = _data(response);

    if (data['reset_link_sent'] != true) {
      throw const ApiException(
        message: 'TradeX could not issue a password reset link.',
      );
    }
  }

  Future<void> resendResetLink(PasswordRecoverySession session) async {
    await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/reset-link/resend',
      _sessionPayload(session),
    );
  }

  Future<void> resetPassword({
    required PasswordRecoverySession session,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.publicPost(
      '/api/v1/auth/password-recovery/reset',
      <String, dynamic>{
        ..._sessionPayload(session),
        'reset_token': resetToken.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = _data(response);

    if (data['completed'] != true) {
      throw const ApiException(
        message: 'TradeX password reset could not be completed.',
      );
    }
  }

  Map<String, dynamic> _sessionPayload(PasswordRecoverySession session) {
    return <String, dynamic>{
      'recovery_id': session.id,
      'recovery_token': session.token,
    };
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final raw = response['data'];

    if (raw is! Map) {
      throw const ApiException(
        message: 'TradeX returned an invalid password recovery response.',
      );
    }

    return Map<String, dynamic>.from(raw);
  }
}
