import 'package:flutter/material.dart';

import '../../../core/domain/api_gateway.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../../catalog/presentation/secure_workflow_screens.dart';

class MobileNumberDetailsScreen extends StatelessWidget {
  const MobileNumberDetailsScreen({
    super.key,
    required this.apiClient,
    required this.number,
    required this.verified,
    required this.telegramUsername,
  });

  final ApiGateway apiClient;
  final String number;
  final bool verified;
  final String telegramUsername;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.background,
    appBar: AppBar(
      backgroundColor: context.palette.background,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Mobile Number Details',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Contact Details',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage your verified messaging contacts and security status.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: context.palette.secondaryText, height: 1.35),
        ),
        const SizedBox(height: 18),
        _ContactCard(
          icon: Icons.chat_rounded,
          title: 'WhatsApp',
          value: number,
          status: verified ? 'Verified' : 'Unverified',
          statusIcon: verified
              ? Icons.verified_rounded
              : Icons.warning_amber_rounded,
          statusColor: verified
              ? TradeXColors.success
              : TradeXColors.goldBright,
          actionLabel: 'Change WhatsApp Number',
          onChange: () => _openChange(context, 'whatsapp'),
        ),
        const SizedBox(height: 14),
        _ContactCard(
          icon: Icons.send_rounded,
          title: 'Telegram',
          value: telegramUsername.isEmpty
              ? 'Not configured'
              : telegramUsername.startsWith('@')
              ? telegramUsername
              : '@$telegramUsername',
          status: telegramUsername.isEmpty
              ? 'Telegram username not configured'
              : 'Telegram username saved',
          statusIcon: telegramUsername.isEmpty
              ? Icons.info_outline_rounded
              : Icons.check_circle_outline_rounded,
          statusColor: telegramUsername.isEmpty
              ? TradeXColors.secondaryText
              : TradeXColors.success,
          actionLabel: telegramUsername.isEmpty
              ? 'Add Telegram Username'
              : 'Change Telegram Username',
          onChange: () => _openChange(context, 'telegram'),
        ),
        const SizedBox(height: 16),
        _ContactVerificationSummary(
          mobileVerified: verified,
          telegramConnected: telegramUsername.isNotEmpty,
        ),
        const SizedBox(height: 16),
        const Text(
          'Contact changes use the existing TradeX security flow: authenticator confirmation followed by the server-issued email code. Telegram is stored by the backend as a username, not a phone number.',
          style: TextStyle(fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );

  Future<void> _openChange(BuildContext context, String channel) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ContactChangeScreen(apiClient: apiClient, initialChannel: channel),
      ),
    );
    if (updated == true && context.mounted) Navigator.pop(context, true);
  }
}

class _ContactVerificationSummary extends StatelessWidget {
  const _ContactVerificationSummary({
    required this.mobileVerified,
    required this.telegramConnected,
  });

  final bool mobileVerified;
  final bool telegramConnected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.palette.goldSoft.withValues(alpha: .42),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.palette.gold.withValues(alpha: .4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Status',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ContactStatusChip(
              label: mobileVerified ? 'WhatsApp Verified' : 'Unverified',
              active: mobileVerified,
            ),
            _ContactStatusChip(
              label: telegramConnected ? 'Telegram Linked' : 'Not linked',
              active: telegramConnected,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ContactStatusChip extends StatelessWidget {
  const _ContactStatusChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: (active ? TradeXColors.success : context.palette.surface)
          .withValues(alpha: active ? .1 : 1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: active ? TradeXColors.success : context.palette.border,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          active ? Icons.check_rounded : Icons.info_outline_rounded,
          size: 17,
          color: active ? TradeXColors.success : context.palette.secondaryText,
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.status,
    required this.statusIcon,
    required this.statusColor,
    required this.actionLabel,
    required this.onChange,
  });

  final IconData icon;
  final String title;
  final String value;
  final String status;
  final IconData statusIcon;
  final Color statusColor;
  final String actionLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Card(
    color: context.palette.surfaceRaised,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: TradeXRadii.card,
      side: BorderSide(color: context.palette.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.palette.goldSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: context.palette.goldText),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 19),
              const SizedBox(width: 7),
              Expanded(child: Text(status)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.edit_outlined),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    ),
  );
}
