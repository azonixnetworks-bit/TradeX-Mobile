import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/affiliate_repository.dart';
import 'bloc/affiliate_cubits.dart';
import 'services/affiliate_share_card_service.dart';

const _gold = TradeXColors.goldBright;
const _muted = TradeXColors.secondaryText;
const _purple = Color(0xFFA855F7);

abstract final class _AffiliateAssets {
  static const gift = 'assets/affiliate/illustrations/gift_gold.png';
  static const money = 'assets/affiliate/illustrations/money_gold.png';
  static const crown = 'assets/affiliate/illustrations/crown_gold.png';
  static const wallet = 'assets/affiliate/illustrations/wallet_gold.png';
  static const trophy = 'assets/affiliate/illustrations/trophy_silver.png';
  static const paypal = 'assets/affiliate/brands/paypal.svg';
  static const tether = 'assets/affiliate/brands/tether.svg';
  static const binance = 'assets/affiliate/brands/binance.svg';
  static const dashboardGlobe =
      'assets/affiliate/illustrations/dashboard_network_globe.png';
  static const dashboardGift =
      'assets/affiliate/illustrations/dashboard_gift_box.png';
  static const dashboardGrowthArrow =
      'assets/affiliate/illustrations/dashboard_growth_arrow.png';
  static const dashboardSmallArrow =
      'assets/affiliate/illustrations/dashboard_small_arrow.png';
  static const dashboardDollarCoin =
      'assets/affiliate/illustrations/dashboard_dollar_coin.png';
  static const dashboardSparkles =
      'assets/affiliate/illustrations/dashboard_sparkles.png';
  static const dashboardEarnings =
      'assets/affiliate/illustrations/dashboard_earnings_icon.png';
  static const dashboardSales =
      'assets/affiliate/illustrations/dashboard_sales_icon.png';
  static const dashboardReferrals =
      'assets/affiliate/illustrations/dashboard_referrals_icon.png';
  static const dashboardLevel =
      'assets/affiliate/illustrations/dashboard_level_icon.png';
  static const dashboardMenu =
      'assets/affiliate/illustrations/dashboard_menu_icon.png';
  static const dashboardBell =
      'assets/affiliate/illustrations/dashboard_notification_bell.png';
  static const dashboardWhatsApp =
      'assets/affiliate/illustrations/dashboard_whatsapp_button.png';
  static const dashboardTelegram =
      'assets/affiliate/illustrations/dashboard_telegram_button.png';
  static const dashboardShare =
      'assets/affiliate/illustrations/dashboard_share_button.png';
  static const dashboardQr =
      'assets/affiliate/illustrations/dashboard_qr_button.png';
}

class AffiliateDashboardScreen extends StatelessWidget {
  const AffiliateDashboardScreen({
    super.key,
    required this.apiClient,
    required this.onUpgrade,
    required this.onConfigurePayoutMethod,
    this.onNotifications,
  });

  final TradeXApiClient apiClient;
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigurePayoutMethod;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final repository = AffiliateRepository(apiClient);
    return BlocProvider(
      create: (_) => AffiliateLoadCubit(repository.overview)..load(),
      child: _DashboardBody(
        repository: repository,
        onUpgrade: onUpgrade,
        onConfigurePayoutMethod: onConfigurePayoutMethod,
        onNotifications: onNotifications,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.repository,
    required this.onUpgrade,
    required this.onConfigurePayoutMethod,
    this.onNotifications,
  });

