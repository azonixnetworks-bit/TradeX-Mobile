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

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _verifying = false;
  bool _resending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _startCooldown(widget.initialCooldownSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = seconds;
    });

    if (seconds <= 0) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
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
      },
    );
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Verification code is required.';
    }

    if (code.length != widget.codeLength) {
      return 'Enter the ' +
          widget.codeLength.toString() +
          '-digit verification code.';
    }

    return null;
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.onVerify(_codeController.text.trim());
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
        ? 'Resend in ' + _secondsRemaining.toString() + 's'
        : 'Resend Code';

    return TradeXAuthPage(
      title: widget.title,
      subtitle: widget.subtitle,
      onBack: widget.onBack,
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
            TradeXAuthField(
              controller: _codeController,
              label: widget.codeLength == 8
                  ? '8-digit verification code'
                  : '6-digit verification code',
              icon: Icons.password_rounded,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.codeLength),
              ],
              maxLength: widget.codeLength,
              validator: _validateCode,
              onFieldSubmitted: (_) {
                if (!_verifying) {
                  _verify();
                }
              },
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
                  onPressed:
                      _secondsRemaining > 0 || _resending ? null : _resend,
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