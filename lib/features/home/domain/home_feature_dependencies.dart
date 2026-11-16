import '../../../core/domain/api_gateway.dart';
import '../../../core/domain/dashboard_tab_preferences.dart';
import '../../../core/domain/profile_photo_store.dart';
import '../../profile/domain/repositories/withdrawal_draft_store.dart';
import '../../affiliate/domain/repositories/affiliate_repository.dart';
import '../../affiliate/domain/repositories/referral_qr_cache.dart';
import '../../auth/domain/repositories/auth_repositories.dart';
import '../../learn/domain/repositories/learn_repository.dart';
import '../../market/domain/repositories/crypto_market_repository.dart';
import '../../trade_ideas/domain/repositories/trade_idea_repository.dart';
import 'market_news_repository.dart';
import 'no_trade_zone_warning.dart';
import 'trade_ideas_repository.dart';
import 'learning_repository.dart';
import 'home_widget_publisher.dart';

abstract interface class HomeFeatureDependencies {
  ApiGateway get apiGateway;
  AuthRepositoryContract get authRepository;
  MarketNewsRepositoryContract get marketNewsRepository;
  NoTradeWarningSource get marketNewsWarningSource;
  LearnRepository get learnRepository;
  TradeIdeaRepositoryContract get tradeIdeasRepository;
  AffiliateRepository get affiliateRepository;
  ReferralQrCache get referralQrCache;
  MarketFeatureDependencies get marketDependencies;
  DashboardTabPreferences get dashboardPreferences;
  ProfilePhotoStore get profilePhotoStore;
  WithdrawalDraftStore get withdrawalDraftStore;
  DashboardTradeIdeasRepository get dashboardTradeIdeasRepository;
  DashboardLearningRepository get dashboardLearningRepository;
  HomeWidgetPublisher get homeWidgetPublisher;
}
