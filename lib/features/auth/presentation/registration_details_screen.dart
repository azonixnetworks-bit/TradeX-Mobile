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
  })
  onContinue;
  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen> {
  final _form = GlobalKey<FormState>();
  final _country = TextEditingController(text: 'Sri Lanka');
  final _phone = TextEditingController();
  final _referral = TextEditingController();
  bool _risk = false, _disclaimer = false, _terms = false, _loading = false;
  @override
  void dispose() {
    _country.dispose();
    _phone.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate() || !_risk || !_disclaimer || !_terms) {
      setState(() {});
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onContinue(
        countryCode: 'LK',
        phone: '+94${_phone.text.trim()}',
        referralCode: _referral.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => TradeXAuthPage(
    title: 'Complete Your Details',
    subtitle: 'Confirm your country, contact number, referral and agreements.',
    onBack: widget.onBack,
    child: Form(
      key: _form,
      child: Column(
        children: [
          TradeXAuthField(
            controller: _country,
            label: 'Country',
            icon: Icons.public_rounded,
            readOnly: true,
          ),
          const SizedBox(height: 13),
          TradeXAuthField(
            controller: _referral,
            label: 'Referral Code',
            icon: Icons.group_add_outlined,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Referral code is required.'
                : null,
          ),
          const SizedBox(height: 13),
          TradeXAuthField(
            controller: _phone,
            label: 'WhatsApp / Mobile Number',
            icon: Icons.phone_android_rounded,
            prefixText: '+94 ',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => v == null || v.trim().length < 8
                ? 'Enter a valid mobile number.'
                : null,
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _risk,
            onChanged: (v) => setState(() => _risk = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I understand that I trade at my own risk.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          CheckboxListTile(
            value: _disclaimer,
            onChanged: (v) => setState(() => _disclaimer = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I have read the Trade Disclaimer.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I accept the Terms & Conditions.',
              style: TextStyle(color: Colors.white, fontSize: 13),
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
