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
import '../../../core/theme/tradex_design_system.dart';
import '../../../core/theme/tradex_icons.dart';
import '../domain/repositories/affiliate_repository.dart';
import '../domain/repositories/referral_qr_cache.dart';
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

abstract final class _AffiliateAssets {
  static const brandLogo = 'assets/branding/trade_x_final_logo.png';
  static const money = 'assets/affiliate/illustrations/money_gold.png';
  static const wallet = 'assets/affiliate/illustrations/wallet_gold.png';
  static const paypal = 'assets/affiliate/brands/paypal.svg';
  static const tether = 'assets/affiliate/brands/tether.svg';
  static const binance = 'assets/affiliate/brands/binance.svg';
  static const whatsapp = 'assets/affiliate/brands/whatsapp.svg';
  static const referralLinkBadge =
      'assets/affiliate/dynamic_v2/glossy_gold_chain_link_badge.png';
  static const earningsCoins =
      'assets/affiliate/dynamic_v2/glossy_gold_coin_stack_icon.png';
  static const milestoneStar =
      'assets/affiliate/dynamic_v2/premium_golden_star_badge_emblem.png';
  static const milestoneGift =
      'assets/affiliate/dynamic_v2/premium_gold_gift_box_icon.png';
}
