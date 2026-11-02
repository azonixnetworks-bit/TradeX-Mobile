import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/activity/activity_tracking_scope.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/tradex_colors.dart';
import '../domain/entities/risk_reward_entities.dart';
import '../domain/repositories/risk_reward_repository.dart';
import 'bloc/risk_reward_cubit.dart';

part 'screens/risk_reward_home_screen.dart';
part 'screens/forex_deriv_calculator_screen.dart';
part 'screens/crypto_risk_calculator_screen.dart';
part 'screens/stock_risk_calculator_screen.dart';
part 'screens/dividend_calculator_screen.dart';
part 'screens/dividend_history_screen.dart';
part 'screens/calculation_result_screen.dart';
part 'widgets/risk_reward_shared_widgets.dart';
part 'widgets/risk_reward_calculator_widgets.dart';

const _assetRoot = 'assets/risk_reward';
