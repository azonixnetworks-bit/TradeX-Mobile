import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/bloc/bloc_future_builder.dart';
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

class CopyTradeDashboardScreen extends StatefulWidget {
  const CopyTradeDashboardScreen({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  State<CopyTradeDashboardScreen> createState() =>
      _CopyTradeDashboardScreenState();
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

class _CopyTradeDashboardScreenState extends State<CopyTradeDashboardScreen>
    with WidgetsBindingObserver {
  static const _markets = ['ALL', 'FOREX', 'CRYPTO', 'DERIV'];

  late Future<Map<String, dynamic>> _request;
  final Map<String, Map<String, dynamic>> _pendingIntents = {};
  String _market = 'ALL';
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    setState(() {
      _request = widget.apiClient.getJson('/api/v1/copy-trade/bootstrap');
    });
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Copy Trading',
    child: BlocFutureBuilder<Map<String, dynamic>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: _Busy());
        }
        if (snapshot.hasError) {
          return _CopyTradeError(error: snapshot.error, onRetry: _reload);
        }

        final data = _payload(snapshot.data);
        final accounts = _list(data['broker_accounts']);
        final brokers = _list(data['brokers']);
        final premium = _mapValue(data['education_premium']);
        final ready = data['copy_trade_ready'] == true;
        final nextStep = data['next_step']?.toString() ?? 'CONNECT_BROKER';
        final filteredBrokers = brokers
            .where((broker) {
              return _market == 'ALL' ||
                  broker['market_category']?.toString().toUpperCase() ==
                      _market;
            })
            .toList(growable: false);
        final filteredAccounts = accounts
            .where((account) {
              return _market == 'ALL' ||
                  account['market_category']?.toString().toUpperCase() ==
                      _market;
            })
            .toList(growable: false);

        return RefreshIndicator(
          color: TradeXColors.gold,
          onRefresh: () async {
            _reload();
            await _request;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _CopyTradeHero(
                ready: ready,
                nextStep: nextStep,
                premiumActive: premium['active'] == true,
              ),
              const SizedBox(height: 16),
              _CopyTradeMarketPicker(
                values: _markets,
                selected: _market,
                onSelected: (value) => setState(() => _market = value),
              ),
              const SizedBox(height: 20),
              _CopyTradeHeading(
                title: 'Your broker accounts',
                subtitle: 'Verification and eligibility are shown separately.',
                trailing: '${filteredAccounts.length}',
              ),
              const SizedBox(height: 10),
              if (filteredAccounts.isEmpty)
                const _CopyTradeEmpty(
                  icon: Icons.account_balance_wallet_outlined,
                  message: 'No broker account submitted for this market yet.',
                )
              else
                for (final account in filteredAccounts) ...[
                  _CopyTradeAccountCard(
                    account: account,
                    working: _working,
                    onResubmit: () => _showResubmitForm(account),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 18),
              const _CopyTradeHeading(
                title: 'Open or connect an account',
                subtitle: 'Use the TradeX partner link, then submit only your account number.',
              ),
              const SizedBox(height: 10),
              if (premium['active'] != true)
                const _SecurityNotice(
                  'Education Premium is required before broker onboarding. Your broker password is never requested.',
                )
              else if (filteredBrokers.isEmpty)
                const _CopyTradeEmpty(
                  icon: Icons.business_outlined,
                  message: 'No active broker is configured for this market.',
                )
              else
                for (final broker in filteredBrokers) ...[
                  _CopyTradeBrokerCard(
                    broker: broker,
                    hasIntent: _pendingIntents.containsKey(
                      broker['broker_market_uuid']?.toString(),
                    ),
                    working: _working,
                    onOpen: () => _openBroker(broker),
                    onSubmit: () => _showAccountForm(broker),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 10),
              const _SecurityNotice(
                'Security: enter the broker account number only. Never share a password, OTP, API secret or recovery code.',
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _openBroker(Map<String, dynamic> broker) async {
    final marketUuid = broker['broker_market_uuid']?.toString();
    if (marketUuid == null || marketUuid.isEmpty || _working) return;
    setState(() => _working = true);
    try {
      final response = await widget.apiClient.postJson(
        '/api/v1/copy-trade/broker-markets/$marketUuid/open-account-action',
        const {},
      );
      final data = _payload(response);
      final url = data['open_account_via_tradex_url']?.toString();
      final intent = data['onboarding_intent_uuid']?.toString();
      if (url == null || intent == null) {
        throw const ApiException(
          message: 'The broker onboarding action is unavailable.',
        );
      }
      if (!mounted) return;
      setState(() => _pendingIntents[marketUuid] = data);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw const ApiException(
          message: 'The broker link could not be opened.',
        );
      }
      _message(
        'After opening the LIVE account, return here and submit its account number.',
      );
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The broker link could not be opened right now.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showAccountForm(Map<String, dynamic> broker) async {
    final marketUuid = broker['broker_market_uuid']?.toString();
    final intent = _pendingIntents[marketUuid];
    if (marketUuid == null || intent == null) {
      _message('Open the TradeX partner link first.');
      return;
    }
    final account = TextEditingController();
    final key = GlobalKey<FormState>();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF071321),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit ${broker['broker_name'] ?? 'broker'} account',
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${broker['market_category'] ?? ''} · LIVE · ${broker['required_currency'] ?? 'USD'}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: account,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 15,
                decoration: const InputDecoration(
                  labelText: 'Broker account number',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Account number is required.';
                  if (text.length > 15) return 'Use at most 15 digits.';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (key.currentState?.validate() != true) return;
                    Navigator.pop(sheetContext, true);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit for verification'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Do not enter your broker password or OTP.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted != true || !mounted) {
      account.dispose();
      return;
    }

    setState(() => _working = true);
    try {
      await widget.apiClient.postJson('/api/v1/copy-trade/broker-accounts', {
        'onboarding_intent_uuid': intent['onboarding_intent_uuid'],
        'account_number': account.text.trim(),
      });
      _pendingIntents.remove(marketUuid);
      _message('Account submitted. TradeX will verify the IB relationship.');
      _reload();
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      account.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showResubmitForm(Map<String, dynamic> accountData) async {
    final accountUuid = accountData['uuid']?.toString();
    if (accountUuid == null || accountUuid.isEmpty || _working) return;

    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF071321),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Correct broker account number',
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                accountData['status_reason']?.toString() ??
                    'TradeX requested a corrected account number.',
                style: const TextStyle(color: Color(0xFFFF9DA8)),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 15,
                decoration: const InputDecoration(
                  labelText: 'Correct account number',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Account number is required.'
                    : null,
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (key.currentState?.validate() == true) {
                      Navigator.pop(sheetContext, true);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Resubmit for verification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted != true || !mounted) {
      controller.dispose();
      return;
    }

    setState(() => _working = true);
    try {
      await widget.apiClient.postJson(
        '/api/v1/copy-trade/broker-accounts/$accountUuid/resubmit',
        {'account_number': controller.text.trim()},
      );
      _message('Corrected account number submitted for verification.');
      _reload();
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      controller.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  Map<String, dynamic> _payload(Map<String, dynamic>? response) {
    final raw = response?['data'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : Map<String, dynamic>.from(response ?? const {});
  }

  Map<String, dynamic> _mapValue(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false)
      : const [];

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _CopyTradeHero extends StatelessWidget {
  const _CopyTradeHero({
    required this.ready,
    required this.nextStep,
    required this.premiumActive,
  });

  final bool ready;
  final String nextStep;
  final bool premiumActive;

  @override
  Widget build(BuildContext context) {
    final (title, message, icon, color) = switch (nextStep) {
      'COPY_TRADE_READY' => (
        'Copy Trade ready',
        'Your verified account passed the activation gates.',
        Icons.verified_rounded,
        const Color(0xFF19D6A3),
      ),
      'ACTIVATION_PENDING' => (
        'Eligibility review',
        'Broker verification is complete. Activation gates are pending.',
        Icons.rule_rounded,
        TradeXColors.gold,
      ),
      'WAITING_FOR_VERIFICATION' => (
        'Verification pending',
        'TradeX is checking your partner relationship and LIVE account.',
        Icons.hourglass_top_rounded,
        const Color(0xFF4EA4FF),
      ),
      'ACTION_REQUIRED' => (
        'Action required',
        'Review the account status below and resubmit when requested.',
        Icons.error_outline_rounded,
        const Color(0xFFFF6374),
      ),
      'EDUCATION_PREMIUM_REQUIRED' => (
        'Premium required',
        'Activate Education Premium before connecting a broker account.',
        Icons.workspace_premium_outlined,
        TradeXColors.gold,
      ),
      _ => (
        'Connect your account',
        'Open a supported account using the TradeX partner link.',
        Icons.link_rounded,
        const Color(0xFF4EA4FF),
      ),
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2038), Color(0xFF06111D)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .6)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .12), blurRadius: 24),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  premiumActive ? 'PREMIUM ACTIVE' : 'PREMIUM INACTIVE',
                  style: TextStyle(
                    color: premiumActive
                        ? const Color(0xFF19D6A3)
                        : TradeXColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          if (ready) const Icon(Icons.check_circle, color: Color(0xFF19D6A3)),
        ],
      ),
    );
  }
}

class _CopyTradeMarketPicker extends StatelessWidget {
  const _CopyTradeMarketPicker({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: values
          .map((value) {
            final active = selected == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(value == 'ALL' ? 'All' : value),
                selected: active,
                onSelected: (_) => onSelected(value),
                selectedColor: TradeXColors.gold,
                labelStyle: TextStyle(
                  color: active ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          })
          .toList(growable: false),
    ),
  );
}

class _CopyTradeHeading extends StatelessWidget {
  const _CopyTradeHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(
            color: TradeXColors.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
    ],
  );
}

class _CopyTradeAccountCard extends StatelessWidget {
  const _CopyTradeAccountCard({
    required this.account,
    required this.working,
    required this.onResubmit,
  });
  final Map<String, dynamic> account;
  final bool working;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    final broker = account['broker'] is Map
        ? Map<String, dynamic>.from(account['broker'] as Map)
        : <String, dynamic>{};
    final activation = account['activation'] is Map
        ? Map<String, dynamic>.from(account['activation'] as Map)
        : <String, dynamic>{};
    final status = account['status']?.toString() ?? 'PENDING';
    final color = switch (status) {
      'ACTIVE' => const Color(0xFF19D6A3),
      'VERIFIED' => const Color(0xFF4EA4FF),
      'PENDING' || 'ESCALATED' => TradeXColors.gold,
      _ => const Color(0xFFFF6374),
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CopyTradeInitials(name: broker['name']?.toString() ?? 'Broker'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broker['name']?.toString() ?? 'Broker account',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${account['market_category'] ?? '—'} · ${account['account_number_masked'] ?? '—'}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: .5)),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CopyTradeStatusLine(
                  label: 'IB verification',
                  value: status == 'PENDING'
                      ? 'Under review'
                      : status.replaceAll('_', ' '),
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CopyTradeStatusLine(
                  label: 'Eligibility',
                  value:
                      activation['state']?.toString().replaceAll('_', ' ') ??
                      'NOT ELIGIBLE',
                  color: activation['copy_trade_ready'] == true
                      ? const Color(0xFF19D6A3)
                      : Colors.white60,
                ),
              ),
            ],
          ),
          if (account['status_reason'] != null) ...[
            const SizedBox(height: 10),
            Text(
              account['status_reason'].toString(),
              style: const TextStyle(color: Color(0xFFFF9DA8), fontSize: 12),
            ),
          ],
          if (status == 'NEEDS_RESUBMISSION') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: working ? null : onResubmit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Correct and resubmit'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyTradeStatusLine extends StatelessWidget {
  const _CopyTradeStatusLine({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CopyTradeBrokerCard extends StatelessWidget {
  const _CopyTradeBrokerCard({
    required this.broker,
    required this.hasIntent,
    required this.working,
    required this.onOpen,
    required this.onSubmit,
  });

  final Map<String, dynamic> broker;
  final bool hasIntent;
  final bool working;
  final VoidCallback onOpen;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF091726),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        _CopyTradeInitials(name: broker['broker_name']?.toString() ?? 'Broker'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                broker['broker_name']?.toString() ?? 'Supported broker',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${broker['market_category'] ?? '—'} · LIVE · ${broker['required_currency'] ?? 'USD'}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (hasIntent)
          FilledButton(
            onPressed: working ? null : onSubmit,
            child: const Text('Submit ID'),
          )
        else
          OutlinedButton(
            onPressed: working ? null : onOpen,
            child: const Text('Open'),
          ),
      ],
    ),
  );
}

class _CopyTradeInitials extends StatelessWidget {
  const _CopyTradeInitials({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD45C), Color(0xFFB77A10)],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        initials.isEmpty ? 'TX' : initials,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CopyTradeEmpty extends StatelessWidget {
  const _CopyTradeEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF091522),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.white60)),
        ),
      ],
    ),
  );
}

class _CopyTradeError extends StatelessWidget {
  const _CopyTradeError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          Text(
            error is ApiException
                ? (error as ApiException).message
                : 'Copy Trade details could not be loaded.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
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
