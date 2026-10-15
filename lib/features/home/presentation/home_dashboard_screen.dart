import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _selectedTab = 0;

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label will be available soon.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeXColors.background,
      body: SafeArea(
        child: _selectedTab == 0
            ? _HomeContent(
                onActionTap: _showComingSoon,
                onLogout: widget.onLogout,
              )
            : _EmptyTab(
                icon: _tabIcons[_selectedTab],
                title: _tabLabels[_selectedTab],
                onBackHome: () => setState(() => _selectedTab = 0),
              ),
      ),
      bottomNavigationBar: _DashboardNavBar(
        selectedIndex: _selectedTab,
        onChanged: (index) => setState(() => _selectedTab = index),
      ),
    );
  }
}

const List<IconData> _tabIcons = <IconData>[
  Icons.home_rounded,
  Icons.candlestick_chart_rounded,
  Icons.school_rounded,
  Icons.person_rounded,
];

const List<String> _tabLabels = <String>['Home', 'Markets', 'Learn', 'Profile'];

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onActionTap, required this.onLogout});

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _Header(onLogout: onLogout),
              const SizedBox(height: 24),
              const _WelcomeCard(),
              const SizedBox(height: 24),
              const _SectionHeader(title: '24H Global Session Clock'),
              const SizedBox(height: 12),
              const _SessionClockCard(),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.school_rounded,
                      label: 'Start Learning',
                      onTap: () => onActionTap('Learning'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.query_stats_rounded,
                      label: 'Explore Markets',
                      onTap: () => onActionTap('Markets'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.groups_rounded,
                      label: 'Community',
                      onTap: () => onActionTap('Community'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _SectionHeader(
                title: 'Market Overview',
                action: 'View all',
              ),
              const SizedBox(height: 12),
              const _MarketCard(),
              const SizedBox(height: 26),
              const _SectionHeader(
                title: 'Continue Learning',
                action: 'My courses',
              ),
              const SizedBox(height: 12),
              const _LearningCard(),
              const SizedBox(height: 26),
              const _SectionHeader(title: 'Your Watchlist', action: 'Manage'),
              const SizedBox(height: 12),
              const _WatchlistCard(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/branding/trade_x_final_logo.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Welcome to Trade X',
                style: TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: TradeXColors.goldBright,
          ),
          color: TradeXColors.surfaceRaised,
          onSelected: (value) async {
            if (value == 'logout') {
              await onLogout();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'logout', child: Text('Sign out')),
          ],
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26200C), Color(0xFF121713)],
        ),
        border: Border.all(color: TradeXColors.gold.withValues(alpha: 0.42)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trade smarter.\nGrow stronger.',
                  style: TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Your market learning journey starts here.',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.bolt_rounded, color: TradeXColors.goldBright, size: 52),
        ],
      ),
    );
  }
}

class _SessionClockCard extends StatelessWidget {
  const _SessionClockCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(
        const Duration(seconds: 1),
        (value) => value,
      ),
      builder: (context, snapshot) {
        final now = DateTime.now().toUtc();
        final hour = now.hour;
        final sessions = <({String name, String hours, int start, int end})>[
          (name: 'Tokyo', hours: '00:00 - 09:00 UTC', start: 0, end: 9),
          (name: 'London', hours: '08:00 - 17:00 UTC', start: 8, end: 17),
          (name: 'New York', hours: '13:00 - 22:00 UTC', start: 13, end: 22),
        ];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: TradeXColors.goldBright,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} UTC',
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '24H LIVE',
                    style: TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...sessions.map((session) {
                final open = hour >= session.start && hour < session.end;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: open
                              ? const Color(0xFF18D77A)
                              : TradeXColors.tertiaryText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          session.name,
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        session.hours,
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        open ? 'OPEN' : 'CLOSED',
                        style: TextStyle(
                          color: open
                              ? const Color(0xFF18D77A)
                              : TradeXColors.tertiaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: TradeXColors.goldBright,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 106,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TradeXColors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TradeXColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: TradeXColors.goldBright, size: 25),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: const Column(
        children: [
          _MarketRow(
            symbol: 'BTC',
            name: 'Bitcoin',
            price: r'$67,482.12',
            change: '+2.86%',
            positive: true,
          ),
          Divider(height: 1, color: TradeXColors.border),
          _MarketRow(
            symbol: 'ETH',
            name: 'Ethereum',
            price: r'$3,621.44',
            change: '+1.42%',
            positive: true,
          ),
          Divider(height: 1, color: TradeXColors.border),
          _MarketRow(
            symbol: 'XAU',
            name: 'Gold',
            price: r'$2,336.68',
            change: '-0.31%',
            positive: false,
          ),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.positive,
  });

  final String symbol;
  final String name;
  final String price;
  final String change;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? TradeXColors.success : TradeXColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TradeXColors.backgroundSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                color: TradeXColors.goldBright,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                change,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.play_circle_fill_rounded,
                color: TradeXColors.goldBright,
                size: 38,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trading Foundations',
                      style: TextStyle(
                        color: TradeXColors.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Lesson 3 of 12 · Risk management',
                      style: TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: const LinearProgressIndicator(
              value: 0.25,
              minHeight: 7,
              color: TradeXColors.goldBright,
              backgroundColor: TradeXColors.surfaceMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '25% complete',
            style: TextStyle(color: TradeXColors.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  const _WatchlistCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: const Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            color: TradeXColors.goldBright,
            size: 34,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Text(
              'Add instruments to your watchlist and follow the moves that matter.',
              style: TextStyle(color: TradeXColors.secondaryText, height: 1.35),
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: TradeXColors.goldBright),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.onBackHome,
  });

  final IconData icon;
  final String title;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: TradeXColors.goldBright, size: 58),
            const SizedBox(height: 18),
            Text(
              '$title is coming next',
              style: const TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We are building this part of your Trade X experience.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TradeXColors.secondaryText),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onBackHome,
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardNavBar extends StatelessWidget {
  const _DashboardNavBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TradeXColors.surface,
        border: Border(top: BorderSide(color: TradeXColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List<Widget>.generate(_tabLabels.length, (index) {
            final selected = index == selectedIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _tabIcons[index],
                        color: selected
                            ? TradeXColors.goldBright
                            : TradeXColors.tertiaryText,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tabLabels[index],
                        style: TextStyle(
                          color: selected
                              ? TradeXColors.goldBright
                              : TradeXColors.tertiaryText,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

final BoxDecoration _cardDecoration = BoxDecoration(
  color: TradeXColors.surfaceRaised,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: TradeXColors.border),
);
