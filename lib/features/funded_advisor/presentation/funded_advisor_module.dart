import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tradex_colors.dart';
import '../domain/entities/funded_advisor_entities.dart';
import '../domain/usecases/funded_advisor_use_cases.dart';
import 'bloc/funded_advisor_cubit.dart';
import 'funded_advisor_widgets.dart';

class FundedAdvisorScreen extends StatelessWidget {
  const FundedAdvisorScreen({super.key, required this.useCases});

  final FundedAdvisorUseCases useCases;

  @override
  Widget build(BuildContext context) => BlocProvider<FundedAdvisorCubit>(
    create: (_) => FundedAdvisorCubit(useCases)..initialize(),
    child: const _FundedCompaniesScreen(),
  );
}

class _FundedCompaniesScreen extends StatefulWidget {
  const _FundedCompaniesScreen();

  @override
  State<_FundedCompaniesScreen> createState() => _FundedCompaniesScreenState();
}

class _FundedCompaniesScreenState extends State<_FundedCompaniesScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FundedAdvisorCubit>().refreshIfDue();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FundedAdvisorCubit, FundedAdvisorState>(
    builder: (context, state) {
      final cubit = context.read<FundedAdvisorCubit>();
      if (!state.hasCatalog &&
          state.status != FundedAdvisorStatus.errorNoCache) {
        return const Scaffold(
          backgroundColor: TradeXColors.background,
          body: SafeArea(
            child: Center(child: CircularProgressIndicator(color: fundedGold)),
          ),
        );
      }
      return FundedPage(
        title: 'Funded Companies',
        subtitle: 'Compare verified partners and official news rules.',
        onRefresh: () => cubit.refreshIfDue(manual: true),
        actions: [
          FundedIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: () => cubit.refreshIfDue(manual: true),
          ),
        ],
        children: [
          if (state.message != null) ...[
            FundedStatusNotice(message: state.message!),
            const SizedBox(height: 12),
          ],
          if (!state.hasCatalog)
            FundedEmptyState(
              title: 'Funded Advisor unavailable',
              message: state.message ?? 'No saved data is available yet.',
              action: 'Retry',
              onAction: () => cubit.refreshIfDue(manual: true),
            )
          else ...[
            TextField(
              onChanged: cubit.setQuery,
              decoration: InputDecoration(
                hintText: 'Search funded companies',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: TradeXColors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FundedPill(
                  label: 'All',
                  selected: !state.featuredOnly,
                  onTap: () => cubit.setFeaturedOnly(false),
                ),
                FundedPill(
                  label: 'Featured',
                  selected: state.featuredOnly,
                  onTap: () => cubit.setFeaturedOnly(true),
                ),
                const FundedPill(label: 'A–Z'),
              ],
            ),
            const SizedBox(height: 20),
            FundedSectionTitle(
              title: state.featuredOnly
                  ? 'Featured Partners'
                  : 'Available Partners',
              subtitle: '${state.visiblePartners.length} verified listings',
            ),
            if (state.visiblePartners.isEmpty)
              const FundedEmptyState(
                title: 'No matching companies',
                message: 'Try another search or remove the featured filter.',
              )
            else
              for (final partner in state.visiblePartners) ...[
                _PartnerCard(
                  partner: partner,
                  onTap: () {
                    cubit.selectPartner(partner);
                    _open(context, const FundedCompanyDetailsScreen());
                  },
                ),
                const SizedBox(height: 12),
              ],
          ],
        ],
      );
    },
  );
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partner, required this.onTap});

  final FundedPartner partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FundedCard(
    gold: partner.isFeatured,
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PartnerLogo(partner: partner, size: 58),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partner.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (partner.isFeatured)
                    const FundedPill(label: 'FEATURED', selected: true),
                ],
              ),
              if (partner.offerText != null) ...[
                const SizedBox(height: 6),
                Text(
                  partner.offerText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: fundedMuted, height: 1.35),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (partner.challengeTypes.isNotEmpty)
                    FundedPill(
                      label:
                          '${partner.challengeTypes.length} challenge type${partner.challengeTypes.length == 1 ? '' : 's'}',
                    ),
                  if (partner.rules.isNotEmpty)
                    FundedPill(label: '${partner.rules.length} news rules'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: fundedGold),
      ],
    ),
  );
}

class _PartnerLogo extends StatelessWidget {
  const _PartnerLogo({required this.partner, required this.size});

