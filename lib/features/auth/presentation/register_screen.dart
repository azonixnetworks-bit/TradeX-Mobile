import 'package:flutter/material.dart';

import 'widgets/auth_form_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onNext,
  });
  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  })
  onNext;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _passwordValidator(String? value) {
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

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onNext(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => TradeXAuthPage(
    title: 'Create Your Account',
    subtitle: 'Start with your secure Trade X account details.',
    onBack: widget.onBack,
    footer: Wrap(
      alignment: WrapAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
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
            controller: _name,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().length < 2
                ? 'Enter your full name.'
                : null,
          ),
          const SizedBox(height: 13),
          TradeXAuthField(
            controller: _email,
            label: 'Email Address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value == null ||
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())
                ? 'Enter a valid email address.'
                : null,
          ),
          const SizedBox(height: 13),
          TradeXAuthField(
            controller: _password,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            validator: _passwordValidator,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PasswordChecklist(password: _password.text),
          const SizedBox(height: 13),
          TradeXAuthField(
            controller: _confirmation,
            label: 'Confirm Password',
            icon: Icons.lock_reset_rounded,
            obscureText: _hideConfirmation,
            textInputAction: TextInputAction.done,
            validator: (value) =>
                value != _password.text ? 'Passwords do not match.' : null,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _hideConfirmation = !_hideConfirmation),
              icon: Icon(
                _hideConfirmation
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: 18),
          TradeXGoldButton(label: 'Next', loading: _loading, onPressed: _next),
        ],
      ),
    ),
  );
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = <(String, bool)>[
      ('8+ characters', password.length >= 8),
      ('Uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      ('Lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
      ('Number', RegExp(r'[0-9]').hasMatch(password)),
      ('Symbol', RegExp(r'[^A-Za-z0-9]').hasMatch(password)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 7,
      children: checks
          .map(
            (check) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  check.$2 ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 15,
                  color: check.$2
                      ? const Color(0xFF18D77A)
                      : const Color(0xFF7D8796),
                ),
                const SizedBox(width: 4),
                Text(
                  check.$1,
                  style: TextStyle(
                    color: check.$2
                        ? const Color(0xFFB8F5D3)
                        : const Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
