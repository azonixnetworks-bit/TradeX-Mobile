import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/auth_form_components.dart';

class RegistrationDetailsScreen extends StatefulWidget {
  const RegistrationDetailsScreen({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final Future<void> Function({
    required String countryCode,
    required String phone,
    required String referralCode,
  }) onContinue;

  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen> {
  final _form = GlobalKey<FormState>();
  final _country = TextEditingController(text: 'Sri Lanka');
  final _phone = TextEditingController();
  final _referral = TextEditingController();

  // Backend expects the two-letter ISO code (e.g. LK, IN, AE).
  String _selectedCountryCode = 'LK';
  String _selectedDialCode = '94';

  bool _risk = false;
  bool _disclaimer = false;
  bool _terms = false;
  bool _loading = false;

  @override
  void dispose() {
    _country.dispose();
    _phone.dispose();
    _referral.dispose();
    super.dispose();
  }

  void _selectCountry() {
    FocusScope.of(context).unfocus();
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      showSearch: true,
      favorite: const ['LK', 'IN', 'AE', 'GB', 'US'],
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        backgroundColor: Colors.white,
        textStyle: const TextStyle(color: Color(0xFF182230), fontSize: 15),
        inputDecoration: InputDecoration(
          hintText: 'Search country or dialing code',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFC39319)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      onSelect: (country) {
        if (!mounted) return;
        final changed = _selectedCountryCode != country.countryCode;
        setState(() {
          _selectedCountryCode = country.countryCode;
          _selectedDialCode = country.phoneCode;
          _country.text = country.name;
          // Avoid sending a number from a previous country with a new prefix.
          if (changed) _phone.clear();
        });
      },
    );
  }

  String _nationalPhoneNumber() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    // Remove the domestic trunk zero only for these common cases.
    // For countries such as Italy, a leading zero may be significant.
    if (const {'LK', 'GB', 'IN', 'AE'}.contains(_selectedCountryCode)) {
      return digits.replaceFirst(RegExp(r'^0'), '');
    }
    return digits;
  }

  String? _validatePhone(String? value) {
    final national = _nationalPhoneNumber();
    final fullNumber = '$_selectedDialCode$national';
    if (national.isEmpty) return 'Enter your WhatsApp / mobile number.';
    if (national.length < 6 || fullNumber.length > 15) {
      return 'Enter a valid international mobile number.';
    }
    return null;
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate() || !_risk || !_disclaimer || !_terms) {
      setState(() {});
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onContinue(
        countryCode: _selectedCountryCode,
        phone: '+$_selectedDialCode${_nationalPhoneNumber()}',
        referralCode: _referral.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => TradeXAuthPage(
    title: 'Registration Details',
    subtitle:
        'Complete your registration with your mobile number and referral code.',
    onBack: widget.onBack,
    securityDecor: true,
    child: Form(
      key: _form,
      child: Column(
        children: [
          TradeXAuthField(
            controller: _country,
            label: 'Country',
            icon: Icons.public_rounded,
            readOnly: true,
            onTap: _selectCountry,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Select your country.'
                : null,
          ),
          const SizedBox(height: 13),
          TradeXAuthField(
            controller: _phone,
            label: 'WhatsApp / Mobile Number',
            icon: Icons.phone_android_rounded,
            // Displays the selected dialing prefix when the field is focused.
            prefixText: '+$_selectedDialCode ',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            validator: _validatePhone,
          ),
          const SizedBox(height: 13),
          TradeXAuthField(
            controller: _referral,
            label: 'Referral Code',
            icon: Icons.local_activity_outlined,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
              LengthLimitingTextInputFormatter(30),
              TextInputFormatter.withFunction(
                (oldValue, newValue) =>
                    newValue.copyWith(text: newValue.text.toUpperCase()),
              ),
            ],
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Referral code is required.'
                : null,
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _risk,
            onChanged: (v) => setState(() => _risk = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'I understand that I trade at my own risk.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
          CheckboxListTile(
            value: _disclaimer,
            onChanged: (v) => setState(() => _disclaimer = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'I have read the Trade Disclaimer.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'I accept the Terms & Conditions.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
          if (!_risk || !_disclaimer || !_terms)
            const Text(
              'Accept all three agreements to continue.',
              style: TextStyle(color: Color(0xFFFF7A7A), fontSize: 12),
            ),
          const SizedBox(height: 12),
          TradeXGoldButton(
            label: 'Continue',
            loading: _loading,
            onPressed: _continue,
          ),
        ],
      ),
    ),
  );
}
