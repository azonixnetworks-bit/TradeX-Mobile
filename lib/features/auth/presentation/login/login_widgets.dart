part of '../login_screen.dart';

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
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.palette.primaryText,
            ),
          ),
        ),

        SizedBox(
          width: 220,
          height: 136,
          child: Image.asset(
            'assets/branding/trade_x_final_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'TRADING EDUCATION  •  TRADING SERVICES',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.palette.secondaryText,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.75,
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
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 23),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFDEE2EA), width: 1.1),
        boxShadow: const [
          BoxShadow(color: Color(0x160E1B32), blurRadius: 28, offset: Offset(0, 14)),
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
                color: Color(0xFF101827),
                fontSize: 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE9A400),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sign in securely to continue your trading journey.',
              style: TextStyle(
                color: Color(0xFF5D6878),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remember this device',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rememberDevice
                            ? 'Use fingerprint or passcode for quick unlock.'
                            : 'Stay signed in for faster and more secure access.',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Switch(
                  value: rememberDevice,
                  onChanged: submitting ? null : onRememberDeviceChanged,
                  activeTrackColor: const Color(0xFFF6BD2C),
                  activeThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE6EAF0),
                  inactiveThumbColor: const Color(0xFF59687A),
                  trackOutlineColor: WidgetStateProperty.all(
                    const Color(0xFFC5CDD9),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

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

              const SizedBox(height: 12),

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

              const SizedBox(height: 12),

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

            const SizedBox(height: 20),

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
      style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
      cursorColor: context.palette.gold,
      decoration: InputDecoration(
        counterText: '',
        hintText: label,
        hintStyle: const TextStyle(color: Color(0xFF647084)),
        prefixIcon: Icon(icon, color: const Color(0xFF596679), size: 22),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 19,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFCBD2DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFCBD2DD), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD7A11C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: TradeXColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
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
          color: selected ? context.palette.goldSoft : context.palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? context.palette.gold : context.palette.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? context.palette.goldText
                  : context.palette.secondaryText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? context.palette.goldText
                      : context.palette.primaryText,
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
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFE26B),
              Color(0xFFF7BE37),
              Color(0xFFD79500),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDDA726).withValues(alpha: 0.19),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: submitting ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
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
          style: TextStyle(color: Color(0xFF647084), fontSize: 14),
        ),
        GestureDetector(
          onTap: onCreateAccount,
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: Color(0xFFB77D00),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF303846),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF18202C)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFFFFC84C),
            size: 20,
          ),
          SizedBox(width: 9),
          Flexible(
            child: Text(
              'Your account is protected with TradeX security.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFF4F5F7), fontSize: 11),
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
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF9FAFD),
                Color(0xFFF9FAFD),
              ],
            ),
          ),
        ),
        Positioned(
          top: 56,
          right: -32,
          width: 188,
          child: Opacity(
            opacity: .18,
            child: Image.asset(
              'assets/auth_ui/shared/minimalist_ascending_candlestick_overlay.png',
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 140,
          child: Opacity(
            opacity: .82,
            child: Image.asset(
              'assets/auth_ui/shared/soft_cream_layered_wave_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
