part of '../funded_advisor_module.dart';

class FundedNoTradeRulesScreen extends StatelessWidget {
  const FundedNoTradeRulesScreen({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FundedAdvisorCubit, FundedAdvisorState>(
    builder: (context, state) {
      final partner = state.selectedPartner;
      if (partner == null) return const _MissingPartnerPage();
      final phases = <String>{
        'ALL',
        ...partner.rules.map((rule) => rule.phase),
      }.toList();
      const order = ['ALL', 'CHALLENGE', 'VERIFICATION', 'FUNDED'];
      phases.sort((a, b) {
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });
      final program = state.selectedChallengeType?.toLowerCase();
      final rules = partner.rules
          .where((rule) {
            final phaseMatches =
                state.selectedPhase == 'ALL' ||
                rule.phase == 'ALL' ||
                rule.phase == state.selectedPhase;
            final programMatches =
                program == null ||
                rule.programName == null ||
                rule.programName!.toLowerCase() == program;
            return phaseMatches && programMatches;
          })
          .toList(growable: false);
      return FundedPage(
        title: 'No Trade Zone Rules',
        subtitle: 'Official news restrictions for your selected program.',
        children: [
          NoTradeZoneWarningBanner(
            source: context.read<NoTradeWarningSource>(),
            applicableSymbolsOrCurrencies: rules.expand(
              (rule) => <String>[
                ...rule.restrictedCurrencies,
                ...rule.restrictedInstruments,
              ],
            ),
          ),
          _CompactPartnerHeader(partner: partner),
          const SizedBox(height: 12),
          if (state.selectedChallengeType != null ||
              state.selectedAccountSize != null)
            FundedCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (state.selectedChallengeType != null)
                    FundedPill(label: state.selectedChallengeType!),
                  if (state.selectedAccountSize != null)
                    FundedPill(label: state.selectedAccountSize!),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: phases
                  .map(
                    (phase) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FundedPill(
                        label: _titleCase(phase),
                        selected: state.selectedPhase == phase,
                        onTap: () => context
                            .read<FundedAdvisorCubit>()
                            .selectPhase(phase),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          if (rules.isEmpty)
            const FundedEmptyState(
              title: 'No published rules',
              message:
                  'No active news restriction matches this program and phase.',
            )
          else
            for (final rule in rules) ...[
              _RuleCard(
                rule: rule,
                onTap: () =>
                    _open(context, FundedRuleDetailsScreen(rule: rule)),
              ),
              const SizedBox(height: 11),
            ],
          const SizedBox(height: 10),
          const FundedStatusNotice(
            message: 'Rules are informational snapshots. Always verify the official funded-company source before placing a trade.',
          ),
        ],
      );
    },
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onTap});

  final FundedRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _policyColor(rule.policy);
    return FundedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rule.programName ?? 'News Trading Rule',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FundedPill(label: rule.policy, selected: true, color: color),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            rule.summary ?? 'Open to view the published restriction details.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: fundedMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              FundedPill(label: _titleCase(rule.phase)),
              FundedPill(label: rule.enforcementType.replaceAll('_', ' ')),
              FundedPill(
                label:
                    '${rule.minutesBefore}m before · ${rule.minutesAfter}m after',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FundedRuleDetailsScreen extends StatelessWidget {
  const FundedRuleDetailsScreen({super.key, required this.rule});

  final FundedRule rule;

  @override
  Widget build(BuildContext context) {
    final partner = context.read<FundedAdvisorCubit>().state.selectedPartner;
    return FundedPage(
      title: 'Rule Details',
      subtitle: partner?.name ?? 'Funded company rule',
      children: [
        FundedCard(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FundedPill(
                    label: rule.policy,
                    selected: true,
                    color: _policyColor(rule.policy),
                  ),
                  FundedPill(label: _titleCase(rule.phase)),
                  FundedPill(label: rule.enforcementType.replaceAll('_', ' ')),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                rule.programName ?? 'News Trading Rule',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (rule.summary != null) ...[
                const SizedBox(height: 8),
                Text(
                  rule.summary!,
                  style: const TextStyle(color: fundedMuted, height: 1.5),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Row(
              children: [
                SizedBox(
                  width: width,
                  child: _WindowCard(
                    label: 'Before event',
                    value: '${rule.minutesBefore} min',
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: width,
                  child: _WindowCard(
                    label: 'After event',
                    value: '${rule.minutesAfter} min',
                    icon: Icons.timer_off_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const FundedSectionTitle(title: 'Policy Conditions'),
        _BooleanRule(
          label: 'Opening new trades',
          blocked: rule.blockOpenNewTrades,
        ),
        _BooleanRule(
          label: 'Closing existing trades',
          blocked: rule.blockCloseTrades,
        ),
        _BooleanRule(
          label: 'Placing pending orders',
          blocked: rule.blockPendingOrders,
        ),
        if (rule.impactLevels.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ValueSection(
            icon: Icons.warning_amber_rounded,
            title: 'Impact levels',
            values: rule.impactLevels,
            emptyText: '',
          ),
        ],
        if (rule.eventKeywords.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ValueSection(
            icon: Icons.newspaper_rounded,
            title: 'News events',
            values: rule.eventKeywords,
            emptyText: '',
          ),
        ],
        if (rule.restrictedCurrencies.isNotEmpty ||
            rule.restrictedInstruments.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ValueSection(
            icon: Icons.currency_exchange_rounded,
            title: rule.affectedInstrumentsOnly
                ? 'Affected instruments only'
                : 'Restricted markets',
            values: <String>{
              ...rule.restrictedCurrencies,
              ...rule.restrictedInstruments,
            }.toList(),
            emptyText: '',
          ),
        ],
        const SizedBox(height: 16),
        FundedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verification',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (rule.sourceReference != null)
                _KeyValue('Reference', rule.sourceReference!),
              if (rule.verifiedAt != null)
                _KeyValue('Verified', _date(rule.verifiedAt!)),
              if (rule.effectiveFrom != null)
                _KeyValue('Effective from', _date(rule.effectiveFrom!)),
              if (rule.expiresAt != null)
                _KeyValue('Expires', _date(rule.expiresAt!)),
            ],
          ),
        ),
        if (rule.sourceUrl != null) ...[
          const SizedBox(height: 14),
          FundedPrimaryButton(
            label: 'Open Official Source',
            icon: Icons.open_in_new_rounded,
            onPressed: () => _launch(rule.sourceUrl!),
          ),
        ],
      ],
    );
  }
}

class _CompactPartnerHeader extends StatelessWidget {
  const _CompactPartnerHeader({required this.partner});

  final FundedPartner partner;

  @override
  Widget build(BuildContext context) => FundedCard(
    gold: true,
    child: Row(
      children: [
        _PartnerLogo(partner: partner, size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${partner.rules.length} active news rule${partner.rules.length == 1 ? '' : 's'}',
                style: const TextStyle(color: fundedMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => FundedCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: fundedGold),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: fundedMuted, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _BooleanRule extends StatelessWidget {
  const _BooleanRule({required this.label, required this.blocked});

  final String label;
  final bool blocked;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: FundedCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            blocked ? Icons.block_rounded : Icons.check_circle_outline_rounded,
            color: blocked ? TradeXColors.error : TradeXColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            blocked ? 'BLOCKED' : 'ALLOWED',
            style: TextStyle(
              color: blocked ? TradeXColors.error : TradeXColors.success,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: fundedMuted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _MissingPartnerPage extends StatelessWidget {
  const _MissingPartnerPage();

  @override
  Widget build(BuildContext context) => FundedPage(
    title: 'Funded Advisor',
    subtitle: 'Partner selection is required.',
    children: const [
      FundedEmptyState(
        title: 'Partner not selected',
        message: 'Return to the company list and select a funded partner.',
      ),
    ],
  );
}

Future<void> _open(BuildContext context, Widget page) {
  final warningSource = context.read<NoTradeWarningSource>();
  final cubit = context.read<FundedAdvisorCubit>();
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => RepositoryProvider.value(
        value: warningSource,
        child: BlocProvider.value(value: cubit, child: page),
      ),
    ),
  );
}

Future<void> _launch(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Color _policyColor(String policy) => switch (policy.toUpperCase()) {
  'ALLOWED' => TradeXColors.success,
  'CONDITIONAL' => TradeXColors.warning,
  _ => TradeXColors.error,
};

String _titleCase(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

Iterable<String> _partnerWarningScope(FundedPartner partner) => partner.rules
    .expand(
      (rule) => <String>[
        ...rule.restrictedCurrencies,
        ...rule.restrictedInstruments,
      ],
    )
    .where((value) => value.trim().isNotEmpty)
    .toSet();

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
