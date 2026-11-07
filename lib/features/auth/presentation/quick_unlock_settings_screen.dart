import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../../../core/widgets/security_screen_shell.dart';
import '../domain/repositories/auth_repositories.dart';
import '../domain/services/quick_unlock_service.dart';

class QuickUnlockSettingsScreen extends StatefulWidget {
  const QuickUnlockSettingsScreen({
    super.key,
    required this.repository,
    required this.quickUnlockService,
  });

  final AuthRepositoryContract repository;
  final QuickUnlockService quickUnlockService;

  @override
  State<QuickUnlockSettingsScreen> createState() =>
      _QuickUnlockSettingsScreenState();
}

class _QuickUnlockSettingsScreenState extends State<QuickUnlockSettingsScreen> {
  final _totp = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();

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
      return await widget.quickUnlockService.authenticate(
        'Confirm your fingerprint for TradeX quick unlock.',
      );
    } catch (_) {
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
  Widget build(BuildContext context) => SecurityScreenShell(
    title: 'Quick Unlock',
    subtitle: 'Choose how you want to securely unlock TradeX on this device.',
    child: _loading
        ? const Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          )
        : ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            children: [
              _MethodCard(
                asset: 'assets/security_ui/golden_fingerprint_app_tile.png',
                title: 'Fingerprint',
                subtitle: 'Use your enrolled fingerprint for instant access.',
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
                asset: 'assets/security_ui/premium_gold_keypad_tile.png',
                title: 'PIN Code',
                subtitle:
                    'Use a private 4-digit PIN stored only on this device.',
                added: _passcodeEnabled,
                onAdd: _saving ? null : _addPasscode,
                onChange: _saving || !_passcodeEnabled ? null : _addPasscode,
                onRemove: _saving || !_passcodeEnabled ? null : _removePasscode,
              ),
              if (_passcodeEnabled && _editingPasscode) ...[
                const SizedBox(height: 14),
                _pinField(_pin, 'Create 4-digit passcode'),
                const SizedBox(height: 12),
                _pinField(_confirmPin, 'Confirm passcode'),
              ],
              const SizedBox(height: 14),
              _ActionRow(
                icon: Icons.edit_outlined,
                title: 'Change PIN',
                enabled: _passcodeEnabled && !_saving,
                onTap: _addPasscode,
              ),
              const SizedBox(height: 10),
              _ActionRow(
                icon: Icons.shield_outlined,
                title: 'Unlock Method',
                subtitle: _biometricEnabled && _passcodeEnabled
                    ? 'Fingerprint and PIN'
                    : _biometricEnabled
                    ? 'Fingerprint'
                    : _passcodeEnabled
                    ? 'PIN Code'
                    : 'Not configured',
              ),
              const SizedBox(height: 18),
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
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.added,
    this.onAdd,
    this.onChange,
    this.onRemove,
  });

  final String asset;
  final String title;
  final String subtitle;
  final bool added;
  final VoidCallback? onAdd;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
    decoration: BoxDecoration(
      color: added ? context.palette.goldSoft : context.palette.surfaceRaised,
      borderRadius: TradeXRadii.control,
      border: Border.all(
        color: added
            ? context.palette.gold.withValues(alpha: .55)
            : context.palette.border,
      ),
      boxShadow: TradeXElevation.surface(
        brightness: Theme.of(context).brightness,
        palette: context.palette,
      ),
    ),
    child: Row(
      children: [
        Image.asset(asset, width: 58, height: 58, fit: BoxFit.contain),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: added,
          activeTrackColor: context.palette.gold,
          onChanged: onAdd == null && onRemove == null
              ? null
              : (value) => value ? onAdd?.call() : onRemove?.call(),
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.surfaceRaised,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.palette.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled
                  ? context.palette.goldText
                  : context.palette.tertiaryText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.palette.goldText),
          ],
        ),
      ),
    ),
  );
}
