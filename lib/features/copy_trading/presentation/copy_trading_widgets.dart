import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../domain/entities/copy_trading_entities.dart';
import '../domain/usecases/copy_trading_use_cases.dart';

const copyGold = TradeXColors.goldBright;
const copyMuted = Color(0xFFAAB6CA);
const copyGreen = Color(0xFF08E493);
const copyRed = Color(0xFFFF4D58);

class CopyTradingPage extends StatelessWidget {
  const CopyTradingPage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 32),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.background,
    body: SafeArea(
      child: Padding(padding: padding, child: child),
    ),
  );
}

class CopyTradingScrollPage extends StatelessWidget {
  const CopyTradingScrollPage({
    super.key,
    required this.children,
    this.onRefresh,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: children,
    );
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: onRefresh == null
            ? list
            : RefreshIndicator(
                color: copyGold,
                onRefresh: onRefresh!,
                child: list,
              ),
      ),
    );
  }
}

class CopySectionCard extends StatelessWidget {
  const CopySectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highlight = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        gradient: context.isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlight
                    ? [palette.goldSoft, palette.surface]
                    : [palette.surfaceRaised, palette.surface],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? copyGold.withValues(alpha: .88) : palette.border,
        ),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class CopyHeroCard extends StatelessWidget {
  const CopyHeroCard({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: copyGold.withValues(alpha: .9)),
    ),
    child: Stack(
      fit: StackFit.loose,
      children: [
        Positioned(
          right: -80,
          top: -70,
          width: 300,
          height: 300,
          child: Opacity(
            opacity: .54,
            child: Image.asset(
              'assets/affiliate/illustrations/dashboard_network_globe.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: .96),
                  Colors.black.withValues(alpha: .58),
                ],
              ),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.all(20), child: child),
      ],
    ),
  );
}

class CopyPageHeading extends StatelessWidget {
  const CopyPageHeading({
    super.key,
    required this.title,
    required this.goldTitle,
    required this.subtitle,
    this.icon,
  });

  final String title;
  final String goldTitle;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        CopyIconBadge(icon: icon!, size: 48),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 0,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  goldTitle,
                  style: const TextStyle(
                    color: copyGold,
                    fontSize: 27,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: copyMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  );
}

class CopySectionHeading extends StatelessWidget {
  const CopySectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

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
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(color: copyMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(action!, style: const TextStyle(color: copyGold)),
        ),
    ],
  );
}

class CopyIconBadge extends StatelessWidget {
  const CopyIconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.color = copyGold,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(size * .32),
      border: Border.all(color: color.withValues(alpha: .65)),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .12), blurRadius: 14),
      ],
    ),
    child: Icon(icon, color: color, size: size * .52),
  );
}

class CopyStatusPill extends StatelessWidget {
  const CopyStatusPill({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final color = switch (normalized) {
      'ACTIVE' || 'READY' || 'CONNECTED' => copyGreen,
      'REJECTED' || 'SUSPENDED' || 'DISCONNECTED' => copyRed,
      _ => copyGold,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              normalized.replaceAll('_', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CopyBrokerLogo extends StatefulWidget {
  const CopyBrokerLogo({
    super.key,
    required this.useCases,
    required this.name,
    this.logoUrl,
    this.size = 58,
  });

  final CopyTradingUseCases useCases;
  final String name;
  final String? logoUrl;
  final double size;

  @override
  State<CopyBrokerLogo> createState() => _CopyBrokerLogoState();
}

class _CopyBrokerLogoState extends State<CopyBrokerLogo> {
  Future<Uint8List>? _logo;

  @override
  void initState() {
    super.initState();
    if (widget.logoUrl case final url? when url.isNotEmpty) {
      _logo = widget.useCases.loadBrokerLogo(url);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: widget.size,
    height: widget.size,
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: copyGold.withValues(alpha: .45)),
    ),
    child: _logo == null
        ? _initials()
        : FutureBuilder<Uint8List>(
            future: _logo,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                );
              }
              if (snapshot.hasError) return _initials();
              return const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
          ),
  );

  Widget _initials() {
    final words = widget.name.trim().split(RegExp(r'\s+'));
    final letters = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    return Text(
      letters.isEmpty ? 'TX' : letters,
      style: const TextStyle(
        color: copyGold,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class CopyMarketIcon extends StatelessWidget {
  const CopyMarketIcon({super.key, required this.market, this.size = 44});
  final String market;
  final double size;

  @override
  Widget build(BuildContext context) {
    final category = market.toUpperCase();
    final asset = switch (category) {
      'FOREX' => 'assets/branding/market_forex.png',
      'CRYPTO' => 'assets/branding/market_crypto.png',
      'DERIV' => 'assets/branding/market_deriv.png',
      _ => null,
    };
    if (asset == null) {
      return CopyIconBadge(icon: Icons.candlestick_chart_rounded, size: size);
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: copyGold.withValues(alpha: .5)),
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class CopyPrimaryButton extends StatelessWidget {
  const CopyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFDE67), Color(0xFFFFB913)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.black38,
          foregroundColor: Colors.black,
          shadowColor: Colors.transparent,
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    ),
  );
}

class CopyEmptyState extends StatelessWidget {
  const CopyEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.action,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => CopySectionCard(
    child: Column(
      children: [
        CopyIconBadge(icon: icon, size: 52),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: copyMuted, height: 1.4),
        ),
        if (action != null) ...[
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onAction,
            child: Text(action!, style: const TextStyle(color: copyGold)),
          ),
        ],
      ],
    ),
  );
}

class CopyLoadingState extends StatelessWidget {
  const CopyLoadingState({super.key});
  @override
  Widget build(BuildContext context) => const CopyTradingPage(
    child: Center(child: CircularProgressIndicator(color: copyGold)),
  );
}

class CopyErrorState extends StatelessWidget {
  const CopyErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CopyTradingPage(
    child: Center(
      child: CopyEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Copy Trading unavailable',
        message: message,
        action: 'Try again',
        onAction: onRetry,
      ),
    ),
  );
}

String copyAccountId(CopyTradingAccount account) => account.uuid;

String copyAccountStatus(CopyTradingAccount account) => account.status;

String copyAccountMarket(CopyTradingAccount account) => account.marketCategory;

CopyTradingBrokerMarket copyAccountBroker(CopyTradingAccount account) =>
    account.broker;
