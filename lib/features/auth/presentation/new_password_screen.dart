import 'package:flutter/material.dart';

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
      title: 'Create New Password',
      subtitle: 'Open the TradeX reset email and paste the reset link or token below.',
      onBack: widget.onBack,
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
            const TradeXInfoBanner(
              message: 'Use at least 8 characters with uppercase, lowercase, number, and symbol. Your current password cannot be reused.',
              icon: Icons.password_rounded,
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
