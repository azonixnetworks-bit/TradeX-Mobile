part of '../funded_advisor_module.dart';

class FundedAccountOptionsScreen extends StatelessWidget {
  const FundedAccountOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FundedAdvisorCubit, FundedAdvisorState>(
        builder: (context, state) {
          final partner = state.selectedPartner;
          if (partner == null) return const _MissingPartnerPage();
          final cubit = context.read<FundedAdvisorCubit>();
          final ready =
              state.selectedChallengeType != null &&
              state.selectedAccountSize != null;
          return FundedPage(
            title: 'Account Options',
            subtitle: 'Choose an available challenge program and account size.',
            children: [
              _CompactPartnerHeader(partner: partner),
              const SizedBox(height: 20),
              const FundedSectionTitle(
                title: 'Challenge Options',
                subtitle: 'Options published by the funded company',
              ),
              if (partner.challengeTypes.isEmpty)
                const FundedEmptyState(
                  title: 'No challenge types',
                  message: 'This partner has not published challenge options.',
                )
              else
                for (final type in partner.challengeTypes) ...[
                  _SelectionCard(
                    title: type,
                    icon: Icons.layers_outlined,
                    selected: state.selectedChallengeType == type,
                    onTap: () => cubit.selectChallengeType(type),
                  ),
                  const SizedBox(height: 9),
                ],
              const SizedBox(height: 16),
              const FundedSectionTitle(
                title: 'Account Size',
                subtitle: 'Choose one available account size',
              ),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: partner.accountSizes
                    .map(
                      (size) => FundedPill(
                        label: size,
                        selected: state.selectedAccountSize == size,
                        onTap: () => cubit.selectAccountSize(size),
                      ),
                    )
                    .toList(),
              ),
              if (ready) ...[
                const SizedBox(height: 18),
                FundedCard(
                  gold: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Account Configuration',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      _KeyValue('Program', state.selectedChallengeType!),
                      _KeyValue('Account size', state.selectedAccountSize!),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FundedPrimaryButton(
                label: 'Review No Trade Zone Rules',
                icon: Icons.shield_outlined,
                onPressed: ready
                    ? () => _open(context, const FundedNoTradeRulesScreen())
                    : null,
              ),
            ],
          );
        },
      );
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FundedCard(
    gold: selected,
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: selected ? fundedGold : fundedMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? fundedGold : fundedMuted,
        ),
      ],
    ),
  );
}
