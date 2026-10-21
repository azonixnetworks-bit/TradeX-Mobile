import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/auth/secure_session_store.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onForgotPassword,
    required this.onCreateAccount,
    required this.onLogin,
    this.quickUnlockConfig,
    this.onQuickUnlock,
  });

  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;
  final QuickUnlockConfig? quickUnlockConfig;
  final Future<void> Function()? onQuickUnlock;

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
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _obscurePassword = true;
  bool _useRecoveryCode = false;
  bool _rememberDevice = false;
  String _quickUnlockMethod = 'BIOMETRIC';
  bool _biometricConfirmed = false;
  bool _submitting = false;

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
      final supported =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!supported) {
        throw PlatformException(code: 'NOT_AVAILABLE');
      }

      final confirmed = await _localAuth.authenticate(
        localizedReason:
            'Place your finger on the sensor to sign in to TradeX.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (mounted) {
        setState(() {
          _biometricConfirmed = confirmed;
          _errorMessage = confirmed
              ? null
              : 'Authentication failed. Fingerprint was not recognized.';
        });
      }
      return confirmed;
    } on PlatformException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication failed. Fingerprint is not available on this device.';
        });
      }
      return false;
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
    final result = await SecureSessionStore().verifyQuickUnlockPin(
      _quickUnlockPinController.text.trim(),
    );
    if (!mounted) return;
    if (result != QuickUnlockPinResult.success) {
      setState(() {
        _quickUnlockPinController.clear();
        _errorMessage = result == QuickUnlockPinResult.locked
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
            error is ApiException &&
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
      backgroundColor: TradeXColors.background,
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: TradeXColors.goldBright,
            ),
          ),
        ),

        SizedBox(
          width: 128,
          height: 128,
          child: Image.asset(
            'assets/branding/trade_x_final_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'The OS for Every Trader.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Learn. Trade. Grow.',
          style: TextStyle(
            color: TradeXColors.goldBright,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.securityCodeController,
    required this.obscurePassword,
    required this.useRecoveryCode,
    required this.submitting,
    required this.errorMessage,
    required this.deviceSlotOccupied,
    required this.rememberDevice,
    required this.quickUnlockMethod,
    required this.biometricConfirmed,
    required this.quickLoginAvailable,
    required this.quickUnlockPinController,
    required this.onPasswordVisibilityChanged,
    required this.onRecoveryModeChanged,
    required this.onRememberDeviceChanged,
    required this.onQuickUnlockMethodChanged,
    required this.onForgotPassword,
    required this.onSubmit,
    required this.onRecoverMobileAccess,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateSecurityCode,
    required this.validateQuickUnlockPin,
  });

  final GlobalKey<FormState> formKey;

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController securityCodeController;

  final bool obscurePassword;
  final bool useRecoveryCode;
  final bool submitting;
  final bool rememberDevice;
  final String quickUnlockMethod;
  final bool biometricConfirmed;
  final bool quickLoginAvailable;

  final String? errorMessage;
  final bool deviceSlotOccupied;
  final TextEditingController quickUnlockPinController;

  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onRecoveryModeChanged;
  final ValueChanged<bool> onRememberDeviceChanged;
  final ValueChanged<String> onQuickUnlockMethodChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;
  final VoidCallback onRecoverMobileAccess;

  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateSecurityCode;
  final String? Function(String?) validateQuickUnlockPin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111614), Color(0xFF080B0A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: TradeXColors.gold.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TradeXColors.gold.withValues(alpha: 0.10),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Sign in securely to continue your trading journey.',
              style: TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 22),

            SwitchListTile.adaptive(
              value: rememberDevice,
              onChanged: submitting ? null : onRememberDeviceChanged,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: TradeXColors.goldBright,
              title: const Text(
                'Remember this device',
                style: TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                rememberDevice
                    ? 'Use fingerprint or passcode for quick unlock.'
                    : 'Use your email, password and authenticator code.',
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (!rememberDevice) ...[
              _LoginField(
                controller: emailController,
                label: 'Email Address',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: validateEmail,
              ),

              const SizedBox(height: 13),

              _LoginField(
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                validator: validatePassword,
                suffixIcon: IconButton(
                  onPressed: onPasswordVisibilityChanged,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: TradeXColors.secondaryText,
                  ),
                ),
              ),

              const SizedBox(height: 13),

              _LoginField(
                controller: securityCodeController,
                label: useRecoveryCode
                    ? 'Recovery Code'
                    : 'Authenticator Code (6 digits)',
                icon: Icons.shield_outlined,
                keyboardType: useRecoveryCode
                    ? TextInputType.text
                    : TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: useRecoveryCode
                    ? null
                    : [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                maxLength: useRecoveryCode ? null : 6,
                validator: validateSecurityCode,
                onFieldSubmitted: (_) {
                  if (!submitting) {
                    onSubmit();
                  }
                },
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onRecoveryModeChanged,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: useRecoveryCode
                                      ? TradeXColors.goldBright
                                      : TradeXColors.borderStrong,
                                ),
                                color: useRecoveryCode
                                    ? TradeXColors.goldBright
                                    : Colors.transparent,
                              ),
                              child: useRecoveryCode
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Colors.black,
                                    )
                                  : null,
                            ),

                            const SizedBox(width: 9),

                            const Flexible(
                              child: Text(
                                'Use recovery code instead',
                                style: TextStyle(
                                  color: TradeXColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  TextButton(
                    onPressed: onForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: TradeXColors.goldBright,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (rememberDevice) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _QuickUnlockMethodButton(
                      label: 'Fingerprint',
                      icon: Icons.fingerprint_rounded,
                      selected: quickUnlockMethod == 'BIOMETRIC',
                      onTap: () => onQuickUnlockMethodChanged('BIOMETRIC'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickUnlockMethodButton(
                      label: 'Passcode',
                      icon: Icons.pin_outlined,
                      selected: quickUnlockMethod == 'PIN',
                      onTap: () => onQuickUnlockMethodChanged('PIN'),
                    ),
                  ),
                ],
              ),
              if (quickUnlockMethod == 'PIN') ...[
                const SizedBox(height: 12),
                _LoginField(
                  controller: quickUnlockPinController,
                  label: 'Enter passcode',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  maxLength: 4,
                  validator: validateQuickUnlockPin,
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      biometricConfirmed
                          ? Icons.verified_rounded
                          : Icons.touch_app_rounded,
                      size: 18,
                      color: biometricConfirmed
                          ? TradeXColors.success
                          : TradeXColors.goldBright,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        biometricConfirmed
                            ? 'Fingerprint verified. Signing in securely…'
                            : 'Select Fingerprint and place your finger on the mobile sensor.',
                        style: TextStyle(
                          color: biometricConfirmed
                              ? TradeXColors.success
                              : TradeXColors.secondaryText,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Your passcode and biometric data stay only on this device.',
                style: TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 10,
                ),
              ),
              if (!quickLoginAvailable) ...[
                const SizedBox(height: 8),
                const Text(
                  'Sign in normally, then set up fingerprint or passcode from Profile.',
                  style: TextStyle(
                    color: TradeXColors.goldBright,
                    fontSize: 10,
                  ),
                ),
              ],
            ],

            if (errorMessage != null) ...[
              const SizedBox(height: 10),

              _ErrorMessage(message: errorMessage!),
              if (deviceSlotOccupied) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRecoverMobileAccess,
                    icon: const Icon(Icons.phonelink_lock_rounded),
                    label: const Text('Recover Mobile Access'),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),

            _SignInButton(submitting: submitting, onPressed: onSubmit),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.inputFormatters,
    this.maxLength,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final bool obscureText;

  final Widget? suffixIcon;

  final List<TextInputFormatter>? inputFormatters;

  final int? maxLength;

  final Iterable<String>? autofillHints;

  final String? Function(String?) validator;

  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(color: TradeXColors.primaryText, fontSize: 14),
      cursorColor: TradeXColors.goldBright,
      decoration: InputDecoration(
        counterText: '',
        hintText: label,
        hintStyle: const TextStyle(color: TradeXColors.secondaryText),
        prefixIcon: Icon(icon, color: TradeXColors.gold, size: 21),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF090D0B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: TradeXColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: TradeXColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: TradeXColors.gold, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: TradeXColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: TradeXColors.error, width: 1.3),
        ),
        errorStyle: const TextStyle(color: TradeXColors.error, fontSize: 11),
      ),
    );
  }
}

