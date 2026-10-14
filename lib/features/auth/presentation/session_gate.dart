import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/auth_repository.dart';
import 'auth_flow_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _loading = true;
  bool _authenticated = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _restore();
  }

  Future<void> _restore() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final session = await widget.authRepository.restoreSession();

      if (!mounted) {
        return;
      }

      setState(() {
        _authenticated = session != null;
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

  void _onAuthenticated() {
    setState(() {
      _authenticated = true;
    });
  }

  Future<void> _logout() async {
    await widget.authRepository.logout();

    if (!mounted) {
      return;
    }

    setState(() {
      _authenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _SessionLoadingScreen();
    }

    if (_error != null) {
      return _SessionErrorScreen(message: _error!, onRetry: _restore);
    }

    if (_authenticated) {
      return _AuthenticatedPlaceholder(onLogout: _logout);
    }

    return AuthFlowScreen(
      authRepository: widget.authRepository,
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

class _AuthenticatedPlaceholder extends StatelessWidget {
  const _AuthenticatedPlaceholder({required this.onLogout});

  final Future<void> Function() onLogout;

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
                  Icons.verified_user_rounded,
                  color: TradeXColors.success,
                  size: 64,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Secure Login Successful',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AUTH-03B is connected. '
                  'The TradeX Home screen will replace this temporary screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                TextButton(
                  onPressed: () async {
                    await onLogout();
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: TradeXColors.goldBright),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
