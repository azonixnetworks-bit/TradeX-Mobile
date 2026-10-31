import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';

const fundedGold = TradeXColors.goldBright;
const fundedMuted = TradeXColors.secondaryText;

class FundedPage extends StatelessWidget {
  const FundedPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onRefresh,
    this.actions = const <Widget>[],
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: [
        Row(
          children: [
            if (showBack) ...[
              FundedIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: fundedMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
    return Scaffold(
      backgroundColor: TradeXColors.background,
      body: SafeArea(
        child: onRefresh == null
            ? content
            : RefreshIndicator(
                color: fundedGold,
                backgroundColor: TradeXColors.surfaceRaised,
                onRefresh: onRefresh!,
                child: content,
              ),
      ),
    );
  }
}

class FundedIconButton extends StatelessWidget {
  const FundedIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: TradeXColors.surfaceRaised,
      side: const BorderSide(color: TradeXColors.borderStrong),
    ),
    icon: Icon(icon, color: fundedGold),
  );
}

class FundedCard extends StatelessWidget {
  const FundedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gold = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool gold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    final content = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gold
              ? const [TradeXColors.goldSoft, TradeXColors.surface]
              : const [TradeXColors.surfaceRaised, TradeXColors.surface],
        ),
        borderRadius: radius,
        border: Border.all(
          color: gold
              ? TradeXColors.gold.withValues(alpha: .72)
              : TradeXColors.borderStrong,
        ),
        boxShadow: gold
            ? [
                BoxShadow(
                  color: fundedGold.withValues(alpha: .08),
                  blurRadius: 22,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: radius, child: content),
      ),
    );
  }
}

class FundedPill extends StatelessWidget {
  const FundedPill({
    super.key,
    required this.label,
    this.selected = false,
    this.color,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? fundedGold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: .18)
              : TradeXColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : TradeXColors.borderStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : TradeXColors.secondaryText,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class FundedPrimaryButton extends StatelessWidget {
  const FundedPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: TradeXColors.gold,
        foregroundColor: const Color(0xFF11151B),
        disabledBackgroundColor: TradeXColors.surfaceMuted,
        disabledForegroundColor: TradeXColors.tertiaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

class FundedEmptyState extends StatelessWidget {
  const FundedEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => FundedCard(
    gold: true,
    child: Column(
      children: [
        const Icon(Icons.shield_outlined, color: fundedGold, size: 42),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: fundedMuted, height: 1.45),
        ),
        if (action != null && onAction != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(action!),
          ),
        ],
      ],
    ),
  );
}

class FundedStatusNotice extends StatelessWidget {
  const FundedStatusNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: TradeXColors.warning.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TradeXColors.warning.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_off_rounded, color: TradeXColors.warning),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class FundedSectionTitle extends StatelessWidget {
  const FundedSectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(color: fundedMuted, fontSize: 12),
          ),
      ],
    ),
  );
}
