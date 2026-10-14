import 'package:flutter/material.dart';

import 'app/tradex_app.dart';
import 'core/auth/secure_session_store.dart';
import 'core/device/device_identity.dart';
import 'core/network/tradex_api_client.dart';
import 'features/auth/data/auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionStore = SecureSessionStore();

  final deviceIdentity = DeviceIdentity(sessionStore);

  final apiClient = TradeXApiClient(
    sessionStore: sessionStore,
    deviceIdentity: deviceIdentity,
  );

  final authRepository = AuthRepository(
    apiClient: apiClient,
    sessionStore: sessionStore,
    deviceIdentity: deviceIdentity,
  );

  runApp(TradeXApp(authRepository: authRepository));
}
