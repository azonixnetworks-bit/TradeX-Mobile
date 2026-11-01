import 'package:flutter/material.dart';

import '../../core/network/tradex_api_client.dart';
import '../copy_trading/copy_trading_dependencies.dart';
import '../copy_trading/presentation/copy_trading_module.dart';
import '../funded_advisor/funded_advisor_dependencies.dart';
import '../funded_advisor/presentation/funded_advisor_module.dart';
import '../home/data/market_news_repository.dart';
import '../home/data/market_news_warning_source.dart';
import '../home/presentation/economic_news_screen.dart';
import '../investments/investment_dependencies.dart';
import '../investments/presentation/investment_module.dart';
import '../journal/journal_dependencies.dart';
import '../journal/presentation/trade_journal_home_screen.dart';
import '../journal/presentation/trade_journal_insights_screens.dart';
import '../journal/presentation/trade_journal_trade_screens.dart';
import '../market/market_dependencies.dart';
import '../market/presentation/crypto_market_screen.dart';
import '../notifications/notification_dependencies.dart';
import '../notifications/presentation/notification_module.dart';
import '../risk_reward/presentation/risk_reward_module.dart';
import '../risk_reward/risk_reward_dependencies.dart';
import '../support/presentation/support_module.dart';
import '../support/support_dependencies.dart';
import 'models/feature_spec.dart';
import 'presentation/feature_catalog_screen.dart';
import 'presentation/secure_workflow_screens.dart';

class CatalogDependencies {
  CatalogDependencies(this.apiClient);

  final TradeXApiClient apiClient;

  Widget buildFeature(FeatureSpec spec) {
    final journal = JournalDependencies(apiClient).repository;
    return switch (spec.id) {
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
      'copy-dashboard' || 'connect-broker' => CopyTradingHomeScreen(
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
      _ => TradeXFeatureScreen(apiClient: apiClient, spec: spec),
    };
  }
}

abstract final class CatalogDependenciesRegistry {
  static CatalogDependencies? _current;
  static CatalogDependencies get current =>
      _current ??
      (throw StateError('Catalog dependencies are not configured.'));
  static void configure(CatalogDependencies value) => _current = value;
}
