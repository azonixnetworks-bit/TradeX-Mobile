import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../models/feature_spec.dart';
import 'secure_workflow_screens.dart';

class FeatureCatalogScreen extends StatelessWidget {
  const FeatureCatalogScreen({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<FeatureSpec>>{};
    for (final spec in tradeXFeatureSpecs) {
      groups.putIfAbsent(spec.group, () => <FeatureSpec>[]).add(spec);
    }
    return _FeatureScaffold(
      title: 'TradeX Services',
      subtitle: 'Secure access to your available account services',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _SafetyNotice(),
          const SizedBox(height: 14),
          for (final entry in groups.entries) ...[
            _GroupHeading(entry.key),
            const SizedBox(height: 8),
            _FeatureGroup(
              specs: entry.value,
              onOpen: (spec) => openTradeXFeature(context, apiClient, spec),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

Future<void> openTradeXFeature(
  BuildContext context,
  TradeXApiClient apiClient,
  FeatureSpec spec,
) {
  final workflow = switch (spec.id) {
    'kyc-submit' => KycSubmissionScreen(apiClient: apiClient),
    'payment-proof' => PaymentProofScreen(apiClient: apiClient),
    'contact-number' => ContactChangeScreen(apiClient: apiClient),
    'connect-broker' => BrokerConnectionScreen(apiClient: apiClient),
    'checkout' => PaymentCheckoutScreen(apiClient: apiClient),
    _ => null,
  };
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          workflow ?? TradeXFeatureScreen(apiClient: apiClient, spec: spec),
    ),
  );
}

class TradeXFeatureScreen extends StatefulWidget {
  const TradeXFeatureScreen({
    super.key,
    required this.apiClient,
    required this.spec,
  });

  final TradeXApiClient apiClient;
  final FeatureSpec spec;

  @override
  State<TradeXFeatureScreen> createState() => _TradeXFeatureScreenState();
}

class _TradeXFeatureScreenState extends State<TradeXFeatureScreen> {
  final _search = TextEditingController();
  Future<Map<String, dynamic>>? _request;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    final endpoint = widget.spec.endpoint;
    setState(() {
      _request = endpoint == null ? null : widget.apiClient.getJson(endpoint);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spec.kind == FeatureKind.local) {
      return widget.spec.id == 'help-faq'
          ? const _HelpScreen()
          : const _ContactSupportScreen();
    }

    return _FeatureScaffold(
      title: widget.spec.title,
      subtitle: widget.spec.subtitle,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      floatingActionButton: widget.spec.kind == FeatureKind.action
          ? FloatingActionButton.extended(
              backgroundColor: TradeXColors.goldBright,
              foregroundColor: Colors.black,
              onPressed: () => _openAction(context),
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('Continue'),
            )
          : null,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error, onRetry: _reload);
          }
          final payload = snapshot.data ?? const <String, dynamic>{};
          final cache = payload['_offline_cache'];
          final records = _findBestRecords(payload);
          final filtered = records
              .where((record) {
                if (_query.isEmpty) return true;
                return jsonEncode(record).toLowerCase().contains(_query);
              })
              .toList(growable: false);
          return RefreshIndicator(
            color: TradeXColors.goldBright,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              children: [
                if (cache is Map) ...[
                  _OfflineCacheNotice(
                    metadata: Map<String, dynamic>.from(cache),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_supportsSearch(widget.spec)) ...[
                  TextField(
                    controller: _search,
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_isFinancial(widget.spec)) const _FinancialNotice(),
                if (_isFinancial(widget.spec)) const SizedBox(height: 12),
                if (records.isEmpty)
                  _ObjectPanel(payload: _dataMap(payload))
                else if (filtered.isEmpty)
                  const _EmptyState(message: 'No matching records found.')
                else
                  for (final record in filtered) ...[
                    _RecordCard(
                      record: record,
                      onTap: () => _openRecord(context, record),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRecord(
    BuildContext context,
    Map<String, dynamic> record,
  ) async {
    final spec = widget.spec;
    var detail = record;
    final identifier = _identifier(record);
    String? endpoint;
    if (identifier != null) {
      endpoint = switch (spec.id) {
        'trade-idea-details' ||
        'share-trade-idea' => '/api/v1/trade-ideas/$identifier',
        'trade-journal' ||
        'trade-entry-details' => '/api/v1/trade-journal/$identifier',
        'notification-details' ||
        'notifications' => '/api/v1/notifications/$identifier',
        'product-details' ||
        'products' ||
        'checkout' => '/api/v1/products/$identifier',
        _ => null,
      };
    }
    if (endpoint != null) {
      try {
        final response = await widget.apiClient.getJson(endpoint);
        detail = _dataMap(response);
      } catch (_) {
        // The summary remains useful when a detail request is unavailable.
      }
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RecordDetailsScreen(
          apiClient: widget.apiClient,
          spec: spec,
          record: detail,
          identifier: identifier,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _openAction(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _FeatureActionScreen(
          apiClient: widget.apiClient,
          spec: widget.spec,
        ),
      ),
    );
    if (changed == true && mounted) _reload();
  }
}

class _OfflineCacheNotice extends StatelessWidget {
  const _OfflineCacheNotice({required this.metadata});

  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final cachedAt = DateTime.tryParse(metadata['cached_at']?.toString() ?? '')
        ?.toLocal();
    final timestamp = cachedAt == null
        ? 'an earlier session'
        : '${cachedAt.year}-${cachedAt.month.toString().padLeft(2, '0')}-${cachedAt.day.toString().padLeft(2, '0')} '
              '${cachedAt.hour.toString().padLeft(2, '0')}:${cachedAt.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saved data from $timestamp. Market and news values may be stale.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordDetailsScreen extends StatefulWidget {
  const _RecordDetailsScreen({
    required this.apiClient,
    required this.spec,
    required this.record,
    this.identifier,
  });

  final TradeXApiClient apiClient;
  final FeatureSpec spec;
  final Map<String, dynamic> record;
  final String? identifier;

  @override
  State<_RecordDetailsScreen> createState() => _RecordDetailsScreenState();
}

class _RecordDetailsScreenState extends State<_RecordDetailsScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: widget.spec.title,
      subtitle: _titleFor(widget.record),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ObjectPanel(payload: widget.record),
          if (_isTradeIdea(widget.spec) && widget.identifier != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _working ? null : _shareTradeIdea,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share verified trade idea'),
            ),
          ],
          if (_isNotification(widget.spec) && widget.identifier != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _working ? null : _markNotificationRead,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark as read'),
            ),
          ],
          if (_isJournal(widget.spec) && widget.identifier != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _working ? null : _deleteJournalEntry,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete entry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TradeXColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _shareTradeIdea() async {
    final id = widget.identifier!;
    setState(() => _working = true);
    try {
      final response = await widget.apiClient.postJson(
        '/api/v1/trade-ideas/$id/share-action',
        const {'channel': 'WHATSAPP', 'variant': 'portrait'},
      );
      if (!mounted) return;
      final action = _findMapNamed(response, 'share_action');
      final target =
          action?['url'] ?? action?['share_url'] ?? action?['deep_link'];
      if (target is! String ||
          !await launchUrl(
            Uri.parse(target),
            mode: LaunchMode.externalApplication,
          )) {
        throw const ApiException(
          message: 'The share destination is unavailable.',
        );
      }
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The trade idea could not be shared right now.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _markNotificationRead() async {
    setState(() => _working = true);
    try {
      await widget.apiClient.patchJson(
        '/api/v1/notifications/${widget.identifier}/read',
        const {},
      );
      _message('Notification marked as read.');
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteJournalEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete journal entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _working = true);
    try {
      await widget.apiClient.deleteJson(
        '/api/v1/trade-journal/${widget.identifier}',
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FeatureActionScreen extends StatefulWidget {
  const _FeatureActionScreen({required this.apiClient, required this.spec});

  final TradeXApiClient apiClient;
  final FeatureSpec spec;

  @override
  State<_FeatureActionScreen> createState() => _FeatureActionScreenState();
}

class _FeatureActionScreenState extends State<_FeatureActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, TextEditingController>{};
  bool _working = false;
  XFile? _selectedFile;

  List<_FieldSpec> get _fields => switch (widget.spec.id) {
    'trade-entry-form' => const [
      _FieldSpec('symbol', 'Instrument / symbol'),
      _FieldSpec('entry_reason', 'Entry reason', lines: 3),
      _FieldSpec('planned_entry', 'Planned entry', numeric: true),
      _FieldSpec('planned_sl', 'Stop loss', numeric: true),
      _FieldSpec('planned_tp', 'Take profit', numeric: true),
      _FieldSpec('position_size', 'Quantity / position size', numeric: true),
    ],
    'request-withdrawal' => const [
      _FieldSpec('method', 'Withdrawal method'),
      _FieldSpec('amount', 'Amount (USD)', numeric: true),
    ],
    'financial-profile' => const [
      _FieldSpec('totp_code', 'Authenticator code'),
      _FieldSpec('paypal_email', 'PayPal email', required: false),
      _FieldSpec('binance_email', 'Binance email', required: false),
      _FieldSpec('usdt_trc20_address', 'USDT TRC20 address', required: false),
      _FieldSpec('bank_name', 'Bank name', required: false),
      _FieldSpec('bank_branch', 'Bank branch', required: false),
      _FieldSpec('bank_account_holder', 'Bank account holder', required: false),
      _FieldSpec('bank_account_number', 'Bank account number', required: false),
    ],
    'contact-number' => const [
      _FieldSpec('number', 'New WhatsApp / Telegram number'),
      _FieldSpec('totp_code', 'Authenticator code'),
    ],
    'recovery-codes' => const [_FieldSpec('totp_code', 'Authenticator code')],
    'preferences' => const [_FieldSpec('language_code', 'Language code')],
    _ => const [],
  };

  @override
  void initState() {
    super.initState();
    for (final field in _fields) {
      _values[field.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supported = _isSupportedMutation(widget.spec.id);
    return _FeatureScaffold(
      title: widget.spec.title,
      subtitle: supported
          ? 'Review carefully before submitting'
          : 'The backend does not expose a safe standalone action',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if (_isFinancial(widget.spec)) const _FinancialNotice(),
            if (!supported) ...[
              const _UnavailableNotice(),
              const SizedBox(height: 14),
            ],
            if (widget.spec.id == 'payment-proof' ||
                widget.spec.id == 'kyc-submit') ...[
              _UploadPicker(
                selectedFile: _selectedFile,
                onPick: _pickDocumentImage,
                onRemove: () => setState(() => _selectedFile = null),
              ),
              const SizedBox(height: 14),
            ],
            for (final field in _fields) ...[
              TextFormField(
                controller: _values[field.name],
                keyboardType: field.numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                maxLines: field.lines,
                obscureText: field.name == 'totp_code',
                decoration: InputDecoration(labelText: field.label),
                validator: (value) {
                  if (field.required &&
                      (value == null || value.trim().isEmpty)) {
                    return '${field.label} is required.';
                  }
                  if (field.numeric &&
                      value?.trim().isNotEmpty == true &&
                      double.tryParse(value!.trim()) == null) {
                    return 'Enter a valid number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            if (supported)
              FilledButton.icon(
                onPressed: _working ? null : _submit,
                icon: _working
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_rounded),
                label: Text(_working ? 'Submitting…' : 'Review and submit'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocumentImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2200,
      maxHeight: 2200,
    );
    if (file != null && mounted) setState(() => _selectedFile = file);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _working = true);
    try {
      final body = <String, dynamic>{
        for (final entry in _values.entries)
          if (entry.value.text.trim().isNotEmpty)
            entry.key: entry.value.text.trim(),
      };
      switch (widget.spec.id) {
        case 'trade-entry-form':
          final now = DateTime.now();
          final timezone = await FlutterTimezone.getLocalTimezone();
          body.addAll({
            'market': 'forex',
            'direction': 'buy',
            'status': 'planned',
            'trade_date': _date(now),
            'trade_time': _time(now),
            'timezone': timezone.identifier,
          });
          await widget.apiClient.postJson('/api/v1/trade-journal', body);
        case 'request-withdrawal':
          await widget.apiClient.postJsonWithHeaders('/api/v1/payouts', body, {
            'Idempotency-Key': const Uuid().v4(),
          });
        case 'financial-profile':
          await widget.apiClient.patchJson('/api/v1/profile/financial', body);
        case 'preferences':
          await widget.apiClient.patchJson('/api/v1/profile/preferences', body);
        case 'recovery-codes':
          await widget.apiClient.postJson(
            '/api/v1/auth/recovery-codes/regenerate',
            body,
          );
        case 'contact-number':
          await widget.apiClient.postJson(
            '/api/v1/profile/whatsapp/change/request',
            {
              'new_whatsapp_number': body['number'],
              'totp_code': body['totp_code'],
            },
          );
        default:
          throw const ApiException(
            message: 'This action needs additional account context.',
          );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully.')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _HelpScreen extends StatefulWidget {
  const _HelpScreen();

  @override
  State<_HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<_HelpScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    const topics = <(String, String)>[
      (
        'Account access',
        'Use password recovery from the sign-in screen. Never share an OTP or recovery code.',
      ),
      (
        'Payments',
        'Open Payment Status & History for authoritative transaction states. A pending payment is not a successful payment.',
      ),
      (
        'Withdrawals',
        'Eligibility, minimums, balance and supported destinations are returned by your account API.',
      ),
      (
        'KYC',
        'Open KYC Verification Status for required documents, review state and any rejection reason.',
      ),
      (
        'Trade ideas',
        'Trade ideas are educational information, not guaranteed returns or personalized financial advice.',
      ),
    ];
    final visible = topics
        .where(
          (topic) => '${topic.$1} ${topic.$2}'.toLowerCase().contains(_query),
        )
        .toList();
    return _FeatureScaffold(
      title: 'Help & FAQ',
      subtitle: 'Approved in-app guidance only',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search help',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
          ),
          const SizedBox(height: 14),
          for (final topic in visible)
            Card(
              child: ExpansionTile(
                title: Text(topic.$1),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Text(topic.$2)],
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Company-specific support policies are not included because the backend does not publish an approved FAQ feed.',
            style: TextStyle(color: TradeXColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _ContactSupportScreen extends StatefulWidget {
  const _ContactSupportScreen();

  @override
  State<_ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<_ContactSupportScreen> {
  final _key = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FeatureScaffold(
      title: 'Contact Support',
      subtitle: 'Prepare a validated support request',
      child: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _UnavailableNotice(
              message: 'The backend has no customer support submission endpoint. You can validate a draft here, but it will not be sent.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Message'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                if (_key.currentState?.validate() != true) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Draft validated. It has not been submitted.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Validate draft'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureScaffold extends StatelessWidget {
  const _FeatureScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(child: child),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({required this.specs, required this.onOpen});

  final List<FeatureSpec> specs;
  final ValueChanged<FeatureSpec> onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      children: [
        for (var index = 0; index < specs.length; index++) ...[
          ListTile(
            minVerticalPadding: 12,
            leading: Icon(specs[index].icon, color: TradeXColors.goldBright),
            title: Text(specs[index].title),
            subtitle: Text(specs[index].subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onOpen(specs[index]),
          ),
          if (index != specs.length - 1)
            const Divider(height: 1, color: TradeXColors.border),
        ],
      ],
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});

  final Map<String, dynamic> record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scalars = _visibleScalars(record).take(4).toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _titleFor(record),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: TradeXColors.gold,
                ),
              ],
            ),
            if (scalars.isNotEmpty) const SizedBox(height: 8),
            for (final entry in scalars)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${_label(entry.key)}: ${_display(entry.value)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ObjectPanel extends StatelessWidget {
  const _ObjectPanel({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final entries = _visibleScalars(payload).toList();
    if (entries.isEmpty) {
      return const _EmptyState(
        message: 'No data is available for this account yet.',
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    _label(entries[i].key),
                    style: const TextStyle(color: TradeXColors.secondaryText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Text(
                    _display(entries[i].value),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (i != entries.length - 1)
              const Divider(height: 22, color: TradeXColors.border),
          ],
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: TradeXColors.goldBright),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: TradeXColors.gold,
          ),
          const SizedBox(height: 12),
          Text(
            error is ApiException
                ? (error! as ApiException).message
                : 'This service is unavailable right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: _panelDecoration(context),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 38, color: TradeXColors.gold),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();
  @override
  Widget build(BuildContext context) => const _Notice(
    icon: Icons.shield_outlined,
    message: 'Values and statuses are loaded from TradeX. No transaction or broker connection is presented as successful before the backend confirms it.',
  );
}

class _FinancialNotice extends StatelessWidget {
  const _FinancialNotice();
  @override
  Widget build(BuildContext context) => const _Notice(
    icon: Icons.info_outline_rounded,
    message: 'Review amounts, destinations and status carefully. Pending does not mean paid or approved.',
  );
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({
    this.message = 'This screen is available, but submission needs a preceding account, order, or verification step. No result will be simulated.',
  });
  final String message;
  @override
  Widget build(BuildContext context) => _Notice(
    icon: Icons.link_off_rounded,
    message: message,
    color: TradeXColors.warning,
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    this.color = TradeXColors.gold,
  });
  final IconData icon;
  final String message;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _UploadPicker extends StatelessWidget {
  const _UploadPicker({
    required this.selectedFile,
    required this.onPick,
    required this.onRemove,
  });
  final XFile? selectedFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _panelDecoration(context),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          size: 38,
          color: TradeXColors.gold,
        ),
        const SizedBox(height: 8),
        Text(selectedFile?.name ?? 'PNG or JPEG image'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: onPick,
              child: const Text('Choose image'),
            ),
            if (selectedFile != null)
              TextButton(onPressed: onRemove, child: const Text('Remove')),
          ],
        ),
      ],
    ),
  );
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: TradeXColors.goldBright,
      fontSize: 15,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _FieldSpec {
  const _FieldSpec(
    this.name,
    this.label, {
    this.required = true,
    this.numeric = false,
    this.lines = 1,
  });
  final String name;
  final String label;
  final bool required;
  final bool numeric;
  final int lines;
}

BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Theme.of(context).dividerColor),
);

List<Map<String, dynamic>> _findBestRecords(Object? value) {
  if (value is List) {
    final maps = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    if (maps.isNotEmpty) return maps;
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    const preferred = [
      'items',
      'data',
      'results',
      'events',
      'notifications',
      'trade_ideas',
      'entries',
      'trades',
      'products',
      'brokers',
      'invoices',
      'payments',
      'payouts',
      'referrals',
      'sales',
      'commissions',
      'policies',
      'languages',
    ];
    for (final key in preferred) {
      final records = _findBestRecords(map[key]);
      if (records.isNotEmpty) return records;
    }
    for (final child in map.values) {
      final records = _findBestRecords(child);
      if (records.isNotEmpty) return records;
    }
  }
  return const [];
}

Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
  final data = payload['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return payload;
}

Map<String, dynamic>? _findMapNamed(Object? value, String key) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final direct = map[key];
  if (direct is Map) return Map<String, dynamic>.from(direct);
  for (final child in map.values) {
    final found = _findMapNamed(child, key);
    if (found != null) return found;
  }
  return null;
}

Iterable<MapEntry<String, dynamic>> _visibleScalars(Map<String, dynamic> map) {
  const hidden = {'id', 'user_id', 'created_by', 'updated_by'};
  return map.entries.where((entry) {
    if (hidden.contains(entry.key) || entry.value == null) return false;
    return entry.value is String || entry.value is num || entry.value is bool;
  });
}

String _titleFor(Map<String, dynamic> record) {
  const keys = [
    'title',
    'name',
    'symbol',
    'subject',
    'label',
    'status',
    'uuid',
  ];
  for (final key in keys) {
    final value = record[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  for (final nested in record.values.whereType<Map>()) {
    final title = _titleFor(Map<String, dynamic>.from(nested));
    if (title != 'TradeX record') return title;
  }
  return 'TradeX record';
}

String? _identifier(Map<String, dynamic> record) {
  for (final key in const ['uuid', 'id', 'slug']) {
    final value = record[key]?.toString();
    if (value?.isNotEmpty == true) return value;
  }
  return null;
}

String _label(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _display(Object? value) {
  if (value is bool) return value ? 'Yes' : 'No';
  return value?.toString() ?? '—';
}

bool _supportsSearch(FeatureSpec spec) => spec.kind == FeatureKind.collection;
bool _isTradeIdea(FeatureSpec spec) => spec.id.contains('trade-idea');
bool _isNotification(FeatureSpec spec) => spec.id.contains('notification');
bool _isJournal(FeatureSpec spec) =>
    spec.id.contains('trade-journal') || spec.id.contains('trade-entry');
bool _isFinancial(FeatureSpec spec) => const {
  'copy-billing',
  'products',
  'product-details',
  'payment-method',
  'checkout',
  'payment-proof',
  'payment-history',
  'request-withdrawal',
  'withdrawal-history',
  'financial-profile',
  'commissions',
}.contains(spec.id);

bool _isSupportedMutation(String id) => const {
  'trade-entry-form',
  'request-withdrawal',
  'financial-profile',
  'preferences',
  'contact-number',
  'recovery-codes',
}.contains(id);

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;
