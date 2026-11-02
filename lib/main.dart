import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';

import 'app/bloc/tradex_bloc_observer.dart';
import 'core/activity/activity_tracker.dart';
import 'app/tradex_app.dart';
import 'core/auth/secure_session_store.dart';
import 'core/device/device_identity.dart';
import 'core/network/tradex_api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/password_recovery_repository.dart';
import 'features/auth/data/registration_repository.dart';
import 'features/home/data/trade_ideas_repository.dart';
import 'features/home/data/learning_repository.dart';
import 'core/preferences/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const TradeXBlocObserver();
  await AppPreferences.instance.load();

  final sessionStore = SecureSessionStore();
  final deviceIdentity = DeviceIdentity(sessionStore);

  final apiClient = TradeXApiClient(sessionStore, deviceIdentity);
  final activityTracker = ActivityTracker(
    accountResolver: () async {
      final session = await sessionStore.readSession();
      return session?.user['uuid']?.toString();
    },
    sendBatch: (events) async {
      await apiClient.postJson('/api/v1/activity/events', {
        'events': events,
      });
    },
  );

  final authRepository = AuthRepository(
    apiClient,
    sessionStore,
    deviceIdentity,
  );

  final registrationRepository = RegistrationRepository(apiClient);

  final passwordRecoveryRepository = PasswordRecoveryRepository(apiClient);
  final tradeIdeasRepository = TradeIdeasRepository(apiClient);
  final learningRepository = LearningRepository(apiClient);

  runApp(
    TradeXApp(
      authRepository: authRepository,
      registrationRepository: registrationRepository,
      passwordRecoveryRepository: passwordRecoveryRepository,
      apiClient: apiClient,
      activityTracker: activityTracker,
      tradeIdeasRepository: tradeIdeasRepository,
      learningRepository: learningRepository,
    ),
  );
}
