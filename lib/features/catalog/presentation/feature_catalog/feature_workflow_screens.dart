part of '../feature_catalog_screen.dart';

class TradeXFeatureScreen extends StatefulWidget {
  const TradeXFeatureScreen({
    super.key,
    required this.apiClient,
    required this.spec,
  });

  final ApiGateway apiClient;
  final FeatureSpec spec;

  @override
  State<TradeXFeatureScreen> createState() => _TradeXFeatureScreenState();
}

class _TradeXFeatureScreenState extends State<TradeXFeatureScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  Future<Map<String, dynamic>>? _request;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.spec.endpoint != null) {
      _reload();
    }
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
      child: BlocFutureBuilder<Map<String, dynamic>>(
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
                return encodeStructuredText(record)
                    .toLowerCase()
                    .contains(_query);
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

  final ApiGateway apiClient;
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
          !await SecureWorkflowPlatformRegistry.current.launchExternal(
            target,
          )) {
        throw const UserFacingFailure(
          message: 'The share destination is unavailable.',
        );
      }
    } on UserFacingException catch (error) {
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
    } on UserFacingException catch (error) {
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
    } on UserFacingException catch (error) {
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

  final ApiGateway apiClient;
  final FeatureSpec spec;

  @override
  State<_FeatureActionScreen> createState() => _FeatureActionScreenState();
}

class _FeatureActionScreenState extends State<_FeatureActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, TextEditingController>{};
  bool _working = false;
  PickedImage? _selectedFile;

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
    final file = await SecureWorkflowPlatformRegistry.current.pickImage(
      camera: false,
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
          final timezone = await SecureWorkflowPlatformRegistry.current
              .timezoneId();
          body.addAll({
            'market': 'forex',
            'direction': 'buy',
            'status': 'planned',
            'trade_date': _date(now),
            'trade_time': _time(now),
            'timezone': timezone,
          });
          await widget.apiClient.postJson('/api/v1/trade-journal', body);
        case 'request-withdrawal':
          await widget.apiClient.postJsonWithHeaders('/api/v1/payouts', body, {
            'Idempotency-Key': SecureWorkflowPlatformRegistry.current.newUuid(),
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
          throw const UserFacingFailure(
            message: 'This action needs additional account context.',
          );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully.')),
      );
      Navigator.pop(context, true);
    } on UserFacingException catch (error) {
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