  final AffiliateRepository repository;
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigurePayoutMethod;
  final VoidCallback? onNotifications;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TradeXColors.surfaceRaised,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuTile(
                icon: Icons.people_alt_outlined,
                label: 'My Referrals',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliateReferralsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.bar_chart_rounded,
                label: 'Earnings & Sales',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliateEarningsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.workspace_premium_outlined,
                label: 'Levels & Rewards',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliateLevelsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                    ),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Payouts & Withdrawals',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(
                    context,
                    AffiliatePayoutsScreen(
                      repository: repository,
                      onUpgrade: onUpgrade,
                      onConfigureMethod: onConfigurePayoutMethod,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
      builder: (context, state) => AffiliateScaffold(
        showBack: false,
        dashboardHeader: true,
        title: 'Affiliate Dashboard',
        subtitle: 'Invite traders. Grow together. Earn rewards.',
        onMenu: () => _openMenu(context),
        onNotifications: onNotifications,
        onRefresh: context.read<AffiliateLoadCubit>().load,
        child: AffiliateStateBody(
          state: state,
          onRetry: context.read<AffiliateLoadCubit>().load,
          onUpgrade: onUpgrade,
          builder: (data) => _DashboardContent(
            data: data,
            repository: repository,
            openReferrals: () => _open(
              context,
              AffiliateReferralsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
              ),
            ),
            openEarnings: () => _open(
              context,
              AffiliateEarningsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
              ),
            ),
            openLevels: () => _open(
              context,
              AffiliateLevelsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
              ),
            ),
            openPayouts: () => _open(
              context,
              AffiliatePayoutsScreen(
                repository: repository,
                onUpgrade: onUpgrade,
                onConfigureMethod: onConfigurePayoutMethod,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.repository,
    required this.openReferrals,
    required this.openEarnings,
    required this.openLevels,
    required this.openPayouts,
  });

  final JsonMap data;
  final AffiliateRepository repository;
  final VoidCallback openReferrals;
  final VoidCallback openEarnings;
  final VoidCallback openLevels;
  final VoidCallback openPayouts;

  Future<void> _shareExternal(BuildContext context, String channel) async {
    try {
      final result = await repository.shareAction(channel);
      final url = Uri.tryParse(
        AffiliateRepository.text(result['external_share_url'], ''),
      );
      if (url == null ||
          !await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw const ApiException(message: 'The share app could not be opened.');
      }
    } catch (error) {
      if (context.mounted) _snack(context, _message(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final referral = AffiliateRepository.mapOf(data['referral']);
    final financials = AffiliateRepository.mapOf(data['financials']);
    final stage = AffiliateRepository.mapOf(data['current_stage']);
    final commission = AffiliateRepository.mapOf(data['commission']);
    final url = AffiliateRepository.text(referral['url'], '');
    final code = AffiliateRepository.text(referral['code'], '');
    final rate = AffiliateRepository.text(
      commission['next_sale_rate_percent'],
      '0.00',
    );
    final direct = AffiliateRepository.integer(
      referral['direct_referrals_count'],
    );
    final sales = AffiliateRepository.integer(data['qualified_sales_count']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AffiliateHero(
          commissionRate: rate,
          onInvite: () => _nativeShare(context, url),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DashboardMetricCard(
                  width: width,
                  label: 'Total Earnings',
                  value: AffiliateRepository.moneyText(
                    financials['lifetime_commission_earned'],
                  ),
                  assetPath: _AffiliateAssets.dashboardEarnings,
                  onTap: openEarnings,
                ),
                _DashboardMetricCard(
                  width: width,
                  label: 'Qualified Sales',
                  value: '$sales',
                  assetPath: _AffiliateAssets.dashboardSales,
                  onTap: openEarnings,
                ),
                _DashboardMetricCard(
                  width: width,
                  label: 'Total Referrals',
                  value: '$direct',
                  assetPath: _AffiliateAssets.dashboardReferrals,
                  onTap: openReferrals,
                ),
                _DashboardMetricCard(
                  width: width,
                  label: 'Current Level',
                  value: AffiliateRepository.text(stage['name']),
                  subtitle: '$rate% commission',
                  assetPath: _AffiliateAssets.dashboardLevel,
                  onTap: openLevels,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        ReferralLinkPanel(
          code: code,
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) _snack(context, 'Referral code copied.');
          },
          onWhatsApp: () => _shareExternal(context, 'WHATSAPP'),
          onTelegram: () => _shareExternal(context, 'TELEGRAM'),
          onShare: () => _shareAffiliateIncomeCard(
            context,
            referralUrl: url,
            referralCode: code,
            earnings: AffiliateRepository.moneyText(
              financials['lifetime_commission_earned'],
            ),
          ),
          onQr: () => _showQr(context, url),
        ),
        const SizedBox(height: 16),
        _CommissionRewardBanner(commissionRate: rate, onTap: openPayouts),
      ],
    );
  }
}

class AffiliateScaffold extends StatelessWidget {
  const AffiliateScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.dashboardHeader = false,
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
            if (!dashboardHeader) ...[
              const SizedBox(width: 6),
              const Text(
                'Trade',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const Text(
                'X',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _gold,
                ),
              ),
            ],
            const Spacer(),
            ...actions,
            if (onNotifications != null)
              IconButton(
                onPressed: onNotifications,
                icon: dashboardHeader
                    ? Image.asset(
                        _AffiliateAssets.dashboardBell,
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                        semanticLabel: 'Notifications',
                      )
                    : const Icon(Icons.notifications_none_rounded),
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
      final height = compact ? 270.0 : 286.0;
      return Container(
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
              right: compact ? -72 : -54,
              bottom: -44,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardGlobe,
                  width: compact ? 245 : 275,
                  height: compact ? 245 : 275,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: compact ? -6 : 4,
              bottom: 8,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardGift,
                  width: compact ? 108 : 126,
                  height: compact ? 108 : 126,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: compact ? -18 : -8,
              top: 1,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardGrowthArrow,
                  width: compact ? 86 : 102,
                  height: compact ? 86 : 102,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: compact ? 72 : 92,
              bottom: 4,
              child: IgnorePointer(
                child: Image.asset(
                  _AffiliateAssets.dashboardDollarCoin,
                  width: 50,
                  height: 50,
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
              padding: EdgeInsets.fromLTRB(18, 20, compact ? 100 : 118, 18),
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
                  const SizedBox(height: 13),
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
                  GoldActionButton(label: 'Invite Now', onPressed: onInvite),
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
    padding: const EdgeInsets.all(16),
    decoration: _dashboardCardDecoration(goldAccent: true),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Referral Code', style: _sectionTitle),
        const SizedBox(height: 12),
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
        const SizedBox(height: 14),
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
          ? AspectRatio(
              aspectRatio: 1.2,
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

class AffiliateReferralsScreen extends StatelessWidget {
  const AffiliateReferralsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
  });

  final AffiliateRepository repository;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReferralCubit(repository)..load(),
    child: _ReferralsBody(onUpgrade: onUpgrade),
  );
}

class _ReferralsBody extends StatelessWidget {
  const _ReferralsBody({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReferralCubit, ReferralState>(
      builder: (context, state) => AffiliateScaffold(
        title: 'My Referrals',
        subtitle: 'Your direct referral network and qualified sales.',
        onRefresh: context.read<ReferralCubit>().load,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: context.read<ReferralCubit>().search,
                    decoration: const InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<ReferralFilter>(
                  tooltip: 'Filter referrals',
                  initialValue: state.filter,
                  onSelected: context.read<ReferralCubit>().filter,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: ReferralFilter.all,
                      child: Text('All referrals'),
                    ),
                    PopupMenuItem(
                      value: ReferralFilter.qualified,
                      child: Text('Qualified'),
                    ),
                    PopupMenuItem(
                      value: ReferralFilter.noSale,
                      child: Text('No qualified sale'),
                    ),
                  ],
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: _fieldDecoration(),
                    child: const Icon(Icons.filter_list_rounded, color: _gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final entry in const [
                  (ReferralFilter.all, 'All'),
                  (ReferralFilter.qualified, 'Qualified'),
                  (ReferralFilter.noSale, 'No sale'),
                ]) ...[
                  Expanded(
                    child: _FilterButton(
                      label: entry.$2,
                      selected: state.filter == entry.$1,
                      onTap: () =>
                          context.read<ReferralCubit>().filter(entry.$1),
                    ),
                  ),
                  if (entry.$1 != ReferralFilter.noSale)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (state.status == AffiliateLoadStatus.loading &&
                state.items.isEmpty)
              const LoadingSkeleton()
            else if (state.status == AffiliateLoadStatus.premium)
              PremiumGate(message: state.message, onUpgrade: onUpgrade)
            else if (state.status == AffiliateLoadStatus.failure)
              _ErrorCard(
                message: state.message ?? 'Unable to load referrals.',
                onRetry: context.read<ReferralCubit>().load,
              )
            else if (state.items.isEmpty)
              const _EmptyCard(
                message: 'No direct referrals match this filter.',
              )
            else ...[
              for (final referral in state.items) ...[
                ReferralTile(data: referral),
                const SizedBox(height: 10),
              ],
              if (state.page < state.lastPage)
                OutlinedButton.icon(
                  onPressed: state.loadingMore
                      ? null
                      : context.read<ReferralCubit>().loadMore,
                  icon: state.loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: const Text('Load more'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReferralTile extends StatelessWidget {
  const ReferralTile({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final name = AffiliateRepository.text(data['name']);
    final qualification = AffiliateRepository.mapOf(data['qualification']);
    final qualified = AffiliateRepository.boolean(
      qualification['has_qualified_sale'],
    );
    final sales = AffiliateRepository.integer(
      qualification['active_qualified_sales_count'],
    );
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _InitialAvatar(name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_date(data['joined_at'])}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: qualified ? 'Qualified' : 'No sale',
                color: qualified ? TradeXColors.success : TradeXColors.warning,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AffiliateArt(
                    path: _AffiliateAssets.gift,
                    fallback: Icons.card_giftcard_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$sales ${sales == 1 ? 'sale' : 'sales'}',
                    style: const TextStyle(color: _gold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AffiliateEarningsScreen extends StatefulWidget {
  const AffiliateEarningsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
  });
  final AffiliateRepository repository;
  final VoidCallback onUpgrade;

  @override
  State<AffiliateEarningsScreen> createState() =>
      _AffiliateEarningsScreenState();
}

class _AffiliateEarningsScreenState extends State<AffiliateEarningsScreen> {
  int months = 1;

  Future<JsonMap> _load() async {
    final values = await Future.wait([
      widget.repository.overview(),
      widget.repository.earningsSeries(months: months == 0 ? 12 : months),
      widget.repository.commissions(perPage: 20),
    ]);
    return {
      'overview': values[0],
      'series': values[1],
      'commissions': values[2],
    };
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(months),
    create: (_) => AffiliateLoadCubit(_load)..load(),
    child: Builder(
      builder: (context) => BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
        builder: (context, state) => AffiliateScaffold(
          title: 'Earnings & Sales',
          subtitle: 'Track commission income and qualified sales.',
          onRefresh: context.read<AffiliateLoadCubit>().load,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in const [
                      (1, 'This Month'),
                      (3, 'Last 3 Months'),
                      (6, 'Last 6 Months'),
                      (0, 'All'),
                    ]) ...[
                      _FilterButton(
                        label: option.$2,
                        selected: months == option.$1,
                        onTap: () => setState(() => months = option.$1),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AffiliateStateBody(
                state: state,
                onRetry: context.read<AffiliateLoadCubit>().load,
                onUpgrade: widget.onUpgrade,
                builder: (data) => EarningsContent(data: data),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EarningsContent extends StatelessWidget {
  const EarningsContent({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final overview = AffiliateRepository.mapOf(data['overview']);
    final financials = AffiliateRepository.mapOf(overview['financials']);
    final commission = AffiliateRepository.mapOf(overview['commission']);
    final series = AffiliateRepository.mapOf(data['series']);
    final points = AffiliateRepository.listOf(series['items']);
    final commissionsData = AffiliateRepository.mapOf(data['commissions']);
    final entries = AffiliateRepository.listOf(commissionsData['items']);
    final sales = AffiliateRepository.integer(
      overview['qualified_sales_count'],
    );
    final rate = AffiliateRepository.text(
      commission['next_sale_rate_percent'],
      '0.00',
    );
    return Column(
      children: [
        SectionCard(
          borderColor: TradeXColors.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _AffiliateArt(
                    path: _AffiliateAssets.money,
                    fallback: Icons.stacked_line_chart_rounded,
                    size: 56,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Total Commission Earned',
                      style: _sectionTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AffiliateRepository.moneyText(
                  financials['lifetime_commission_earned'],
                ),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(height: 210, child: EarningsChart(points: points)),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 10, height: 10, color: _gold),
                    const SizedBox(width: 6),
                    const Text(
                      'Net commission',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      AffiliateRepository.text(points.first['label']),
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–', style: TextStyle(color: _muted)),
                    ),
                    Text(
                      AffiliateRepository.text(points.last['label']),
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AffiliateMetricCard(
                width: double.infinity,
                label: 'Qualified Sales',
                value: '$sales',
                icon: Icons.shopping_cart_outlined,
                assetPath: _AffiliateAssets.gift,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AffiliateMetricCard(
                width: double.infinity,
                label: 'Commission Rate',
                value: '$rate%',
                icon: Icons.percent_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionHeading(title: 'Recent Commissions'),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const _EmptyCard(message: 'No commission records yet.')
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  CommissionTile(data: entries[index]),
                  if (index != entries.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key, required this.points});
  final List<JsonMap> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('No chart data', style: TextStyle(color: _muted)),
      );
    }
    return CustomPaint(painter: _EarningsChartPainter(points));
  }
}

class _EarningsChartPainter extends CustomPainter {
  _EarningsChartPainter(this.points);
  final List<JsonMap> points;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points
        .map((item) => AffiliateRepository.money(item['net_commission']))
        .toList(growable: false);
    final maxValue = math.max(1.0, values.fold<double>(0, math.max));
    final gap = 6.0;
    final width = math.max(
      4.0,
      (size.width - gap * (values.length - 1)) / values.length,
    );
    final baseline = size.height - 24;
    final grid = Paint()..color = TradeXColors.border;
    for (var index = 0; index < 4; index++) {
      final y = index * baseline / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final bar = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [TradeXColors.goldDeep, _gold],
      ).createShader(Offset.zero & size);
    for (var index = 0; index < values.length; index++) {
      final height = values[index] / maxValue * (baseline - 10);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(index * (width + gap), baseline - height, width, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, bar);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class CommissionTile extends StatelessWidget {
  const CommissionTile({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final status = AffiliateRepository.text(data['status']);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const _GoldIcon(Icons.receipt_long_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commission #${AffiliateRepository.integer(data['qualified_ordinal'])}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _date(data['earned_at']),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${AffiliateRepository.moneyText(data['net_commission'])}',
                style: const TextStyle(
                  color: TradeXColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${AffiliateRepository.text(data['rate_percent'], '0.00')}% · $status',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AffiliateLevelsScreen extends StatelessWidget {
  const AffiliateLevelsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
  });
  final AffiliateRepository repository;
  final VoidCallback onUpgrade;

  Future<JsonMap> _load() async {
    final values = await Future.wait([
      repository.overview(),
      repository.stages(),
      repository.milestones(),
    ]);
    return {
      'overview': values[0],
      'stages': values[1],
      'milestones': values[2],
    };
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AffiliateLoadCubit(_load)..load(),
    child: Builder(
      builder: (context) => BlocBuilder<AffiliateLoadCubit, AffiliateLoadState>(
        builder: (context, state) => AffiliateScaffold(
          title: 'Levels & Rewards',
          subtitle: 'Progress with every qualified paid sale.',
          onRefresh: context.read<AffiliateLoadCubit>().load,
          child: AffiliateStateBody(
            state: state,
            onRetry: context.read<AffiliateLoadCubit>().load,
            onUpgrade: onUpgrade,
            builder: (data) => LevelsContent(data: data),
          ),
        ),
      ),
    ),
  );
}

class LevelsContent extends StatelessWidget {
  const LevelsContent({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final overview = AffiliateRepository.mapOf(data['overview']);
    final current = AffiliateRepository.mapOf(overview['current_stage']);
    final next = AffiliateRepository.mapOf(overview['next_stage']);
    final stagesData = AffiliateRepository.mapOf(data['stages']);
    final stages = AffiliateRepository.listOf(stagesData['items']);
    final milestones = AffiliateRepository.mapOf(overview['milestones']);
    final nextMilestone = AffiliateRepository.mapOf(milestones['next']);
    final sales = AffiliateRepository.integer(
      overview['qualified_sales_count'],
    );
    final nextTarget = AffiliateRepository.integer(
      next['starts_at_qualified_sales'],
    );
    final progress = nextTarget <= 0
        ? 1.0
        : (sales / nextTarget).clamp(0.0, 1.0);
    final currentCode = AffiliateRepository.text(current['code'], '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          borderColor: TradeXColors.gold,
          child: Column(
            children: [
              Row(
                children: [
                  _StageBadge(
                    code: AffiliateRepository.text(current['code'], 'STARTER'),
                    size: 76,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Level',
                          style: TextStyle(color: _muted),
                        ),
                        Text(
                          AffiliateRepository.text(
                            current['name'],
                            'Not started',
                          ),
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${AffiliateRepository.text(current['standard_commission_percent'], '0.00')}% commission',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (next.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Next Level',
                          style: TextStyle(color: _muted),
                        ),
                        Text(
                          AffiliateRepository.text(next['name']),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$nextTarget sales',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: _gold,
                  backgroundColor: TradeXColors.border,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('$sales qualified sales'),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (AffiliateRepository.boolean(milestones['eligible']) &&
            nextMilestone.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            borderColor: TradeXColors.goldSoft,
            child: Row(
              children: [
                const _GoldIcon(Icons.card_giftcard_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AffiliateRepository.integer(nextMilestone['remaining_qualified_sales'])} more qualified sales to ${AffiliateRepository.moneyText(nextMilestone['gift'])} milestone gift',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        const _SectionHeading(title: 'All Affiliate Levels'),
        const SizedBox(height: 10),
        if (stages.isEmpty)
          const _EmptyCard(message: 'No affiliate levels are configured.')
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < stages.length; index++) ...[
                  StageTile(
                    data: stages[index],
                    sales: sales,
                    currentCode: currentCode,
                  ),
                  if (index != stages.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class StageTile extends StatelessWidget {
  const StageTile({
    super.key,
    required this.data,
    required this.sales,
    required this.currentCode,
  });
  final JsonMap data;
  final int sales;
  final String currentCode;

  @override
  Widget build(BuildContext context) {
    final code = AffiliateRepository.text(data['code'], '');
    final range = AffiliateRepository.mapOf(data['qualified_sales_range']);
    final min = AffiliateRepository.integer(range['min']);
    final max = range['max'] == null
        ? null
        : AffiliateRepository.integer(range['max']);
    final milestone = AffiliateRepository.mapOf(data['milestone']);
    final current = code == currentCode;
    final achieved = sales >= min;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: current ? Border.all(color: _gold, width: 1.5) : null,
        color: current ? const Color(0x1AFFC83D) : Colors.transparent,
      ),
      child: Row(
        children: [
          _StageBadge(code: code),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        AffiliateRepository.text(data['name']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: 8),
                      const StatusChip(label: 'Current', color: _gold),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  max == null ? '$min+ sales' : '$min - $max sales',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AffiliateRepository.text(data['standard_commission_percent'], '0.00')}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (AffiliateRepository.money(milestone['gift']) > 0)
                Text(
                  AffiliateRepository.moneyText(milestone['gift']),
                  style: const TextStyle(color: _gold, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            current
                ? Icons.radio_button_checked
                : achieved
                ? Icons.check_circle_outline
                : Icons.lock_outline,
            color: current || achieved ? _gold : _muted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.code, this.size = 52});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = code.toUpperCase();
    final (color, icon) = switch (normalized) {
      'STARTER' => (const Color(0xFFCD7F32), Icons.stars_rounded),
      'GROWTH' => (const Color(0xFFC0C0C0), Icons.stars_rounded),
      'PRO' => (_gold, Icons.workspace_premium_rounded),
      'ELITE' => (const Color(0xFF248EFF), Icons.diamond_rounded),
      'DIAMOND' => (const Color(0xFF18CEDC), Icons.diamond_outlined),
      'AMBASSADOR' => (_purple, Icons.workspace_premium_outlined),
      _ => (const Color(0xFFFF5252), Icons.diamond_rounded),
    };
    final assetPath = switch (normalized) {
      'STARTER' || 'GROWTH' => _AffiliateAssets.trophy,
      'PRO' || 'AMBASSADOR' => _AffiliateAssets.crown,
      _ => null,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: .14),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .2), blurRadius: 12),
        ],
      ),
      child: assetPath == null
          ? Icon(icon, color: color, size: size * .52)
          : Padding(
              padding: EdgeInsets.all(size * .12),
              child: _AffiliateArt(
                path: assetPath,
                fallback: icon,
                size: size * .72,
                tint: normalized == 'PRO' ? null : color,
              ),
            ),
    );
  }
}

class AffiliatePayoutsScreen extends StatelessWidget {
  const AffiliatePayoutsScreen({
    super.key,
    required this.repository,
    required this.onUpgrade,
    required this.onConfigureMethod,
  });
  final AffiliateRepository repository;
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigureMethod;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PayoutCubit(repository)..load(),
    child: _PayoutsBody(
      onUpgrade: onUpgrade,
      onConfigureMethod: onConfigureMethod,
    ),
  );
}

class _PayoutsBody extends StatelessWidget {
  const _PayoutsBody({
    required this.onUpgrade,
    required this.onConfigureMethod,
  });
  final VoidCallback onUpgrade;
  final ValueChanged<String> onConfigureMethod;

  @override
  Widget build(BuildContext context) => BlocBuilder<PayoutCubit, PayoutState>(
    builder: (context, state) => AffiliateScaffold(
      title: 'Payouts & Withdrawals',
      subtitle: 'View available earnings and withdrawal requests.',
      onRefresh: context.read<PayoutCubit>().load,
      child: switch (state.status) {
        AffiliateLoadStatus.initial ||
        AffiliateLoadStatus.loading => const LoadingSkeleton(),
        AffiliateLoadStatus.premium => PremiumGate(
          message: state.message,
          onUpgrade: onUpgrade,
        ),
        AffiliateLoadStatus.failure => _ErrorCard(
          message: state.message ?? 'Payouts are unavailable.',
          onRetry: context.read<PayoutCubit>().load,
        ),
        AffiliateLoadStatus.ready || AffiliateLoadStatus.empty =>
          PayoutsContent(state: state, onConfigureMethod: onConfigureMethod),
      },
    ),
  );
}

class PayoutsContent extends StatelessWidget {
  const PayoutsContent({
    super.key,
    required this.state,
    required this.onConfigureMethod,
  });
  final PayoutState state;
  final ValueChanged<String> onConfigureMethod;

  String _eligibilityMessage(JsonMap summary, List<JsonMap> methods) {
    final kyc = AffiliateRepository.mapOf(summary['kyc']);
    if (AffiliateRepository.boolean(kyc['required']) &&
        !AffiliateRepository.boolean(kyc['satisfied'])) {
      return 'Complete KYC verification before requesting a withdrawal.';
    }
    if (!methods.any(
      (item) => AffiliateRepository.boolean(item['configured']),
    )) {
      return 'Configure at least one payout method in your profile.';
    }
    return 'Minimum withdrawal is ${AffiliateRepository.moneyText(summary['minimum_payout'])}.';
  }

  Future<void> _request(
    BuildContext context,
    JsonMap summary,
    List<JsonMap> methods,
  ) async {
    final configured = methods
        .where((item) => AffiliateRepository.boolean(item['configured']))
        .toList();
    if (!AffiliateRepository.boolean(summary['can_request_payout'])) {
      _snack(context, _eligibilityMessage(summary, methods));
      return;
    }
    final amount = TextEditingController();
    String method = AffiliateRepository.text(configured.first['code'], '');
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TradeXColors.surfaceRaised,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Request Withdrawal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  items: [
                    for (final item in configured)
                      DropdownMenuItem(
                        value: AffiliateRepository.text(item['code'], ''),
                        child: Text(
                          _methodName(
                            AffiliateRepository.text(item['code'], ''),
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setModalState(() => method = value ?? method),
                  decoration: const InputDecoration(labelText: 'Payout method'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    helperText:
                        'Available: ${AffiliateRepository.moneyText(summary['available'])}',
                    prefixText: r'$ ',
                  ),
                ),
                const SizedBox(height: 18),
                GoldActionButton(
                  label: 'Submit Request',
                  onPressed: () {
                    if (double.tryParse(amount.text) == null ||
                        double.parse(amount.text) <= 0) {
                      _snack(sheetContext, 'Enter a valid withdrawal amount.');
                      return;
                    }
                    Navigator.pop(sheetContext, true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<PayoutCubit>().submit(
      method,
      amount.text.trim(),
    );
    if (!context.mounted) return;
    _snack(context, error ?? 'Withdrawal request submitted.');
  }

  @override
  Widget build(BuildContext context) {
    final summary = AffiliateRepository.mapOf(state.data['summary']);
    final methodsData = AffiliateRepository.mapOf(state.data['methods']);
    final methods = AffiliateRepository.listOf(methodsData['items']);
    final historyData = AffiliateRepository.mapOf(state.data['history']);
    final history = AffiliateRepository.listOf(historyData['items']);
    final canRequest = AffiliateRepository.boolean(
      summary['can_request_payout'],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          borderColor: TradeXColors.gold,
          child: Row(
            children: [
              const _AffiliateArt(
                path: _AffiliateAssets.wallet,
                fallback: Icons.account_balance_wallet_rounded,
                size: 62,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(color: _muted),
                    ),
                    Text(
                      AffiliateRepository.moneyText(summary['available']),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              GoldActionButton(
                label: state.submitting ? 'Sending...' : 'Withdraw',
                onPressed: state.submitting
                    ? null
                    : () => _request(context, summary, methods),
                compact: true,
              ),
            ],
          ),
        ),
        if (!canRequest) ...[
          const SizedBox(height: 8),
          Text(
            _eligibilityMessage(summary, methods),
            style: const TextStyle(color: TradeXColors.warning, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PayoutMetric(
                'Total Earned',
                summary['net_earned'],
                Icons.monetization_on_outlined,
                assetPath: _AffiliateAssets.money,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PayoutMetric(
                'Paid',
                summary['paid'],
                Icons.north_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PayoutMetric(
                'Locked',
                summary['locked'],
                Icons.lock_clock_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: _SectionHeading(title: 'Withdrawal Methods')),
            TextButton.icon(
              onPressed: methods.isEmpty
                  ? null
                  : () => onConfigureMethod(
                      AffiliateRepository.text(methods.first['code'], ''),
                    ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set up'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (methods.isEmpty)
          const _EmptyCard(
            message: 'No payout methods are available for your country.',
          )
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < methods.length; index++) ...[
                  PayoutMethodTile(
                    data: methods[index],
                    onTap: () => onConfigureMethod(
                      AffiliateRepository.text(methods[index]['code'], ''),
                    ),
                  ),
                  if (index != methods.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
        const SizedBox(height: 22),
        const _SectionHeading(title: 'Withdrawal History'),
        const SizedBox(height: 8),
        if (history.isEmpty)
          const _EmptyCard(message: 'No withdrawal requests yet.')
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < history.length; index++) ...[
                  PayoutHistoryTile(data: history[index]),
                  if (index != history.length - 1)
                    const Divider(height: 1, color: TradeXColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _PayoutMetric extends StatelessWidget {
  const _PayoutMetric(this.label, this.value, this.icon, {this.assetPath});
  final String label;
  final Object? value;
  final IconData icon;
  final String? assetPath;
  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assetPath == null)
          _GoldIcon(icon)
        else
          _AffiliateArt(path: assetPath!, fallback: icon, size: 42),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          AffiliateRepository.moneyText(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class PayoutMethodTile extends StatelessWidget {
  const PayoutMethodTile({super.key, required this.data, required this.onTap});
  final JsonMap data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final code = AffiliateRepository.text(data['code'], '');
    final configured = AffiliateRepository.boolean(data['configured']);
    final destination = AffiliateRepository.mapOf(data['destination']);
    final label = AffiliateRepository.text(
      destination['label'] ?? destination['account_number'],
      configured ? 'Configured' : 'Not configured',
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _PaymentMethodIcon(code: code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _methodName(code),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: configured ? 'Configured' : 'Set up',
              color: configured ? TradeXColors.success : TradeXColors.warning,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }
}

class PayoutHistoryTile extends StatelessWidget {
  const PayoutHistoryTile({super.key, required this.data});
  final JsonMap data;

  @override
  Widget build(BuildContext context) {
    final status = AffiliateRepository.text(data['status']);
    final color = switch (status) {
      'PAID' => TradeXColors.success,
      'REJECTED' || 'FAILED' || 'CANCELLED' => TradeXColors.error,
      _ => TradeXColors.warning,
    };
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _GoldIcon(
            status == 'PAID' ? Icons.check_rounded : Icons.north_east_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_methodName(AffiliateRepository.text(data['method'], ''))} withdrawal',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  _date(data['requested_at']),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AffiliateRepository.moneyText(data['amount']),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(status, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

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
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111614), Color(0xFF07100E)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? TradeXColors.border),
        boxShadow: borderColor == null
            ? null
            : [
                BoxShadow(
                  color: borderColor!.withValues(alpha: .12),
                  blurRadius: 18,
                ),
              ],
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
            color: TradeXColors.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TradeXColors.border),
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
      color: selected ? null : TradeXColors.surfaceRaised,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: selected ? _gold : TradeXColors.border),
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
            color: selected ? Colors.black : Colors.white,
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
    this.tint,
  });

  final String path;
  final IconData fallback;
  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.modulate,
      errorBuilder: (_, _, _) =>
          Icon(fallback, color: tint ?? _gold, size: size * .65),
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

BoxDecoration _fieldDecoration() => BoxDecoration(
  color: const Color(0xFF121A19),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: TradeXColors.border),
);

BoxDecoration _dashboardCardDecoration({bool goldAccent = false}) =>
    BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: goldAccent
            ? const [Color(0xFF101615), Color(0xFF07100E), Color(0xFF291F08)]
            : const [Color(0xFF101718), Color(0xFF07110F), Color(0xFF171407)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: goldAccent ? const Color(0xFFD6A800) : const Color(0xFF49606A),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFFC83D)
              .withValues(alpha: goldAccent ? .12 : .06),
          blurRadius: 18,
        ),
      ],
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

String _message(Object error) => error is ApiException
    ? error.message
    : 'The request could not be completed.';

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
  required String referralUrl,
  required String referralCode,
  required String earnings,
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
      referralUrl: referralUrl,
      earnings: earnings,
      referralCode: referralCode,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  } catch (_) {
    if (context.mounted) {
      _snack(context, 'The premium share card could not be generated.');
    }
  }
}

Future<void> _showQr(BuildContext context, String url) async {
  if (url.isEmpty) {
    _snack(context, 'Referral link is unavailable.');
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: TradeXColors.surfaceRaised,
      title: const Text('Referral QR Code'),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: QrImageView(data: url, size: 220),
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
