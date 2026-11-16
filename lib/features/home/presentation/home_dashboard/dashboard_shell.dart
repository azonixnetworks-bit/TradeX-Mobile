part of '../home_dashboard_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onLogout,
    required this.onForgetDevice,
    required this.onLogoutAll,
    required this.dependencies,
  });

  final Future<void> Function() onLogout;
  final Future<void> Function() onForgetDevice;
  final Future<void> Function() onLogoutAll;
  final HomeFeatureDependencies dependencies;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late final HomeNavigationCubit _navigationCubit;
  late final List<Widget?> _tabPages;
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _navigationCubit = HomeNavigationCubit(
      preferences: widget.dependencies.dashboardPreferences,
    );
    _tabPages = List<Widget?>.filled(5, null);
    _tabPages[_navigationCubit.state] = _buildTab(_navigationCubit.state);
    unawaited(_primeDailyEconomicNews());
    unawaited(widget.dependencies.homeWidgetPublisher.refresh());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _restorePendingFinancialForm(),
    );
  }

  Future<void> _logout() async {
    await widget.dependencies.homeWidgetPublisher.clear();
    await widget.onLogout();
  }

  @override
  void dispose() {
    _navigationCubit.close();
    super.dispose();
  }

  Future<void> _primeDailyEconomicNews() async {
    try {
      await widget.dependencies.marketNewsRepository.today();
    } catch (_) {
      // The Economic News screen retains its retry state when the first daily
      // network request cannot be completed.
    }
  }

  Future<void> _restorePendingFinancialForm() async {
    try {
      final draft = await widget.dependencies.withdrawalDraftStore
          .readWithdrawal();
      if (!mounted || draft == null) return;
      WithdrawalMethod? method;
      for (final candidate in WithdrawalMethod.values) {
        if (candidate.name == draft.method) method = candidate;
      }
      final restoredMethod = method;
      if (restoredMethod == null) {
        await widget.dependencies.withdrawalDraftStore.clearWithdrawal();
        return;
      }
      final navigator = Navigator.of(context);
      if (navigator.canPop()) return;
      _selectTab(4);
      final saved = await navigator.push<bool>(
        MaterialPageRoute<bool>(
          settings: RouteSettings(
            name: '/profile/withdrawal/${restoredMethod.name}',
          ),
          builder: (_) => WithdrawalMethodScreen(
            apiClient: widget.dependencies.apiGateway,
            draftStore: widget.dependencies.withdrawalDraftStore,
            method: restoredMethod,
          ),
        ),
      );
      if (saved == true && mounted) {
        setState(() => _tabPages[4] = _buildTab(4));
      }
    } catch (_) {
      // Secure draft restoration is best-effort and must not block startup.
    }
  }

  void _selectTab(int index) {
    if (index == _navigationCubit.state) return;
    setState(() {
      _tabPages[index] ??= _buildTab(index);
    });
    _navigationCubit.select(index);
    const modules = <String>[
      'app',
      'learning',
      'trade_ideas',
      'affiliate',
      'profile',
    ];
    const screens = <String>[
      'dashboard_home',
      'dashboard_learn',
      'dashboard_ideas',
      'dashboard_affiliate',
      'dashboard_profile',
    ];
    ActivityTrackingScope.maybeOf(context)
        ?.view(modules[index], screens[index]);
  }

  void _beginHorizontalSwipe(DragStartDetails _) {
    _horizontalDragDistance = 0;
  }

  void _updateHorizontalSwipe(DragUpdateDetails details) {
    _horizontalDragDistance += details.primaryDelta ?? 0;
  }

  void _finishHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final distance = _horizontalDragDistance;
    _horizontalDragDistance = 0;
    if (distance.abs() < 56 && velocity.abs() < 450) return;

    final direction = distance.abs() >= 56 ? distance : velocity;
    final current = _navigationCubit.state;
    if (direction < 0 && current < 4) {
      _selectTab(current + 1);
    } else if (direction > 0 && current > 0) {
      _selectTab(current - 1);
    }
  }

  Widget _buildTab(int index) => switch (index) {
    0 => _HomeContent(
      key: const PageStorageKey('home-tab'),
      onActionTap: _openAction,
      onLogout: _logout,
      apiClient: widget.dependencies.apiGateway,
      marketNewsRepository: widget.dependencies.marketNewsRepository,
      tradeIdeasRepository: widget.dependencies.dashboardTradeIdeasRepository,
      learningRepository: widget.dependencies.dashboardLearningRepository,
      courseRepository: widget.dependencies.learnRepository,
    ),
    1 => _LearnTab(
      key: const PageStorageKey('learn-tab'),
      repository: widget.dependencies.learnRepository,
      onNotifications: () => _openAction('notifications'),
    ),
    2 => _TradeIdeasTab(
      key: const PageStorageKey('ideas-tab'),
      onActionTap: _openAction,
      apiClient: widget.dependencies.apiGateway,
      repository: widget.dependencies.tradeIdeasRepository,
      warningSource: widget.dependencies.marketNewsWarningSource,
      learnRepository: widget.dependencies.learnRepository,
    ),
    3 => _AffiliateTab(
      key: const PageStorageKey('affiliate-tab'),
      onActionTap: _openAction,
      apiClient: widget.dependencies.apiGateway,
      repository: widget.dependencies.affiliateRepository,
      referralQrCache: widget.dependencies.referralQrCache,
      learnRepository: widget.dependencies.learnRepository,
      withdrawalDraftStore: widget.dependencies.withdrawalDraftStore,
    ),
    _ => _ProfileTab(
      key: const PageStorageKey('profile-tab'),
      onActionTap: _openAction,
      onLogout: _logout,
      onForgetDevice: widget.onForgetDevice,
      onLogoutAll: widget.onLogoutAll,
      apiClient: widget.dependencies.apiGateway,
      authRepository: widget.dependencies.authRepository,
      profilePhotoStore: widget.dependencies.profilePhotoStore,
      learnRepository: widget.dependencies.learnRepository,
      withdrawalDraftStore: widget.dependencies.withdrawalDraftStore,
    ),
  };

  void _openAction(String label) {
    final normalized = label.toLowerCase();
    if (normalized == 'learning library' ||
        normalized.startsWith('free lesson:')) {
      _selectTab(1);
      return;
    }
    if (normalized == 'trade ideas') {
      _selectTab(2);
      return;
    }
    const marketCategories = <String>{
      'forex',
      'commodity',
      'crypto',
      'stocks',
      'deriv',
      'indices',
    };
    if (normalized.endsWith(' trade ideas')) {
      final category = normalized.substring(
        0,
        normalized.length - ' trade ideas'.length,
      );
      if (marketCategories.contains(category)) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => _MarketCategoryTradeIdeasScreen(
              category: category[0].toUpperCase() + category.substring(1),
              repository: widget.dependencies.dashboardTradeIdeasRepository,
            ),
          ),
        );
        return;
      }
    }
    if (normalized == 'economic news') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EconomicNewsScreen(
            repository: widget.dependencies.marketNewsRepository,
          ),
        ),
      );
      return;
    }
    if (normalized == 'services') {
      ActivityTrackingScope.maybeOf(context)?.openedFeature('services');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FeatureCatalogScreen(
            dependencies: CatalogDependenciesRegistry.current,
          ),
        ),
      );
      return;
    }
    if (normalized == 'crypto trade ideas') {
      ActivityTrackingScope.maybeOf(context)?.openedFeature('crypto-market');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CryptoMarketScreen(
            dependencies: widget.dependencies.marketDependencies,
          ),
        ),
      );
      return;
    }
    if (normalized == 'tradex content') {
      openTradeXFeature(
        context,
        CatalogDependenciesRegistry.current,
        const FeatureSpec(
          id: 'our-channel',
          group: 'Notifications & Support',
          title: 'Our Channel / Videos',
          subtitle: 'Published TradeX videos and details',
          icon: Icons.ondemand_video_rounded,
          endpoint: '/api/v1/our-channel/videos',
        ),
      );
      return;
    }
    if (normalized == 'premium access') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PremiumAccessScreen(
            repository: widget.dependencies.learnRepository,
          ),
        ),
      );
      return;
    }

    final id = switch (normalized) {
      'notifications' => 'notifications',
      'market categories' => 'market-screener',
      'risk calculator' => 'risk-reward-calculator',
      'share referral link' => 'direct-referrals',
      'affiliate milestones' => 'qualified-sales',
      'my referrals' => 'direct-referrals',
      'rewards history' => 'commissions',
      'whatsapp contact' => 'contact-number',
      'learning language' => 'preferences',
      'authenticator security' => 'recovery-codes',
      'support centre' => 'help-faq',
      _
          when normalized.endsWith('trade ideas') ||
              normalized.endsWith('trade idea') =>
        'trade-idea-details',
      _ => 'help-faq',
    };
    openTradeXFeature(
      context,
      CatalogDependenciesRegistry.current,
      featureById(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _navigationCubit,
      child: BlocBuilder<HomeNavigationCubit, int>(
        builder: (context, selectedTab) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(AppBackgroundService.moveToBackground());
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  _DashboardTopBar(
                    onNotifications: () => _openAction('notifications'),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: _beginHorizontalSwipe,
                      onHorizontalDragUpdate: _updateHorizontalSwipe,
                      onHorizontalDragEnd: _finishHorizontalSwipe,
                      onHorizontalDragCancel: () => _horizontalDragDistance = 0,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _SmoothIndexedStack(
                              key: const ValueKey('main-menu-page-view'),
                              index: selectedTab,
                              children: List<Widget>.generate(
                                5,
                                (index) => TickerMode(
                                  enabled: index == selectedTab,
                                  child:
                                      _tabPages[index] ??
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                          if (selectedTab > 0)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 24,
                              child: GestureDetector(
                                key: const ValueKey('dashboard-swipe-previous'),
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragStart: _beginHorizontalSwipe,
                                onHorizontalDragUpdate: _updateHorizontalSwipe,
                                onHorizontalDragEnd: _finishHorizontalSwipe,
                                onHorizontalDragCancel: () =>
                                    _horizontalDragDistance = 0,
                              ),
                            ),
                          if (selectedTab < 4)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: 24,
                              child: GestureDetector(
                                key: const ValueKey('dashboard-swipe-next'),
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragStart: _beginHorizontalSwipe,
                                onHorizontalDragUpdate: _updateHorizontalSwipe,
                                onHorizontalDragEnd: _finishHorizontalSwipe,
                                onHorizontalDragCancel: () =>
                                    _horizontalDragDistance = 0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _DashboardNavBar(
              selectedIndex: selectedTab,
              onChanged: _selectTab,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmoothIndexedStack extends StatefulWidget {
  const _SmoothIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_SmoothIndexedStack> createState() => _SmoothIndexedStackState();
}

class _SmoothIndexedStackState extends State<_SmoothIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late int _activeIndex;
  int? _previousIndex;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _previousIndex = null);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SmoothIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _activeIndex) return;
    _direction = widget.index > _activeIndex ? 1 : -1;
    _previousIndex = _activeIndex;
    _activeIndex = widget.index;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        return ClipRect(
          child: Stack(
            children: List<Widget>.generate(widget.children.length, (index) {
              final isActive = index == _activeIndex;
              final isPrevious = index == _previousIndex;
              final isVisible = isActive || isPrevious;
              final offset = isActive
                  ? _direction * (1 - progress) * constraints.maxWidth
                  : isPrevious
                  ? -_direction * progress * constraints.maxWidth
                  : 0.0;
              return Positioned.fill(
                child: Offstage(
                  offstage: !isVisible,
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: Opacity(
                      opacity: isActive ? .72 + (.28 * progress) : 1 - progress,
                      child: IgnorePointer(
                        ignoring: !isActive,
                        child: widget.children[index],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    ),
  );
}
