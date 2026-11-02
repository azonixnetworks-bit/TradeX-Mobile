part of '../feature_catalog_screen.dart';

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
            error is UserFacingException
                ? (error! as UserFacingException).message
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
  final PickedImage? selectedFile;
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
  const hidden = {'id', 'uuid', 'user_id', 'created_by', 'updated_by'};
  return map.entries.where((entry) {
    if (hidden.contains(entry.key) ||
        entry.key.endsWith('_uuid') ||
        entry.value == null) {
      return false;
    }
    return entry.value is String || entry.value is num || entry.value is bool;
  });
}

String _titleFor(Map<String, dynamic> record) {
  const keys = ['title', 'name', 'symbol', 'subject', 'label', 'status'];
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
