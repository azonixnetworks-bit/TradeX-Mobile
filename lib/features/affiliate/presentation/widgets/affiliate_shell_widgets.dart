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
            IconButton(
              onPressed: showBack ? () => Navigator.maybePop(context) : onMenu,
              icon: dashboardHeader
                  ? Image.asset(
                      _AffiliateAssets.dashboardMenu,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      semanticLabel: 'Affiliate menu',
                    )
                  : Icon(
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
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 14)),
        const SizedBox(height: 20),
        child,
      ],
    );
    return Material(
      color: TradeXColors.background,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.75, -0.95),
            radius: 1.15,
            colors: [Color(0x27261D08), Colors.transparent],
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
      final height = compact ? 244.0 : 256.0;
      return Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF13150F), Color(0xFF050A09), Color(0xFF231A05)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7B820), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x35FFC83D), blurRadius: 24),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardSparkles,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(.55),
                ),
              ),
            ),
            Positioned(
              right: compact ? -58 : -44,
              bottom: -34,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardGlobe,
                  width: compact ? 218 : 232,
                  height: compact ? 218 : 232,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: compact ? -2 : 8,
              bottom: 6,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardGift,
                  width: compact ? 92 : 104,
                  height: compact ? 92 : 104,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: compact ? -10 : 0,
              top: 2,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardGrowthArrow,
                  width: compact ? 74 : 84,
                  height: compact ? 74 : 84,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: compact ? 66 : 78,
              bottom: 4,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardDollarCoin,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xF2050A09),
                      Color(0x9A050A09),
                      Colors.transparent,
                    ],
                    stops: [0, .48, .78],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, compact ? 88 : 102, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TURN',
                    style: TextStyle(
                      color: _gold,
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
                      color: Colors.white,
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
                      color: _gold,
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
                      color: const Color(0xFFC5D0E2),
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
    required this.assetPath,
    required this.onTap,
    this.subtitle,
  });

  final double width;
  final String label;
  final String value;
  final String assetPath;
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
        decoration: _dashboardCardDecoration(),
        child: Stack(
          children: [
            Positioned(
              right: -3,
              top: -4,
              child: Image.asset(
                assetPath,
                width: 55,
                height: 55,
                fit: BoxFit.contain,
                semanticLabel: '$label icon',
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
                    style: const TextStyle(
                      color: Color(0xFFB8C6DC),
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    style: const TextStyle(
                      color: Color(0xFFC6D0E0),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF321405), Color(0xFF0A110F), Color(0xFF2A2107)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5AD00)),
        boxShadow: const [BoxShadow(color: Color(0x2AFFC83D), blurRadius: 18)],
      ),
      child: Row(
        children: [
          Image.asset(
            _AffiliateAssets.dashboardGift,
            width: 66,
            height: 66,
            fit: BoxFit.contain,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'And unlock milestone rewards',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFB9C6D9), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Image.asset(
            _AffiliateAssets.dashboardSmallArrow,
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
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
    decoration: _dashboardCardDecoration(goldAccent: true),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Referral Code', style: _sectionTitle),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.only(left: 14),
          decoration: _fieldDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code.isEmpty ? 'Referral code unavailable' : code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
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
                assetPath: _AffiliateAssets.dashboardWhatsApp,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                'Telegram',
                Icons.send_rounded,
                const Color(0xFF229ED9),
                onTelegram,
                assetPath: _AffiliateAssets.dashboardTelegram,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                'Share',
                Icons.share_rounded,
                _muted,
                onShare,
                assetPath: _AffiliateAssets.dashboardShare,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShareButton(
                'QR Code',
                Icons.qr_code_2_rounded,
                _gold,
                onQr,
                assetPath: _AffiliateAssets.dashboardQr,
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
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: assetPath?.endsWith('.png') ?? false
          ? SizedBox(
              height: 56,
              child: Image.asset(
                assetPath!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            )
          : Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: _fieldDecoration(),
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
