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
  String _method = 'BIOMETRIC';
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
      setState(() {
        _enabled = status['enabled'] == true;
        _method = status['method']?.toString() == 'PIN' ? 'PIN' : 'BIOMETRIC';
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_totp.text.length != 6) {
      setState(() => _error = 'Enter your 6-digit authenticator code.');
      return;
    }
    if (_enabled &&
        _method == 'PIN' &&
        (!RegExp(r'^\d{4}$').hasMatch(_pin.text) ||
            _pin.text != _confirmPin.text)) {
      setState(() => _error = 'Create and confirm the same 4-digit passcode.');
      return;
    }
    if (_enabled && _method == 'BIOMETRIC') {
      final confirmed = await _localAuth.authenticate(
        localizedReason: 'Confirm your fingerprint for TradeX quick unlock.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!confirmed) {
        if (mounted) {
          setState(
            () => _error = 'Fingerprint confirmation was not completed.',
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
      await widget.repository.configureQuickUnlock(
        enabled: _enabled,
        method: _enabled ? _method : null,
        totpCode: _totp.text,
        pin: _enabled && _method == 'PIN' ? _pin.text : null,
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
                  'Remember this device',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use this device\'s fingerprint or passcode for future quick unlocks. Your local secret never leaves this device.',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    height: 1.4,
                  ),
                ),
                if (_enabled) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TradeXColors.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: TradeXColors.gold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _method == 'BIOMETRIC'
                              ? Icons.fingerprint_rounded
                              : Icons.pin_rounded,
                          color: TradeXColors.goldBright,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _method == 'BIOMETRIC'
                                ? 'Fingerprint added to this device'
                                : 'Passcode added to this device',
                            style: const TextStyle(
                              color: TradeXColors.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _method == 'BIOMETRIC'
                              ? 'Remove fingerprint unlock'
                              : 'Remove passcode unlock',
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                  _enabled = false;
                                  _error = 'Enter your authenticator code, then tap Remove quick unlock.';
                                }),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: TradeXColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SwitchListTile(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                  activeThumbColor: TradeXColors.goldBright,
                  title: const Text('Remember this device'),
                  subtitle: const Text('Use local device verification'),
                ),
                if (_enabled) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'BIOMETRIC',
                        icon: Icon(Icons.fingerprint),
                        label: Text('Fingerprint'),
                      ),
                      ButtonSegment(
                        value: 'PIN',
                        icon: Icon(Icons.pin),
                        label: Text('Passcode'),
                      ),
                    ],
                    selected: {_method},
                    onSelectionChanged: (value) =>
                        setState(() => _method = value.first),
                  ),
                  if (_method == 'PIN') ...[
                    const SizedBox(height: 16),
                    _pinField(_pin, 'Create 4-digit passcode'),
                    const SizedBox(height: 12),
                    _pinField(_confirmPin, 'Confirm passcode'),
                  ],
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _totp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Authenticator Code',
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
                        : _enabled
                        ? 'Save security setting'
                        : 'Remove quick unlock',
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
