import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/auth_form_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onSubmit,
  });

  final VoidCallback onBack;
  final VoidCallback onSignIn;

  final Future<void> Function({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String passwordConfirmation,
    required String countryCode,
    required String languageCode,
    String? referralCode,
  }) onSubmit;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Set<String> _allowedLanguages = <String>{
    'en',
    'ta',
    'si',
    'hi',
    'ml',
    'te',
    'ur',
  };

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _countryController =
      TextEditingController(text: 'LK');
  final TextEditingController _languageController =
      TextEditingController(text: 'en');
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    _referralController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _validateName(String? value) {
    final requiredError = _required(value, 'Full name');
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 2) {
      return 'Enter at least 2 characters.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _required(value, 'Email');
    if (requiredError != null) {
      return requiredError;
    }

    final email = value!.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateWhatsApp(String? value) {
    final requiredError = _required(value, 'WhatsApp number');
    if (requiredError != null) {
      return requiredError;
    }

    final number = value!.trim();

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
      return 'Use international format, for example +94771234567.';
    }

    return null;
  }

  String? _validateCountry(String? value) {
    final code = value?.trim() ?? '';

    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(code)) {
      return 'Enter a 2-letter country code.';
    }

    return null;
  }

  String? _validateLanguage(String? value) {
    final code = value?.trim().toLowerCase() ?? '';

    if (!_allowedLanguages.contains(code)) {
      return 'Use en, ta, si, hi, ml, te, or ur.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.length < 12) {
      return 'Password must contain at least 12 characters.';
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
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        countryCode: _countryController.text.trim(),
        languageCode: _languageController.text.trim(),
        referralCode: _referralController.text.trim().isEmpty
            ? null
            : _referralController.text.trim(),
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
      title: 'Create Your Account',
      subtitle:
          'Set up your TradeX account, then verify email, WhatsApp, and authenticator security.',
      onBack: widget.onBack,
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: widget.onSignIn,
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: Color(0xFFFFC83D),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TradeXAuthField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: _validateName,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 13),
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
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9+]'),
                ),
                LengthLimitingTextInputFormatter(16),
              ],
              validator: _validateWhatsApp,
            ),
            const SizedBox(height: 13),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TradeXAuthField(
                    controller: _countryController,
                    label: 'Country',
                    icon: Icons.public_rounded,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z]'),
                      ),
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: _validateCountry,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TradeXAuthField(
                    controller: _languageController,
                    label: 'Language',
                    icon: Icons.language_rounded,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z]'),
                      ),
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: _validateLanguage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            TradeXAuthField(
              controller: _referralController,
              label: 'Referral Code (optional)',
              icon: Icons.group_add_outlined,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                LengthLimitingTextInputFormatter(30),
              ],
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 13),
            TradeXAuthField(
              controller: _passwordController,
              label: 'Password',
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
              controller: _confirmPasswordController,
              label: 'Confirm Password',
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
              message:
                  'Password must be 12+ characters and include uppercase, lowercase, number, and symbol.',
              icon: Icons.security_rounded,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              TradeXErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 18),
            TradeXGoldButton(
              label: 'Create Account',
              onPressed: _submit,
              loading: _submitting,
              icon: Icons.person_add_alt_1_rounded,
            ),
          ],
        ),
      ),
    );
  }
}