import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/auth_form_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onSignIn,
    required this.onContinue,
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
    required String referralCode,
  })
  onContinue;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(
    text: 'Sri Lanka',
  );
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _submitting = false;
  String? _errorMessage;
  String? _countryCode = 'LK';
  List<_Country> _countrySuggestions = _countries;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _countryController.dispose();
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

    final number = '${_selectedCountry.dialCode}${value!.trim()}';

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
      return 'Use international format, for example +94771234567.';
    }

    return null;
  }

  String? _validateCountry(String? value) {
    if (_countryCode == null || (value?.trim().isEmpty ?? true)) {
      return 'Select a country from the list.';
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
      await widget.onContinue(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        whatsappNumber:
            '${_selectedCountry.dialCode}${_whatsappController.text.trim()}',
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        countryCode: _countryCode!,
        referralCode: _referralController.text.trim(),
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

  void _onCountryChanged(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    setState(() {
      _countryCode = null;
      _countrySuggestions = _countries
          .where(
            (country) =>
                country.name.toLowerCase().contains(normalizedQuery) ||
                country.code.toLowerCase().startsWith(normalizedQuery),
          )
          .take(6)
          .toList();
    });
  }

  void _selectCountry(_Country country) {
    setState(() {
      _countryController.text = country.name;
      _countryCode = country.code;
      _whatsappController.clear();
      _countrySuggestions = <_Country>[];
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return TradeXAuthPage(
      title: 'Create Your Account',
      subtitle: 'Add your account details. You will choose your learning language on the next step.',
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
              controller: _countryController,
              label: 'Country',
              icon: Icons.public_rounded,
              textInputAction: TextInputAction.next,
              validator: _validateCountry,
              onChanged: _onCountryChanged,
              textCapitalization: TextCapitalization.words,
            ),
            if (_countrySuggestions.isNotEmpty && _countryCode == null)
              _CountrySuggestions(
                countries: _countrySuggestions,
                onSelected: _selectCountry,
              ),
            const SizedBox(height: 13),
            TradeXAuthField(
              controller: _whatsappController,
              label: 'Mobile Number',
              icon: Icons.phone_android_rounded,
              prefixText: '${_selectedCountry.dialCode} ',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              validator: _validateWhatsApp,
            ),
            const SizedBox(height: 13),
            TradeXAuthField(
              controller: _referralController,
              label: 'Referral Code (Required)',
              icon: Icons.group_add_outlined,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              textCapitalization: TextCapitalization.characters,
              validator: (value) => _required(value, 'Referral code'),
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
              message: 'Password must be 8+ characters and include uppercase, lowercase, number, and symbol.',
              icon: Icons.security_rounded,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              TradeXErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 18),
            TradeXGoldButton(
              label: 'Continue to Language',
              onPressed: _submit,
              loading: _submitting,
              icon: Icons.person_add_alt_1_rounded,
            ),
          ],
        ),
      ),
    );
  }

  _Country get _selectedCountry => _countries.firstWhere(
    (country) => country.code == _countryCode,
    orElse: () => _countries.firstWhere((country) => country.code == 'LK'),
  );
}

class _CountrySuggestions extends StatelessWidget {
  const _CountrySuggestions({
    required this.countries,
    required this.onSelected,
  });

  final List<_Country> countries;
  final ValueChanged<_Country> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111614),
        border: Border.all(
          color: const Color(0xFFFFC83D).withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: countries
            .map(
              (country) => ListTile(
                dense: true,
                title: Text(
                  country.name,
                  style: const TextStyle(color: Color(0xFFF8FAFC)),
                ),
                trailing: Text(
                  '${country.code} · ${country.dialCode}',
                  style: const TextStyle(color: Color(0xFFFFC83D)),
                ),
                onTap: () => onSelected(country),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Country {
  const _Country(this.name, this.code, this.dialCode);

  final String name;
  final String code;
  final String dialCode;
}

const List<_Country> _countries = <_Country>[
  _Country('Australia', 'AU', '+61'),
  _Country('Bangladesh', 'BD', '+880'),
  _Country('Canada', 'CA', '+1'),
  _Country('France', 'FR', '+33'),
  _Country('Germany', 'DE', '+49'),
  _Country('India', 'IN', '+91'),
  _Country('Indonesia', 'ID', '+62'),
  _Country('Italy', 'IT', '+39'),
  _Country('Japan', 'JP', '+81'),
  _Country('Malaysia', 'MY', '+60'),
  _Country('Maldives', 'MV', '+960'),
  _Country('Nepal', 'NP', '+977'),
  _Country('Pakistan', 'PK', '+92'),
  _Country('Qatar', 'QA', '+974'),
  _Country('Saudi Arabia', 'SA', '+966'),
  _Country('Singapore', 'SG', '+65'),
  _Country('South Africa', 'ZA', '+27'),
  _Country('Sri Lanka', 'LK', '+94'),
  _Country('Thailand', 'TH', '+66'),
  _Country('United Arab Emirates', 'AE', '+971'),
  _Country('United Kingdom', 'GB', '+44'),
  _Country('United States', 'US', '+1'),
];
