part of '../home_dashboard_screen.dart';

// ignore: unused_element
class _AffiliateHero extends StatelessWidget {
  const _AffiliateHero({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D230B), Color(0xFF0F1915)],
        ),
        border: Border.all(color: TradeXColors.gold.withValues(alpha: .65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: TradeXColors.goldBright,
            size: 34,
          ),
          const SizedBox(height: 12),
          const Text(
            'Invite. Empower. Earn.',
            style: TextStyle(
              color: TradeXColors.primaryText,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your unique referral code is ready to share.',
            style: TextStyle(color: TradeXColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TradeXColors.borderStrong),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color: TradeXColors.goldBright,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TRADEX.OS/REF/TRXADMIN',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.copy_rounded,
                  color: TradeXColors.goldBright,
                  size: 17,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _GoldButton(label: 'Share Your Link', onTap: onShare),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AffiliateMetrics extends StatelessWidget {
  const _AffiliateMetrics();

  @override
  Widget build(BuildContext context) {
    const metrics = [
      ('0', 'Total referrals', Icons.groups_rounded),
      ('0', 'Qualified clients', Icons.verified_rounded),
      ('LKR 0.00', 'Available rewards', Icons.account_balance_wallet_rounded),
    ];
    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        childAspectRatio: .83,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: _panelDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metric.$3, color: TradeXColors.goldBright, size: 21),
              const Spacer(),
              Text(
                metric.$1,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                metric.$2,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: TradeXColors.goldBright,
                ),
                SizedBox(width: 8),
                Text(
                  'Community Builder',
                  style: TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Invite 5 qualified clients to unlock your first reward tier.',
              style: TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 13),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 7,
                color: TradeXColors.goldBright,
                backgroundColor: TradeXColors.surfaceMuted,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '0 of 5 qualified clients',
              style: TextStyle(color: TradeXColors.secondaryText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AffiliateTools extends StatelessWidget {
  const _AffiliateTools({required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.people_alt_outlined,
            title: 'My Referrals',
            subtitle: 'See your referral network',
            onTap: () => onActionTap('My referrals'),
          ),
          const Divider(height: 1, color: TradeXColors.border),
          _MenuRow(
            icon: Icons.history_rounded,
            title: 'Rewards History',
            subtitle: 'Track your affiliate rewards',
            onTap: () => onActionTap('Rewards history'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.status,
    this.expanded,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? status;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final color = danger ? TradeXColors.error : TradeXColors.goldBright;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: danger
                                ? TradeXColors.error
                                : TradeXColors.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 6),
                        status!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween<double>(begin: .88, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  expanded == true
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.chevron_right_rounded,
                  key: ValueKey(expanded == true ? 'expanded' : 'collapsed'),
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
