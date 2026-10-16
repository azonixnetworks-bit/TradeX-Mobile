import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tradex_colors.dart';
import '../models/registration_session.dart';
import 'widgets/auth_form_components.dart';

class RegistrationRecoveryCodesScreen extends StatelessWidget {
  const RegistrationRecoveryCodesScreen({
    super.key,
    required this.recoveryCodes,
    required this.onContinue,
  });

  final RegistrationRecoveryCodes recoveryCodes;
  final VoidCallback onContinue;

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: recoveryCodes.codes.join('\n')),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Recovery codes copied. Save them in a secure place.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return TradeXAuthPage(
      title: 'Save Recovery Codes',
      subtitle: 'These codes are shown only once. They are not sent by email.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TradeXInfoBanner(
            message: 'Use one code only if you lose access to your authenticator. Each code works once.',
            icon: Icons.key_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF090D0B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: TradeXColors.gold.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              children: [
                for (final code in recoveryCodes.codes) ...[
                  SelectableText(
                    code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      height: 1.9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _copyAll(context),
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Copy All Codes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TradeXColors.goldBright,
              side: const BorderSide(color: TradeXColors.gold),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 18),
          TradeXGoldButton(
            label: 'I Saved My Codes',
            onPressed: onContinue,
            icon: Icons.verified_user_rounded,
          ),
        ],
      ),
    );
  }
}
