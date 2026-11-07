part of '../affiliate_module.dart';

class AffiliatePayoutsScreen extends StatelessWidget {
  const AffiliatePayoutsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
    required this.onConfigureMethod,
  });
  final AffiliateRepository repository;
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigureMethod;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PayoutCubit(repository)..load(),
    child: _PayoutsBody(
      onUpgrade: onUpgrade,
      onConfigureMethod: onConfigureMethod,
    ),
  );
}

class _PayoutsBody extends StatelessWidget {
  const _PayoutsBody({
    required this.onUpgrade,
    required this.onConfigureMethod,
  });
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigureMethod;

  @override
  Widget build(BuildContext context) => BlocBuilder<PayoutCubit, PayoutState>(
    builder: (context, state) => AffiliateScaffold(
      title: 'Affiliate Payout',
      subtitle: 'Withdraw eligible earnings to your configured payout method.',
      onRefresh: context.read<PayoutCubit>().load,
      child: switch (state.status) {
        AffiliateLoadStatus.initial ||
        AffiliateLoadStatus.loading => const LoadingSkeleton(),
        AffiliateLoadStatus.premium => PremiumGate(
          message: state.message,
          onUpgrade: onUpgrade,
        ),
        AffiliateLoadStatus.failure => _ErrorCard(
          message: state.message ?? 'Payouts are unavailable.',
          onRetry: context.read<PayoutCubit>().load,
        ),
        AffiliateLoadStatus.ready || AffiliateLoadStatus.empty =>
          PayoutsContent(state: state, onConfigureMethod: onConfigureMethod),
      },
    ),
  );
}

class PayoutsContent extends StatelessWidget {
  const PayoutsContent({
    super.key,
    required this.state,
    required this.onConfigureMethod,
  });
  final PayoutState state;
  final ValueChanged<String> onConfigureMethod;

  String _eligibilityMessage(JsonMap summary, List<JsonMap> methods) {
    final kyc = AffiliateRepository.mapOf(summary['kyc']);
    if (AffiliateRepository.boolean(kyc['required']) &&
        !AffiliateRepository.boolean(kyc['satisfied'])) {
      return 'Complete KYC verification before requesting a withdrawal.';
    }
    if (!methods.any(
      (item) => AffiliateRepository.boolean(item['configured']),
    )) {
      return 'Configure at least one payout method in your profile.';
    }
    return 'Minimum withdrawal is ${AffiliateRepository.moneyText(summary['minimum_payout'])}.';
  }

