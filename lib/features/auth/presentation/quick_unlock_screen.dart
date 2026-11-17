import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/user_facing_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../domain/repositories/auth_repositories.dart';
import '../domain/services/quick_unlock_service.dart';
import 'widgets/auth_form_components.dart';

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
    return TradeXAuthPage(
      title: 'Quick Unlock',
      subtitle: biometric
          ? 'Use $_biometricLabel to securely continue to TradeX.'
          : 'Enter your private 4-digit passcode to continue.',
      securityDecor: true,
      keepDecorationFixedOnKeyboard: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: context.palette.goldSoft,
              shape: BoxShape.circle,
              border: Border.all(color: context.palette.gold),
            ),
            child: Icon(
              biometric
                  ? Icons.fingerprint_rounded
                  : Icons.lock_outline_rounded,
              color: context.palette.goldText,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            biometric ? 'Unlock with $_biometricLabel' : 'Enter Passcode',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          if (hasBoth) ...[
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
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
            ),
            const SizedBox(height: 18),
          ],
          if (biometric)
            TradeXGoldButton(
              label: _busy ? 'Verifying…' : 'Use $_biometricLabel',
              onPressed: _unlockWithBiometrics,
              loading: _busy,
              icon: Icons.fingerprint_rounded,
            )
          else ...[
            TextField(
              controller: _pinController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.primaryText,
                fontSize: 25,
                letterSpacing: 12,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _unlockWithPin(),
              decoration: const InputDecoration(
                labelText: 'Enter passcode',
                counterText: '',
                hintText: '••••',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TradeXGoldButton(
              label: _busy ? 'Unlocking…' : 'Unlock TradeX',
              onPressed: _unlockWithPin,
              loading: _busy,
              icon: Icons.lock_open_rounded,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TradeXColors.error.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TradeXColors.error.withValues(alpha: .3),
                ),
              ),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TradeXColors.error, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _busy ? null : widget.onSignOut,
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Sign in another way'),
          ),
          Text(
            'Your quick-unlock credential stays protected on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
