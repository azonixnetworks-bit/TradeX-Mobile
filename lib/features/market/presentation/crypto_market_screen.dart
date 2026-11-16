import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/market_assets/market_asset_widget.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../../home/domain/trade_ideas_repository.dart';
import '../domain/entities/crypto_market_entities.dart';
import '../domain/entities/market_screener_entities.dart';
import '../domain/repositories/crypto_market_repository.dart';
import '../domain/repositories/market_screener_repository.dart';
import 'crypto_bubble_field.dart';
import 'crypto_bubble_map_screen.dart';
import 'crypto_market_cubit.dart';
import 'crypto_watchlist_screen.dart';
import 'trading_view_chart_screen.dart';

part 'crypto_market/crypto_market_state.dart';
part 'crypto_market/crypto_market_summary_widgets.dart';
part 'crypto_market/crypto_trade_ideas_widgets.dart';
part 'crypto_market/crypto_coin_list_widgets.dart';
part 'crypto_market/crypto_market_shared_widgets.dart';
part 'crypto_market/multi_market_screener_widgets.dart';
