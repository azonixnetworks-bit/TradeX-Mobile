part of '../affiliate_module.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        gradient: context.isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.surfaceRaised, palette.surface],
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? palette.border),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: body,
    );
  }
}

class GoldActionButton extends StatelessWidget {
  const GoldActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_gold, Color(0xFFF0A900)]),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Color(0x50FFC83D), blurRadius: 14)],
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.black,
        minimumSize: compact ? const Size(100, 46) : const Size(150, 50),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
      ),
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withValues(alpha: .7)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class PremiumGate extends StatelessWidget {
  const PremiumGate({super.key, required this.onUpgrade, this.message});
  final VoidCallback onUpgrade;
  final String? message;

  @override
  Widget build(BuildContext context) => SectionCard(
    borderColor: TradeXColors.gold,
    child: Column(
      children: [
        const _GoldIcon(Icons.workspace_premium_rounded, size: 42),
        const SizedBox(height: 14),
        const Text(
          'Premium Affiliate Access',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          message ?? 'Premium access is required to use the affiliate program.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 18),
        GoldActionButton(label: 'View Premium', onPressed: onUpgrade),
      ],
    ),
  );
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < 4; index++) ...[
        Container(
          height: index == 0 ? 180 : 84,
          decoration: BoxDecoration(
            color: context.palette.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.border),
          ),
          child: const Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: TradeXColors.error,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
      ),
    ),
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    decoration: BoxDecoration(
      gradient: selected
          ? const LinearGradient(colors: [_gold, Color(0xFFF0A900)])
          : null,
      color: selected ? null : context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: selected ? _gold : context.palette.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.black : context.palette.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty);
    final initials = parts
        .take(2)
        .map((value) => value[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: 24,
      backgroundColor: TradeXColors.goldDeep,
      foregroundColor: _gold,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _GoldIcon extends StatelessWidget {
  const _GoldIcon(this.icon, {this.size = 22});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size + 20,
    height: size + 20,
    decoration: BoxDecoration(
      color: const Color(0x28FFC83D),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x66D4AF37)),
    ),
    child: Icon(icon, color: _gold, size: size),
  );
}

class _AffiliateArt extends StatelessWidget {
  const _AffiliateArt({
    required this.path,
    required this.fallback,
    required this.size,
  });

  final String path;
  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Icon(fallback, color: _gold, size: size * .65),
    ),
  );
}

class _PaymentMethodIcon extends StatelessWidget {
  const _PaymentMethodIcon({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final asset = switch (code) {
      'PAYPAL' => _AffiliateAssets.paypal,
      'BINANCE' => _AffiliateAssets.binance,
      'USDT_TRC20' => _AffiliateAssets.tether,
      _ => null,
    };
    if (asset == null) return _GoldIcon(_methodIcon(code));
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: TradeXColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TradeXColors.border),
      ),
      child: SvgPicture.asset(
        asset,
        width: 24,
        height: 24,
        semanticsLabel: '${_methodName(code)} logo',
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: _sectionTitle);
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: _gold),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

const _sectionTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w900);

BoxDecoration _fieldDecoration(BuildContext context) => BoxDecoration(
  color: context.palette.surfaceMuted,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: context.palette.border),
);

BoxDecoration _dashboardCardDecoration(
  BuildContext context, {
  bool goldAccent = false,
}) => BoxDecoration(
  color: context.palette.surface,
  gradient: context.isDarkMode
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.surfaceRaised, context.palette.surface],
        )
      : null,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(
    color: goldAccent ? context.palette.gold : context.palette.border,
  ),
  boxShadow: TradeXElevation.surface(
    brightness: Theme.of(context).brightness,
    palette: context.palette,
  ),
);

String _date(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) return '—';
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
  return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
}

String _methodName(String code) => switch (code) {
  'PAYPAL' => 'PayPal',
  'BINANCE' => 'Binance',
  'USDT_TRC20' => 'USDT (TRC20)',
  'LOCAL_BANK' => 'Local Bank',
  _ => code.replaceAll('_', ' '),
};

IconData _methodIcon(String code) => switch (code) {
  'PAYPAL' => Icons.paypal_rounded,
  'BINANCE' => Icons.currency_bitcoin_rounded,
  'USDT_TRC20' => Icons.toll_rounded,
  'LOCAL_BANK' => Icons.account_balance_rounded,
  _ => Icons.account_balance_wallet_outlined,
};

String _message(Object error) => error is AffiliateException
    ? error.message
    : 'The request could not be completed.';

String _averageEarningsPerSale(Object? lifetimeValue, int qualifiedSales) {
  final money = AffiliateRepository.mapOf(lifetimeValue);
  final currency = AffiliateRepository.text(money['currency'], 'USD');
  final average = qualifiedSales <= 0
      ? 0.0
      : AffiliateRepository.decimal(money['amount']) / qualifiedSales;
  return currency == 'USD'
      ? '\$${average.toStringAsFixed(2)}'
      : '$currency ${average.toStringAsFixed(2)}';
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _nativeShare(BuildContext context, String url) async {
  if (url.isEmpty) {
    _snack(context, 'Referral link is unavailable.');
    return;
  }
  try {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: 'Join me on TradeX: $url',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      _snack(context, 'The share sheet could not be opened.');
    }
  }
}

Future<void> _shareAffiliateIncomeCard(
  BuildContext context, {
  required String clientName,
  required String referralUrl,
  required String referralCode,
  required String earnings,
  required String averageEarningsPerSale,
  required int totalReferrals,
  required int qualifiedSales,
  required String commissionRate,
  required String currentLevel,
}) async {
  if (referralCode.isEmpty) {
    _snack(context, 'Referral code is unavailable.');
    return;
  }
  _snack(context, 'Preparing your premium share card...');
  try {
    final box = context.findRenderObject() as RenderBox?;
    await const AffiliateShareCardService().share(
      anchor: box,
      clientName: clientName,
      referralUrl: referralUrl,
      earnings: earnings,
      referralCode: referralCode,
      averageEarningsPerSale: averageEarningsPerSale,
      totalReferrals: totalReferrals,
      qualifiedSales: qualifiedSales,
      commissionRate: commissionRate,
      currentLevel: currentLevel,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  } catch (_) {
    if (context.mounted) {
      _snack(context, 'The premium share card could not be generated.');
    }
  }
}

Future<void> _showQr(
  BuildContext context,
  String url, {
  required String cacheKey,
  required ReferralQrCache cache,
}) async {
  if (url.isEmpty) {
    _snack(context, 'Referral link is unavailable.');
    return;
  }
  final normalizedKey = cacheKey.trim().isEmpty ? 'current' : cacheKey.trim();
  String qrPayload = url;
  try {
    qrPayload = await cache.resolve(key: normalizedKey, payload: url);
  } catch (_) {
    // Secure-storage availability must never prevent referral sharing.
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.palette.surfaceRaised,
      title: const Text('Referral QR Code'),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: QrImageView(data: qrPayload, size: 220),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
