
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

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _whatsappController =
      TextEditingController();

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
      return _whatsappController.text.trim().isEmpty
          ? 'Enter your email or WhatsApp number.'
          : null;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateWhatsApp(String? value) {
    final number = value?.trim() ?? '';

    if (number.isEmpty) return null;

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
          'Enter your registered email or WhatsApp number. Both contacts must be verified to reset your password.',

      onBack: widget.onBack,

      decorTopAsset:
          'assets/auth_recovery_ui/subtle_gold_uptrend_candlesticks.png',

      decorFooterAsset:
          'assets/auth_recovery_ui/soft_ivory_wave_layers.png',

      child: Form(
        key: _formKey,
        child: Column(
          children: [

            // EMAIL HEADER — GOLD
            const _RecoverySectionLabel(
              icon: Icons.mail_outline_rounded,
              iconColor: Color(0xFFD4A017),
              label: 'Recover with your email',
            ),

            const SizedBox(height: 10),

            TradeXAuthField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),

            const SizedBox(height: 16),

            const _OrDivider(),

            const SizedBox(height: 16),

            // WHATSAPP HEADER — ORIGINAL PNG + GREEN
            const _RecoverySectionLabel(
              asset:
                  'assets/auth_recovery_ui/minimal_chat_phone_icon.png',
              iconColor: Color(0xFF25D366),
              label: 'Recover with your WhatsApp',
            ),

            const SizedBox(height: 10),

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

            const SizedBox(height: 14),

            const TradeXInfoBanner(
              message:
                  'For privacy, TradeX returns the same response whether or not the account details are eligible.',
              icon: Icons.info_outline_rounded,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              TradeXErrorBanner(
                message: _errorMessage!,
              ),
            ],

            const SizedBox(height: 18),

            TradeXGoldButton(
              label: 'Send Code',
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

// EMAIL AND WHATSAPP HEADER ICON COMPONENT
class _RecoverySectionLabel extends StatelessWidget {
  const _RecoverySectionLabel({
    this.icon,
    this.asset,
    required this.iconColor,
    required this.label,
  });

  final IconData? icon;
  final String? asset;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (asset != null)
          Image.asset(
            asset!,
            width: 25,
            height: 25,
            fit: BoxFit.contain,
            color: iconColor,
            colorBlendMode: BlendMode.srcIn,
          )
        else
          Icon(
            icon ?? Icons.help_outline_rounded,
            size: 25,
            color: iconColor,
          ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

// OR DIVIDER — UNCHANGED
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
          ),
        ),

        const Expanded(child: Divider()),
      ],
    );
  }
}
