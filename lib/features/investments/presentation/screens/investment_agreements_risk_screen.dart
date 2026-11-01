part of '../investment_module.dart';

class InvestmentAgreementsRiskScreen extends StatelessWidget {
  const InvestmentAgreementsRiskScreen({
    super.key,
    required this.repository,
    this.investmentId,
  });

  final InvestmentRepository repository;
  final String? investmentId;

  Future<InvestmentDashboard> _load() => investmentId == null
      ? repository.loadDashboard()
      : repository.loadInvestment(investmentId!);

  @override
  Widget build(BuildContext context) => _InvestmentScaffold(
    title: 'Agreements & Risk',
    child: FutureBuilder<InvestmentDashboard>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _InvestmentLoading();
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InvestmentUnavailable(message: _investmentError(snapshot.error)),
              const SizedBox(height: 16),
              const _RiskDisclosureList(),
            ],
          );
        }
        final agreement = snapshot.data?.agreement;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _InvestmentSectionTitle('Risk Acceptance'),
            const SizedBox(height: 10),
            _InvestmentCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: TradeXColors.goldBright,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Risk acceptance',
                          style: TextStyle(
                            color: _investmentText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _InvestmentStatusBadge(
                        agreement?.riskAccepted == true
                            ? 'Accepted'
                            : 'Pending',
                      ),
                    ],
                  ),
                  _InvestmentKeyValue(
                    label: 'Disclosure version',
                    value: agreement?.disclosureVersion ?? '—',
                  ),
                  _InvestmentKeyValue(
                    label: 'Accepted on',
                    value: _date(agreement?.riskAcceptedAt),
                  ),
                  const _InvestmentKeyValue(
                    label: 'Confirmation record',
                    value: 'Read-only',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Investment Agreement'),
            const SizedBox(height: 10),
            _InvestmentCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: TradeXColors.goldBright,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Investment agreement',
                          style: TextStyle(
                            color: _investmentText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (agreement?.status != null)
                        _InvestmentStatusBadge(
                          _recordStatusLabel(agreement!.status!),
                        ),
                    ],
                  ),
                  _InvestmentKeyValue(
                    label: 'Agreement version',
                    value: agreement?.agreementVersion ?? '—',
                  ),
                  _InvestmentKeyValue(
                    label: 'Last verified',
                    value: _date(agreement?.verifiedAt),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: agreement?.authorizedViewPath == null
                              ? null
                              : () => _documentUnavailable(context),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('View Agreement'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: agreement?.authorizedDownloadPath == null
                              ? null
                              : () => _documentUnavailable(context),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Document Verification Timeline'),
            const SizedBox(height: 10),
            _InvestmentCard(
              child: Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  _DocumentStep(
                    label: 'Generated',
                    complete: agreement?.generatedAt != null,
                  ),
                  _DocumentStep(
                    label: 'Signed',
                    complete: agreement?.signedAt != null,
                  ),
                  _DocumentStep(
                    label: 'Verified',
                    complete: agreement?.verifiedAt != null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _InvestmentSectionTitle('Investment Risk Disclosures'),
            const SizedBox(height: 10),
            const _RiskDisclosureList(),
            const SizedBox(height: 14),
            const _InvestmentRiskNotice(
              'Investment products involve financial risk. Review all terms and disclosures before making any decision.',
            ),
          ],
        );
      },
    ),
  );

  void _documentUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Secure agreement delivery is not available in the mobile API yet.',
        ),
      ),
    );
  }
}

class _DocumentStep extends StatelessWidget {
  const _DocumentStep({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        complete ? Icons.check_rounded : Icons.schedule_rounded,
        color: complete ? _investmentGreen : _investmentMuted,
        size: 18,
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: complete ? _investmentGreen : _investmentMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _RiskDisclosureList extends StatelessWidget {
  const _RiskDisclosureList();

  static const _risks = <(String, String)>[
    (
      'Crypto volatility',
      'Cryptoasset prices and liquidity may change significantly and may cause loss of capital.',
    ),
    (
      'Partial or total capital loss',
      'Investment capital can decrease and partial or total capital loss is possible.',
    ),
    (
      'Stablecoin and network risks',
      'Stablecoins, custodians and blockchain networks can fail, delay or restrict transfers.',
    ),
    (
      'Regulatory risks',
      'Regulatory or legal changes may restrict investment activity or asset transfers.',
    ),
    (
      'No guaranteed returns',
      'Profits and returns are not guaranteed. Past performance is not predictive.',
    ),
    (
      'Early-termination conditions',
      'Early termination is subject to the verified investment agreement and applicable conditions.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final risk in _risks) ...[
        _InvestmentCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            iconColor: TradeXColors.goldBright,
            collapsedIconColor: TradeXColors.goldBright,
            leading: const Icon(
              Icons.error_outline_rounded,
              color: TradeXColors.goldBright,
            ),
            title: Text(
              risk.$1,
              style: const TextStyle(
                color: _investmentText,
                fontWeight: FontWeight.w800,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  risk.$2,
                  style: const TextStyle(color: _investmentMuted, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}
