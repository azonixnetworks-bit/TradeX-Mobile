import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../data/password_recovery_repository.dart';
import '../data/registration_repository.dart';
import '../models/password_recovery_session.dart';
import '../models/registration_session.dart';
import 'auth_success_screen.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'new_password_screen.dart';
import 'register_screen.dart';
import 'registration_totp_setup_screen.dart';
import 'registration_details_screen.dart';
import 'registration_verification_gate_screen.dart';
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
  registerEmailOtp,
  registerWhatsAppOtp,
  registerTotpSetup,
  registerTotpVerify,
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
  });

  final AuthRepository authRepository;
  final RegistrationRepository registrationRepository;
  final PasswordRecoveryRepository passwordRecoveryRepository;
  final VoidCallback onAuthenticated;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  _AuthStep _step = _AuthStep.splash;

  RegistrationSession? _registrationSession;
  RegistrationTotpSetup? _registrationTotpSetup;
  _RegistrationDraft? _registrationDraft;

  PasswordRecoverySession? _recoverySession;

  String _registrationEmail = '';
  String _registrationWhatsApp = '';
  String _recoveryEmail = '';
  String _recoveryWhatsApp = '';

  void _setStep(_AuthStep step) {
    if (!mounted) {
      return;
    }

    setState(() {
      _step = step;
    });
  }

  void _showWelcome() => _setStep(_AuthStep.welcome);

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
        _setStep(_AuthStep.registerLanguage);
      case _AuthStep.registerEmailOtp:
        _setStep(_AuthStep.registerGate);
      case _AuthStep.registerWhatsAppOtp:
        _setStep(_AuthStep.registerEmailOtp);
      case _AuthStep.registerTotpSetup:
        _setStep(_AuthStep.registerWhatsAppOtp);
      case _AuthStep.registerTotpVerify:
        _setStep(_AuthStep.registerTotpSetup);
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
    _registrationSession = null;
    _registrationTotpSetup = null;
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
  }) async {
    await widget.authRepository.login(
      email: email,
      password: password,
      totpCode: totpCode,
      recoveryCode: recoveryCode,
    );

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

    setState(() {
      _registrationDraft = _RegistrationDraft(
        name: draft.name,
        email: draft.email,
        whatsappNumber: phone,
        password: draft.password,
        passwordConfirmation: draft.passwordConfirmation,
        countryCode: countryCode,
        referralCode: referralCode,
      );
      _step = _AuthStep.registerGate;
    });
  }

  Future<void> _beginVerification() async {
    final draft = _registrationDraft;

    if (draft == null) {
      throw StateError('Registration details are missing. Please start again.');
    }

    final session = await widget.registrationRepository.start(
      name: draft.name,
      email: draft.email,
      whatsappNumber: draft.whatsappNumber,
      password: draft.password,
      passwordConfirmation: draft.passwordConfirmation,
      countryCode: draft.countryCode,
      languageCode: 'en',
      referralCode: draft.referralCode,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _registrationSession = session;
      _registrationEmail = draft.email.trim();
      _registrationWhatsApp = draft.whatsappNumber.trim();
      _step = _AuthStep.registerEmailOtp;
    });
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

    _setStep(_AuthStep.registerComplete);
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
        return SplashScreen(onFinished: _showWelcome);

      case _AuthStep.welcome:
        return WelcomeScreen(
          onGetStarted: _showRegister,
          onSignIn: _showLogin,
          onSkip: _skipOnboarding,
        );

      case _AuthStep.login:
        return LoginScreen(
          onBack: _showWelcome,
          onForgotPassword: _showForgotPassword,
          onCreateAccount: _showRegister,
          onLogin: _login,
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
        );
      case _AuthStep.registerGate:
        return RegistrationVerificationGateScreen(onVerify: _beginVerification);

      case _AuthStep.registerEmailOtp:
        return OtpVerificationScreen(
          title: 'Verify Your Email',
          subtitle: 'Enter the 8 digits from the Trade X email code. The email may display it in TRX-XX XX XX XX format.',
          codeLength: 8,
          channelLabel: 'Verification code sent to $_registrationEmail.',
          onVerify: _verifyRegistrationEmail,
          onResend: _resendRegistrationEmail,
          onBack: () => _setStep(_AuthStep.registerLanguage),
        );

      case _AuthStep.registerWhatsAppOtp:
        return OtpVerificationScreen(
          title: 'Verify Mobile Number',
          subtitle: 'WhatsApp delivery is coming soon. Enter the 6-digit code sent to your email.',
          codeLength: 6,
          channelLabel:
              'Temporary mobile verification code sent to $_registrationEmail.',
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
        return OtpVerificationScreen(
          title: 'Verify Authenticator',
          subtitle: 'Enter the current 6-digit code from the authenticator app you just configured.',
          codeLength: 6,
          channelLabel:
              'This final security check activates your TradeX account.',
          onVerify: _confirmRegistrationTotp,
          onResend: () async {},
          onBack: () => _setStep(_AuthStep.registerTotpSetup),
          initialCooldownSeconds: 0,
          showResend: false,
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
