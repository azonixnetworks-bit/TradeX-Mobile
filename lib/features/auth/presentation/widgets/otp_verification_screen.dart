import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tradex_colors.dart';
import '../../../../core/theme/tradex_design_system.dart';
import 'auth_form_components.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.codeLength,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
    this.channelLabel,
    this.initialCooldownSeconds = 60,
    this.showResend = true,
    this.digitsPerBox = 2,
    this.forceSingleDigitBoxes = false,
    this.titleIconAsset,
  });

  final String title;
  final String subtitle;
  final int codeLength;
  final String? channelLabel;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onBack;
  final int initialCooldownSeconds;
  final bool showResend;
  final int digitsPerBox;
  final bool forceSingleDigitBoxes;
  final String? titleIconAsset;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

/// A dedicated six-field OTP screen for mobile verification. Keeping this as a
/// separate widget ensures the old two-digit email layout can never be reused
/// when the registration flow moves to WhatsApp/mobile verification.
class MobileOtpVerificationScreen extends StatelessWidget {
  const MobileOtpVerificationScreen({
    super.key,
    required this.subtitle,
    required this.channelLabel,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  final String subtitle;
  final String channelLabel;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OtpVerificationScreen(
      key: const ValueKey('mobile-single-digit-otp'),
      title: 'Verify WhatsApp',
      subtitle: subtitle,
      codeLength: 6,
      forceSingleDigitBoxes: true,
      titleIconAsset: 'assets/branding/whatsapp_verification.png',
      channelLabel: channelLabel,
      onVerify: onVerify,
      onResend: onResend,
      onBack: onBack,
    );
  }
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _codeFocusNodes;

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _verifying = false;
  bool _resending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(_boxCount, (_) => TextEditingController());
    _codeFocusNodes = List.generate(_boxCount, (_) => FocusNode());
    _startCooldown(widget.initialCooldownSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code =>
      _codeControllers.map((controller) => controller.text).join();

  void _applyFullCode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != widget.codeLength) return;
    for (var index = 0; index < _codeControllers.length; index++) {
      final start = index * _digitsPerBox;
      final end = start + _digitsPerBox;
      _codeControllers[index].text = digits.substring(start, end);
    }
    _codeFocusNodes.last.requestFocus();
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != widget.codeLength) {
      setState(
        () => _errorMessage =
            'Clipboard must contain exactly ${widget.codeLength} digits.',
      );
      return;
    }
    _applyFullCode(digits);
  }

  int get _boxCount => widget.forceSingleDigitBoxes
      ? widget.codeLength
      : widget.codeLength ~/ widget.digitsPerBox;

  int get _digitsPerBox =>
      widget.forceSingleDigitBoxes ? 1 : widget.digitsPerBox;

  void _startCooldown(int seconds) {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = seconds;
    });

    if (seconds <= 0) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        return;
      }

      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Verification code is required.';
    }

    if (code.length != widget.codeLength) {
      return 'Enter the ${widget.codeLength}-digit verification code.';
    }

    return null;
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    final validationError = _validateCode(_code);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.onVerify(_code);
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
          _verifying = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _resending) {
      return;
    }

    setState(() {
      _resending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.onResend();

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = 'A new verification code has been sent.';
      });

      _startCooldown(widget.initialCooldownSeconds);
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
    final isEmailVerification = widget.codeLength == 8;
    final resendLabel = _secondsRemaining > 0
        ? 'Resend in ${_secondsRemaining}s'
        : 'Resend Code';

    return TradeXAuthPage(
      title: widget.title,
      subtitle: widget.subtitle,
      onBack: widget.onBack,
      titleIconAsset: widget.titleIconAsset,
      decorTopAsset: isEmailVerification
          ? 'assets/auth_recovery_ui/subtle_gold_uptrend_candlesticks.png'
          : null,
      decorFooterAsset: isEmailVerification
          ? 'assets/auth_recovery_ui/soft_ivory_wave_layers.png'
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEmailVerification) ...[
              Center(
                child: Image.asset(
                  'assets/auth_recovery_ui/secure_email_verification_icon.png',
                  width: 126,
                  height: 112,
                  fit: BoxFit.contain,
                  semanticLabel: 'Secure email verification',
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.channelLabel != null) ...[
              TradeXInfoBanner(
                message: widget.channelLabel!,
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.codeLength == 8
                  ? 'Email verification code'
                  : 'Verification code',
              style: TextStyle(
                color: context.palette.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.codeLength == 8) ...[
                  const Text(
                    'TRX',
                    style: TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                for (
                  var index = 0;
                  index < _codeControllers.length;
                  index++
                ) ...[
                  Expanded(
                    child: _OtpCodeField(
                      controller: _codeControllers[index],
                      focusNode: _codeFocusNodes[index],
                      autofocus: index == 0,
                      digitsPerBox: _digitsPerBox,
                      maxInputLength: widget.codeLength,
                      enableOtpAutofill: index == 0,
                      onChanged: (value) {
                        if (value.length == widget.codeLength) {
                          _applyFullCode(value);
                          return;
                        }
                        if (value.length > _digitsPerBox) {
                          _codeControllers[index].text = value.substring(
                            0,
                            _digitsPerBox,
                          );
                          return;
                        }
                        if (value.length == _digitsPerBox &&
                            index < _codeFocusNodes.length - 1) {
                          _codeFocusNodes[index + 1].requestFocus();
                        }
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      onSubmitted: () {
                        if (index < _codeFocusNodes.length - 1) {
                          _codeFocusNodes[index + 1].requestFocus();
                        } else if (!_verifying) {
                          _verify();
                        }
                      },
                    ),
                  ),
                  if (index < _codeControllers.length - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _verifying ? null : _pasteCode,
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: const Text('Paste code'),
              ),
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
              label: 'Verify Code',
              onPressed: _verify,
              loading: _verifying,
              icon: Icons.verified_rounded,
            ),
            if (widget.showResend) ...[
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: _secondsRemaining > 0 || _resending
                      ? null
                      : _resend,
                  child: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TradeXColors.goldBright,
                          ),
                        )
                      : Text(
                          resendLabel,
                          style: TextStyle(
                            color: _secondsRemaining > 0
                                ? TradeXColors.tertiaryText
                                : TradeXColors.goldBright,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OtpCodeField extends StatelessWidget {
  const _OtpCodeField({
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.digitsPerBox,
    required this.maxInputLength,
    required this.enableOtpAutofill,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final int digitsPerBox;
  final int maxInputLength;
  final bool enableOtpAutofill;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    autofillHints: enableOtpAutofill
        ? const <String>[AutofillHints.oneTimeCode]
        : null,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: context.palette.primaryText,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
    ),
    textInputAction: TextInputAction.next,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxInputLength),
    ],
    onChanged: onChanged,
    onSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(
      counterText: '',
      filled: true,
      fillColor: context.palette.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: TradeXColors.goldBright,
          width: 1.5,
        ),
      ),
    ),
  );
}
