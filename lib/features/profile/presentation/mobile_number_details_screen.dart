import 'package:flutter/material.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../catalog/presentation/secure_workflow_screens.dart';

class MobileNumberDetailsScreen extends StatelessWidget {
  const MobileNumberDetailsScreen({
    super.key,
    required this.apiClient,
    required this.number,
    required this.verified,
    required this.telegramUsername,
  });

  final TradeXApiClient apiClient;
  final String number;
  final bool verified;
  final String telegramUsername;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mobile Number Details')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
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
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: TradeXColors.goldBright),
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
