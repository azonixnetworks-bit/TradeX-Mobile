import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tradex_colors.dart';
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
    final resendLabel = _secondsRemaining > 0
        ? 'Resend in ${_secondsRemaining}s'
        : 'Resend Code';

    return TradeXAuthPage(
      title: widget.title,
      subtitle: widget.subtitle,
      onBack: widget.onBack,
      titleIconAsset: widget.titleIconAsset,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: const TextStyle(
                color: TradeXColors.secondaryText,
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
                      onChanged: (value) {
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
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final int digitsPerBox;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
    ),
    textInputAction: TextInputAction.next,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(digitsPerBox),
    ],
    onChanged: onChanged,
    onSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(
      counterText: '',
      filled: true,
      fillColor: const Color(0xFF08100E),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334138)),
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
