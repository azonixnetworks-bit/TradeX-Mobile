part of '../investment_module.dart';

const _investmentBackground = Color(0xFF080A0E);
const _investmentCard = Color(0xFF15171B);
const _investmentCardBorder = Color(0xFF303238);
const _investmentText = Color(0xFFF3F3F1);
const _investmentMuted = Color(0xFFA3A4A7);
const _investmentGreen = Color(0xFF4BDD8A);
const _investmentWarning = Color(0xFFFBD26F);
const _investmentNegative = Color(0xFFE87980);
const _investmentInfo = Color(0xFFA3CAFF);

class _InvestmentScaffold extends StatelessWidget {
  const _InvestmentScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _investmentBackground,
      colorScheme: const ColorScheme.dark(
        primary: TradeXColors.goldBright,
        surface: _investmentCard,
      ),
    ),
    child: Scaffold(
      backgroundColor: _investmentBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: TradeXColors.goldBright,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _investmentText,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF232527)),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _InvestmentCard extends StatelessWidget {
  const _InvestmentCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _investmentCard,
      gradient: emphasized
          ? const LinearGradient(colors: [Color(0xFF2B2515), Color(0xFF17191E)])
          : null,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: emphasized ? const Color(0xFF9B681E) : _investmentCardBorder,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 14,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class _InvestmentSectionTitle extends StatelessWidget {
  const _InvestmentSectionTitle(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _investmentText,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

class _InvestmentMetric extends StatelessWidget {
  const _InvestmentMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.positive = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) => _InvestmentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: TradeXColors.goldBright, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: _investmentMuted, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: positive ? _investmentGreen : _investmentText,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _InvestmentStatusBadge extends StatelessWidget {
  const _InvestmentStatusBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase().replaceAll(' ', '_');
    final color = switch (normalized) {
      'active' ||
      'approved' ||
      'paid' ||
      'verified' ||
      'completed' => _investmentGreen,
      'pending' => _investmentWarning,
      'prepared' || 'matured' => _investmentInfo,
      'rejected' || 'loss' => _investmentNegative,
      _ => _investmentMuted,
    };
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          border: Border.all(color: color.withValues(alpha: .45)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _InvestmentNavTile extends StatelessWidget {
  const _InvestmentNavTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _InvestmentCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: TradeXColors.goldBright),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _investmentText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: TradeXColors.goldBright),
      ],
    ),
  );
}

class _InvestmentUnavailable extends StatelessWidget {
  const _InvestmentUnavailable({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _InvestmentCard(
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: TradeXColors.goldBright,
          size: 40,
        ),
        const SizedBox(height: 12),
        const Text(
          'Investment data unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _investmentText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _investmentMuted, height: 1.4),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ],
    ),
  );
}

class _InvestmentEmpty extends StatelessWidget {
  const _InvestmentEmpty({
    this.title = 'No investments yet',
    this.message = 'Your verified investments will appear here once available.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => _InvestmentCard(
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_rounded,
          color: TradeXColors.goldBright,
          size: 38,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _investmentText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _investmentMuted),
        ),
      ],
    ),
  );
}

class _InvestmentLoading extends StatelessWidget {
  const _InvestmentLoading();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: 4,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (_, index) => Container(
      height: index == 0 ? 150 : 92,
      decoration: BoxDecoration(
        color: _investmentCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _investmentCardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: const Align(
        alignment: Alignment.topLeft,
        child: LinearProgressIndicator(
          color: TradeXColors.goldBright,
          backgroundColor: Color(0xFF303238),
        ),
      ),
    ),
  );
}

class _InvestmentRiskNotice extends StatelessWidget {
  const _InvestmentRiskNotice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF2A210C),
      border: Border.all(color: const Color(0xFF9B681E)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: _investmentWarning,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _investmentWarning,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InvestmentKeyValue extends StatelessWidget {
  const _InvestmentKeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: _investmentMuted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _investmentText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

String _money(double? value, String? currency, {bool hidden = false}) {
  if (hidden) return '••••••••';
  if (value == null) return '—';
  final symbol = switch (currency?.toUpperCase()) {
    'USD' => r'$',
    _ => '',
  };
  final digits = value.toStringAsFixed(2);
  final parts = digits.split('.');
  final formatted = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final suffix = currency == null || symbol.isNotEmpty
      ? ''
      : ' ${currency.toUpperCase()}';
  return '$symbol$formatted.${parts.last}$suffix';
}

String _date(DateTime? value) {
  if (value == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}

String _investmentStatusLabel(InvestmentStatus status) =>
    status.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)!.toLowerCase()}',
    );

String _recordStatusLabel(InvestmentRecordStatus status) =>
    status.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)!.toLowerCase()}',
    );

String _investmentError(Object? error) => error is InvestmentFeatureUnavailable
    ? error.message
    : 'Unable to load investments. Please try again.';

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}
