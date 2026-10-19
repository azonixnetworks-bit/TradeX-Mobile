import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/theme/tradex_colors.dart';
import '../data/auth_repository.dart';

class QuickUnlockSettingsScreen extends StatefulWidget {
  const QuickUnlockSettingsScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<QuickUnlockSettingsScreen> createState() =>
      _QuickUnlockSettingsScreenState();
}

class _QuickUnlockSettingsScreenState extends State<QuickUnlockSettingsScreen> {
  final _totp = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();
  final _localAuth = LocalAuthentication();

  bool _biometricEnabled = false;
  bool _passcodeEnabled = false;
  bool _initialBiometricEnabled = false;
  bool _initialPasscodeEnabled = false;
  bool _editingPasscode = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _hasChanges =>
      _biometricEnabled != _initialBiometricEnabled ||
      _passcodeEnabled != _initialPasscodeEnabled ||
      _editingPasscode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _totp.dispose();
    _pin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await widget.repository.quickUnlockStatus();
      if (!mounted) return;
      final biometric = status['local_biometric_enabled'] == true;
      final passcode = status['local_passcode_enabled'] == true;
      setState(() {
        _biometricEnabled = biometric;
        _passcodeEnabled = passcode;
        _initialBiometricEnabled = biometric;
        _initialPasscodeEnabled = passcode;
        _error = status['requires_reenrollment'] == true
            ? 'Quick unlock was revoked or is incomplete. Add a method again using your authenticator code.'
            : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _addPasscode() {
    setState(() {
      _passcodeEnabled = true;
      _editingPasscode = true;
      _pin.clear();
      _confirmPin.clear();
      _error = null;
    });
  }

  void _removePasscode() {
    setState(() {
      _passcodeEnabled = false;
      _editingPasscode = false;
      _pin.clear();
      _confirmPin.clear();
      _error = null;
    });
  }

  Future<bool> _confirmFingerprint() async {
    try {
      final supported =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!supported) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Confirm your fingerprint for TradeX quick unlock.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> _save() async {
    if (!_hasChanges) {
      setState(() => _error = 'Choose Add, Change, or Remove first.');
      return;
    }
    if (_totp.text.length != 6) {
      setState(() => _error = 'Enter your 6-digit authenticator code.');
      return;
    }
    if (_passcodeEnabled &&
        (_editingPasscode || !_initialPasscodeEnabled) &&
        (!RegExp(r'^\d{4}$').hasMatch(_pin.text) ||
            _pin.text != _confirmPin.text)) {
      setState(() => _error = 'Create and confirm the same 4-digit passcode.');
      return;
    }
    if (_biometricEnabled && !_initialBiometricEnabled) {
      final confirmed = await _confirmFingerprint();
      if (!confirmed) {
        if (mounted) {
          setState(
            () => _error = 'Fingerprint confirmation failed. Try again with an enrolled finger.',
          );
        }
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.configureQuickUnlockMethods(
        biometricEnabled: _biometricEnabled,
        passcodeEnabled: _passcodeEnabled,
        totpCode: _totp.text,
        pin: _passcodeEnabled && (_editingPasscode || !_initialPasscodeEnabled)
            ? _pin.text
            : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    appBar: AppBar(
      title: const Text('Quick Unlock'),
      backgroundColor: TradeXColors.background,
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          )
        : SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Security on this device',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fingerprint and passcode can both be active. Your passcode, biometric result and private device key stay on this mobile.',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _MethodCard(
                  icon: Icons.fingerprint_rounded,
                  title: 'Fingerprint',
                  added: _biometricEnabled,
                  onAdd: _saving
                      ? null
                      : () => setState(() {
                          _biometricEnabled = true;
                          _error = null;
                        }),
                  onRemove: _saving
                      ? null
                      : () => setState(() {
                          _biometricEnabled = false;
                          _error = null;
                        }),
                ),
                const SizedBox(height: 12),
                _MethodCard(
                  icon: Icons.pin_rounded,
                  title: 'Passcode',
                  added: _passcodeEnabled,
                  onAdd: _saving ? null : _addPasscode,
                  onChange: _saving || !_passcodeEnabled ? null : _addPasscode,
                  onRemove: _saving || !_passcodeEnabled
                      ? null
                      : _removePasscode,
                ),
                if (_passcodeEnabled && _editingPasscode) ...[
                  const SizedBox(height: 14),
                  _pinField(_pin, 'Create 4-digit passcode'),
                  const SizedBox(height: 12),
                  _pinField(_confirmPin, 'Confirm passcode'),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _totp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Authenticator Code',
                    helperText: 'Required to save security changes',
                    counterText: '',
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: TradeXColors.error),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : !_biometricEnabled && !_passcodeEnabled
                        ? 'Remove quick unlock'
                        : 'Save security settings',
                  ),
                ),
              ],
            ),
          ),
  );

  Widget _pinField(TextEditingController controller, String label) => TextField(
    controller: controller,
    obscureText: true,
    maxLength: 4,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, counterText: ''),
  );
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.added,
    this.onAdd,
    this.onChange,
    this.onRemove,
  });

  final IconData icon;
  final String title;
  final bool added;
  final VoidCallback? onAdd;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: added
          ? TradeXColors.gold.withValues(alpha: .10)
          : TradeXColors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: added
            ? TradeXColors.gold.withValues(alpha: .55)
            : TradeXColors.border,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: TradeXColors.goldBright),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$title: ${added ? 'Added' : 'Not added'}',
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                added
                    ? 'Saved securely on this mobile'
                    : 'Not available for login',
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (!added)
          TextButton(onPressed: onAdd, child: const Text('Add'))
        else ...[
          if (onChange != null)
            TextButton(onPressed: onChange, child: const Text('Change')),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(foregroundColor: TradeXColors.error),
            child: const Text('Remove'),
          ),
        ],
      ],
    ),
  );
}
