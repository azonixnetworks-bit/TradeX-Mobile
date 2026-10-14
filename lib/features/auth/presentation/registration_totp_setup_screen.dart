import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tradex_colors.dart';
import '../models/registration_session.dart';
import 'widgets/auth_form_components.dart';

class RegistrationTotpSetupScreen extends StatelessWidget {
  const RegistrationTotpSetupScreen({
    super.key,
    required this.setup,
    required this.onBack,
    required this.onContinue,
  });

  final RegistrationTotpSetup setup;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  Future<void> _copy(
    BuildContext context,
    String value,
    String label,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: value),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: TradeXColors.surfaceRaised,
          content: Text(
            '$label copied.',
            style: const TextStyle(
              color: TradeXColors.primaryText,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return TradeXAuthPage(
      title: 'Set Up Authenticator',
      subtitle:
          'Add TradeX to your authenticator app before confirming the 6-digit code.',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TradeXInfoBanner(
            message:
                'Use Google Authenticator, Microsoft Authenticator, 1Password, Authy, or another TOTP-compatible app.',
            icon: Icons.security_rounded,
          ),
          const SizedBox(height: 18),
          const Text(
            'Issuer',
            style: TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            setup.issuer,
            style: const TextStyle(
              color: TradeXColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Account',
            style: TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            setup.accountName,
            style: const TextStyle(
              color: TradeXColors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Manual Setup Key',
            style: TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF090D0B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TradeXColors.gold.withValues(alpha: 0.28),
              ),
            ),
            child: SelectableText(
              setup.secret,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TradeXColors.goldBright,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _copy(
                  context,
                  setup.secret,
                  'Authenticator setup key',
                );
              },
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
              ),
              label: const Text('Copy Setup Key'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TradeXColors.goldBright,
                side: const BorderSide(
                  color: TradeXColors.gold,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TradeXInfoBanner(
            message:
                'Code settings: ${setup.digits} digits • refreshes every ${setup.periodSeconds} seconds.',
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 18),
          TradeXGoldButton(
            label: 'I Added TradeX',
            onPressed: onContinue,
            icon: Icons.verified_user_rounded,
          ),
        ],
      ),
    );
  }
}