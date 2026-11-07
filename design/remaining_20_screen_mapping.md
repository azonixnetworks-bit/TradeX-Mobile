# TradeX Remaining 20 Screens — Implementation Mapping

This mapping was recorded before the remaining-screen visual pass. The redesign is presentation-only: existing repositories, API contracts, state, navigation callbacks, calculations, playback, and persistence remain authoritative.

| # | Reference screen | Existing Flutter surface | State owner | Existing data / API owner | Existing navigation |
|---:|---|---|---|---|---|
| 1 | Investment Home | `lib/features/investments/presentation/screens/investment_home_screen.dart` | `_InvestmentHomeScreenState`, `InvestmentsCubit` | `InvestmentRepository.loadDashboard` and `InvestmentPreferencesRepository` | Existing `MaterialPageRoute` callbacks in the screen |
| 2 | Investment Products | `lib/features/investments/presentation/screens/investment_products_screen.dart` | `FutureBuilder<InvestmentDashboard>` | `InvestmentRepository.loadDashboard` | Existing product-card callback |
| 3 | Investment Details | `lib/features/investments/presentation/screens/investment_details_screen.dart` | `FutureBuilder<InvestmentDashboard>` | `InvestmentRepository.loadInvestment` | Existing performance, transactions, and agreement routes |
| 4 | Agreements & Risk | `lib/features/investments/presentation/screens/investment_agreements_risk_screen.dart` | `FutureBuilder<InvestmentDashboard>` | `InvestmentRepository.loadDashboard/loadInvestment` | Existing scaffold back navigation |
| 5 | My Investments | `lib/features/investments/presentation/screens/my_investments_screen.dart` | `_MyInvestmentsScreenState` | `InvestmentRepository.loadDashboard` | Existing investment-details route |
| 6 | Transactions | `lib/features/investments/presentation/screens/investment_transactions_screen.dart` | `_InvestmentTransactionsScreenState` | `InvestmentRepository.loadDashboard/loadInvestment` | Existing detail/modal callbacks |
| 7 | Profit Performance | `lib/features/investments/presentation/screens/profit_performance_screen.dart` | `_ProfitPerformanceScreenState` | `InvestmentRepository.loadDashboard/loadInvestment` | Existing scaffold back navigation |
| 8 | Markets | `lib/features/market/presentation/crypto_market_screen.dart` and its `crypto_market/*` parts | `CryptoMarketCubit`, `CryptoMarketState` | `CryptoMarketRepositoryContract` and existing trade-idea provider | Existing chart, watchlist, and bubble-map routes |
| 9 | Trade Ideas | `lib/features/trade_ideas/presentation/trade_ideas_screen.dart` | `_TradeIdeasScreenState` | `TradeIdeaRepositoryContract.list` | Existing trade-idea details route |
| 10 | Course Video Player | `lib/features/learn/presentation/course_video_player_screen.dart` | `_CourseVideoPlayerScreenState`, `VideoPlayerController` | `LearnRepository.updateProgress` and backend playback URL | Existing lesson-viewer route; player manages fullscreen locally |
| 11 | My Learning | `lib/features/learn/presentation/screens/my_learning_screen.dart` | `_MyLearningScreenState`, `TabController` | `LearnRepository.myLearning` | Existing universal lesson-viewer route |
| 12 | Support Center | `lib/features/support/presentation/screens/support_home_screen.dart` | Repository-backed child screens | `SupportUseCases` | Existing chat, ticket, help-center, and ticket-list routes |
| 13 | Trading Journal | `lib/features/journal/presentation/journal_sections/journal_home.dart` | `_TradeJournalHomeScreenState` | `TradeJournalRepositoryContract.home/analytics` | Existing plan, detail, analytics, and review routes |
| 14 | Trade Plan | `lib/features/journal/presentation/trade_screens/trade_plan_screen.dart` plus `trade_plan_screen_state.dart` | `_TradeJournalPlanScreenState` | Existing journal meta, price, create/update, timezone methods | Existing form callbacks and pop result |
| 15 | Open Trade | `lib/features/journal/presentation/trade_screens/trade_open_screen.dart` | `_TradeJournalOpenScreenState` | Existing journal open/update methods | Existing form callback and pop result |
| 16 | My Profile | `lib/features/home/presentation/home_dashboard/profile_tab_state.dart` and `profile_tab_models.dart` | `_ProfileTabState` | Existing customer/profile repositories supplied by the dashboard | Existing profile detail/edit routes |
| 17 | Account Security | Security accordion within the existing profile surface, plus its already-linked security screens | `_ProfileTabState` and destination-screen state | Existing auth/profile repositories | Existing trusted-device, quick-unlock, password, and 2FA actions |
| 18 | App Preferences | Existing profile/help/preferences destinations exposed from the profile surface | Destination-screen state | Existing preference repositories | Existing preference/navigation callbacks; no new route invented |
| 19 | Linked Accounts | Existing account/withdrawal profile actions and linked-account destinations | `_ProfileTabState` and destination-screen state | Existing profile/account repositories | Existing callbacks only; no illustrative provider is hard-coded |
| 20 | Payment Methods | Existing withdrawal/payment destination exposed by the profile surface | Destination-screen state | Existing payment/withdrawal repositories | Existing withdrawal/payment callback |

## Guardrails

- Reference screenshots are visual targets only; sample names, balances, prices, statuses, QR codes, providers, and transactions are not production data.
- The original TradeX logo, animated bottom navigation bubble, and 24-hour analog session clock stay unchanged.
- Unsupported conceptual screens remain mapped to their current profile sections/destinations instead of creating duplicate state or endpoints.
- Empty, loading, error, offline, and unavailable states continue to come from existing state and repository results.
