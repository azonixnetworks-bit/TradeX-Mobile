import '../../core/domain/api_gateway.dart';
import '../../core/domain/dashboard_tab_preferences.dart';
import '../../core/preferences/app_preferences.dart';
import '../../core/domain/profile_photo_store.dart';
import '../../core/profile/local_profile_photo_store.dart';
import '../../core/domain/app_platform.dart';
import '../../core/platform/app_platform_impl.dart';
import '../profile/domain/repositories/withdrawal_draft_store.dart';
import '../profile/data/repositories/withdrawal_draft_store_impl.dart';
import '../affiliate/affiliate_dependencies.dart';
import '../affiliate/domain/repositories/affiliate_repository.dart';
import '../auth/domain/repositories/auth_repositories.dart';
import '../learn/domain/repositories/learn_repository.dart';
import '../learn/learn_dependencies.dart';
import '../market/domain/repositories/crypto_market_repository.dart';
import '../market/market_dependencies.dart';
import '../trade_ideas/domain/repositories/trade_idea_repository.dart';
import '../trade_ideas/trade_ideas_dependencies.dart';
import 'data/market_news_repository.dart';
import 'data/trade_ideas_repository.dart';
import 'data/learning_repository.dart';
import 'data/market_news_warning_source.dart';
import 'domain/home_feature_dependencies.dart';
import 'domain/market_news_repository.dart';
import 'domain/no_trade_zone_warning.dart';
import 'domain/trade_ideas_repository.dart';

final class HomeDependencies implements HomeFeatureDependencies {
  HomeDependencies(
    ApiGateway apiGateway,
    this.authRepository, {
    ProfilePhotoStore? profilePhotoStore,
    this._withdrawalDraftStore,
  }) : profilePhotoStore = profilePhotoStore ?? const LocalProfilePhotoStore(),
       apiGateway = apiGateway,
       marketNewsRepository = MarketNewsRepository(apiGateway as dynamic),
       learnRepository = LearnDependencies(apiGateway as dynamic).repository,
       tradeIdeasRepository = TradeIdeasDependencies(apiGateway as dynamic)
           .repository,
       affiliateRepository = AffiliateDependencies(apiGateway as dynamic)
           .repository,
       marketDependencies = MarketDependencies(
         apiGateway as dynamic,
         tradeIdeasRepository: TradeIdeasRepository(
           apiGateway as dynamic,
           TradeIdeasDependencies(apiGateway as dynamic).repository,
         ),
       ) {
    AppPlatformRegistry.configure(AppPlatformImpl());
    marketNewsWarningSource = MarketNewsWarningSource(marketNewsRepository);
  }

  @override
  final ApiGateway apiGateway;
  @override
  final AuthRepositoryContract authRepository;
  @override
  final MarketNewsRepositoryContract marketNewsRepository;
  @override
  late final NoTradeWarningSource marketNewsWarningSource;
  @override
  final LearnRepository learnRepository;
  @override
  final TradeIdeaRepositoryContract tradeIdeasRepository;
  @override
  final AffiliateRepository affiliateRepository;
  @override
  final MarketFeatureDependencies marketDependencies;
  @override
  final DashboardTabPreferences dashboardPreferences = AppPreferences.instance;
  @override
  final ProfilePhotoStore profilePhotoStore;
  final WithdrawalDraftStore? _withdrawalDraftStore;
  @override
  late final DashboardTradeIdeasRepository dashboardTradeIdeasRepository =
      TradeIdeasRepository(apiGateway as dynamic, tradeIdeasRepository);
  @override
  late final DashboardLearningRepository dashboardLearningRepository =
      LearningRepository(apiGateway as dynamic);
  @override
  late final WithdrawalDraftStore withdrawalDraftStore =
      _withdrawalDraftStore ?? WithdrawalDraftStoreImpl();
}