  Future<void> _request(
    BuildContext context,
    JsonMap summary,
    List<JsonMap> methods,
  ) async {
    final configured = methods
        .where((item) => AffiliateRepository.boolean(item['configured']))
        .toList();
    if (configured.isEmpty) {
      _snack(context, _eligibilityMessage(summary, methods));
      return;
    }
    final amount = TextEditingController();
    String method = AffiliateRepository.text(configured.first['code'], '');
    final available = AffiliateRepository.money(summary['available']);
    final minimum = AffiliateRepository.money(summary['minimum_payout']);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TradeXColors.surfaceRaised,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Request Withdrawal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  items: [
                    for (final item in configured)
                      DropdownMenuItem(
                        value: AffiliateRepository.text(item['code'], ''),
                        child: Text(
                          _payoutMethodLabel(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setModalState(() => method = value ?? method),
                  decoration: const InputDecoration(labelText: 'Payout method'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    helperText:
                        'Available: ${AffiliateRepository.moneyText(summary['available'])}',
                    prefixText: r'$ ',
                    suffixIcon: TextButton(
                      onPressed: () =>
                          amount.text = available.toStringAsFixed(2),
                      child: const Text('MAX'),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GoldActionButton(
                  label: 'Submit Request',
                  onPressed: () {
                    final requested = double.tryParse(amount.text);
                    if (requested == null || requested <= 0) {
                      _snack(sheetContext, 'Enter a valid withdrawal amount.');
                      return;
                    }
                    if (requested < minimum) {
                      _snack(
                        sheetContext,
                        'Minimum withdrawal is ${AffiliateRepository.moneyText(summary['minimum_payout'])}.',
                      );
                      return;
                    }
                    if (requested > available) {
                      _snack(
                        sheetContext,
                        'Amount cannot exceed your available balance.',
                      );
                      return;
                    }
                    Navigator.pop(sheetContext, true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final requestedAmount = amount.text.trim();
    if (confirmed != true || !context.mounted) return;
    final selected = configured.firstWhere(
      (item) => AffiliateRepository.text(item['code'], '') == method,
    );
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm withdrawal'),
        content: Text(
          'Withdraw \$$requestedAmount to ${_payoutMethodLabel(selected)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    final error = await context.read<PayoutCubit>().submit(
      method,
      requestedAmount,
    );
    if (!context.mounted) return;
    _snack(context, error ?? 'Withdrawal request submitted.');
  }

  @override
  Widget build(BuildContext context) {
    final summary = AffiliateRepository.mapOf(state.data['summary']);
    final methodsData = AffiliateRepository.mapOf(state.data['methods']);
    final methods = AffiliateRepository.listOf(methodsData['items']);
    final historyData = AffiliateRepository.mapOf(state.data['history']);
    final history = AffiliateRepository.listOf(historyData['items']);
    final canRequest = AffiliateRepository.boolean(
      summary['can_request_payout'],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Payout Overview',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SectionCard(
          borderColor: TradeXColors.gold,
          child: Row(
            children: [
              const _AffiliateArt(
                path: _AffiliateAssets.wallet,
                fallback: Icons.account_balance_wallet_rounded,
                size: 62,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AffiliateRepository.moneyText(summary['available']),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              GoldActionButton(
                label: state.submitting ? 'Sending...' : 'Withdraw',
                onPressed: state.submitting
                    ? null
                    : () => _request(context, summary, methods),
                compact: true,
              ),
            ],
          ),
        ),
        if (!canRequest) ...[
          const SizedBox(height: 8),
          Text(
            _eligibilityMessage(summary, methods),
            style: const TextStyle(color: TradeXColors.warning, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PayoutMetric(
                'Total Earned',
                summary['net_earned'],
                Icons.monetization_on_outlined,
                assetPath: _AffiliateAssets.money,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PayoutMetric(
                'Paid',
                summary['paid'],
                Icons.north_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PayoutMetric(
                'Locked',
                summary['locked'],
                Icons.lock_clock_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: _SectionHeading(title: 'Withdrawal Methods')),
            TextButton.icon(
              onPressed: methods.isEmpty
                  ? null
                  : () => onConfigureMethod(
                      AffiliateRepository.text(methods.first['code'], ''),
                    ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set up'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (methods.isEmpty)
          const _EmptyCard(
            message: 'No payout methods are available for your country.',
          )
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < methods.length; index++) ...[
                  PayoutMethodTile(
                    data: methods[index],
                    onTap: () => onConfigureMethod(
                      AffiliateRepository.text(methods[index]['code'], ''),
                    ),
                  ),
                  if (index != methods.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
        const SizedBox(height: 22),
        const _SectionHeading(title: 'Recent Payouts'),
        const SizedBox(height: 8),
        if (history.isEmpty)
          const _EmptyCard(message: 'No withdrawal requests yet.')
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < history.length; index++) ...[
                  PayoutHistoryTile(data: history[index]),
                  if (index != history.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

String _payoutMethodLabel(JsonMap method) {
  final code = AffiliateRepository.text(method['code'], '');
  final destination = AffiliateRepository.mapOf(method['destination']);
  final account = AffiliateRepository.text(
    destination['label'] ??
        destination['account_number'] ??
        destination['bank_name'],
    '',
  );
  return account.isEmpty
      ? _methodName(code)
      : '${_methodName(code)} • $account';
}

class _PayoutMetric extends StatelessWidget {
  const _PayoutMetric(this.label, this.value, this.icon, {this.assetPath});
  final String label;
  final Object? value;
  final IconData icon;
  final String? assetPath;
  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assetPath == null)
          _GoldIcon(icon)
        else
          _AffiliateArt(path: assetPath!, fallback: icon, size: 42),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          AffiliateRepository.moneyText(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class PayoutMethodTile extends StatelessWidget {
  const PayoutMethodTile({super.key, required this.data, required this.onTap});
  final JsonMap data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final code = AffiliateRepository.text(data['code'], '');
    final configured = AffiliateRepository.boolean(data['configured']);
    final destination = AffiliateRepository.mapOf(data['destination']);
    final label = AffiliateRepository.text(
      destination['label'] ?? destination['account_number'],
      configured ? 'Configured' : 'Not configured',
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _PaymentMethodIcon(code: code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _methodName(code),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: configured ? 'Configured' : 'Set up',
              color: configured ? TradeXColors.success : TradeXColors.warning,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }
}

class PayoutHistoryTile extends StatelessWidget {
  const PayoutHistoryTile({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final status = AffiliateRepository.text(data['status']);
    final color = switch (status) {
      'PAID' => TradeXColors.success,
      'REJECTED' || 'FAILED' || 'CANCELLED' => TradeXColors.error,
      _ => TradeXColors.warning,
    };
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _GoldIcon(
            status == 'PAID' ? Icons.check_rounded : Icons.north_east_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_methodName(AffiliateRepository.text(data['method'], ''))} withdrawal',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  _date(data['requested_at']),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AffiliateRepository.moneyText(data['amount']),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(status, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
