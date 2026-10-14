import 'package:flutter/material.dart';

import '../core/theme/tradex_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/password_recovery_repository.dart';
import '../features/auth/data/registration_repository.dart';
import '../features/auth/presentation/session_gate.dart';

class TradeXApp extends StatelessWidget {
  const TradeXApp({
    super.key,
    required this.authRepository,
    required this.registrationRepository,
    required this.passwordRecoveryRepository,
  });

  final AuthRepository authRepository;
  final RegistrationRepository registrationRepository;
  final PasswordRecoveryRepository passwordRecoveryRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeX',
      debugShowCheckedModeBanner: false,
      theme: TradeXTheme.dark,
      home: SessionGate(
        authRepository: authRepository,
        registrationRepository: registrationRepository,
        passwordRecoveryRepository: passwordRecoveryRepository,
      ),
    );
  }
}
