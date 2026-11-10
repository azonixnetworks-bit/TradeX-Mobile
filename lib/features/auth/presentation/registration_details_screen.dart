import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/auth_form_components.dart';

class RegistrationDetailsScreen extends StatefulWidget {
  const RegistrationDetailsScreen({
    super.key,
    required this.onBack,
    required this.onContinue,
    required this.onCheckReferralCode,
  });

  final VoidCallback onBack;
  final Future<void> Function({
    required String countryCode,
    required String phone,
    required String referralCode,
  }) onContinue;
  /// Wired from AuthFlowScreen. The field is optional for the user, but
  /// entered codes must be verified against the backend before continuing.
  /// Keep this named callback in sync with auth_flow_screen.dart.
  final Future<bool> Function(String referralCode) onCheckReferralCode;

  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen> {
  final _form = GlobalKey<FormState>();
  final _country = TextEditingController(text: 'Sri Lanka');
  final _phone = TextEditingController();
  final _referral = TextEditingController();
  Timer? _referralDebounce;
  int _referralRevision = 0;
  bool? _referralIsValid;
  bool _referralChecking = false;
  String? _referralError;
  String? _submitError;

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
    _referralDebounce?.cancel();
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

  void _referralChanged(String value) {
    _referralDebounce?.cancel();
    final revision = ++_referralRevision;
    final code = value.trim().toUpperCase();
    setState(() {
      _referralIsValid = null;
      _referralChecking = false;
      _referralError = null;
      _submitError = null;
    });
    if (code.isEmpty) return;

    // Debounce server lookups; stale responses are ignored.
    _referralDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkReferral(code, revision);
    });
  }

  Future<bool> _checkReferral(String code, int revision) async {
    if (!mounted || code.isEmpty) return false;
    setState(() {
      _referralChecking = true;
      _referralError = null;
    });
    try {
      final valid = await widget.onCheckReferralCode(code);
      if (!mounted ||
          revision != _referralRevision ||
          _referral.text.trim().toUpperCase() != code) {
        return false;
      }
      setState(() {
        _referralChecking = false;
        _referralIsValid = valid;
      });
      return valid;
    } catch (_) {
      if (mounted && revision == _referralRevision) {
        setState(() {
          _referralChecking = false;
          _referralIsValid = null;
          _referralError = 'Unable to check referral code. Please retry.';
        });
      }
      return false; // fail closed when network or backend is unavailable
    }
  }

  Future<void> _continue() async {
    if (!_form.currentState!.validate() || !_risk || !_disclaimer || !_terms) {
      setState(() {});
      return;
    }
    _referralDebounce?.cancel();
    final code = _referral.text.trim().toUpperCase();
    // The referral field is optional. Validate only when a code is entered.
    // A supplied but invalid code still prevents registration.
    if (code.isNotEmpty && _referralIsValid != true) {
      final valid = await _checkReferral(code, ++_referralRevision);
      if (!valid) return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _submitError = null;
    });
    try {
      // Laravel revalidates the referral atomically when starting registration.
      await widget.onContinue(
        countryCode: _selectedCountryCode,
        phone: '+$_selectedDialCode${_nationalPhoneNumber()}',
        referralCode: code,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _referralIsValid = null;
          _submitError = 'Unable to start registration. Check your details and referral code.';
        });
      }
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
            label: 'Referral Code (Optional)',
            icon: Icons.local_activity_outlined,
            textCapitalization: TextCapitalization.characters,
            onChanged: _referralChanged,
            suffixIcon: _referralChecking
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _referralIsValid == true
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16834A))
                    : _referralIsValid == false
                        ? const Icon(Icons.cancel_rounded, color: Color(0xFFD32F2F))
                        : null,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
              LengthLimitingTextInputFormatter(30),
              TextInputFormatter.withFunction(
                (oldValue, newValue) =>
                    newValue.copyWith(text: newValue.text.toUpperCase()),
              ),
            ],

          ),
          if (_referralError != null || _referralIsValid != null || _referralChecking) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _referralError ??
                    (_referralChecking
                        ? 'Checking referral code…'
                        : _referralIsValid == true
                            ? 'Valid referral code'
                            : 'Referral code is invalid or unavailable.'),
                style: TextStyle(
                  color: _referralIsValid == true
                      ? const Color(0xFF16834A)
                      : _referralChecking
                          ? const Color(0xFF667085)
                          : const Color(0xFFD32F2F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
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
          ),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
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
          ),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
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
          ),
          if (!_risk || !_disclaimer || !_terms)
            const Text(
              'Accept all three agreements to continue.',
              style: TextStyle(color: Color(0xFFFF7A7A), fontSize: 12),
            ),
          if (_submitError != null) ...[
            const SizedBox(height: 8),
            Text(
              _submitError!,
              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
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
