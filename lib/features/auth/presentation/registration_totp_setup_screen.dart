import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../domain/entities/registration_session.dart';
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

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: context.palette.surfaceRaised,
          content: Text(
            '$label copied.',
            style: TextStyle(color: context.palette.primaryText),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return TradeXAuthPage(
      title: 'Set Up Authenticator',
      subtitle: 'Add TradeX to your authenticator app before confirming the 6-digit code.',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TradeXInfoBanner(
            message: 'Use Google Authenticator, Microsoft Authenticator, 1Password, Authy, or another TOTP-compatible app.',
            icon: Icons.security_rounded,
          ),
          const SizedBox(height: 18),
          Text(
            'Scan QR Code',
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          _TotpQrCode(value: setup.otpauthUri),
          const SizedBox(height: 18),
          Text(
            'Issuer',
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            setup.issuer,
            style: TextStyle(
              color: context.palette.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Account',
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            setup.accountName,
            style: TextStyle(
              color: context.palette.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Manual Setup Key',
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.palette.surfaceMuted,
              borderRadius: TradeXRadii.control,
              border: Border.all(
                color: TradeXColors.gold.withValues(alpha: 0.28),
              ),
            ),
            child: SelectableText(
              setup.secret,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.goldText,
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
                _copy(context, setup.secret, 'Authenticator setup key');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Setup Key'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TradeXColors.goldBright,
                side: const BorderSide(color: TradeXColors.gold),
                padding: const EdgeInsets.symmetric(vertical: 13),
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

class _TotpQrCode extends StatelessWidget {
  const _TotpQrCode({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final qrSize = (constraints.maxWidth * 0.62).clamp(150.0, 210.0);

        return Center(
          child: Container(
            width: qrSize + 24,
            height: qrSize + 24,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TradeXColors.gold.withValues(alpha: 0.52),
              ),
              boxShadow: [
                BoxShadow(
                  color: TradeXColors.gold.withValues(alpha: 0.16),
                  blurRadius: 22,
                ),
              ],
            ),
            child: QrImageView(
              data: value,
              version: QrVersions.auto,
              size: qrSize,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF080B0A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF080B0A),
              ),
            ),
          ),
        );
      },
    );
  }
}
