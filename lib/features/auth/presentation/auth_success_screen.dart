import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';
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
    return TradeXAuthPage(
      title: title,
      subtitle: message,
      child: Column(
        children: [
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
          const TradeXInfoBanner(
            message:
                'Your security flow completed successfully. Continue to sign in with your account credentials and authenticator code.',
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
