import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../models/registration_session.dart';

class RegistrationRepository {
  RegistrationRepository(this._apiClient);

  final TradeXApiClient _apiClient;

  Future<RegistrationSession> start({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String passwordConfirmation,
    required String countryCode,
    required String languageCode,
    required String referralCode,
  }) async {
    final response = await _apiClient.publicPost(
      '/api/v1/auth/register/start',
      <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'whatsapp_number': whatsappNumber.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        'country_code': countryCode.trim().toUpperCase(),
        'language_code': languageCode.trim().toLowerCase(),
        'referral_code': referralCode.trim().toUpperCase(),
      },
    );

    return RegistrationSession.fromJson(_data(response));
  }

  Future<void> verifyEmail(RegistrationSession session, String otpCode) async {
    await _apiClient.publicPost(
      '/api/v1/auth/register/email/verify',
      <String, dynamic>{
        ..._sessionPayload(session),
        'otp_code': otpCode.trim(),
      },
    );
  }

  Future<void> resendEmail(RegistrationSession session) async {
    await _apiClient.publicPost(
      '/api/v1/auth/register/email/resend',
      _sessionPayload(session),
    );
  }

  Future<void> verifyWhatsApp(
    RegistrationSession session,
    String otpCode,
  ) async {
    await _apiClient.publicPost(
      '/api/v1/auth/register/whatsapp/verify',
      <String, dynamic>{
        ..._sessionPayload(session),
        'otp_code': otpCode.trim(),
      },
    );
  }

  Future<void> resendWhatsApp(RegistrationSession session) async {
    await _apiClient.publicPost(
      '/api/v1/auth/register/whatsapp/resend',
      _sessionPayload(session),
    );
  }

  Future<RegistrationTotpSetup> setupTotp(RegistrationSession session) async {
    final response = await _apiClient.publicPost(
      '/api/v1/auth/register/totp/setup',
      _sessionPayload(session),
    );

    return RegistrationTotpSetup.fromJson(_data(response));
  }

  Future<void> confirmTotp(RegistrationSession session, String totpCode) async {
    final response = await _apiClient.publicPost(
      '/api/v1/auth/register/totp/confirm',
      <String, dynamic>{
        ..._sessionPayload(session),
        'totp_code': totpCode.trim(),
      },
    );

    final data = _data(response);

    if (data['completed'] != true) {
      throw const ApiException(
        message: 'TradeX registration could not be completed.',
      );
    }
  }

  Map<String, dynamic> _sessionPayload(RegistrationSession session) {
    return <String, dynamic>{
      'registration_id': session.id,
      'registration_token': session.token,
    };
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final raw = response['data'];

    if (raw is! Map) {
      throw const ApiException(
        message: 'TradeX returned an invalid registration response.',
      );
    }

    return Map<String, dynamic>.from(raw);
  }
}