  final FundedPartner partner;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fundedGold.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TradeXColors.goldSoft),
      ),
      child: Text(
        partner.initials,
        style: const TextStyle(color: fundedGold, fontWeight: FontWeight.w900),
      ),
    );
    final logoUrl = partner.logoUrl;
    if (logoUrl == null) return fallback;
    return FutureBuilder<Uint8List>(
      future: context.read<FundedAdvisorCubit>().useCases.loadLogo(logoUrl),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            snapshot.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      },
    );
  }
}

class FundedCompanyDetailsScreen extends StatelessWidget {
  const FundedCompanyDetailsScreen({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FundedAdvisorCubit, FundedAdvisorState>(
    builder: (context, state) {
      final partner = state.selectedPartner;
      if (partner == null) return const _MissingPartnerPage();
      return FundedPage(
        title: 'Company Details',
        subtitle: 'Review verified partner information.',
        children: [
          FundedCard(
            gold: true,
            child: Column(
              children: [
                _PartnerLogo(partner: partner, size: 82),
                const SizedBox(height: 12),
                Text(
                  partner.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (partner.isFeatured) ...[
                  const SizedBox(height: 8),
                  const FundedPill(
                    label: 'TRADEX FEATURED PARTNER',
                    selected: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LinkGrid(partner: partner),
          if (partner.offerText != null) ...[
            const SizedBox(height: 14),
            FundedCard(
              gold: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_offer_outlined, color: fundedGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      partner.offerText!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const FundedSectionTitle(title: 'Available Programs'),
          _ValueSection(
            icon: Icons.flag_outlined,
            title: 'Supported countries',
            values: partner.supportedCountries,
            emptyText: 'Country availability is not published.',
          ),
          const SizedBox(height: 10),
          _ValueSection(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Account sizes',
            values: partner.accountSizes,
            emptyText: 'Account sizes are not published.',
          ),
          const SizedBox(height: 10),
          _ValueSection(
            icon: Icons.layers_outlined,
            title: 'Challenge types',
            values: partner.challengeTypes,
            emptyText: 'Challenge types are not published.',
          ),
          if (partner.disclosure != null) ...[
            const SizedBox(height: 14),
            FundedCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: fundedGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      partner.disclosure!,
                      style: const TextStyle(color: fundedMuted, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          FundedPrimaryButton(
            label: 'Choose Account Options',
            icon: Icons.arrow_forward_rounded,
            onPressed:
                partner.challengeTypes.isEmpty || partner.accountSizes.isEmpty
                ? null
                : () => _open(context, const FundedAccountOptionsScreen()),
          ),
        ],
      );
    },
  );
}

class _LinkGrid extends StatelessWidget {
  const _LinkGrid({required this.partner});

  final FundedPartner partner;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (partner.websiteUrl != null)
            _LinkTile(
              width: width,
              icon: Icons.language_rounded,
              label: 'Official Website',
              onTap: () => _launch(partner.websiteUrl!),
            ),
          if (partner.affiliateUrl != null)
            _LinkTile(
              width: width,
              icon: Icons.open_in_new_rounded,
              label: 'TradeX Partner Link',
              onTap: () => _launch(partner.affiliateUrl!),
            ),
          if (partner.promoCode != null)
            _LinkTile(
              width: width,
              icon: Icons.copy_rounded,
              label: partner.promoCode!,
              onTap: () {
                Clipboard.setData(ClipboardData(text: partner.promoCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Promo code copied.')),
                );
              },
            ),
        ],
      );
    },
  );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: FundedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fundedGold),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ValueSection extends StatelessWidget {
  const _ValueSection({
    required this.icon,
    required this.title,
    required this.values,
    required this.emptyText,
  });

  final IconData icon;
  final String title;
  final List<String> values;
  final String emptyText;

  @override
  Widget build(BuildContext context) => FundedCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: fundedGold),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (values.isEmpty)
          Text(emptyText, style: const TextStyle(color: fundedMuted))
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values.map((value) => FundedPill(label: value)).toList(),
          ),
      ],
    ),
  );
}

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
            subtitle: 'Select the program you want to review.',
            children: [
              _CompactPartnerHeader(partner: partner),
              const SizedBox(height: 20),
              const FundedSectionTitle(
                title: 'Challenge Type',
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
                        'Selected configuration',
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

Future<void> _open(BuildContext context, Widget page) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<FundedAdvisorCubit>(),
          child: page,
        ),
      ),
    );

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

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
