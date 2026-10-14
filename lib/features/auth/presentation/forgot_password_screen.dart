import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/auth_form_components.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });

  final VoidCallback onBack;

  final Future<void> Function({
    required String email,
    required String whatsappNumber,
  }) onSubmit;

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email address is required.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateWhatsApp(String? value) {
    final number = value?.trim() ?? '';

    if (number.isEmpty) {
      return 'WhatsApp number is required.';
    }

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
      return 'Use international format, for example +94771234567.';
    }

    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        email: _emailController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return TradeXAuthPage(
      title: 'Forgot Password',
      subtitle:
          'Confirm the email and WhatsApp number linked to your TradeX account.',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const TradeXInfoBanner(
              message:
                  'For privacy, TradeX returns the same response whether or not the account details are eligible.',
              icon: Icons.privacy_tip_outlined,
            ),
            const SizedBox(height: 16),
            TradeXAuthField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 13),
            TradeXAuthField(
              controller: _whatsappController,
              label: 'WhatsApp Number',
              icon: Icons.chat_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9+]'),
                ),
                LengthLimitingTextInputFormatter(16),
              ],
              validator: _validateWhatsApp,
              onFieldSubmitted: (_) {
                if (!_submitting) {
                  _submit();
                }
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              TradeXErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 18),
            TradeXGoldButton(
              label: 'Start Recovery',
              onPressed: _submit,
              loading: _submitting,
              icon: Icons.lock_reset_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
