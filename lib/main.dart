import 'package:flutter/material.dart';

import 'app/tradex_app.dart';
import 'core/auth/secure_session_store.dart';
import 'core/device/device_identity.dart';
import 'core/network/tradex_api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/password_recovery_repository.dart';
import 'features/auth/data/registration_repository.dart';
import 'features/home/data/trade_ideas_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionStore = SecureSessionStore();
  final deviceIdentity = DeviceIdentity(sessionStore);

  final apiClient = TradeXApiClient(sessionStore, deviceIdentity);

  final authRepository = AuthRepository(
    apiClient,
    sessionStore,
    deviceIdentity,
  );

  final registrationRepository = RegistrationRepository(apiClient);

  final passwordRecoveryRepository = PasswordRecoveryRepository(apiClient);
  final tradeIdeasRepository = TradeIdeasRepository(apiClient);

  runApp(
    TradeXApp(
      authRepository: authRepository,
      registrationRepository: registrationRepository,
      passwordRecoveryRepository: passwordRecoveryRepository,
      apiClient: apiClient,
      tradeIdeasRepository: tradeIdeasRepository,
    ),
  );
}
