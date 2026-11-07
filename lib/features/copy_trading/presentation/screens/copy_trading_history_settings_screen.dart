part of '../copy_trading_module.dart';

class CopyTradingHistorySettingsScreen extends StatefulWidget {
  const CopyTradingHistorySettingsScreen({
    super.key,
    required this.useCases,
    required this.account,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;

  @override
  State<CopyTradingHistorySettingsScreen> createState() =>
      _CopyTradingHistorySettingsScreenState();
}

class _CopyTradingHistorySettingsScreenState
    extends State<CopyTradingHistorySettingsScreen> {
  bool _history = true;

  @override
  Widget build(BuildContext context) => CopyTradingScrollPage(
    children: [
      CopyPageHeading(
        title: 'Copy',
        goldTitle: _history ? 'History' : 'Settings',
        subtitle: _history
            ? 'Track the copy-trading information available for this account.'
            : 'Manage only the controls supported by your connected account.',
        icon: _history ? Icons.history_rounded : Icons.tune_rounded,
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                selected: _history,
                icon: Icons.history_rounded,
                label: 'History',
                onTap: () => setState(() => _history = true),
              ),
            ),
            Expanded(
              child: _TabButton(
                selected: !_history,
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => setState(() => _history = false),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      CopySectionCard(
        highlight: true,
        child: _CompactAccountHeader(
          useCases: widget.useCases,
          account: widget.account,
        ),
      ),
      const SizedBox(height: 14),
      if (_history) ...[
        const CopySectionHeading(title: 'Recent Closed Trades'),
        const SizedBox(height: 10),
        const CopyEmptyState(
          icon: Icons.history_toggle_off_rounded,
          title: 'Trade history unavailable',
          message: 'The current backend has billing history but no cTrader closed-trades endpoint. No trade rows are fabricated.',
        ),
        const SizedBox(height: 12),
        CopyPrimaryButton(
          label: 'Statement Unavailable',
          icon: Icons.download_for_offline_outlined,
          onPressed: null,
        ),
      ] else ...[
        const CopySectionHeading(title: 'Copy Settings'),
        const SizedBox(height: 10),
        const CopySectionCard(
          child: Column(
            children: [
              _UnavailableSetting(
                icon: Icons.notifications_none_rounded,
                title: 'Trade Notifications',
              ),
              Divider(),
              _UnavailableSetting(
                icon: Icons.sync_rounded,
                title: 'Auto Sync Trades',
              ),
              Divider(),
              _UnavailableSetting(
                icon: Icons.shield_outlined,
                title: 'Risk Alert Level',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CopyEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Settings are read-only',
          message: 'These controls will activate only when Laravel exposes authorized cTrader settings and stop-copying endpoints.',
        ),
      ],
    ],
  );
}
