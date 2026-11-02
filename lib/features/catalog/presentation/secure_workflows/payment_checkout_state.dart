part of '../secure_workflow_screens.dart';

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen>
    with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _catalog;
  String? _provider;
  String? _receivingAccount;
  bool _confirmed = false;
  bool _working = false;
  String? _orderUuid;
  String? _checkoutStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _catalog = _loadCatalog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _orderUuid != null) {
      _verifyCheckoutStatus();
    }
  }

  Future<Map<String, dynamic>> _loadCatalog() async {
    final methodsResponse = await widget.apiClient.getJson(
      '/api/v1/payments/methods',
    );
    final methodsData = _map(methodsResponse['data']);
    final methods = _listOfMaps(methodsData['methods'])
        .where((method) => method['available'] == true)
        .toList();
    var accounts = <Map<String, dynamic>>[];
    try {
      final accountsResponse = await widget.apiClient.getJson(
        '/api/v1/payments/manual-accounts',
      );
      accounts = _listOfMaps(_map(accountsResponse['data'])['accounts']);
      _addMissingManualMethods(methods, accounts);
    } on UserFacingException {
      // Online redirect methods remain usable if no manual account is enabled.
    }
    _provider ??= methods.isEmpty ? null : methods.first['code']?.toString();
    return <String, dynamic>{
      'product': _map(methodsData['product']),
      'purchase_allowed': methodsData['purchase_allowed'] == true,
      'methods': methods,
      'accounts': accounts,
    };
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Payment Checkout',
    child: BlocFutureBuilder<Map<String, dynamic>>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: _Busy());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _catalog = _loadCatalog();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data ?? const <String, dynamic>{};
        final product = _map(data['product']);
        final methods = _listOfMaps(data['methods']);
        Map<String, dynamic>? method;
        for (final candidate in methods) {
          if (candidate['code']?.toString() == _provider) method = candidate;
        }
        method ??= methods.isEmpty ? null : methods.first;
        final manual = method != null && _isManualMethod(method);
        final accounts = manual
            ? _matchingAccounts(_listOfMaps(data['accounts']), _provider ?? '')
            : const <Map<String, dynamic>>[];
        if (accounts.isNotEmpty &&
            !accounts.any((item) => item['uuid'] == _receivingAccount)) {
          _receivingAccount = accounts.first['uuid']?.toString();
        }
        final legacyManual =
            manual && accounts.isEmpty && _legacySubmitPath(method).isNotEmpty;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SecurityNotice(
              'Only payment methods currently enabled by TradeX are shown. Access activates only after authoritative backend confirmation.',
            ),
            const SizedBox(height: 14),
            if (product.isNotEmpty)
              _SecurityNotice(
                '${product['name'] ?? 'TradeX membership'} • ${_money(product['base_price'])}',
              ),
            const SizedBox(height: 14),
            if (methods.isEmpty)
              const _SecurityNotice(
                'No payment method is currently available for this account or country.',
              )
            else ...[
              DropdownButtonFormField<String>(
                key: ValueKey(_provider),
                initialValue: _provider,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Available payment method',
                ),
                items: methods
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['code']?.toString(),
                        child: Text(
                          '${item['display_name'] ?? item['code']} • ${_money(item['amount'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _provider = value;
                  _receivingAccount = null;
                  _confirmed = false;
                }),
              ),
              const SizedBox(height: 12),
              if (manual)
                if (accounts.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: ValueKey(_receivingAccount),
                    initialValue: _receivingAccount,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Receiving account',
                    ),
                    items: accounts
                        .map(
                          (account) => DropdownMenuItem<String>(
                            value: account['uuid']?.toString(),
                            child: Text(
                              '${account['display_name'] ?? account['type']} • ${_money(account['tender'])}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _receivingAccount = value),
                  ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                title: const Text(
                  'I reviewed the product, payment method and amount.',
                ),
                onChanged: (value) =>
                    setState(() => _confirmed = value == true),
              ),
              FilledButton.icon(
                onPressed:
                    !_confirmed ||
                        _working ||
                        method == null ||
                        (manual && !legacyManual && _receivingAccount == null)
                    ? null
                    : () => _startCheckout(method!),
                icon: _working
                    ? const _Busy()
                    : Icon(
                        manual
                            ? Icons.receipt_long_rounded
                            : Icons.open_in_new_rounded,
                      ),
                label: Text(
                  _working
                      ? 'Preparing…'
                      : manual
                      ? legacyManual
                            ? 'Continue with manual payment'
                            : 'Prepare payment order'
                      : 'Continue to provider',
                ),
              ),
              if (_orderUuid != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _working ? null : _verifyCheckoutStatus,
                  icon: const Icon(Icons.verified_rounded),
                  label: Text(
                    _checkoutStatus == null
                        ? 'Check verified payment status'
                        : 'Backend status: $_checkoutStatus',
                  ),
                ),
              ],
            ],
          ],
        );
      },
    ),
  );

  Future<void> _startCheckout(Map<String, dynamic> method) async {
    setState(() => _working = true);
    try {
      final code = (method['code']?.toString() ?? '').toLowerCase();
      if (_isManualMethod(method)) {
        final legacyEndpoint = _legacySubmitPath(method);
        if (_receivingAccount == null && legacyEndpoint.isNotEmpty) {
          final type = code.contains('bank') ? 'bank' : 'usdt';
          if (!mounted) return;
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => PaymentProofScreen(
                apiClient: widget.apiClient,
                initialEvidenceType: type,
                preparedOrder: _legacyInstructions(method, type),
                legacySubmitEndpoint: legacyEndpoint,
              ),
            ),
          );
          return;
        }
        final response = await widget.apiClient.postJsonWithHeaders(
          '/api/v1/payments/manual-orders',
          {'receiving_account_uuid': _receivingAccount},
          {'Idempotency-Key': SecureWorkflowPlatformRegistry.current.newUuid()},
        );
        final order = _map(response['data']);
        final uuid = order['uuid']?.toString();
        if (uuid == null || uuid.isEmpty) {
          throw const UserFacingFailure(
            message: 'TradeX did not return a prepared payment order.',
          );
        }
        final provider = order['provider']?.toString().toLowerCase() ?? code;
        final type = provider.contains('bank')
            ? 'bank'
            : provider.contains('usdt')
            ? 'usdt'
            : 'crypto';
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PaymentProofScreen(
              apiClient: widget.apiClient,
              initialOrderUuid: uuid,
              initialEvidenceType: type,
              preparedOrder: order,
            ),
          ),
        );
        return;
      }
      final endpoint = switch (code) {
        'stripe' => '/api/v1/payments/stripe/checkout-sessions',
        'nowpayments' => '/api/v1/payments/nowpayments/invoices',
        'paypal' => '/api/v1/payments/paypal/orders',
        _ => throw const UserFacingFailure(
          message: 'This payment method is not supported by the app.',
        ),
      };
      final response = await widget.apiClient.postJsonWithHeaders(
        endpoint,
        {
          if (code == 'paypal' && widget.productUuid?.isNotEmpty == true)
            'product_uuid': widget.productUuid,
        },
        {'Idempotency-Key': SecureWorkflowPlatformRegistry.current.newUuid()},
      );
      final order = _map(response['data']);
      _orderUuid =
          order['payment_order_uuid']?.toString() ?? order['uuid']?.toString();
      final action = _deepMap(response, 'approval_url');
      final url = action?['approval_url']?.toString();
      if (url == null ||
          !await SecureWorkflowPlatformRegistry.current.launchExternal(url)) {
        throw const UserFacingFailure(
          message: 'The payment provider could not be opened.',
        );
      }
      _message(
        'Checkout opened. Return to Payment History for verified status.',
      );
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _verifyCheckoutStatus() async {
    if (_orderUuid == null || _working) return;
    setState(() => _working = true);
    try {
      final results = await Future.wait([
        widget.apiClient.getJson('/api/v1/payments/orders/$_orderUuid'),
        widget.apiClient.getJson('/api/v1/payments/activation-status'),
      ]);
      final order = _map(results[0]['data']);
      final activation = _map(results[1]['data']);
      final active = activation['premium_active'] == true;
      if (!mounted) return;
      setState(() {
        _checkoutStatus = active
            ? 'ACTIVE'
            : order['status']?.toString() ?? 'PENDING';
      });
      if (active) {
        _message('Payment confirmed by TradeX. Premium access is active.');
        Navigator.of(context).pop(true);
      } else {
        _message(
          'Payment is not active yet. TradeX will unlock access only after server confirmation.',
        );
      }
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  List<Map<String, dynamic>> _matchingAccounts(
    List<Map<String, dynamic>> accounts,
    String provider,
  ) {
    final code = provider.toLowerCase();
    return accounts.where((account) {
      final type = account['type']?.toString().toLowerCase() ?? '';
      final coin = account['coin']?.toString().toLowerCase() ?? '';
      if (code.contains('bank')) return type.contains('bank');
      if (code.contains('usdt')) {
        return type.contains('crypto') && coin == 'usdt';
      }
      return type.contains('crypto');
    }).toList();
  }

  void _addMissingManualMethods(
    List<Map<String, dynamic>> methods,
    List<Map<String, dynamic>> accounts,
  ) {
    final existingCodes = methods
        .map((method) => method['code']?.toString().toLowerCase() ?? '')
        .toSet();
    var hasBankMethod = existingCodes.any((code) => code.contains('bank'));
    var hasUsdtMethod = existingCodes.any((code) => code.contains('usdt'));

    void addMethod({
      required String code,
      required String displayName,
      required Map<String, dynamic> account,
    }) {
      if (existingCodes.contains(code) ||
          (code.contains('bank') && hasBankMethod) ||
          (code.contains('usdt') && hasUsdtMethod)) {
        return;
      }
      methods.add({
        'code': code,
        'display_name': displayName,
        'mode': 'MANUAL_REVIEW',
        'available': true,
        'amount': account['tender'],
      });
      existingCodes.add(code);
      if (code.contains('bank')) hasBankMethod = true;
      if (code.contains('usdt')) hasUsdtMethod = true;
    }

    for (final account in accounts) {
      final type = account['type']?.toString().toLowerCase() ?? '';
      final coin = account['coin']?.toString().toLowerCase() ?? '';
      if (type.contains('bank')) {
        addMethod(
          code: 'local_bank',
          displayName: 'Local bank deposit',
          account: account,
        );
      } else if (type.contains('crypto') && coin == 'usdt') {
        addMethod(
          code: 'usdt_manual',
          displayName: 'USDT manual deposit',
          account: account,
        );
      }
    }
  }

  bool _isManualMethod(Map<String, dynamic> method) =>
      method['mode']?.toString().toUpperCase() == 'MANUAL_REVIEW';

  String _legacySubmitPath(Map<String, dynamic> method) {
    final value = method['submit_endpoint']?.toString().trim() ?? '';
    final match = RegExp(
      r'^(?:POST\s+)?(/api/\S+)$',
      caseSensitive: false,
    ).firstMatch(value);
    return match?.group(1) ?? '';
  }

  Map<String, dynamic> _legacyInstructions(
    Map<String, dynamic> method,
    String type,
  ) {
    final instructions = _map(method['instructions']);
    return {
      'manual_payment': {
        'type': type == 'bank' ? 'BANK' : 'CRYPTO',
        'amount': _map(method['amount']),
        ...instructions,
        if (type == 'usdt')
          'coin_symbol': instructions['token']?.toString() ?? 'USDT',
      },
    };
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _listOfMaps(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];

  String _money(Object? value) {
    final money = _map(value);
    return (money['formatted'] ??
            money['display'] ??
            '${money['currency'] ?? ''} ${money['amount'] ?? ''}')
        .toString()
        .trim();
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
