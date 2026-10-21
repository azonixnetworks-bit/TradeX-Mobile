import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';

class KycSubmissionScreen extends StatefulWidget {
  const KycSubmissionScreen({super.key, required this.apiClient});
  final TradeXApiClient apiClient;

  @override
  State<KycSubmissionScreen> createState() => _KycSubmissionScreenState();
}

class _KycSubmissionScreenState extends State<KycSubmissionScreen> {
  final _key = GlobalKey<FormState>();
  final _documentType = TextEditingController();
  final _legalName = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _identityNumber = TextEditingController();
  final _address = TextEditingController();
  final _files = <String, XFile>{};
  bool _working = false;

  @override
  void dispose() {
    for (final controller in [
      _documentType,
      _legalName,
      _dateOfBirth,
      _identityNumber,
      _address,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'KYC Document Submission',
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SecurityNotice(
            'Your country and document requirements are validated by TradeX. Images are uploaded only when you submit.',
          ),
          const SizedBox(height: 14),
          _field(_documentType, 'Document type code'),
          _field(_legalName, 'Legal name'),
          _field(_dateOfBirth, 'Date of birth (YYYY-MM-DD)'),
          _field(_identityNumber, 'Identity number'),
          _field(_address, 'Residential address', lines: 3),
          for (final item in const [
            ('identity_front', 'Identity document front'),
            ('identity_back', 'Identity document back'),
            ('selfie', 'Selfie'),
          ])
            _FileTile(
              label: item.$2,
              file: _files[item.$1],
              onPick: () => _pick(item.$1, item.$1 == 'selfie'),
              onRemove: () => setState(() => _files.remove(item.$1)),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _working ? null : _submit,
            icon: _working
                ? const _Busy()
                : const Icon(Icons.verified_user_rounded),
            label: Text(_working ? 'Uploading…' : 'Submit for verification'),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );

  Future<void> _pick(String key, bool selfie) async {
    final file = await ImagePicker().pickImage(
      source: selfie ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file != null && mounted) setState(() => _files[key] = file);
  }

  Future<void> _submit() async {
    if (_key.currentState?.validate() != true) return;
    if (_files.isEmpty) {
      _message('Select the documents required for your account country.');
      return;
    }
    setState(() => _working = true);
    try {
      await widget.apiClient.postMultipart(
        '/api/v1/kyc/submissions',
        {
          'document_type': _documentType.text.trim(),
          'legal_name': _legalName.text.trim(),
          'date_of_birth': _dateOfBirth.text.trim(),
          'identity_number': _identityNumber.text.trim(),
          'address': _address.text.trim(),
        },
        {for (final entry in _files.entries) entry.key: entry.value.path},
      );
      _message('KYC submission received for review.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class PaymentProofScreen extends StatefulWidget {
  const PaymentProofScreen({
    super.key,
    required this.apiClient,
    this.initialOrderUuid,
    this.initialEvidenceType,
    this.preparedOrder = const <String, dynamic>{},
  });
  final TradeXApiClient apiClient;
  final String? initialOrderUuid;
  final String? initialEvidenceType;
  final Map<String, dynamic> preparedOrder;

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
  XFile? _file;
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
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
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
      final endpoint = switch (_type) {
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
      final response = await widget.apiClient.postMultipart(endpoint, fields, {
        if (_file != null) 'proof_file': _file!.path,
      });
      final data = _asMap(response['data']);
      final submission = _asMap(data['manual_submission']);
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submissionStatus = submission['status']?.toString() ?? 'PENDING';
      });
      _message('Evidence submitted securely. Payment is pending review.');
    } on ApiException catch (error) {
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
    } on ApiException catch (error) {
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
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const ApiException(
          message: 'TradeX support contact is not configured right now.',
        );
      }
    } on ApiException catch (error) {
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

class ContactChangeScreen extends StatefulWidget {
  const ContactChangeScreen({
    super.key,
    required this.apiClient,
    this.initialChannel = 'whatsapp',
  });
  final TradeXApiClient apiClient;
  final String initialChannel;

  @override
  State<ContactChangeScreen> createState() => _ContactChangeScreenState();
}

class _ContactChangeScreenState extends State<ContactChangeScreen> {
  final _key = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _totp = TextEditingController();
  final _otp = TextEditingController();
  late String _channel;
  String? _challengeId;
  String? _challengeToken;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _channel = widget.initialChannel == 'telegram' ? 'telegram' : 'whatsapp';
  }

  @override
  void dispose() {
    _value.dispose();
    _totp.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Change Contact',
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SecurityNotice(
            'Authenticator verification is required before TradeX sends a confirmation code.',
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'whatsapp', label: Text('WhatsApp')),
              ButtonSegment(value: 'telegram', label: Text('Telegram')),
            ],
            selected: {_channel},
            onSelectionChanged: _challengeId == null
                ? (value) => setState(() => _channel = value.first)
                : null,
          ),
          const SizedBox(height: 14),
          if (_challengeId == null) ...[
            _input(
              _value,
              _channel == 'whatsapp'
                  ? 'New number (+country code)'
                  : 'New Telegram username',
            ),
            _input(_totp, '6-digit authenticator code', secret: true),
            FilledButton(
              onPressed: _working ? null : _request,
              child: const Text('Send confirmation code'),
            ),
          ] else ...[
            _input(_otp, 'Email confirmation code', secret: true),
            FilledButton(
              onPressed: _working ? null : _confirm,
              child: const Text('Confirm change'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _input(
    TextEditingController controller,
    String label, {
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: secret,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );

  Future<void> _request() async {
    if (_key.currentState?.validate() != true) return;
    setState(() => _working = true);
    try {
      final response = await widget.apiClient.postJson(
        '/api/v1/profile/$_channel/change/request',
        {
          _channel == 'whatsapp'
              ? 'new_whatsapp_number'
              : 'new_telegram_username': _value.text
              .trim(),
          'totp_code': _totp.text.trim(),
        },
      );
      final data = _deepMap(response, 'challenge_id');
      final id = data?['challenge_id']?.toString();
      final token = data?['challenge_token']?.toString();
      if (id == null || token == null) {
        throw const ApiException(
          message: 'TradeX did not return a valid confirmation challenge.',
        );
      }
      setState(() {
        _challengeId = id;
        _challengeToken = token;
      });
      _message('Confirmation code sent.');
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirm() async {
    if (_key.currentState?.validate() != true) return;
    setState(() => _working = true);
    try {
      await widget.apiClient.postJson(
        '/api/v1/profile/$_channel/change/confirm',
        {
          'challenge_id': _challengeId,
          'challenge_token': _challengeToken,
          'otp_code': _otp.text.trim(),
        },
      );
      _message(
        '${_channel == 'whatsapp' ? 'WhatsApp number' : 'Telegram username'} updated.',
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class BrokerConnectionScreen extends StatefulWidget {
  const BrokerConnectionScreen({super.key, required this.apiClient});
  final TradeXApiClient apiClient;

  @override
  State<BrokerConnectionScreen> createState() => _BrokerConnectionScreenState();
}

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.apiClient,
    this.productUuid,
  });
  final TradeXApiClient apiClient;
  final String? productUuid;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _product;
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
    _product = TextEditingController(text: widget.productUuid ?? '');
    _catalog = _loadCatalog();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _product.dispose();
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
    } on ApiException {
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
    child: FutureBuilder<Map<String, dynamic>>(
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
        final manual = method?['mode']?.toString() == 'MANUAL_REVIEW';
        final accounts = manual
            ? _matchingAccounts(_listOfMaps(data['accounts']), _provider ?? '')
            : const <Map<String, dynamic>>[];
        if (accounts.isNotEmpty &&
            !accounts.any((item) => item['uuid'] == _receivingAccount)) {
          _receivingAccount = accounts.first['uuid']?.toString();
        }
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
                decoration: const InputDecoration(
                  labelText: 'Available payment method',
                ),
                items: methods
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['code']?.toString(),
                        child: Text(
                          '${item['display_name'] ?? item['code']} • ${_money(item['amount'])}',
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
                DropdownButtonFormField<String>(
                  key: ValueKey(_receivingAccount),
                  initialValue: _receivingAccount,
                  decoration: const InputDecoration(
                    labelText: 'Receiving account',
                  ),
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem<String>(
                          value: account['uuid']?.toString(),
                          child: Text(
                            '${account['display_name'] ?? account['type']} • ${_money(account['tender'])}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _receivingAccount = value),
                ),
              if ((_provider ?? '').toLowerCase() == 'paypal') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _product,
                  readOnly: widget.productUuid != null,
                  decoration: const InputDecoration(
                    labelText: 'Product UUID (optional)',
                  ),
                ),
              ],
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
                        (manual && _receivingAccount == null)
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
                      ? 'Prepare payment order'
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
      if (method['mode']?.toString() == 'MANUAL_REVIEW') {
        final response = await widget.apiClient.postJsonWithHeaders(
          '/api/v1/payments/manual-orders',
          {'receiving_account_uuid': _receivingAccount},
          {'Idempotency-Key': const Uuid().v4()},
        );
        final order = _map(response['data']);
        final uuid = order['uuid']?.toString();
        if (uuid == null || uuid.isEmpty) {
          throw const ApiException(
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
        _ => throw const ApiException(
          message: 'This payment method is not supported by the app.',
        ),
      };
      final response = await widget.apiClient.postJsonWithHeaders(
        endpoint,
        {
          if (code == 'paypal' && _product.text.trim().isNotEmpty)
            'product_uuid': _product.text.trim(),
        },
        {'Idempotency-Key': const Uuid().v4()},
      );
      final order = _map(response['data']);
      _orderUuid =
          order['payment_order_uuid']?.toString() ?? order['uuid']?.toString();
      final action = _deepMap(response, 'approval_url');
      final url = action?['approval_url']?.toString();
      if (url == null ||
          !await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          )) {
        throw const ApiException(
          message: 'The payment provider could not be opened.',
        );
      }
      _message(
        'Checkout opened. Return to Payment History for verified status.',
      );
    } on ApiException catch (error) {
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
    } on ApiException catch (error) {
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

class _BrokerConnectionScreenState extends State<BrokerConnectionScreen> {
  final _key = GlobalKey<FormState>();
  final _intent = TextEditingController();
  final _account = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _intent.dispose();
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Connect Broker Account',
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SecurityNotice(
            'TradeX accepts an onboarding intent and numeric account number. Never enter a broker password here.',
          ),
          const SizedBox(height: 14),
          _input(_intent, 'Onboarding intent UUID'),
          _input(_account, 'Broker account number'),
          FilledButton.icon(
            onPressed: _working ? null : _submit,
            icon: _working ? const _Busy() : const Icon(Icons.link_rounded),
            label: const Text('Submit connection request'),
          ),
        ],
      ),
    ),
  );

  Widget _input(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: label.contains('number')
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );

  Future<void> _submit() async {
    if (_key.currentState?.validate() != true) return;
    setState(() => _working = true);
    try {
      await widget.apiClient.postJson('/api/v1/copy-trade/broker-accounts', {
        'onboarding_intent_uuid': _intent.text.trim(),
        'account_number': _account.text.trim(),
      });
      _message('Broker account submitted for activation review.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _WorkflowScaffold extends StatelessWidget {
  const _WorkflowScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    ),
    body: SafeArea(child: child),
  );
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: TradeXColors.gold.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: TradeXColors.gold),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final XFile? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: const Icon(Icons.image_outlined, color: TradeXColors.gold),
      title: Text(label),
      subtitle: Text(file?.name ?? 'No image selected'),
      trailing: file == null
          ? IconButton(
              onPressed: onPick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            )
          : IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
      onTap: onPick,
    ),
  );
}

class _Busy extends StatelessWidget {
  const _Busy();
  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

Map<String, dynamic>? _deepMap(Object? value, String requiredKey) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  if (map.containsKey(requiredKey)) return map;
  for (final child in map.values) {
    final found = _deepMap(child, requiredKey);
    if (found != null) return found;
  }
  return null;
}
