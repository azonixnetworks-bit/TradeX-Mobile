import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/tradex_theme.dart';
import '../core/activity/activity_tracker.dart';
import '../core/activity/activity_tracking_scope.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/password_recovery_repository.dart';
import '../features/auth/data/registration_repository.dart';
import '../features/auth/presentation/session_gate.dart';
import 'connectivity_observer.dart';
import '../core/network/app_messenger.dart';
import '../core/network/tradex_api_client.dart';
import '../features/home/data/trade_ideas_repository.dart';
import '../features/home/data/learning_repository.dart';
import '../features/home/data/market_news_repository.dart';
import '../core/preferences/app_preferences.dart';
import '../features/learn/data/learn_repository.dart';

class TradeXApp extends StatelessWidget {
  const TradeXApp({
    super.key,
    required this.authRepository,
    required this.registrationRepository,
    required this.passwordRecoveryRepository,
    required this.apiClient,
    this.activityTracker,
    required this.tradeIdeasRepository,
    required this.learningRepository,
  });

  final AuthRepository authRepository;
  final RegistrationRepository registrationRepository;
  final PasswordRecoveryRepository passwordRecoveryRepository;
  final TradeXApiClient apiClient;
  final ActivityTracker? activityTracker;
  final TradeIdeasRepository tradeIdeasRepository;
  final LearningRepository learningRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: registrationRepository),
        RepositoryProvider.value(value: passwordRecoveryRepository),
        RepositoryProvider.value(value: tradeIdeasRepository),
        RepositoryProvider.value(value: learningRepository),
        RepositoryProvider(create: (_) => LearnRepository(apiClient)),
        RepositoryProvider(create: (_) => MarketNewsRepository(apiClient)),
      ],
      child: BlocProvider.value(
        value: AppPreferences.instance,
        child: BlocBuilder<AppPreferences, AppPreferencesState>(
          buildWhen: (previous, current) =>
              previous.themeMode != current.themeMode,
          builder: (context, preferences) => MaterialApp(
            title: 'Trade X',
            navigatorObservers: activityTracker == null
                ? <NavigatorObserver>[]
                : <NavigatorObserver>[
                    ActivityNavigationObserver(activityTracker!),
                  ],
            restorationScopeId: 'tradex-app',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: AppMessenger.key,
            theme: TradeXTheme.light,
            darkTheme: TradeXTheme.dark,
            themeMode: preferences.themeMode,
            builder: (context, child) => ActivityTrackingScope(
              tracker: activityTracker,
              child: ActivityLifecycleObserver(
                tracker: activityTracker,
                child: ConnectivityObserver(
                  apiClient: apiClient,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
            home: SessionGate(
              authRepository: authRepository,
              registrationRepository: registrationRepository,
              passwordRecoveryRepository: passwordRecoveryRepository,
              apiClient: apiClient,
              activityTracker: activityTracker,
              tradeIdeasRepository: tradeIdeasRepository,
              learningRepository: learningRepository,
            ),
          ),
        ),
      ),
    );
  }
}
