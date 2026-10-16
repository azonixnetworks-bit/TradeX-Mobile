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

class TradeXApp extends StatelessWidget {
  const TradeXApp({
    super.key,
    required this.authRepository,
    required this.registrationRepository,
    required this.passwordRecoveryRepository,
    required this.apiClient,
    required this.tradeIdeasRepository,
  });

  final AuthRepository authRepository;
  final RegistrationRepository registrationRepository;
  final PasswordRecoveryRepository passwordRecoveryRepository;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;

  @override
  Widget build(BuildContext context) {
    return ConnectivityObserver(
      child: MaterialApp(
        title: 'Trade X',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: AppMessenger.key,
        theme: TradeXTheme.dark,
        home: SessionGate(
          authRepository: authRepository,
          registrationRepository: registrationRepository,
          passwordRecoveryRepository: passwordRecoveryRepository,
          apiClient: apiClient,
          tradeIdeasRepository: tradeIdeasRepository,
        ),
      ),
    );
  }
}
