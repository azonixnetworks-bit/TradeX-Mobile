part of '../copy_trading_module.dart';

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: CopySectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CopyIconBadge(icon: icon),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: copyMuted, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.useCases,
    required this.account,
    required this.onTap,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final broker = copyAccountBroker(account);
    final name = broker.brokerName;
    return CopySectionCard(
      onTap: onTap,
      child: Row(
        children: [
          CopyBrokerLogo(
            useCases: useCases,
            name: name,
            logoUrl: broker.logoUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${account.marketCategory} · ${account.accountNumberMasked}',
                  style: const TextStyle(color: copyMuted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                const Text(
                  'cTrader Copy',
                  style: TextStyle(color: copyGold, fontSize: 11),
                ),
              ],
            ),
          ),
          CopyStatusPill(status: copyAccountStatus(account)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CopySectionCard(
    onTap: onTap,
    child: Row(
      children: [
        CopyIconBadge(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: copyMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: onTap == null ? Colors.white24 : copyGold,
        ),
      ],
    ),
  );
}

class _MarketSelector extends StatelessWidget {
  const _MarketSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return Row(
        children: ['FOREX', 'CRYPTO', 'DERIV']
            .map((market) {
              final selected = value == market;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: market == 'DERIV' ? 0 : 7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => onChanged(market),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: [Color(0xFF6A4A00), Color(0xFF1B1508)],
                              )
                            : null,
                        color: selected ? null : const Color(0xFF0B0E0D),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selected
                              ? copyGold
                              : copyGold.withValues(alpha: .4),
                        ),
                      ),
                      child: Column(
                        children: [
                          CopyMarketIcon(market: market, size: 36),
                          const SizedBox(height: 5),
                          Text(
                            market[0] + market.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected ? copyGold : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      );
    },
  );
}

class _BrokerDirectoryCard extends StatelessWidget {
  const _BrokerDirectoryCard({
    required this.useCases,
    required this.broker,
    required this.busy,
    required this.hasIntent,
    required this.onOpen,
    required this.onContinue,
  });
  final CopyTradingUseCases useCases;
  final CopyTradingBrokerMarket broker;
  final bool busy;
  final bool hasIntent;
  final VoidCallback onOpen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final name = broker.brokerName;
    return CopySectionCard(
      child: Column(
        children: [
          Row(
            children: [
              CopyBrokerLogo(
                useCases: useCases,
                name: name,
                logoUrl: broker.logoUrl,
                size: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${broker.marketCategory} · ${broker.requiredCurrency}',
                      style: const TextStyle(color: copyMuted),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'TradeX configured · LIVE account required',
                      style: TextStyle(color: copyGold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          CopyPrimaryButton(
            label: hasIntent ? 'Continue Account Setup' : 'Open Account',
            onPressed: hasIntent ? onContinue : onOpen,
            busy: busy,
            icon: hasIntent
                ? Icons.arrow_forward_rounded
                : Icons.open_in_new_rounded,
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) => const CopySectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CopySectionHeading(title: 'How It Works'),
        SizedBox(height: 14),
        _SetupStep(
          number: '1',
          title: 'Open Account',
          subtitle: 'Use the returned TradeX IB referral URL.',
        ),
        _SetupStep(
          number: '2',
          title: 'Connect Account',
          subtitle: 'Submit only the LIVE broker account number.',
        ),
        _SetupStep(
          number: '3',
          title: 'Eligibility Review',
          subtitle: 'Admin verifies IB ownership before activation.',
          last: true,
        ),
      ],
    ),
  );
}

class _VerificationSteps extends StatelessWidget {
  const _VerificationSteps({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final completed = switch (status) {
      'ACTIVE' => 4,
      'VERIFIED' => 3,
      'PENDING' || 'ESCALATED' => 2,
      _ => 1,
    };
    return CopySectionCard(
      child: Row(
        children: List.generate(4, (index) {
          final active = index < completed;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? copyGold.withValues(alpha: .16)
                        : Colors.white.withValues(alpha: .04),
                    border: Border.all(
                      color: active ? copyGold : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? copyGold : Colors.white38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  const ['Details', 'Verify', 'Review', 'Done'][index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? copyGold : copyMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _VerificationTimeline extends StatelessWidget {
  const _VerificationTimeline({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => CopySectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CopySectionHeading(
          title: 'Verification Timeline',
          subtitle: 'Server-confirmed account lifecycle.',
        ),
        const SizedBox(height: 14),
        _TimelineRow(
          title: 'Submission Received',
          state: status == 'ACCOUNT DETAILS' ? 'Not submitted' : 'Complete',
          active: status != 'ACCOUNT DETAILS',
        ),
        _TimelineRow(
          title: 'TradeX IB Review',
          state: status,
          active: const {
            'PENDING',
            'ESCALATED',
            'VERIFIED',
            'ACTIVE',
          }.contains(status),
        ),
        _TimelineRow(
          title: 'Eligibility Complete',
          state: status == 'ACTIVE' ? 'Complete' : 'Pending',
          active: status == 'ACTIVE',
          last: true,
        ),
      ],
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.state,
    required this.active,
    this.last = false,
  });
  final String title;
  final String state;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: active ? copyGold : Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
          if (!last) Container(width: 2, height: 36, color: Colors.white24),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      Text(
        state.replaceAll('_', ' '),
        style: TextStyle(color: active ? copyGold : copyMuted, fontSize: 11),
      ),
    ],
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: Row(
      children: [
        Icon(icon, color: copyGold),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: copyMuted, fontSize: 11),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CompactAccountHeader extends StatelessWidget {
  const _CompactAccountHeader({required this.useCases, required this.account});
  final CopyTradingUseCases useCases;
  final CopyTradingAccount account;

  @override
  Widget build(BuildContext context) {
    final broker = copyAccountBroker(account);
    final name = broker.brokerName;
    return Row(
      children: [
        CopyBrokerLogo(
          useCases: useCases,
          name: name,
          logoUrl: broker.logoUrl,
          size: 60,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${account.marketCategory} · ${account.accountNumberMasked}',
                style: const TextStyle(color: copyMuted),
              ),
              const Text(
                'cTrader Copy',
                style: TextStyle(color: copyGold, fontSize: 11),
              ),
            ],
          ),
        ),
        CopyStatusPill(status: copyAccountStatus(account)),
      ],
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.subtitle,
    this.last = false,
  });
  final String number;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: copyGold, width: 2),
              color: copyGold.withValues(alpha: .1),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: copyGold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!last) Container(width: 2, height: 42, color: copyGold),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: copyMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(26),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFFFFDE67), Color(0xFFFFB913)],
              )
            : null,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? Colors.black : copyMuted),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : copyMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _UnavailableSetting extends StatelessWidget {
  const _UnavailableSetting({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: copyGold),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: const Text(
      'Backend endpoint unavailable',
      style: TextStyle(color: copyMuted, fontSize: 11),
    ),
    trailing: Switch(value: false, onChanged: null),
  );
}

String _error(Object? error) {
  if (error is UserFacingException) return error.message;
  if (error is StateError) return error.message;
  return 'Copy Trading could not be loaded right now.';
}
