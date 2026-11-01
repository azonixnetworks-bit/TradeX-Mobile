part of '../home_dashboard_screen.dart';

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    super.key,
    required this.onActionTap,
    required this.onLogout,
    required this.apiClient,
    required this.tradeIdeasRepository,
    required this.learningRepository,
    required this.marketNewsRepository,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;
  final ApiGateway apiClient;
  final DashboardTradeIdeasRepository tradeIdeasRepository;
  final DashboardLearningRepository learningRepository;
  final MarketNewsRepositoryContract marketNewsRepository;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _Header(onLogout: onLogout, onNotificationTap: onActionTap),
              const SizedBox(height: 14),
              _SectionTitle(
                icon: Icons.apps_rounded,
                title: 'Services',
                action: 'View all',
                onAction: () => onActionTap('Services'),
              ),
              const SizedBox(height: 10),
              _CompactServicesGrid(apiClient: apiClient),
              const SizedBox(height: 18),
              _SessionClockCard(apiClient: apiClient),
              const SizedBox(height: 18),
              _SectionTitle(
                key: const ValueKey('economic-news-title'),
                icon: Icons.newspaper_rounded,
                title: 'Economic News',
                action: 'View all',
                onAction: () => onActionTap('Economic News'),
              ),
              const SizedBox(height: 10),
              _MarketNewsSection(
                repository: marketNewsRepository,
                onOpenAll: () => onActionTap('Economic News'),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.bar_chart_rounded,
                title: 'Market Categories',
                action: 'View all',
                onAction: () => onActionTap('Market categories'),
              ),
              const SizedBox(height: 10),
              _CategoryGrid(onTap: onActionTap),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.menu_book_rounded,
                title: 'Continue Learning',
                action: 'View all',
                onAction: () => onActionTap('Learning library'),
              ),
              const SizedBox(height: 10),
              _ContinueLearningSection(
                repository: learningRepository,
                onActionTap: onActionTap,
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.lightbulb_rounded,
                title: 'Latest Trade Idea',
                action: 'View all',
                onAction: () => onActionTap('Trade ideas'),
              ),
              const SizedBox(height: 10),
              _LiveTradeIdeasCarousel(
                repository: tradeIdeasRepository,
                onActionTap: onActionTap,
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.article_rounded,
                title: 'Latest from TradeX',
                action: 'View all',
                onAction: () => onActionTap('TradeX content'),
              ),
              const SizedBox(height: 10),
              _LatestContentCard(
                apiClient: apiClient,
                onActionTap: onActionTap,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLogout, required this.onNotificationTap});

  final Future<void> Function() onLogout;
  final ValueChanged<String> onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/branding/trade_x_wordmark.png',
          width: 136,
          height: 36,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => onNotificationTap('Notifications'),
          icon: Badge(
            smallSize: 9,
            backgroundColor: TradeXColors.goldBright,
            child: Icon(
              TradeXIcons.notifications,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        PopupMenuButton<String>(
          color: TradeXColors.surfaceRaised,
          icon: const Icon(Icons.more_horiz_rounded, color: TradeXColors.gold),
          onSelected: (value) async {
            if (value == 'logout') await onLogout();
            if (value == 'services') onNotificationTap('Services');
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'services', child: Text('TradeX services')),
            PopupMenuItem(value: 'logout', child: Text('Sign out')),
          ],
        ),
      ],
    );
  }
}

class _CompactServicesGrid extends StatelessWidget {
  const _CompactServicesGrid({required this.apiClient});

  final ApiGateway apiClient;

  @override
  Widget build(BuildContext context) {
    final journal = featureById('trade-journal');
    final services = <FeatureSpec>[
      journal,
      ...tradeXFeatureSpecs.where((item) => item.id != journal.id),
    ];

    return SizedBox(
      key: const ValueKey('home-services-grid'),
      height: 174,
      child: GridView.builder(
        key: const ValueKey('home-services-scroll'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 158,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return _CompactServiceCard(
            key: ValueKey('home-service-${service.id}'),
            service: service,
            accent: _serviceAccent(service.group),
            onTap: () => openTradeXFeature(
              context,
              CatalogDependenciesRegistry.current,
              service,
            ),
          );
        },
      ),
    );
  }

  Color _serviceAccent(String group) => switch (group) {
    'Home & Market' => TradeXColors.gold,
    'Trade Ideas' => TradeXColors.goldBright,
    'Journal & Tools' => TradeXColors.goldBright,
    'Copy Trading' => TradeXColors.goldSoft,
    'Membership & Payments' => TradeXColors.gold,
    'Affiliate & Referrals' => TradeXColors.goldBright,
    'Profile & Security' => TradeXColors.goldBright,
    _ => TradeXColors.gold,
  };
}

class _CompactServiceCard extends StatelessWidget {
  const _CompactServiceCard({
    super.key,
    required this.service,
    required this.accent,
    required this.onTap,
  });

  final FeatureSpec service;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: .14),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accent.withValues(alpha: .34)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(service.icon, color: accent, size: 19),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.id == 'trade-journal'
                        ? 'Trade Journal'
                        : service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 11,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    service.group,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent, size: 17),
          ],
        ),
      ),
    ),
  );
}
