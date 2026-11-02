import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/domain/app_platform.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_icons.dart';
import '../domain/repositories/affiliate_repository.dart';
import 'bloc/affiliate_cubits.dart';
import 'services/affiliate_share_card_service.dart';

part 'screens/affiliate_dashboard_screen.dart';
part 'screens/affiliate_referrals_screen.dart';
part 'screens/affiliate_earnings_screen.dart';
part 'screens/affiliate_levels_screen.dart';
part 'screens/affiliate_payouts_screen.dart';
part 'widgets/affiliate_shell_widgets.dart';
part 'widgets/affiliate_shared_widgets.dart';

const _gold = TradeXColors.goldBright;
const _muted = TradeXColors.secondaryText;
const _purple = Color(0xFFA855F7);

abstract final class _AffiliateAssets {
  static const brandLogo = 'assets/branding/trade_x_final_logo.png';
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
  static const dashboardWhatsApp =
      'assets/affiliate/illustrations/dashboard_whatsapp_button.png';
  static const dashboardTelegram =
      'assets/affiliate/illustrations/dashboard_telegram_button.png';
  static const dashboardShare =
      'assets/affiliate/illustrations/dashboard_share_button.png';
  static const dashboardQr =
      'assets/affiliate/illustrations/dashboard_qr_button.png';
}
