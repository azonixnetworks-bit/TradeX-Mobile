import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/bloc/bloc_future_builder.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../home/data/market_news_repository.dart';
import '../../home/data/market_news_warning_source.dart';
import '../../home/presentation/economic_news_screen.dart';
import '../../copy_trading/presentation/copy_trading_module.dart';
import '../../copy_trading/copy_trading_dependencies.dart';
import '../../funded_advisor/funded_advisor_dependencies.dart';
import '../../funded_advisor/presentation/funded_advisor_module.dart';
import '../../journal/journal_dependencies.dart';
import '../../journal/presentation/trade_journal_home_screen.dart';
import '../../journal/presentation/trade_journal_insights_screens.dart';
import '../../journal/presentation/trade_journal_trade_screens.dart';
import '../../investments/investment_dependencies.dart';
import '../../investments/presentation/investment_module.dart';
import '../../market/presentation/crypto_market_screen.dart';
import '../../market/market_dependencies.dart';
import '../../notifications/notification_dependencies.dart';
import '../../notifications/presentation/notification_module.dart';
import '../../risk_reward/presentation/risk_reward_module.dart';
import '../../risk_reward/risk_reward_dependencies.dart';
import '../../support/presentation/support_module.dart';
import '../../support/support_dependencies.dart';
import '../models/feature_spec.dart';
import 'secure_workflow_screens.dart';

part 'feature_catalog/feature_workflow_screens.dart';
part 'feature_catalog/feature_catalog_widgets.dart';

class FeatureCatalogScreen extends StatelessWidget {
  const FeatureCatalogScreen({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<FeatureSpec>>{};
    for (final spec in tradeXFeatureSpecs) {
      groups.putIfAbsent(spec.group, () => <FeatureSpec>[]).add(spec);
    }
    return _FeatureScaffold(
      title: 'TradeX Services',
      subtitle: 'Secure access to your available account services',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _SafetyNotice(),
          const SizedBox(height: 14),
          for (final entry in groups.entries) ...[
            _GroupHeading(entry.key),
            const SizedBox(height: 8),
            _FeatureGroup(
              specs: entry.value,
              onOpen: (spec) => openTradeXFeature(context, apiClient, spec),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

Future<void> openTradeXFeature(
  BuildContext context,
  TradeXApiClient apiClient,
  FeatureSpec spec,
) {
  final journal = JournalDependencies(apiClient).repository;
  final workflow = switch (spec.id) {
    'investments' => InvestmentHomeScreen(
      repository: InvestmentDependencies(apiClient).repository,
      preferencesRepository: InvestmentDependencies(apiClient)
          .preferencesRepository,
    ),
    'economic-news' => EconomicNewsScreen(apiClient: apiClient),
    'market-screener' => CryptoMarketScreen(
      dependencies: MarketDependencies(apiClient),
    ),
    'trade-journal' => TradeJournalHomeScreen(
      apiClient: apiClient,
      repository: journal,
    ),
    'trade-entry-form' => TradeJournalPlanScreen(repository: journal),
    'trade-entry-details' => TradeJournalEntriesScreen(repository: journal),
    'trade-performance' => TradeJournalAnalyticsScreen(repository: journal),
    'kyc-submit' => KycSubmissionScreen(apiClient: apiClient),
    'payment-proof' => PaymentProofScreen(apiClient: apiClient),
    'contact-number' => ContactChangeScreen(apiClient: apiClient),
    'copy-dashboard' => CopyTradingHomeScreen(
      useCases: CopyTradingDependencies(apiClient).useCases,
    ),
    'connect-broker' => CopyTradingHomeScreen(
      useCases: CopyTradingDependencies(apiClient).useCases,
    ),
    'funded-advisor' => FundedAdvisorScreen(
      useCases: FundedAdvisorDependencies(apiClient).useCases,
      warningSource: MarketNewsWarningSource(MarketNewsRepository(apiClient)),
    ),
    'risk-reward-calculator' => RiskRewardHomeScreen(
      repository: RiskRewardDependencies(apiClient).repository,
    ),
    'notifications' || 'notification-details' => NotificationCenterScreen(
      repository: NotificationDependencies(apiClient).repository,
      permissionRepository: NotificationDependencies(apiClient)
          .permissionRepository,
    ),
    'help-faq' || 'contact-support' => SupportHomeScreen(
      useCases: SupportDependencies(apiClient).useCases,
    ),
    'checkout' => PaymentCheckoutScreen(apiClient: apiClient),
    _ => null,
  };
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          workflow ?? TradeXFeatureScreen(apiClient: apiClient, spec: spec),
    ),
  );
}
