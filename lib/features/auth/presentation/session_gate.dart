import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/secure_session_store.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/profile/pending_financial_form_store.dart';
import '../data/auth_repository.dart';
import '../data/password_recovery_repository.dart';
import '../data/registration_repository.dart';
import 'auth_flow_screen.dart';
import 'quick_unlock_screen.dart';
import 'quick_unlock_settings_screen.dart';
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
    this.now,
  });

  final AuthRepository authRepository;
  final RegistrationRepository registrationRepository;
  final PasswordRecoveryRepository passwordRecoveryRepository;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;
  final LearningRepository learningRepository;
  final DateTime Function()? now;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> with WidgetsBindingObserver {
  static const _defaultBackgroundLockDuration = Duration(minutes: 30);

  bool _loading = true;
  bool _authenticated = false;
  QuickUnlockConfig? _quickUnlock;
  bool _quickUnlockLocked = false;
  bool _privacyShielded = false;
  DateTime? _backgroundedAt;
  Duration _backgroundLockDuration = _defaultBackgroundLockDuration;
  OverlayEntry? _securityOverlay;

  String? _error;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundLockDuration = Duration(
      seconds: AppPreferences.instance.quickUnlockBackgroundLockSeconds,
    );

    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeSecurityOverlay();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_authenticated && !_quickUnlockLocked && !_privacyShielded) {
        if (_quickUnlock != null && _backgroundedAt == null) {
          _backgroundedAt = _now;
          unawaited(AppPreferences.instance.markBackgrounded(_backgroundedAt!));
        }
        _privacyShielded = true;
        _ensureSecurityOverlay();
      }
      return;
    }

    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (!_authenticated) {
      _privacyShielded = false;
      _removeSecurityOverlay();
      return;
    }

    final shouldLock =
        _quickUnlockLocked ||
        (backgroundedAt != null &&
            _quickUnlock != null &&
            _now.difference(backgroundedAt) >= _backgroundLockDuration);
    _privacyShielded = false;
    _quickUnlockLocked = shouldLock;
    if (shouldLock) {
      _ensureSecurityOverlay();
    } else {
      _removeSecurityOverlay();
      unawaited(AppPreferences.instance.clearBackgroundedAt());
    }
  }

  void _ensureSecurityOverlay() {
    if (!mounted ||
        !_authenticated ||
        (!_privacyShielded && !_quickUnlockLocked)) {
      _removeSecurityOverlay();
      return;
    }

    final existing = _securityOverlay;
    if (existing != null) {
      existing.markNeedsBuild();
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureSecurityOverlay();
      });
      return;
    }

    final entry = OverlayEntry(builder: _buildSecurityOverlay);
    _securityOverlay = entry;
    overlay.insert(entry);
  }

  Widget _buildSecurityOverlay(BuildContext context) {
    if (_privacyShielded) {
      return const _SessionPrivacyShield(
        key: ValueKey('session-privacy-shield'),
      );
    }

    final config = _quickUnlock;
    if (_quickUnlockLocked && config != null) {
      return QuickUnlockScreen(
        key: const ValueKey('session-quick-unlock-overlay'),
        config: config,
        sessionStore: SecureSessionStore(),
        onUnlocked: _restoreAfterQuickUnlock,
        onSignOut: _signOutCompletely,
      );
    }

    return const SizedBox.shrink();
  }

  void _removeSecurityOverlay() {
    final entry = _securityOverlay;
    if (entry == null) return;
    _securityOverlay = null;
    if (entry.mounted) entry.remove();
    entry.dispose();
  }

  Future<void> _refreshQuickUnlockPolicy() async {
    if (!_authenticated || _quickUnlock == null) return;
    try {
      final status = await widget.authRepository.quickUnlockStatus();
      final localConfig = await widget.authRepository
          .quickUnlockConfiguration();
      final policy = status['policy'];
      final rawSeconds = policy is Map
          ? (policy['background_lock_seconds'] as num?)?.toInt()
          : null;
      final seconds = (rawSeconds ?? 1800).clamp(1800, 86400);
      if (!mounted || !_authenticated) return;
      setState(() {
        _quickUnlock = status['enabled'] == true ? localConfig : null;
        _backgroundLockDuration = Duration(seconds: seconds);
      });
      unawaited(
        AppPreferences.instance.setQuickUnlockBackgroundLockSeconds(seconds),
      );
      if (_quickUnlock == null) {
        _quickUnlockLocked = false;
        _privacyShielded = false;
        _removeSecurityOverlay();
        unawaited(AppPreferences.instance.clearBackgroundedAt());
      }
    } catch (_) {
      // Keep the secure 30-minute fallback when policy refresh is offline.
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
        final backgroundedAt = AppPreferences.instance.lastBackgroundedAt;
        final elapsed = backgroundedAt == null
            ? null
            : _now.difference(backgroundedAt);
        final mayResumeWithoutUnlock =
            elapsed != null &&
            !elapsed.isNegative &&
            elapsed < _backgroundLockDuration;
        if (mayResumeWithoutUnlock) {
          final session = await widget.authRepository
              .restoreRememberedSession();
          if (!mounted) return;
          if (session != null) {
            await AppPreferences.instance.clearBackgroundedAt();
            if (!mounted) return;
            setState(() {
              _authenticated = true;
              _quickUnlock = quickUnlock;
              _quickUnlockLocked = false;
              _privacyShielded = false;
              _loading = false;
            });
            unawaited(_refreshQuickUnlockPolicy());
            return;
          }
        }
        if (!mounted) return;
        setState(() {
          _authenticated = false;
          _quickUnlock = quickUnlock;
          _quickUnlockLocked = false;
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
    try {
      final session = await widget.authRepository
          .restoreSessionAfterQuickUnlock();
      if (!mounted) return;
      _quickUnlockLocked = false;
      _privacyShielded = false;
      _removeSecurityOverlay();
      unawaited(AppPreferences.instance.clearBackgroundedAt());
      setState(() {
        _authenticated = session != null;
        _quickUnlock = session == null ? null : _quickUnlock;
        _error = null;
      });
      if (session != null) unawaited(_refreshQuickUnlockPolicy());
    } on ApiException catch (error) {
      final enrollmentInvalid = <String>{
        'QUICK_UNLOCK_ENROLLMENT_UNAVAILABLE',
        'QUICK_UNLOCK_CREDENTIAL_MISSING',
        'QUICK_UNLOCK_CHALLENGE_INVALID',
        'QUICK_UNLOCK_SIGNATURE_INVALID',
        'DEVICE_SESSION_REVOKED',
      }.contains(error.code);
      if (enrollmentInvalid) {
        await widget.authRepository.clearLocalQuickUnlock();
      }
      if (!mounted) return;
      if (!enrollmentInvalid) rethrow;
      _quickUnlockLocked = false;
      _privacyShielded = false;
      _removeSecurityOverlay();
      unawaited(AppPreferences.instance.clearBackgroundedAt());
      setState(() {
        _authenticated = false;
        _quickUnlock = null;
        _error = null;
      });
    }
  }

  void _onAuthenticated() {
    unawaited(AppPreferences.instance.clearBackgroundedAt());
    setState(() {
      _authenticated = true;
      _quickUnlockLocked = false;
      _privacyShielded = false;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _offerQuickUnlockSetup(),
    );
  }

  Future<void> _completeQuickLogin() async {
    final config = _quickUnlock;
    if (config == null) return;
    await widget.authRepository.quickLogin(config);
    if (!mounted) return;
    unawaited(AppPreferences.instance.clearBackgroundedAt());
    setState(() {
      _authenticated = true;
      _quickUnlockLocked = false;
      _privacyShielded = false;
      _error = null;
    });
    unawaited(_refreshQuickUnlockPolicy());
  }

  Future<void> _offerQuickUnlockSetup() async {
    if (!mounted) return;
    final existing = await widget.authRepository.quickUnlockConfiguration();
    if (!mounted) return;
    if (existing != null) {
      setState(() => _quickUnlock = existing);
      unawaited(_refreshQuickUnlockPolicy());
      return;
    }
    final sessionStore = SecureSessionStore();
    final alreadyShown = await sessionStore.hasShownQuickUnlockSetupPrompt();
    if (!mounted || alreadyShown) {
      return;
    }
    await sessionStore.markQuickUnlockSetupPromptShown();
    if (!mounted) return;
    final openSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Secure your next sign-in'),
        content: const Text(
          'Set up fingerprint or a 4-digit passcode now for quick, secure login on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Set up now'),
          ),
        ],
      ),
    );
    if (openSettings != true || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            QuickUnlockSettingsScreen(repository: widget.authRepository),
      ),
    );
    final config = await widget.authRepository.quickUnlockConfiguration();
    if (mounted) {
      setState(() => _quickUnlock = config);
      if (config != null) unawaited(_refreshQuickUnlockPolicy());
    }
  }

  Future<void> _logout() async {
    final configuredQuickUnlock =
        _quickUnlock ?? await widget.authRepository.quickUnlockConfiguration();

    if (configuredQuickUnlock != null) {
      await widget.authRepository.logout();
      await _clearPendingFinancialDraft();
      await AppPreferences.instance.setDashboardTab(0);
      await AppPreferences.instance.clearBackgroundedAt();
      if (!mounted) return;
      _removeSecurityOverlay();
      setState(() {
        _authenticated = false;
        _quickUnlock = configuredQuickUnlock;
        _quickUnlockLocked = false;
        _privacyShielded = false;
      });
      return;
    }

    await _signOutCompletely();
  }

  Future<void> _signOutCompletely() async {
    await widget.authRepository.logout();
    await _clearPendingFinancialDraft();
    await AppPreferences.instance.setDashboardTab(0);
    await AppPreferences.instance.clearBackgroundedAt();

    if (!mounted) {
      return;
    }

    _removeSecurityOverlay();
    setState(() {
      _authenticated = false;
      _quickUnlock = null;
      _quickUnlockLocked = false;
      _privacyShielded = false;
    });
  }

  Future<void> _signOutAndForgetDevice() async {
    await widget.authRepository.logout(forgetDevice: true);
    await _clearPendingFinancialDraft();
    await AppPreferences.instance.setDashboardTab(0);
    await AppPreferences.instance.clearBackgroundedAt();
    if (!mounted) return;
    _removeSecurityOverlay();
    setState(() {
      _authenticated = false;
      _quickUnlock = null;
      _quickUnlockLocked = false;
      _privacyShielded = false;
    });
  }

  Future<void> _signOutAllDevices() async {
    await widget.authRepository.logoutAll();
    await _clearPendingFinancialDraft();
    await AppPreferences.instance.setDashboardTab(0);
    await AppPreferences.instance.clearBackgroundedAt();
    if (!mounted) return;
    _removeSecurityOverlay();
    setState(() {
      _authenticated = false;
      _quickUnlock = null;
      _quickUnlockLocked = false;
      _privacyShielded = false;
    });
  }

  Future<void> _clearPendingFinancialDraft() async {
    try {
      await PendingFinancialFormStore().clearWithdrawal();
    } catch (_) {
      // Draft cleanup must never prevent an explicit sign-out.
    }
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
      return KeyedSubtree(
        key: const ValueKey('authenticated-dashboard'),
        child: HomeDashboardScreen(
          onLogout: _logout,
          onForgetDevice: _signOutAndForgetDevice,
          onLogoutAll: _signOutAllDevices,
          apiClient: widget.apiClient,
          tradeIdeasRepository: widget.tradeIdeasRepository,
          learningRepository: widget.learningRepository,
          authRepository: widget.authRepository,
        ),
      );
    }

    return AuthFlowScreen(
      authRepository: widget.authRepository,
      registrationRepository: widget.registrationRepository,
      passwordRecoveryRepository: widget.passwordRecoveryRepository,
      onAuthenticated: _onAuthenticated,
      quickUnlockConfig: _quickUnlock,
      onQuickUnlock: _quickUnlock == null ? null : _completeQuickLogin,
    );
  }
}

class _SessionPrivacyShield extends StatelessWidget {
  const _SessionPrivacyShield({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: TradeXColors.background,
      child: Center(
        child: Image(
          image: AssetImage('assets/branding/tradex_logo.png'),
          width: 104,
          height: 104,
          fit: BoxFit.contain,
        ),
      ),
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
