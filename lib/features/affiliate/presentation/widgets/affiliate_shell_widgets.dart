part of '../affiliate_module.dart';

class AffiliateScaffold extends StatelessWidget {
  const AffiliateScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.dashboardHeader = false,
    this.showBrand = true,
    this.onMenu,
    this.onNotifications,
    this.onRefresh,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final bool dashboardHeader;
  final bool showBrand;
  final VoidCallback? onMenu;
  final VoidCallback? onNotifications;
  final Future<void> Function()? onRefresh;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Row(
          children: [
            if (!dashboardHeader)
              IconButton(
                onPressed: showBack
                    ? () => Navigator.maybePop(context)
                    : onMenu,
                icon: Icon(
                  showBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
                ),
                color: _gold,
                tooltip: showBack ? 'Back' : 'Affiliate menu',
              ),
            if (!dashboardHeader && showBrand) ...[
              const SizedBox(width: 6),
              Image.asset(
                _AffiliateAssets.brandLogo,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                semanticLabel: 'TradeX logo',
              ),
            ],
            if (dashboardHeader)
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else
              const Spacer(),
            ...actions,
            if (onNotifications != null)
              IconButton(
                onPressed: onNotifications,
                icon: const Icon(
                  TradeXIcons.notifications,
                  semanticLabel: 'Notifications',
                ),
                color: _gold,
                tooltip: 'Notifications',
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (!dashboardHeader) ...[
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
        ],
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 14)),
        const SizedBox(height: 20),
        child,
      ],
    );
    return Material(
      color: context.palette.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.75, -0.95),
            radius: 1.15,
            colors: [
              context.palette.gold.withValues(
                alpha: context.isDarkMode ? .07 : .035,
              ),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: onRefresh == null
              ? content
              : RefreshIndicator(
                  color: _gold,
                  onRefresh: onRefresh!,
                  child: content,
                ),
        ),
      ),
    );
  }
}

class AffiliateStateBody extends StatelessWidget {
  const AffiliateStateBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onUpgrade,
    required this.builder,
  });

  final AffiliateLoadState state;
  final VoidCallback onRetry;
  final VoidCallback onUpgrade;
  final Widget Function(JsonMap data) builder;

  @override
  Widget build(BuildContext context) => switch (state.status) {
    AffiliateLoadStatus.initial ||
    AffiliateLoadStatus.loading => const LoadingSkeleton(),
    AffiliateLoadStatus.premium => PremiumGate(
      message: state.message,
      onUpgrade: onUpgrade,
    ),
    AffiliateLoadStatus.failure => _ErrorCard(
      message: state.message ?? 'Unable to load this screen.',
      onRetry: onRetry,
    ),
    AffiliateLoadStatus.empty => const _EmptyCard(
      message: 'No affiliate data is available yet.',
    ),
    AffiliateLoadStatus.ready => builder(state.data),
  };
}

class AffiliateHero extends StatelessWidget {
  const AffiliateHero({
    super.key,
    required this.commissionRate,
    required this.onInvite,
  });

  final String commissionRate;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 350;
      final palette = context.palette;
      final height = compact ? 218.0 : 228.0;
      return Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.surface,
          gradient: context.isDarkMode
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.surfaceRaised, palette.surface],
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.gold, width: 1.2),
          boxShadow: TradeXElevation.surface(
            brightness: Theme.of(context).brightness,
            palette: palette,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              bottom: -42,
              child: Container(
                width: compact ? 150 : 170,
                height: compact ? 150 : 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.goldSoft.withValues(alpha: .7),
                ),
              ),
            ),
            Positioned(
              right: compact ? 18 : 24,
              top: 22,
              child: Container(
                width: compact ? 66 : 74,
                height: compact ? 66 : 74,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: palette.gold.withValues(alpha: .55),
                  ),
                ),
                child: Icon(
                  Icons.group_add_rounded,
                  color: palette.goldText,
                  size: compact ? 34 : 38,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 18, compact ? 92 : 112, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TURN',
                    style: TextStyle(
                      color: palette.goldText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'YOUR NETWORK',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: compact ? 18 : 21,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'INTO REWARDS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.goldText,
                      fontSize: compact ? 18 : 21,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Share TradeX with your friends and earn up to $commissionRate% commission on every qualified sale.',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.secondaryText,
                      fontSize: compact ? 11.5 : 12.5,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  GoldActionButton(
                    label: 'Invite Now',
                    onPressed: onInvite,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 122,
        padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
        decoration: _dashboardCardDecoration(context),
        child: Stack(
          children: [
            Positioned(
              right: -3,
              top: -4,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.palette.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: context.palette.goldText, size: 25),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 44),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CommissionRewardBanner extends StatelessWidget {
  const _CommissionRewardBanner({
    required this.commissionRate,
    required this.onTap,
  });

  final String commissionRate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: _dashboardCardDecoration(context, goldAccent: true),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: context.palette.goldSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: context.palette.goldText,
              size: 30,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earn up to $commissionRate% Commission',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'And unlock milestone rewards',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.palette.goldText),
        ],
      ),
    ),
  );
}

class AffiliateMetricCard extends StatelessWidget {
  const AffiliateMetricCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.assetPath,
    this.subtitle,
    this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final String? assetPath;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: SectionCard(
      onTap: onTap,
      child: SizedBox(
        height: 128,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(color: _muted)),
                ),
                if (assetPath == null)
                  _GoldIcon(icon)
                else
                  _AffiliateArt(path: assetPath!, fallback: icon, size: 42),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(color: _gold, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class ReferralLinkPanel extends StatelessWidget {
  const ReferralLinkPanel({
    super.key,
    required this.code,
    required this.onCopy,
    required this.onWhatsApp,
    required this.onTelegram,
    required this.onShare,
    required this.onQr,
  });

  final String code;
  final VoidCallback onCopy;
  final VoidCallback onWhatsApp;
  final VoidCallback onTelegram;
  final VoidCallback onShare;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _dashboardCardDecoration(context, goldAccent: true),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Referral Code', style: _sectionTitle),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: _fieldDecoration(context),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code.isEmpty ? 'Referral code unavailable' : code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: code.isEmpty ? null : onCopy,
                icon: const Icon(Icons.copy_rounded),
                color: _gold,
                tooltip: 'Copy referral code',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ShareButton(
                'WhatsApp',
                Icons.chat_rounded,
                const Color(0xFF25D366),
                onWhatsApp,
                assetPath: _AffiliateAssets.whatsapp,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                'Telegram',
                Icons.send_rounded,
                const Color(0xFF229ED9),
                onTelegram,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                'Share',
                Icons.share_rounded,
                _muted,
                onShare,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                'QR Code',
                Icons.qr_code_2_rounded,
                _gold,
                onQr,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ShareButton extends StatelessWidget {
  const _ShareButton(
    this.label,
    this.icon,
    this.color,
    this.onTap, {
    this.assetPath,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? assetPath;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: _fieldDecoration(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath == null)
              Icon(icon, color: color)
            else
              SvgPicture.asset(assetPath!, width: 24, height: 24),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}
