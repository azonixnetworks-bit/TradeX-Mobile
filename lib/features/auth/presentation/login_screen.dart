import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/user_facing_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../domain/repositories/auth_repositories.dart';
import '../domain/services/quick_unlock_service.dart';

part 'login/login_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onForgotPassword,
    required this.onCreateAccount,
    required this.onLogin,
    this.quickUnlockConfig,
    this.onQuickUnlock,
    this.authenticateBiometric,
    required this.quickUnlockService,
  });

  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;
  final QuickUnlockConfig? quickUnlockConfig;
  final Future<void> Function()? onQuickUnlock;
  final Future<bool> Function()? authenticateBiometric;
  final QuickUnlockService quickUnlockService;

  final Future<void> Function({
    required String email,
    required String password,
    String? totpCode,
    String? recoveryCode,
    String? quickUnlockMethod,
    String? quickUnlockPin,
  })
  onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _securityCodeController = TextEditingController();
  final TextEditingController _quickUnlockPinController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _useRecoveryCode = false;
  bool _rememberDevice = false;
  String _quickUnlockMethod = 'BIOMETRIC';
  bool _biometricConfirmed = false;
  bool _submitting = false;
  bool _automaticBiometricPromptAttempted = false;

  String? _errorMessage;
  bool _deviceSlotOccupied = false;

  bool get _quickLoginAvailable => widget.quickUnlockConfig != null;

  @override
  void initState() {
    super.initState();
    final config = widget.quickUnlockConfig;
    if (config != null) {
      _rememberDevice = true;
      _quickUnlockMethod = config.hasBiometric ? 'BIOMETRIC' : 'PIN';
      if (config.hasBiometric && widget.onQuickUnlock != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_promptBiometricOnLogin());
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _securityCodeController.dispose();
    _quickUnlockPinController.dispose();

    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (_rememberDevice && _quickLoginAvailable) return null;
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email address is required.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (_rememberDevice && _quickLoginAvailable) return null;
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    return null;
  }

  String? _validateSecurityCode(String? value) {
    if (_rememberDevice && _quickLoginAvailable) return null;
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return _useRecoveryCode
          ? 'Recovery code is required.'
          : 'Authenticator code is required.';
    }

    if (!_useRecoveryCode && code.length != 6) {
      return 'Enter the 6-digit authenticator code.';
    }

    return null;
  }

  String? _validateQuickUnlockPin(String? value) {
    if (!_rememberDevice || _quickUnlockMethod != 'PIN') return null;
    if (!RegExp(r'^\d{4}$').hasMatch(value?.trim() ?? '')) {
      return 'Enter your 4-digit passcode.';
    }
    return null;
  }

  Future<bool> _confirmFingerprint() async {
    try {
      final authenticateBiometric = widget.authenticateBiometric;
      final bool confirmed;
      if (authenticateBiometric != null) {
        confirmed = await authenticateBiometric();
      } else {
        confirmed = await widget.quickUnlockService.authenticate(
          'Place your finger on the sensor to sign in to TradeX.',
        );
      }
      if (mounted) {
        setState(() {
          _biometricConfirmed = confirmed;
          _errorMessage = confirmed
              ? null
              : 'Authentication failed. Fingerprint was not recognized.';
        });
      }
      return confirmed;
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication failed. Fingerprint is not available on this device.';
        });
      }
      return false;
    }
  }

  Future<void> _promptBiometricOnLogin() async {
    if (_automaticBiometricPromptAttempted ||
        _submitting ||
        !_rememberDevice ||
        _quickUnlockMethod != 'BIOMETRIC' ||
        widget.quickUnlockConfig?.hasBiometric != true ||
        widget.onQuickUnlock == null) {
      return;
    }

    _automaticBiometricPromptAttempted = true;
    if (await _confirmFingerprint()) {
      await _completeQuickLogin();
    }
  }

  Future<void> _selectQuickUnlockMethod(String value) async {
    setState(() {
      _quickUnlockMethod = value;
      _quickUnlockPinController.clear();
      _biometricConfirmed = false;
      _errorMessage = null;
    });
    final config = widget.quickUnlockConfig;
    final passcodeAvailable = config?.hasPasscode == true;
    final biometricAvailable = config?.hasBiometric == true;
    if (config == null ||
        (value == 'PIN' && !passcodeAvailable) ||
        (value == 'BIOMETRIC' && !biometricAvailable)) {
      setState(() {
        _errorMessage = value == 'BIOMETRIC'
            ? 'Fingerprint login is not set up. Add it from Profile > Quick Unlock.'
            : 'Passcode login is not set up. Add it from Profile > Quick Unlock.';
      });
      return;
    }
    if (value == 'BIOMETRIC' && await _confirmFingerprint()) {
      await _completeQuickLogin();
    }
  }

  Future<void> _toggleRememberDevice(bool value) async {
    setState(() {
      _rememberDevice = value;
      _errorMessage = null;
      if (!value) {
        _quickUnlockPinController.clear();
        _biometricConfirmed = false;
      }
    });
    if (value && !_quickLoginAvailable) {
      setState(() {
        _rememberDevice = false;
        _errorMessage = 'Set up fingerprint or passcode from your Profile after signing in.';
      });
    }
  }

  Future<void> _completeQuickLogin() async {
    final callback = widget.onQuickUnlock;
    if (callback == null) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _deviceSlotOccupied = false;
    });
    try {
      await callback();
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Authentication failed. ${error.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitQuickLogin() async {
    final config = widget.quickUnlockConfig;
    final passcodeAvailable = config?.hasPasscode == true;
    final biometricAvailable = config?.hasBiometric == true;
    if (config == null ||
        (_quickUnlockMethod == 'PIN' && !passcodeAvailable) ||
        (_quickUnlockMethod == 'BIOMETRIC' && !biometricAvailable)) {
      setState(
        () => _errorMessage =
            'Authentication failed. Set up this login method from Profile.',
      );
      return;
    }
    if (_quickUnlockMethod == 'BIOMETRIC') {
      if (await _confirmFingerprint()) await _completeQuickLogin();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final result = await widget.quickUnlockService.verifyPin(
      _quickUnlockPinController.text.trim(),
    );
    if (!mounted) return;
    if (result != QuickUnlockPinOutcome.success) {
      setState(() {
        _quickUnlockPinController.clear();
        _errorMessage = result == QuickUnlockPinOutcome.locked
            ? 'Authentication failed. Too many attempts; try again in 5 minutes.'
            : 'Authentication failed. Incorrect passcode. Try again.';
      });
      return;
    }
    await _completeQuickLogin();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_rememberDevice && _quickLoginAvailable) {
      await _submitQuickLogin();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _deviceSlotOccupied = false;
    });

    try {
      await widget.onLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        totpCode: _useRecoveryCode ? null : _securityCodeController.text.trim(),
        recoveryCode: _useRecoveryCode
            ? _securityCodeController.text.trim()
            : null,
        quickUnlockMethod: null,
        quickUnlockPin: null,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _deviceSlotOccupied =
            error is UserFacingException &&
            (error.code == 'DEVICE_SLOT_OCCUPIED' ||
                error.code == 'DEVICE_LIMIT_REACHED');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _showDeviceRecovery() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mobile Device Limit Reached'),
      content: const SingleChildScrollView(
        child: Text(
          'Your account already has two active mobile devices. TradeX cannot safely replace either device from this login because the Laravel backend does not allow unauthenticated device replacement.\n\nFrom an authenticated desktop or mobile session, open Profile → Trusted devices and revoke an old mobile device with TOTP, then retry here. Otherwise contact TradeX support for an audited device reset.\n\nYour password, authenticator code, recovery code, device name, or model alone will not bypass the two-mobile-device policy.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Understood'),
        ),
      ],
    ),
  );

  void _toggleRecoveryMode() {
    setState(() {
      _useRecoveryCode = !_useRecoveryCode;
      _securityCodeController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Column(
                      children: [
                        _LoginHeader(onBack: widget.onBack),

                        const SizedBox(height: 12),

                        _LoginCard(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          securityCodeController: _securityCodeController,
                          obscurePassword: _obscurePassword,
                          useRecoveryCode: _useRecoveryCode,
                          submitting: _submitting,
                          errorMessage: _errorMessage,
                          deviceSlotOccupied: _deviceSlotOccupied,
                          rememberDevice: _rememberDevice,
                          quickUnlockMethod: _quickUnlockMethod,
                          biometricConfirmed: _biometricConfirmed,
                          quickLoginAvailable: _quickLoginAvailable,
                          quickUnlockPinController: _quickUnlockPinController,
                          onPasswordVisibilityChanged: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          onRecoveryModeChanged: _toggleRecoveryMode,
                          onRememberDeviceChanged: _toggleRememberDevice,
                          onQuickUnlockMethodChanged: _selectQuickUnlockMethod,
                          onForgotPassword: widget.onForgotPassword,
                          onSubmit: _submit,
                          onRecoverMobileAccess: _showDeviceRecovery,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                          validateSecurityCode: _validateSecurityCode,
                          validateQuickUnlockPin: _validateQuickUnlockPin,
                        ),

                        const SizedBox(height: 22),

                        _CreateAccountSection(
                          onCreateAccount: widget.onCreateAccount,
                        ),

                        const SizedBox(height: 22),

                        const _SecurityNote(),

                        const SizedBox(height: 26),

                        const Text(
                          'DISCIPLINE CREATES FREEDOM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TradeXColors.goldBright,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
