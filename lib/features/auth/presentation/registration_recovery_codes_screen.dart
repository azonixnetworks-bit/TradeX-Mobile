import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tradex_design_system.dart';
import '../domain/entities/registration_session.dart';
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
      title: 'Recovery Codes',
      subtitle: 'Keep these backup codes in a safe place. You can use any of them to regain access to your account.',
      securityDecor: true,
      decorTopAsset:
          'assets/recovery_course_ui/light_gray_candlestick_decor.png',
      decorFooterAsset: 'assets/recovery_course_ui/ivory_wave_footer.png',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TradeXInfoBanner(
            message: 'Each code can only be used once. Do not share them with anyone.',
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your Recovery Codes (${recoveryCodes.codes.length})',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final code in recoveryCodes.codes)
                    Container(
                      width: tileWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: context.palette.border),
                      ),
                      child: SelectableText(
                        code,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.palette.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .35,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _copyAll(context),
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Copy All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.palette.goldText,
              side: BorderSide(color: context.palette.gold),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 18),
          TradeXGoldButton(
            label: 'I Saved Them',
            onPressed: onContinue,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}
