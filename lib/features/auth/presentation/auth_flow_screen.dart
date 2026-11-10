import 'dart:async';

import 'package:flutter/material.dart';

import '../data/pending_registration_store.dart';

import '../domain/entities/password_recovery_session.dart';
import '../domain/entities/registration_session.dart';
import '../domain/repositories/auth_repositories.dart';
import '../domain/services/quick_unlock_service.dart';
import 'auth_success_screen.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'new_password_screen.dart';
import 'register_screen.dart';
import 'registration_totp_setup_screen.dart';
import 'registration_details_screen.dart';
import 'registration_recovery_codes_screen.dart';
import 'registration_verification_gate_screen.dart';
import 'registration_pending_dashboard_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'widgets/otp_verification_screen.dart';

enum _AuthStep {
  splash,
  welcome,
  login,
  register,
  registerLanguage,
  registerGate,
  pendingRegistrationDashboard,
  registerEmailOtp,
  registerWhatsAppOtp,
  registerTotpSetup,
  registerTotpVerify,
  registerRecoveryCodes,
  registerComplete,
  forgotPassword,
  recoveryEmailOtp,
  recoveryWhatsAppOtp,
  recoveryTotp,
  newPassword,
  passwordResetComplete,
}

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    super.key,
    required this.authRepository,
    required this.registrationRepository,
    required this.passwordRecoveryRepository,
    required this.onAuthenticated,
    this.quickUnlockConfig,
    this.onQuickUnlock,
    required this.quickUnlockService,
  });

  final AuthRepositoryContract authRepository;
  final RegistrationRepositoryContract registrationRepository;
  final PasswordRecoveryRepositoryContract passwordRecoveryRepository;
  final QuickUnlockService quickUnlockService;
  final VoidCallback onAuthenticated;
  final QuickUnlockConfig? quickUnlockConfig;
  final Future<void> Function()? onQuickUnlock;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  late _AuthStep _step;
  bool? _hasCompletedFirstLogin;

  RegistrationSession? _registrationSession;
  RegistrationTotpSetup? _registrationTotpSetup;
  RegistrationRecoveryCodes? _registrationRecoveryCodes;
  _RegistrationDraft? _registrationDraft;
  final PendingRegistrationStore _pendingStore = const PendingRegistrationStore();
  Future<void>? _pendingLoadFuture;

  RegistrationReferralValidatorContract get _referralValidator {
    final repository = widget.registrationRepository;
    if (repository is RegistrationReferralValidatorContract) {
      return repository as RegistrationReferralValidatorContract;
    }
    throw StateError('Referral validation service is unavailable.');
  }

  PasswordRecoverySession? _recoverySession;

  String _registrationEmail = '';
  String _registrationWhatsApp = '';
  String _recoveryEmail = '';
  String _recoveryWhatsApp = '';

  @override
  void initState() {
    super.initState();
    // Show the same branded splash on cold start, including quick unlock.
    _step = _AuthStep.splash;
    _loadLoginHistory();
    _pendingLoadFuture = _restorePendingRegistration();
  }

  Future<void> _restorePendingRegistration() async {
    try {
      final pending = await _pendingStore.read();
      if (!mounted || pending == null) return;
      _registrationSession = pending.session;
      _registrationEmail = pending.email;
      _registrationWhatsApp = pending.phone;
    } catch (_) {
      // Secure-storage availability must not block normal login.
    }
  }

  Future<void> _loadLoginHistory() async {
    final completed = await widget.authRepository.hasCompletedFirstLogin();
    if (mounted) {
      setState(() => _hasCompletedFirstLogin = completed);
    }
  }

  void _setStep(_AuthStep step) {
    if (!mounted) {
      return;
    }

    setState(() {
      _step = step;
    });
  }

  void _showWelcome() => _setStep(_AuthStep.welcome);

  Future<void> _continueAfterSplash() async {
    await _pendingLoadFuture;
    if (!mounted) return;
    if (_registrationSession != null) {
      _setStep(_AuthStep.pendingRegistrationDashboard);
      return;
    }
    final completed =
        _hasCompletedFirstLogin ??
        await widget.authRepository.hasCompletedFirstLogin();
    if (!mounted) return;
    _setStep(completed ? _AuthStep.login : _AuthStep.welcome);
  }

  void _showLogin() {
    _clearRegistration();
    _clearRecovery();
    _setStep(_AuthStep.login);
  }

  void _showRegister() {
    _clearRegistration();
    _setStep(_AuthStep.register);
  }

  void _showForgotPassword() {
    _clearRecovery();
    _setStep(_AuthStep.forgotPassword);
  }

  void _skipOnboarding() {
    _showLogin();
  }

  void _goBack() {
    switch (_step) {
      case _AuthStep.register:
        _showWelcome();
      case _AuthStep.registerLanguage:
        _setStep(_AuthStep.register);
      case _AuthStep.registerGate:
        _setStep(_AuthStep.pendingRegistrationDashboard);
      case _AuthStep.pendingRegistrationDashboard:
        _setStep(_AuthStep.login);
      case _AuthStep.registerEmailOtp:
        _setStep(_AuthStep.pendingRegistrationDashboard);
      case _AuthStep.registerWhatsAppOtp:
        _setStep(_AuthStep.registerEmailOtp);
      case _AuthStep.registerTotpSetup:
        _setStep(_AuthStep.registerWhatsAppOtp);
      case _AuthStep.registerTotpVerify:
        _setStep(_AuthStep.registerTotpSetup);
      case _AuthStep.registerRecoveryCodes:
        break;
      case _AuthStep.login:
        _showWelcome();
      case _AuthStep.forgotPassword:
        _showLogin();
      case _AuthStep.recoveryEmailOtp:
        _setStep(_AuthStep.forgotPassword);
      case _AuthStep.recoveryWhatsAppOtp:
        _setStep(_AuthStep.recoveryEmailOtp);
      case _AuthStep.recoveryTotp:
        _setStep(_AuthStep.recoveryWhatsAppOtp);
      case _AuthStep.newPassword:
        _setStep(_AuthStep.recoveryTotp);
      case _AuthStep.registerComplete:
      case _AuthStep.passwordResetComplete:
      case _AuthStep.splash:
      case _AuthStep.welcome:
        break;
    }
  }

  void _clearRegistration() {
    unawaited(_pendingStore.clear().catchError((Object _) {}));
    _registrationSession = null;
    _registrationTotpSetup = null;
    _registrationRecoveryCodes = null;
    _registrationDraft = null;
    _registrationEmail = '';
    _registrationWhatsApp = '';
  }

  void _clearRecovery() {
    _recoverySession = null;
    _recoveryEmail = '';
    _recoveryWhatsApp = '';
  }

  Future<void> _login({
    required String email,
    required String password,
    String? totpCode,
    String? recoveryCode,
    String? quickUnlockMethod,
    String? quickUnlockPin,
  }) async {
    await widget.authRepository.login(
      email: email,
      password: password,
      totpCode: totpCode,
      recoveryCode: recoveryCode,
      quickUnlockMethod: quickUnlockMethod,
      quickUnlockPin: quickUnlockPin,
    );

    await widget.authRepository.markFirstLoginCompleted();

    if (!mounted) {
      return;
    }

    widget.onAuthenticated();
  }

  Future<void> _collectRegistrationDetails({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    setState(() {
      _registrationDraft = _RegistrationDraft(
        name: name,
        email: email,
        whatsappNumber: '',
        password: password,
        passwordConfirmation: passwordConfirmation,
        countryCode: '',
        referralCode: '',
      );
      _step = _AuthStep.registerLanguage;
    });
  }

  Future<void> _completeRegistrationDetails({
    required String countryCode,
    required String phone,
    required String referralCode,
  }) async {
    final draft = _registrationDraft;
    if (draft == null) {
      throw StateError('Registration details are missing. Please start again.');
    }

    if (!await _referralValidator.validateReferralCode(referralCode)) {
      throw StateError('The referral code is invalid or unavailable.');
    }

    // Registration is still pending; no authenticated access token is issued.
    final session = await widget.registrationRepository.start(
      name: draft.name,
      email: draft.email,
      whatsappNumber: phone,
      password: draft.password,
      passwordConfirmation: draft.passwordConfirmation,
      countryCode: countryCode,
      languageCode: 'en',
      referralCode: referralCode,
    );

    try {
      await _pendingStore.save(
        session: session,
        name: draft.name,
        email: draft.email,
        phone: phone,
      );
    } catch (_) {
      // In-memory verification remains available when keychain is unavailable.
    }

    if (!mounted) return;
    setState(() {
      _registrationSession = session;
      _registrationEmail = draft.email.trim();
      _registrationWhatsApp = phone.trim();
      _registrationDraft = null; // Stop retaining password data in the widget.
      _step = _AuthStep.pendingRegistrationDashboard;
    });
  }

  Future<void> _beginVerification() async {
    final session = _registrationSession;
    if (session == null || !session.expiresAt.isAfter(DateTime.now())) {
      _clearRegistration();
      _setStep(_AuthStep.register);
      return;
    }

    _setStep(_AuthStep.registerEmailOtp);
  }

  Future<void> _verifyRegistrationEmail(String code) async {
    final session = _registrationSession;

    if (session == null) {
      throw StateError('Registration session is missing.');
    }

    await widget.registrationRepository.verifyEmail(session, code);

    _setStep(_AuthStep.registerWhatsAppOtp);
  }

  Future<void> _resendRegistrationEmail() async {
    final session = _registrationSession;

    if (session == null) {
      throw StateError('Registration session is missing.');
    }

    await widget.registrationRepository.resendEmail(session);
  }

  Future<void> _verifyRegistrationWhatsApp(String code) async {
    final session = _registrationSession;

    if (session == null) {
      throw StateError('Registration session is missing.');
    }

    await widget.registrationRepository.verifyWhatsApp(session, code);

    final setup = await widget.registrationRepository.setupTotp(session);

    if (!mounted) {
      return;
    }

    setState(() {
      _registrationTotpSetup = setup;
      _step = _AuthStep.registerTotpSetup;
    });
  }

  Future<void> _resendRegistrationWhatsApp() async {
    final session = _registrationSession;

    if (session == null) {
      throw StateError('Registration session is missing.');
    }

    await widget.registrationRepository.resendWhatsApp(session);
  }

  Future<void> _confirmRegistrationTotp(String code) async {
    final session = _registrationSession;

    if (session == null) {
      throw StateError('Registration session is missing.');
    }

    await widget.registrationRepository.confirmTotp(session, code);

    final recoveryCodes = await widget.registrationRepository
        .bootstrapRecoveryCodes(session);
    try {
      await _pendingStore.clear();
    } catch (_) {
      // The completed session is no longer valid as pending state.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _registrationRecoveryCodes = recoveryCodes;
      _step = _AuthStep.registerRecoveryCodes;
    });
  }

  Future<void> _startRecovery({
    required String email,
    required String whatsappNumber,
  }) async {
    final session = await widget.passwordRecoveryRepository.start(
      email: email,
      whatsappNumber: whatsappNumber,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _recoverySession = session;
      _recoveryEmail = email.trim();
      _recoveryWhatsApp = whatsappNumber.trim();
      _step = _AuthStep.recoveryEmailOtp;
    });
  }

  Future<void> _verifyRecoveryEmail(String code) async {
    final session = _recoverySession;

    if (session == null) {
      throw StateError('Password recovery session is missing.');
    }

    await widget.passwordRecoveryRepository.verifyEmail(session, code);

    _setStep(_AuthStep.recoveryWhatsAppOtp);
  }

  Future<void> _resendRecoveryEmail() async {
    final session = _recoverySession;

    if (session == null) {
      throw StateError('Password recovery session is missing.');
    }

    await widget.passwordRecoveryRepository.resendEmail(session);
  }

  Future<void> _verifyRecoveryWhatsApp(String code) async {
    final session = _recoverySession;

    if (session == null) {
      throw StateError('Password recovery session is missing.');
    }

    await widget.passwordRecoveryRepository.verifyWhatsApp(session, code);

    _setStep(_AuthStep.recoveryTotp);
  }

  Future<void> _resendRecoveryWhatsApp() async {
    final session = _recoverySession;

    if (session == null) {
      throw StateError('Password recovery session is missing.');
    }

    await widget.passwordRecoveryRepository.resendWhatsApp(session);
  }

  Future<void> _verifyRecoveryTotp(String code) async {
    final session = _recoverySession;

    if (session == null) {
      throw StateError('Password recovery session is missing.');
    }

    await widget.passwordRecoveryRepository.verifyTotp(session, code);

    _setStep(_AuthStep.newPassword);
  }

  Future<void> _resendResetLink() async {
    final session = _recoverySession;

    if (session == null) {
      throw StateError('Password recovery session is missing.');
    }

    await widget.passwordRecoveryRepository.resendResetLink(session);
  }

  Future<void> _resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final session = _recoverySession;

    if (session == null) {
      throw StateError('Password recovery session is missing.');
    }

    await widget.passwordRecoveryRepository.resetPassword(
      session: session,
      resetToken: resetToken,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    _setStep(_AuthStep.passwordResetComplete);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: _buildStep(context),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case _AuthStep.splash:
        return SplashScreen(onFinished: _continueAfterSplash);

      case _AuthStep.welcome:
        return WelcomeScreen(
          onGetStarted: _showRegister,
          onSignIn: _showLogin,
          onSkip: _skipOnboarding,
        );

      case _AuthStep.login:
        return LoginScreen(
          quickUnlockService: widget.quickUnlockService,
          onBack: _showWelcome,
          onForgotPassword: _showForgotPassword,
          onCreateAccount: _showRegister,
          onLogin: _login,
          quickUnlockConfig: widget.quickUnlockConfig,
          onQuickUnlock: widget.onQuickUnlock,
        );

      case _AuthStep.register:
        return RegisterScreen(
          onBack: _showWelcome,
          onSignIn: _showLogin,
          onNext: _collectRegistrationDetails,
        );

      case _AuthStep.registerLanguage:
        return RegistrationDetailsScreen(
          onBack: () => _setStep(_AuthStep.register),
          onContinue: _completeRegistrationDetails,
          onCheckReferralCode: _referralValidator.validateReferralCode,
        );
      case _AuthStep.pendingRegistrationDashboard:
        return RegistrationPendingDashboardScreen(
          email: _registrationEmail,
          onVerifyNow: _beginVerification,
          onExit: _showLogin,
        );
      case _AuthStep.registerGate:
        return RegistrationVerificationGateScreen(
          onVerify: _beginVerification,
          onBack: () => _setStep(_AuthStep.registerLanguage),
        );

      case _AuthStep.registerEmailOtp:
        return OtpVerificationScreen(
          title: 'Verify Your Email',
          subtitle: 'Enter the 8 digits from the Trade X email code. The email may display it in TRX-XX XX XX XX format.',
          codeLength: 8,
          titleIconAsset: 'assets/branding/email_verification.png',
          channelLabel: 'Verification code sent to $_registrationEmail.',
          onVerify: _verifyRegistrationEmail,
          onResend: _resendRegistrationEmail,
          onBack: () => _setStep(_AuthStep.registerLanguage),
        );

      case _AuthStep.registerWhatsAppOtp:
        return MobileOtpVerificationScreen(
          subtitle:
              'Enter the 6-digit verification code sent through WhatsApp.',
          channelLabel: 'Verification code sent to $_registrationWhatsApp.',
          onVerify: _verifyRegistrationWhatsApp,
          onResend: _resendRegistrationWhatsApp,
          onBack: () => _setStep(_AuthStep.registerEmailOtp),
        );

      case _AuthStep.registerTotpSetup:
        final setup = _registrationTotpSetup;

        if (setup == null) {
          return const _MissingFlowState();
        }

        return RegistrationTotpSetupScreen(
          setup: setup,
          onBack: () => _setStep(_AuthStep.registerWhatsAppOtp),
          onContinue: () => _setStep(_AuthStep.registerTotpVerify),
        );

      case _AuthStep.registerTotpVerify:
        final totpDigits = _registrationTotpSetup?.digits ?? 6;
        return OtpVerificationScreen(
          title: 'Verify Authenticator',
          subtitle:
              'Enter the current $totpDigits-digit code from the authenticator app you just configured.',
          codeLength: totpDigits,
          channelLabel:
              'This final security check activates your TradeX account.',
          onVerify: _confirmRegistrationTotp,
          onResend: () async {},
          onBack: () => _setStep(_AuthStep.registerTotpSetup),
          initialCooldownSeconds: 0,
          showResend: false,
        );

      case _AuthStep.registerRecoveryCodes:
        final recoveryCodes = _registrationRecoveryCodes;

        if (recoveryCodes == null) {
          return const _MissingFlowState();
        }

        return RegistrationRecoveryCodesScreen(
          recoveryCodes: recoveryCodes,
          onContinue: () => _setStep(_AuthStep.registerComplete),
        );

      case _AuthStep.registerComplete:
        return AuthSuccessScreen(
          title: 'Account Created',
          message:
              'Email, WhatsApp, and authenticator verification are complete.',
          buttonLabel: 'Continue to Sign In',
          onContinue: _showLogin,
        );

      case _AuthStep.forgotPassword:
        return ForgotPasswordScreen(
          onBack: _showLogin,
          onSubmit: _startRecovery,
        );

      case _AuthStep.recoveryEmailOtp:
        return OtpVerificationScreen(
          title: 'Verify Recovery Email',
          subtitle:
              'Enter the 8 digits from the TradeX password recovery email.',
          codeLength: 8,
          channelLabel:
              'If eligible, a verification code was sent to $_recoveryEmail.',
          onVerify: _verifyRecoveryEmail,
          onResend: _resendRecoveryEmail,
          onBack: _showForgotPassword,
        );

      case _AuthStep.recoveryWhatsAppOtp:
        return OtpVerificationScreen(
          title: 'Verify Recovery WhatsApp',
          subtitle: 'Enter the 6-digit recovery code sent through WhatsApp.',
          codeLength: 6,
          channelLabel: 'Recovery verification for $_recoveryWhatsApp.',
          onVerify: _verifyRecoveryWhatsApp,
          onResend: _resendRecoveryWhatsApp,
          onBack: () => _setStep(_AuthStep.recoveryEmailOtp),
        );

      case _AuthStep.recoveryTotp:
        return OtpVerificationScreen(
          title: 'Verify Authenticator',
          subtitle: 'Enter the current 6-digit authenticator code for your TradeX account.',
          codeLength: 6,
          channelLabel: 'After verification, TradeX will email a short-lived password reset link.',
          onVerify: _verifyRecoveryTotp,
          onResend: () async {},
          onBack: () => _setStep(_AuthStep.recoveryWhatsAppOtp),
          initialCooldownSeconds: 0,
          showResend: false,
        );

      case _AuthStep.newPassword:
        final session = _recoverySession;

        if (session == null) {
          return const _MissingFlowState();
        }

        return NewPasswordScreen(
          recoveryId: session.id,
          onBack: () => _setStep(_AuthStep.recoveryTotp),
          onResendLink: _resendResetLink,
          onSubmit: _resetPassword,
        );

      case _AuthStep.passwordResetComplete:
        return AuthSuccessScreen(
          title: 'Password Updated',
          message: 'Your password has been reset and previous sessions have been invalidated.',
          buttonLabel: 'Sign In Again',
          onContinue: _showLogin,
        );
    }
  }
}

class _MissingFlowState extends StatelessWidget {
  const _MissingFlowState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050706),
      body: Center(
        child: Text(
          'This security flow has expired. Please start again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _RegistrationDraft {
  const _RegistrationDraft({
    required this.name,
    required this.email,
    required this.whatsappNumber,
    required this.password,
    required this.passwordConfirmation,
    required this.countryCode,
    required this.referralCode,
  });

  final String name;
  final String email;
  final String whatsappNumber;
  final String password;
  final String passwordConfirmation;
  final String countryCode;
  final String referralCode;
}
