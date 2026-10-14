import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({
    super.key,
    required this.authRepository,
    required this.onAuthenticated,
  });

  final AuthRepository authRepository;
  final VoidCallback onAuthenticated;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  int _step = 0;

  void _showWelcome() {
    setState(() {
      _step = 1;
    });
  }

  void _showLogin() {
    setState(() {
      _step = 2;
    });
  }

  void _showRegister() {
    debugPrint('AUTH-04 Register screen next');
  }

  void _showForgotPassword() {
    debugPrint('AUTH-09 Forgot Password screen pending');
  }

  void _skipOnboarding() {
    debugPrint('Onboarding skipped');
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

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return SplashScreen(onFinished: _showWelcome);

      case 1:
        return WelcomeScreen(
          onGetStarted: _showRegister,
          onSignIn: _showLogin,
          onSkip: _skipOnboarding,
        );

      case 2:
        return LoginScreen(
          onBack: _showWelcome,
          onForgotPassword: _showForgotPassword,
          onCreateAccount: _showRegister,
          onLogin: _login,
        );

      default:
        return WelcomeScreen(
          onGetStarted: _showRegister,
          onSignIn: _showLogin,
          onSkip: _skipOnboarding,
        );
    }
  }
}
