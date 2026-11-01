import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/app_platform.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../shared/widgets/no_trade_zone_warning.dart';
import '../../home/domain/no_trade_zone_warning.dart';
import '../domain/entities/funded_advisor_entities.dart';
import '../domain/usecases/funded_advisor_use_cases.dart';
import 'bloc/funded_advisor_cubit.dart';
import 'funded_advisor_widgets.dart';

part 'funded_advisor/funded_companies_screen.dart';
part 'funded_advisor/funded_company_details_screen.dart';
part 'funded_advisor/funded_account_options_screen.dart';
part 'funded_advisor/funded_rules_screens.dart';

class FundedAdvisorScreen extends StatelessWidget {
  const FundedAdvisorScreen({
    super.key,
    required this.useCases,
    required this.warningSource,
  });

  final FundedAdvisorUseCases useCases;
  final NoTradeWarningSource warningSource;

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: warningSource,
    child: BlocProvider<FundedAdvisorCubit>(
      create: (_) => FundedAdvisorCubit(useCases)..initialize(),
      child: const _FundedCompaniesScreen(),
    ),
  );
}
