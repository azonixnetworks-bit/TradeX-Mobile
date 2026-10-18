import 'package:flutter/material.dart';

import '../../../core/auth/secure_session_store.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/network/tradex_api_client.dart';
import '../data/auth_repository.dart';
import '../data/password_recovery_repository.dart';
import '../data/registration_repository.dart';
import 'auth_flow_screen.dart';
import 'quick_unlock_screen.dart';
import '../../home/presentation/home_dashboard_screen.dart';
import '../../home/data/trade_ideas_repository.dart';
import '../../home/data/learning_repository.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({
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
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> with WidgetsBindingObserver {
  bool _loading = true;
  bool _authenticated = false;
  QuickUnlockConfig? _quickUnlock;
  bool _quickUnlockLocked = false;
  DateTime? _backgroundedAt;

  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _backgroundedAt ??= DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null ||
        !_authenticated ||
        _quickUnlock == null ||
        _quickUnlockLocked) {
      return;
    }

    // Mirrors the current Laravel policy default. The authenticated UI is
    // hidden but the rotating refresh session remains intact.
    if (DateTime.now().difference(backgroundedAt) >=
        const Duration(seconds: 30)) {
      setState(() => _quickUnlockLocked = true);
    }
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final quickUnlock = await widget.authRepository
          .quickUnlockConfiguration();

      if (quickUnlock != null) {
        if (!mounted) return;
        setState(() {
          _authenticated = true;
          _quickUnlock = quickUnlock;
          _quickUnlockLocked = true;
          _loading = false;
        });
        return;
      }

      // Remember is off: clear any previous non-persistent session before a
      // refresh call can make authenticated UI visible.
      final session = await widget.authRepository.restoreRememberedSession();

      if (!mounted) {
        return;
      }

      setState(() {
        _authenticated = session != null;
        _quickUnlock = null;
        _quickUnlockLocked = false;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to restore your TradeX session.';
        _loading = false;
      });
    }
  }

  Future<void> _restoreAfterQuickUnlock() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await widget.authRepository
          .restoreSessionAfterQuickUnlock();
      if (!mounted) return;
      setState(() {
        _authenticated = session != null;
        _quickUnlockLocked = false;
        _loading = false;
      });
    } on ApiException catch (error) {
      await widget.authRepository.logout();
      if (!mounted) return;
      setState(() {
        _authenticated = false;
        _quickUnlock = null;
        _quickUnlockLocked = false;
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _onAuthenticated() {
    setState(() {
      _authenticated = true;
      _quickUnlockLocked = false;
    });
  }

  Future<void> _logout() async {
    if (_quickUnlock != null) {
      setState(() {
        _authenticated = true;
        _quickUnlockLocked = true;
      });
      return;
    }

    await _signOutCompletely();
  }

  Future<void> _signOutCompletely() async {
    await widget.authRepository.logout();

    if (!mounted) {
      return;
    }

    setState(() {
      _authenticated = false;
      _quickUnlock = null;
      _quickUnlockLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _SessionLoadingScreen();
    }

    if (_error != null) {
      return _SessionErrorScreen(message: _error!, onRetry: _initialize);
    }

    if (_authenticated) {
      if (_quickUnlockLocked && _quickUnlock != null) {
        return QuickUnlockScreen(
          config: _quickUnlock!,
          sessionStore: SecureSessionStore(),
          onUnlocked: _restoreAfterQuickUnlock,
          onSignOut: _signOutCompletely,
        );
      }
      return HomeDashboardScreen(
        onLogout: _logout,
        apiClient: widget.apiClient,
        tradeIdeasRepository: widget.tradeIdeasRepository,
        learningRepository: widget.learningRepository,
        authRepository: widget.authRepository,
      );
    }

    return AuthFlowScreen(
      authRepository: widget.authRepository,
      registrationRepository: widget.registrationRepository,
      passwordRecoveryRepository: widget.passwordRecoveryRepository,
      onAuthenticated: _onAuthenticated,
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TradeXColors.background,
      body: Center(
        child: CircularProgressIndicator(color: TradeXColors.goldBright),
      ),
    );
  }
}

class _SessionErrorScreen extends StatelessWidget {
  const _SessionErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeXColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: TradeXColors.gold,
                  size: 52,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TradeXColors.primaryText),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
