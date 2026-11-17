part of '../investment_module.dart';

class InvestmentApplyScreen extends StatefulWidget {
  const InvestmentApplyScreen({
    super.key,
    required this.repository,
    required this.onboarding,
  });

  final InvestmentRepository repository;
  final InvestmentOnboarding onboarding;

  @override
  State<InvestmentApplyScreen> createState() => _InvestmentApplyScreenState();
}

class _InvestmentApplyScreenState extends State<InvestmentApplyScreen> {
  final _amount = TextEditingController();
  final _txid = TextEditingController();
  int? _period;
  int? _review;
  bool _riskAccepted = false;
  bool _agreementAccepted = false;
  bool _busy = false;
  CustomerInvestment? _application;

  @override
  void initState() {
    super.initState();
    _period = widget.onboarding.periodYears.firstOrNull;
    _review = widget.onboarding.reviewIntervalsMonths.firstOrNull;
  }

  @override
  void dispose() {
    _amount.dispose();
    _txid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InvestmentScaffold(
    title: 'Invest with TradeX',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (!widget.onboarding.kycVerified)
          _InvestmentCard(
            emphasized: true,
            child: Column(
              children: [
                const Icon(Icons.verified_user_outlined, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Complete KYC before investing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current status: ${widget.onboarding.kycStatus}. Complete and verify KYC from Profile before opening an investment.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_application == null)
          _applicationForm()
        else
          _depositForm(_application!),
      ],
    ),
  );

  Widget _applicationForm() => Column(
    children: [
      _InvestmentCard(
        emphasized: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'USDT TRC20 Investment',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${_money(widget.onboarding.minimumAmount, 'USDT')} minimum · ${_money(widget.onboarding.maximumAmount, 'USDT')} maximum',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Investment amount (USDT)',
                prefixIcon: Icon(Icons.currency_exchange_rounded),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _period,
              decoration: const InputDecoration(labelText: 'Investment period'),
              items: [
                for (final value in widget.onboarding.periodYears)
                  DropdownMenuItem(
                    value: value,
                    child: Text('$value year${value == 1 ? '' : 's'}'),
                  ),
              ],
              onChanged: (value) => setState(() => _period = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _review,
              decoration: const InputDecoration(
                labelText: 'Profit review interval',
              ),
              items: [
                for (final value in widget.onboarding.reviewIntervalsMonths)
                  DropdownMenuItem(
                    value: value,
                    child: Text('Every $value months'),
                  ),
              ],
              onChanged: (value) => setState(() => _review = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _InvestmentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk disclosure',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final statement in widget.onboarding.riskStatements)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $statement'),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _riskAccepted,
              onChanged: (value) =>
                  setState(() => _riskAccepted = value == true),
              title: const Text(
                'I understand and accept the investment risks.',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agreementAccepted,
              onChanged: (value) =>
                  setState(() => _agreementAccepted = value == true),
              title: const Text(
                'I accept the investment agreement and selected period.',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _busy ? null : _create,
        icon: _busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_rounded),
        label: const Text('Accept & Continue'),
      ),
    ],
  );

  Widget _depositForm(CustomerInvestment application) => Column(
    children: [
      _InvestmentCard(
        emphasized: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send USDT using TRC20 only',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Exact amount: ${_money(application.amount, 'USDT')}'),
            Text('Period: ${application.periodLabel ?? '—'}'),
            const SizedBox(height: 12),
            SelectableText(
              widget.onboarding.depositAddress ?? 'Deposit address unavailable',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: widget.onboarding.depositAddress == null
                  ? null
                  : () {
                      Clipboard.setData(
                        ClipboardData(text: widget.onboarding.depositAddress!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TRC20 address copied.')),
                      );
                    },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy address'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _txid,
        maxLength: 64,
        decoration: const InputDecoration(
          labelText: '64-character TRC20 transaction ID',
        ),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _busy ? null : _submitDeposit,
        icon: const Icon(Icons.verified_rounded),
        label: const Text('Submit deposit for verification'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _downloadAgreement,
        icon: const Icon(Icons.download_rounded),
        label: const Text('Download accepted agreement'),
      ),
    ],
  );

  Future<void> _create() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null ||
        amount < widget.onboarding.minimumAmount ||
        amount > widget.onboarding.maximumAmount ||
        _period == null ||
        _review == null ||
        !_riskAccepted ||
        !_agreementAccepted) {
      _message(
        'Enter an amount within the allowed range and accept both confirmations.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final application = await widget.repository.createApplication(
        amount: amount,
        periodYears: _period!,
        reviewIntervalMonths: _review!,
      );
      if (mounted) setState(() => _application = application);
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitDeposit() async {
    final txid = _txid.text.trim();
    if (!RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(txid)) {
      _message('Enter a valid 64-character TRC20 transaction ID.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.submitDeposit(
        investmentId: _application!.id,
        transactionId: txid,
      );
      _message('Deposit submitted. Verification is now pending.');
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadAgreement() async {
    try {
      final bytes = await widget.repository.downloadAgreement(_application!.id);
      await AppPlatformRegistry.current.shareFile(
        bytes: bytes,
        fileName: '${_application!.code}-agreement.html',
        mimeType: 'text/html',
        text: 'TradeX investment agreement',
      );
    } catch (error) {
      _message(error.toString());
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
