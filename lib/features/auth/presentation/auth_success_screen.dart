import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import 'widgets/auth_form_components.dart';

class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isAccountReady = title == 'Account Created';
    return TradeXAuthPage(
      title: isAccountReady ? 'Account Ready' : title,
      subtitle: message,
      securityDecor: true,
      decorTopAsset:
          'assets/recovery_course_ui/light_gray_candlestick_decor.png',
      decorFooterAsset: 'assets/recovery_course_ui/ivory_wave_footer.png',
      child: Column(
        children: [
          if (isAccountReady)
            Image.asset(
              'assets/recovery_course_ui/account_ready_secure_hero.png',
              height: 190,
              fit: BoxFit.contain,
            )
          else
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TradeXColors.success.withValues(alpha: 0.10),
                border: Border.all(
                  color: TradeXColors.success.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: TradeXColors.success,
                size: 48,
              ),
            ),
          const SizedBox(height: 20),
          if (isAccountReady)
            const _AccountReadyChecklist()
          else
            const TradeXInfoBanner(
              message: 'Your security flow completed successfully. Continue to sign in with your account credentials and authenticator code.',
              icon: Icons.verified_user_rounded,
            ),
          const SizedBox(height: 20),
          TradeXGoldButton(
            label: buttonLabel,
            onPressed: onContinue,
            icon: Icons.login_rounded,
          ),
        ],
      ),
    );
  }
}

class _AccountReadyChecklist extends StatelessWidget {
  const _AccountReadyChecklist();

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.person_outline_rounded, 'Account Verified'),
      (Icons.shield_outlined, 'Security Enabled'),
      (Icons.bar_chart_rounded, 'Ready to Trade'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(items[index].$1, color: context.palette.goldText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[index].$2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: TradeXColors.success,
                  ),
                ],
              ),
            ),
            if (index != items.length - 1)
              Divider(height: 1, color: context.palette.border),
          ],
        ],
      ),
    );
  }
}
