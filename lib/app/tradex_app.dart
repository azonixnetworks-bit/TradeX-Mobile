import 'package:flutter/material.dart';

import '../core/theme/tradex_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/password_recovery_repository.dart';
import '../features/auth/data/registration_repository.dart';
import '../features/auth/presentation/session_gate.dart';
import 'connectivity_observer.dart';
import '../core/network/app_messenger.dart';
import '../core/network/tradex_api_client.dart';
import '../features/home/data/trade_ideas_repository.dart';
import '../features/home/data/learning_repository.dart';
import '../core/preferences/app_preferences.dart';

class TradeXApp extends StatelessWidget {
  const TradeXApp({
    super.key,
    required this.authRepository,
    required this.registrationRepository,
    required this.passwordRecoveryRepository,
    required this.apiClient,
    required this.tradeIdeasRepository,
    required this.learningRepository,
  });

  final AuthRepository authRepository;
  final RegistrationRepository registrationRepository;
  final PasswordRecoveryRepository passwordRecoveryRepository;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;
  final LearningRepository learningRepository;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppPreferences.instance,
      builder: (context, _) => MaterialApp(
        title: 'Trade X',
        restorationScopeId: 'tradex-app',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: AppMessenger.key,
        theme: TradeXTheme.light,
        darkTheme: TradeXTheme.dark,
        themeMode: AppPreferences.instance.themeMode,
        builder: (context, child) => ConnectivityObserver(
          apiClient: apiClient,
          child: child ?? const SizedBox.shrink(),
        ),
        home: SessionGate(
          authRepository: authRepository,
          registrationRepository: registrationRepository,
          passwordRecoveryRepository: passwordRecoveryRepository,
          apiClient: apiClient,
          tradeIdeasRepository: tradeIdeasRepository,
          learningRepository: learningRepository,
        ),
      ),
    );
  }
}
