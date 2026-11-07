part of '../secure_workflow_screens.dart';

class PaymentProofScreen extends StatefulWidget {
  const PaymentProofScreen({
    super.key,
    required this.apiClient,
    this.initialOrderUuid,
    this.initialEvidenceType,
    this.preparedOrder = const <String, dynamic>{},
    this.legacySubmitEndpoint,
  });
  final ApiGateway apiClient;
  final String? initialOrderUuid;
  final String? initialEvidenceType;
  final Map<String, dynamic> preparedOrder;
  final String? legacySubmitEndpoint;

  @override
  State<PaymentProofScreen> createState() => _PaymentProofScreenState();
}

class _PaymentProofScreenState extends State<PaymentProofScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _order;
  final _name = TextEditingController();
  final _reference = TextEditingController();
  final _date = TextEditingController();
  final _hash = TextEditingController();
  final _amount = TextEditingController();
  final _sender = TextEditingController();
  late String _type;
  PickedImage? _file;
  bool _working = false;
  bool _submitted = false;
  String? _submissionStatus;

  @override
  void initState() {
    super.initState();
    _order = TextEditingController(text: widget.initialOrderUuid ?? '');
    _type = widget.initialEvidenceType ?? 'bank';
  }

  @override
  void dispose() {
    for (final controller in [
      _order,
      _name,
      _reference,
      _date,
      _hash,
      _amount,
      _sender,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Upload Payment Proof',
    subtitle: 'Secure manual verification',
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _WorkflowIntro(
            icon: Icons.receipt_long_outlined,
            title: 'Payment Evidence',
            message: 'Submit your transfer details and receipt for secure backend verification.',
          ),
          const SizedBox(height: 18),
          const _SecurityNotice(
            'Complete the transfer and submit proof before the backend expiry time. Proof submission never activates access by itself.',
          ),
          if (widget.preparedOrder.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ManualPaymentInstructions(order: widget.preparedOrder),
          ],
          if (_submitted) ...[
            const SizedBox(height: 14),
            _SecurityNotice(
              'Proof received${_submissionStatus == null ? '' : ' • $_submissionStatus'}. Verification is pending. If it is still pending after 30 minutes, contact TradeX support with this order UUID.',
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _working ? null : _checkManualPayment,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check payment status'),
            ),
            OutlinedButton.icon(
              onPressed: _working ? null : _contactSupport,
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Contact support'),
            ),
          ],
          const SizedBox(height: 14),
          const _WorkflowSectionTitle(
            icon: Icons.upload_file_rounded,
            title: 'Evidence details',
          ),
          if (widget.legacySubmitEndpoint == null)
            _input(
              _order,
              'Payment order UUID',
              readOnly: widget.initialOrderUuid != null,
            ),
          DropdownButtonFormField<String>(
            key: ValueKey(_type),
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Evidence type'),
            items: const [
              DropdownMenuItem(value: 'bank', child: Text('Bank deposit')),
              DropdownMenuItem(value: 'crypto', child: Text('Crypto transfer')),
              DropdownMenuItem(value: 'usdt', child: Text('USDT transfer')),
            ],
            onChanged: widget.initialEvidenceType == null
                ? (value) => setState(() => _type = value ?? 'bank')
                : null,
          ),
          const SizedBox(height: 12),
          if (_type == 'bank') ...[
            _input(_name, 'Depositor name'),
            _input(_reference, 'Bank reference'),
            _input(_date, 'Deposit date (YYYY-MM-DD)'),
          ] else ...[
            _input(_hash, 'Transaction hash'),
            _input(_amount, 'Amount'),
            _input(_sender, 'Sender address', required: false),
          ],
          _FileTile(
            label: _type == 'bank'
                ? 'Required proof image'
                : 'Optional proof image',
            file: _file,
            onPick: _pick,
            onRemove: () => setState(() => _file = null),
          ),
          FilledButton.icon(
            onPressed: _working || _submitted ? null : _submit,
            icon: _working ? const _Busy() : const Icon(Icons.upload_rounded),
            label: Text(_working ? 'Uploading…' : 'Submit evidence'),
          ),
        ],
      ),
    ),
  );

  Widget _input(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool readOnly = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required.';
        }
        if (controller == _hash &&
            value?.trim().isNotEmpty == true &&
            !RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(value!.trim())) {
          return 'Enter the 64-character transaction hash.';
        }
        if (controller == _amount &&
            value?.trim().isNotEmpty == true &&
            !RegExp(r'^\d{1,10}(?:\.\d{1,6})?$').hasMatch(value!.trim())) {
          return 'Enter a valid USDT amount (up to 6 decimals).';
        }
        return null;
      },
    ),
  );

  Future<void> _pick() async {
    final file = await SecureWorkflowPlatformRegistry.current.pickImage(
      camera: false,
      imageQuality: 88,
    );
    if (file != null && mounted) setState(() => _file = file);
  }

  Future<void> _submit() async {
    if (_key.currentState?.validate() != true) return;
    if (_type == 'bank' && _file == null) {
      _message('Bank payment proof is required.');
      return;
    }
    setState(() => _working = true);
    try {
      final order = _order.text.trim();
      final endpoint =
          widget.legacySubmitEndpoint ??
          switch (_type) {
            'bank' => '/api/v1/payments/manual-orders/$order/bank-evidence',
            'usdt' => '/api/v1/payments/manual-orders/$order/usdt-evidence',
            _ => '/api/v1/payments/manual-orders/$order/crypto-evidence',
          };
      final fields = _type == 'bank'
          ? {
              'depositor_name': _name.text.trim(),
              'bank_reference': _reference.text.trim(),
              'deposit_date': _date.text.trim(),
            }
          : {
              'tx_hash': _hash.text.trim(),
              'amount': _amount.text.trim(),
              if (_sender.text.trim().isNotEmpty)
                'sender_address': _sender.text.trim(),
            };
      final legacy = widget.legacySubmitEndpoint != null;
      final idempotencyKey = SecureWorkflowPlatformRegistry.current.newUuid();
      final response = legacy && _type != 'bank'
          ? await widget.apiClient.postJsonWithHeaders(endpoint, fields, {
              'Idempotency-Key': idempotencyKey,
            })
          : legacy
          ? await widget.apiClient.postMultipartWithHeaders(
              endpoint,
              fields,
              {if (_file != null) 'proof_file': _file!.path},
              {'Idempotency-Key': idempotencyKey},
            )
          : await widget.apiClient.postMultipart(endpoint, fields, {
              if (_file != null) 'proof_file': _file!.path,
            });
      final data = _asMap(response['data']);
      final submission = _asMap(data['manual_submission']);
      if (!mounted) return;
      setState(() {
        _submitted = true;
        if (legacy && data['uuid']?.toString().isNotEmpty == true) {
          _order.text = data['uuid'].toString();
        }
        _submissionStatus = submission['status']?.toString() ?? 'PENDING';
      });
      _message('Evidence submitted securely. Payment is pending review.');
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _checkManualPayment() async {
    final order = _order.text.trim();
    if (order.isEmpty) return;
    setState(() => _working = true);
    try {
      final results = await Future.wait([
        widget.apiClient.getJson('/api/v1/payments/orders/$order'),
        widget.apiClient.getJson('/api/v1/payments/activation-status'),
      ]);
      final orderData = _asMap(results[0]['data']);
      final activation = _asMap(results[1]['data']);
      final active = activation['premium_active'] == true;
      final submission = _asMap(orderData['manual_submission']);
      if (!mounted) return;
      setState(() {
        _submissionStatus = active
            ? 'ACTIVE'
            : submission['status']?.toString() ??
                  orderData['status']?.toString() ??
                  'PENDING';
      });
      if (active) {
        _message('Payment verified. Premium access is active.');
        Navigator.of(context).pop(true);
      } else {
        _message('Payment is still pending backend verification.');
      }
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _contactSupport() async {
    setState(() => _working = true);
    try {
      final response = await widget.apiClient.getJson('/api/v1/bootstrap');
      final settings = _asMap(_asMap(response['data'])['settings']);
      final whatsapp = settings['support_whatsapp']?.toString().trim() ?? '';
      final email = settings['support_email']?.toString().trim() ?? '';
      final order = _order.text.trim();
      final message =
          'My manual payment is still pending after 30 minutes. Payment order: $order';
      Uri? uri;
      if (whatsapp.isNotEmpty) {
        final number = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
        if (number.isNotEmpty) {
          uri = Uri.parse(
            'https://wa.me/$number?text=${Uri.encodeQueryComponent(message)}',
          );
        }
      }
      uri ??= email.isNotEmpty
          ? Uri(
              scheme: 'mailto',
              path: email,
              queryParameters: {
                'subject': 'Manual payment pending',
                'body': message,
              },
            )
          : null;
      if (uri == null ||
          !await SecureWorkflowPlatformRegistry.current.launchExternal(
            uri.toString(),
          )) {
        throw const UserFacingFailure(
          message: 'TradeX support contact is not configured right now.',
        );
      }
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ManualPaymentInstructions extends StatefulWidget {
  const _ManualPaymentInstructions({required this.order});

  final Map<String, dynamic> order;

  @override
  State<_ManualPaymentInstructions> createState() =>
      _ManualPaymentInstructionsState();
}

class _ManualPaymentInstructionsState
    extends State<_ManualPaymentInstructions> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manual = _map(widget.order['manual_payment']);
    final amount = _map(manual['amount']);
    final type = manual['type']?.toString().toUpperCase() ?? '';
    final expiresAt = DateTime.tryParse(
      widget.order['expires_at']?.toString() ?? '',
    )?.toLocal();
    final remaining = expiresAt?.difference(DateTime.now());
    final expired = remaining != null && remaining.isNegative;
    final fields = <(String, String)>[
      ('Amount', _money(amount)),
      ('Payment reference', manual['reference']?.toString() ?? ''),
      if (type == 'BANK') ...[
        ('Bank', manual['bank_name']?.toString() ?? ''),
        ('Branch', manual['branch']?.toString() ?? ''),
        ('Account holder', manual['account_holder']?.toString() ?? ''),
        ('Account number', manual['account_number']?.toString() ?? ''),
      ] else ...[
        ('Token', manual['coin_symbol']?.toString() ?? 'USDT'),
        ('Network', manual['network']?.toString() ?? 'TRC20'),
        ('Wallet address', manual['wallet_address']?.toString() ?? ''),
      ],
    ].where((field) => field.$2.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TradeXColors.gold.withValues(alpha: .55)),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: TradeXColors.goldBright,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type == 'BANK'
                        ? 'Bank transfer details'
                        : 'USDT TRC20 deposit details',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final field in fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 122,
                      child: Text(
                        field.$1,
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        field.$2,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            if (expiresAt != null) ...[
              const Divider(),
              Text(
                expired
                    ? 'This payment order has expired. Create a new order.'
                    : 'Order expires in ${_duration(remaining!)} (${_dateTime(expiresAt)})',
                style: TextStyle(
                  color: expired ? TradeXColors.error : TradeXColors.goldBright,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              type == 'BANK'
                  ? 'Complete the bank transfer and submit the receipt within 30 minutes for prompt verification.'
                  : 'Send only USDT using the TRC20 network. Then submit the exact amount and 64-character transaction hash within 30 minutes.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String _money(Map<String, dynamic> value) => [
    value['currency']?.toString() ?? '',
    value['amount']?.toString() ?? '',
  ].where((part) => part.isNotEmpty).join(' ');

  String _duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    return hours > 0
        ? '${hours}h ${minutes}m ${seconds}s'
        : '${minutes}m ${seconds}s';
  }

  String _dateTime(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
