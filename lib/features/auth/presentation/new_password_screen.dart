import 'package:flutter/material.dart';

import '../../../core/theme/tradex_design_system.dart';
import 'widgets/auth_form_components.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.recoveryId,
    required this.onBack,
    required this.onResendLink,
    required this.onSubmit,
  });

  final String recoveryId;
  final VoidCallback onBack;
  final Future<void> Function() onResendLink;

  final Future<void> Function({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  })
  onSubmit;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _resetLinkController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _submitting = false;
  bool _resending = false;
  String? _errorMessage;
  String? _successMessage;

  bool get _hasLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSymbol =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text);

  int get _strength => [
    _hasLength,
    _hasUppercase,
    _hasNumber,
    _hasSymbol,
  ].where((value) => value).length;

  @override
  void dispose() {
    _resetLinkController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String? _validateResetLink(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty) {
      return 'Paste the reset link or reset token from your email.';
    }

    try {
      _extractResetToken(raw);
    } catch (error) {
      return error.toString();
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.length < 8) {
      return 'Password must contain at least 8 characters.';
    }

    if (!RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Use uppercase, lowercase, number, and symbol.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  String _extractResetToken(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri != null && uri.queryParameters.containsKey('reset_token')) {
      final recoveryId = uri.queryParameters['recovery_id'];

      if (recoveryId != null &&
          recoveryId.isNotEmpty &&
          recoveryId != widget.recoveryId) {
        throw const FormatException(
          'This reset link belongs to a different recovery session.',
        );
      }

      final token = uri.queryParameters['reset_token'] ?? '';

      if (token.length < 32) {
        throw const FormatException('The reset link is invalid.');
      }

      return token;
    }

    if (trimmed.length < 32) {
      throw const FormatException('The reset token is invalid.');
    }

    return trimmed;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = _extractResetToken(_resetLinkController.text);

      await widget.onSubmit(
        resetToken: token,
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_resending) {
      return;
    }

    setState(() {
      _resending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.onResendLink();

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = 'A new reset link has been sent to your email.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TradeXAuthPage(
      title: 'New Password',
      subtitle: 'Open the TradeX reset email and paste the reset link or token below.',
      onBack: widget.onBack,
      securityDecor: true,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const TradeXInfoBanner(
              message: 'The reset link is short-lived and single-use. Completing the reset signs out existing sessions and clears trusted-device status.',
              icon: Icons.security_update_warning_outlined,
            ),
            const SizedBox(height: 16),
            TradeXAuthField(
              controller: _resetLinkController,
              label: 'Reset Link or Token',
              icon: Icons.link_rounded,
              textInputAction: TextInputAction.next,
              validator: _validateResetLink,
            ),
            const SizedBox(height: 13),
            TradeXAuthField(
              controller: _passwordController,
              label: 'New Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
              onChanged: (_) => setState(() {}),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            const SizedBox(height: 13),
            TradeXAuthField(
              controller: _confirmationController,
              label: 'Confirm New Password',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmation,
              textInputAction: TextInputAction.done,
              validator: _validateConfirmation,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmation = !_obscureConfirmation;
                  });
                },
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              onFieldSubmitted: (_) {
                if (!_submitting) {
                  _submit();
                }
              },
            ),
            const SizedBox(height: 14),
            _PasswordStrength(value: _strength),
            const SizedBox(height: 12),
            _PasswordRequirements(
              requirements: [
                ('At least 8 characters', _hasLength),
                ('One uppercase letter', _hasUppercase),
                ('One number', _hasNumber),
                ('One special character', _hasSymbol),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              TradeXErrorBanner(message: _errorMessage!),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 14),
              TradeXInfoBanner(
                message: _successMessage!,
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
            const SizedBox(height: 18),
            TradeXGoldButton(
              label: 'Reset Password',
              onPressed: _submit,
              loading: _submitting,
              icon: Icons.lock_reset_rounded,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: _resending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Resend Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = value <= 1
        ? 'Weak'
        : value <= 3
        ? 'Good'
        : 'Strong';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Password Strength',
                style: TextStyle(
                  color: palette.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: palette.goldText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index < value ? palette.gold : palette.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.requirements});

  final List<(String, bool)> requirements;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: requirements
            .map(
              (requirement) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    requirement.$2
                        ? Image.asset(
                            'assets/security_ui/glossy_gold_checkmark_badge.png',
                            width: 22,
                            height: 22,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: palette.borderStrong,
                          ),
                    const SizedBox(width: 10),
                    Text(
                      requirement.$1,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