class _QuickUnlockMethodButton extends StatelessWidget {
  const _QuickUnlockMethodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? TradeXColors.gold.withValues(alpha: 0.14)
              : TradeXColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TradeXColors.goldBright : TradeXColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? TradeXColors.goldBright
                  : TradeXColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? TradeXColors.goldBright
                      : TradeXColors.primaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.submitting, required this.onPressed});

  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD760),
              TradeXColors.goldBright,
              Color(0xFFF0A500),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: TradeXColors.goldBright.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: submitting ? null : onPressed,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: submitting
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.black,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 9),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black,
                          size: 21,
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

class _CreateAccountSection extends StatelessWidget {
  const _CreateAccountSection({required this.onCreateAccount});

  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Don\'t have an account? ',
          style: TextStyle(color: TradeXColors.secondaryText, fontSize: 14),
        ),
        GestureDetector(
          onTap: onCreateAccount,
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: TradeXColors.goldBright,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: TradeXColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: TradeXColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: TradeXColors.goldBright,
            size: 18,
          ),
          SizedBox(width: 9),
          Flexible(
            child: Text(
              'Your account is protected with TradeX security.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TradeXColors.secondaryText, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TradeXColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TradeXColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: TradeXColors.error,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: TradeXColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF070A08),
                TradeXColors.background,
                Color(0xFF020302),
              ],
            ),
          ),
        ),

        Positioned(
          top: -150,
          right: -140,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TradeXColors.gold.withValues(alpha: 0.13),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: -180,
          left: -140,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TradeXColors.goldDeep.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
