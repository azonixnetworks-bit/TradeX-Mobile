import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/tradex_colors.dart';
import '../domain/investment_entities.dart';
import '../domain/investment_repository.dart';
import 'bloc/investments_cubit.dart';

part 'screens/investment_home_screen.dart';
part 'screens/investment_products_screen.dart';
part 'screens/my_investments_screen.dart';
part 'screens/investment_details_screen.dart';
part 'screens/profit_performance_screen.dart';
part 'screens/investment_transactions_screen.dart';
part 'screens/investment_agreements_risk_screen.dart';
part 'widgets/investment_shared_widgets.dart';
