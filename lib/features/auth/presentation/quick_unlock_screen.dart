import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/user_facing_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../domain/repositories/auth_repositories.dart';
import '../domain/services/quick_unlock_service.dart';

class QuickUnlockScreen extends StatefulWidget {
  const QuickUnlockScreen({
    super.key,
    required this.config,
    required this.quickUnlockService,
    required this.onUnlocked,
    required this.onSignOut,
  });

  final QuickUnlockConfig config;
  final QuickUnlockService quickUnlockService;
  final Future<void> Function() onUnlocked;
  final Future<void> Function() onSignOut;

  @override
  State<QuickUnlockScreen> createState() => _QuickUnlockScreenState();
}

class _QuickUnlockScreenState extends State<QuickUnlockScreen> {
  final _pinController = TextEditingController();
  bool _busy = false;
  String? _error;
  String _biometricLabel = 'Biometrics';
  late String _method;

  @override
  void initState() {
    super.initState();
    _method = widget.config.hasBiometric ? 'BIOMETRIC' : 'PIN';
    _loadBiometricLabel();
    if (widget.config.hasBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _unlockWithBiometrics();
      });
    }
  }

  Future<void> _loadBiometricLabel() async {
    if (!widget.config.hasBiometric) return;
    try {
      final label = await widget.quickUnlockService.biometricLabel();
      if (mounted) setState(() => _biometricLabel = label);
    } catch (_) {
      // The lock screen retains the generic safe fallback label.
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlockWithPin() async {
    if (_pinController.text.length != 4) {
      setState(() => _error = 'Enter your 4-digit passcode.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.quickUnlockService.verifyPin(
      _pinController.text,
    );
    if (!mounted) return;
    if (result != QuickUnlockPinOutcome.success) {
      setState(() {
        _busy = false;
        _error = result == QuickUnlockPinOutcome.locked
            ? 'Too many attempts. Passcode unlock is locked for 5 minutes.'
            : 'Incorrect passcode. Try again.';
        _pinController.clear();
      });
      return;
    }
    await _completeServerUnlock();
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final unlocked = await widget.quickUnlockService.authenticate(
        'Verify your identity to unlock TradeX.',
      );
      if (!mounted) return;
      if (unlocked) {
        await _completeServerUnlock();
      } else {
        setState(() {
          _busy = false;
          _error = '$_biometricLabel verification was not completed.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            '$_biometricLabel is not available on this device. Sign in another way.';
      });
    }
  }

  Future<void> _completeServerUnlock() async {
    try {
      await widget.onUnlocked();
    } on UserFacingException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'TradeX could not verify this session. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometric = _method == 'BIOMETRIC';
    final hasBoth = widget.config.hasBiometric && widget.config.hasPasscode;
    return Scaffold(
      backgroundColor: TradeXColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TradeXColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: TradeXColors.gold.withValues(alpha: 0.48),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/branding/tradex_logo.png',
                    width: 104,
                    height: 104,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    biometric
                        ? 'Unlock with $_biometricLabel'
                        : 'Enter Passcode',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (hasBoth) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'BIOMETRIC',
                          icon: Icon(Icons.fingerprint_rounded),
                          label: Text('Fingerprint'),
                        ),
                        ButtonSegment(
                          value: 'PIN',
                          icon: Icon(Icons.pin_rounded),
                          label: Text('Passcode'),
                        ),
                      ],
                      selected: {_method},
                      onSelectionChanged: _busy
                          ? null
                          : (selection) => setState(() {
                              _method = selection.first;
                              _pinController.clear();
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (biometric)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _unlockWithBiometrics,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          _busy ? 'Verifying…' : 'Use $_biometricLabel',
                        ),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _pinController,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TradeXColors.primaryText,
                        fontSize: 25,
                        letterSpacing: 12,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _unlockWithPin(),
                      decoration: const InputDecoration(
                        labelText: 'Enter passcode',
                        counterText: '',
                        hintText: '••••',
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (!biometric)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _busy ? null : _unlockWithPin,
                        child: Text(_busy ? 'Unlocking…' : 'Unlock TradeX'),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TradeXColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _busy ? null : widget.onSignOut,
                    child: const Text('Sign in another way'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
