import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';
import 'widgets/auth_form_components.dart';

class RegistrationVerificationGateScreen extends StatefulWidget {
  const RegistrationVerificationGateScreen({super.key, required this.onVerify});
  final Future<void> Function() onVerify;
  @override
  State<RegistrationVerificationGateScreen> createState() =>
      _RegistrationVerificationGateScreenState();
}

class _RegistrationVerificationGateScreenState
    extends State<RegistrationVerificationGateScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onVerify();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    body: Stack(
      children: [
        const Center(
          child: Text(
            'Trade X Dashboard\n\nYour markets and learning space are ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: .68)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: TradeXAuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: TradeXColors.goldBright,
                    size: 52,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete Verification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Verify your email, WhatsApp and authenticator to unlock your dashboard and all Trade X features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFF7A7A)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TradeXGoldButton(
                    label: 'Start Verification',
                    loading: _loading,
                    onPressed: _start,
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
