part of '../copy_trading_module.dart';

class CopyTradingVerificationScreen extends StatefulWidget {
  const CopyTradingVerificationScreen({
    super.key,
    required this.useCases,
    this.broker,
    this.account,
  });

  final CopyTradingUseCases useCases;
  final CopyTradingBrokerMarket? broker;
  final CopyTradingAccount? account;

  @override
  State<CopyTradingVerificationScreen> createState() =>
      _CopyTradingVerificationScreenState();
}

class _CopyTradingVerificationScreenState
    extends State<CopyTradingVerificationScreen> {
  final _key = GlobalKey<FormState>();
  final _accountNumber = TextEditingController();
  CopyTradingAccount? _account;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  @override
  void dispose() {
    _accountNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_key.currentState?.validate() != true || _working) return;
    setState(() => _working = true);
    try {
      final existing = _account;
      final result = existing != null
          ? await widget.useCases.resubmitBrokerAccount(
              ResubmitCopyTradingAccountParams(
                accountId: existing.uuid,
                accountNumber: _accountNumber.text.trim(),
              ),
            )
          : await widget.useCases.submitBrokerAccount(
              SubmitCopyTradingAccountParams(
                marketId: widget.broker!.brokerMarketUuid,
                accountNumber: _accountNumber.text.trim(),
              ),
            );
      if (!mounted) return;
      setState(() => _account = result);
      _message('Account submitted for TradeX IB verification.');
    } catch (error) {
      _message(_error(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    final broker = account == null ? widget.broker! : account.broker;
    final brokerName = broker.brokerName;
    final market = account == null
        ? broker.marketCategory
        : account.marketCategory;
    final currency = account?.verifiedCurrency ?? broker.requiredCurrency;
    final status = account == null
        ? 'ACCOUNT DETAILS'
        : copyAccountStatus(account);
    final canSubmit = account == null || status == 'NEEDS_RESUBMISSION';

    return CopyTradingScrollPage(
      children: [
        const CopyPageHeading(
          title: 'Account',
          goldTitle: 'Verification',
          subtitle: 'Verify and activate your broker account using the secure workflow.',
          icon: Icons.verified_user_outlined,
        ),
        const SizedBox(height: 18),
        CopySectionCard(
          highlight: true,
          child: Row(
            children: [
              CopyBrokerLogo(
                useCases: widget.useCases,
                name: brokerName,
                logoUrl: broker.logoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brokerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$market · cTrader only',
                      style: const TextStyle(color: copyMuted),
                    ),
                  ],
                ),
              ),
              CopyStatusPill(status: status),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _VerificationSteps(status: status),
        const SizedBox(height: 12),
        if (account != null) ...[
          _SubmittedAccountDetails(account: account, currency: currency),
          const SizedBox(height: 12),
        ],
        if (canSubmit)
          CopySectionCard(
            highlight: true,
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CopySectionHeading(
                    title: 'Account Details',
                    subtitle: 'Never enter a password, OTP or API secret.',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _accountNumber,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 15,
                    decoration: const InputDecoration(
                      labelText: 'Broker account number',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Broker account number is required.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _ReadOnlyField(
                    icon: Icons.layers_outlined,
                    label: 'Account Type',
                    value: 'LIVE',
                  ),
                  const SizedBox(height: 10),
                  _ReadOnlyField(
                    icon: Icons.paid_outlined,
                    label: 'Required Currency',
                    value: currency,
                  ),
                  const SizedBox(height: 14),
                  CopyPrimaryButton(
                    label: account == null
                        ? 'Submit for Verification'
                        : 'Resubmit Corrected Account',
                    onPressed: _submit,
                    busy: _working,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
          )
        else
          CopyEmptyState(
            icon: status == 'ACTIVE'
                ? Icons.verified_rounded
                : Icons.hourglass_top_rounded,
            title: status.replaceAll('_', ' '),
            message: account.statusReason ?? 'TradeX is keeping verification and activation as separate security checks.',
          ),
        const SizedBox(height: 12),
        _VerificationTimeline(status: status),
      ],
    );
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}

class _SubmittedAccountDetails extends StatelessWidget {
  const _SubmittedAccountDetails({
    required this.account,
    required this.currency,
  });

  final CopyTradingAccount account;
  final String currency;

  @override
  Widget build(BuildContext context) => CopySectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CopySectionHeading(
          title: 'Submitted Account Details',
          subtitle: 'Sensitive account information remains protected.',
        ),
        const SizedBox(height: 14),
        _ReadOnlyField(
          icon: Icons.person_outline_rounded,
          label: 'Account Number',
          value: account.accountNumberMasked,
        ),
        const SizedBox(height: 10),
        _ReadOnlyField(
          icon: Icons.layers_outlined,
          label: 'Market',
          value: account.marketCategory,
        ),
        const SizedBox(height: 10),
        _ReadOnlyField(
          icon: Icons.paid_outlined,
          label: 'Verified Currency',
          value: currency,
        ),
      ],
    ),
  );
}
