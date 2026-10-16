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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$label is coming soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeXColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _selectedTab == 0
              ? _HomeContent(
                  key: const ValueKey('home'),
                  onActionTap: _showComingSoon,
                  onLogout: widget.onLogout,
                )
              : _DashboardPlaceholder(
                  key: ValueKey(_selectedTab),
                  icon: _tabItems[_selectedTab].icon,
                  title: _tabItems[_selectedTab].label,
                  onBackHome: () => setState(() => _selectedTab = 0),
                ),
        ),
      ),
      bottomNavigationBar: _DashboardNavBar(
        selectedIndex: _selectedTab,
        onChanged: (index) => setState(() => _selectedTab = index),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    super.key,
    required this.onActionTap,
    required this.onLogout,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;

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
              const SizedBox(height: 18),
              _HeroBanner(onTap: () => onActionTap('Continue learning')),
              const SizedBox(height: 20),
              const _SectionTitle(
                icon: Icons.schedule_rounded,
                title: '24H Global Session Clock',
              ),
              const SizedBox(height: 10),
              const _SessionClockCard(),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.menu_book_rounded,
                title: 'Continue Learning',
                action: 'View all',
                onAction: () => onActionTap('Learning library'),
              ),
              const SizedBox(height: 10),
              _LearningCard(onTap: () => onActionTap('Continue learning')),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.lightbulb_rounded,
                title: 'Latest Trade Idea',
                action: 'View all',
                onAction: () => onActionTap('Trade ideas'),
              ),
              const SizedBox(height: 10),
              _TradeIdeaCard(onTap: () => onActionTap('XAUUSD trade idea')),
              const SizedBox(height: 20),
              const _SectionTitle(
                icon: Icons.bar_chart_rounded,
                title: 'Market Categories',
              ),
              const SizedBox(height: 10),
              _CategoryGrid(onTap: onActionTap),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.article_rounded,
                title: 'Latest from TradeX',
                action: 'View all',
                onAction: () => onActionTap('TradeX content'),
              ),
              const SizedBox(height: 10),
              _LatestContentCard(onTap: () => onActionTap('Market outlook')),
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
            child: const Icon(
              Icons.notifications_none_rounded,
              color: TradeXColors.primaryText,
            ),
          ),
        ),
        PopupMenuButton<String>(
          color: TradeXColors.surfaceRaised,
          icon: const Icon(Icons.more_horiz_rounded, color: TradeXColors.gold),
          onSelected: (value) async {
            if (value == 'logout') await onLogout();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'logout', child: Text('Sign out')),
          ],
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 222,
        decoration: BoxDecoration(
          color: TradeXColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TradeXColors.gold.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: TradeXColors.gold.withValues(alpha: 0.08),
              blurRadius: 28,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * .67,
                  child: Image.asset(
                    'assets/branding/tradex_bull_bear_trading_emblem.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.18, 0.08),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF090D0B),
                      Color(0xED090D0B),
                      Color(0x48090D0B),
                    ],
                    stops: [0, .45, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRADE SMARTER\nBUILD A FREER LIFE',
                      style: TextStyle(
                        color: TradeXColors.primaryText,
                        fontSize: 24,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Education  ·  Trade Ideas  ·  Opportunities',
                      style: TextStyle(
                        color: Color(0xFFD0D6D3),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _GoldButton(label: 'Continue Learning', onTap: onTap),
                  ],
                ),
              ),
              const Positioned(
                bottom: 12,
                right: 16,
                child: Text(
                  'DISCIPLINE\nCREATES\nFREEDOM',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFFF4E1A5),
                    fontSize: 8,
                    height: 1.35,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionClockCard extends StatelessWidget {
  const _SessionClockCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (tick) => tick),
      builder: (context, _) {
        final now = DateTime.now().toUtc();
        final sessions = <_TradingSession>[
          const _TradingSession('Sydney', '22:00 - 07:00 UTC', 22, 7),
          const _TradingSession('Tokyo', '00:00 - 09:00 UTC', 0, 9),
          const _TradingSession('London', '08:00 - 17:00 UTC', 8, 17),
          const _TradingSession('New York', '13:00 - 22:00 UTC', 13, 22),
        ];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _panelDecoration,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    color: TradeXColors.goldBright,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)} UTC',
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                  const Spacer(),
                  const _LivePill(),
                ],
              ),
              const SizedBox(height: 15),
              ...sessions.map(
                (session) => _SessionRow(
                  session: session,
                  isOpen: session.isOpen(now.hour),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.isOpen});

  final _TradingSession session;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final stateColor = isOpen
        ? TradeXColors.success
        : TradeXColors.tertiaryText;
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: stateColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
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
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              color: stateColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration,
        child: Row(
          children: [
            _CourseThumbnail(label: 'SMART MONEY\nCONCEPTS'),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Module 3: Market Structure',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Lesson 2: Break of Structure (BOS)',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 13),
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    child: LinearProgressIndicator(
                      value: .68,
                      minHeight: 7,
                      color: TradeXColors.goldBright,
                      backgroundColor: TradeXColors.surfaceMuted,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '68% complete',
                    style: TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeIdeaCard extends StatelessWidget {
  const _TradeIdeaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration,
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'XAUUSD',
                  style: TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TradeXColors.goldDeep.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'GOLD',
                    style: TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.trending_up_rounded,
                  color: TradeXColors.success,
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2342.50',
                        style: TextStyle(
                          color: TradeXColors.success,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '▲ +12.80 (+0.55%)',
                        style: TextStyle(
                          color: TradeXColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _TradeLevels(),
              ],
            ),
            const SizedBox(height: 14),
            const _MiniCandles(),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const categories = [
      (label: 'Forex', icon: Icons.currency_exchange_rounded),
      (label: 'Crypto', icon: Icons.currency_bitcoin_rounded),
      (label: 'Stocks', icon: Icons.show_chart_rounded),
      (label: 'Deriv', icon: Icons.multiline_chart_rounded),
    ];
    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryTile(
          icon: category.icon,
          label: category.label,
          onTap: () => onTap('${category.label} trade ideas'),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
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
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: TradeXColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TradeXColors.gold.withValues(alpha: .7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: TradeXColors.goldBright, size: 28),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: TradeXColors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Trade Ideas',
              style: TextStyle(color: TradeXColors.secondaryText, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestContentCard extends StatelessWidget {
  const _LatestContentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration,
        child: Row(
          children: [
            _CourseThumbnail(label: 'MARKET\nOUTLOOK', compact: true),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Outlook: Gold & USD',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Key levels and setups to watch this week.',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: TradeXColors.secondaryText,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '24:35',
                        style: TextStyle(
                          color: TradeXColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.remove_red_eye_outlined,
                        color: TradeXColors.secondaryText,
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '12.4K',
                        style: TextStyle(
                          color: TradeXColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TradeXColors.goldBright, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: TradeXColors.primaryText,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(action!),
            style: TextButton.styleFrom(
              foregroundColor: TradeXColors.goldBright,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder({
    super.key,
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
              'Your Trade X experience is being built module by module.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TradeXColors.secondaryText),
            ),
            const SizedBox(height: 20),
            _GoldButton(label: 'Back to Home', onTap: onBackHome),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF080D0B),
        border: Border(top: BorderSide(color: Color(0xFF624C16))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 69,
          child: Row(
            children: List.generate(_tabItems.length, (index) {
              final item = _tabItems[index];
              final selected = index == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 230),
                          width: selected ? 34 : 0,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            color: TradeXColors.goldBright,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: TradeXColors.goldBright.withValues(
                                        alpha: .65,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        AnimatedScale(
                          scale: selected ? 1.13 : 1,
                          duration: const Duration(milliseconds: 230),
                          child: Icon(
                            item.icon,
                            size: 23,
                            color: selected
                                ? TradeXColors.goldBright
                                : TradeXColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: selected
                                ? TradeXColors.goldBright
                                : TradeXColors.secondaryText,
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w800
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
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE080), TradeXColors.goldBright],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF171308),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF171308),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseThumbnail extends StatelessWidget {
  const _CourseThumbnail({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 102.0 : 116.0;
    return Container(
      width: width,
      height: compact ? 88 : 102,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: const DecorationImage(
          image: AssetImage(
            'assets/branding/tradex_bull_bear_trading_emblem.png',
          ),
          fit: BoxFit.cover,
          alignment: Alignment(0, -.15),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x29000000), Color(0xD9000000)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  height: 1.02,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: TradeXColors.goldBright,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeLevels extends StatelessWidget {
  const _TradeLevels();

  @override
  Widget build(BuildContext context) {
    const data = [
      ('Direction', 'BUY', TradeXColors.success),
      ('Entry', '2340 - 2345', TradeXColors.primaryText),
      ('TP', '2360 / 2375', TradeXColors.primaryText),
      ('SL', '2320', TradeXColors.primaryText),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 51,
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: item.$3,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MiniCandles extends StatelessWidget {
  const _MiniCandles();

  @override
  Widget build(BuildContext context) {
    const values = [
      20.0,
      27.0,
      23.0,
      34.0,
      30.0,
      43.0,
      38.0,
      51.0,
      47.0,
      59.0,
      55.0,
      66.0,
    ];
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final positive = index != 2 && index != 6 && index != 9;
          return Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 5,
                height: values[index],
                decoration: BoxDecoration(
                  color: positive ? TradeXColors.success : TradeXColors.error,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: TradeXColors.success.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: TradeXColors.success.withValues(alpha: .55)),
      ),
      child: const Text(
        '24H LIVE',
        style: TextStyle(
          color: TradeXColors.success,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _TradingSession {
  const _TradingSession(this.name, this.hours, this.startHour, this.endHour);

  final String name;
  final String hours;
  final int startHour;
  final int endHour;

  bool isOpen(int utcHour) {
    if (startHour < endHour) return utcHour >= startHour && utcHour < endHour;
    return utcHour >= startHour || utcHour < endHour;
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _tabItems = [
  _TabItem('Home', Icons.home_rounded),
  _TabItem('Learn', Icons.menu_book_rounded),
  _TabItem('Trade Ideas', Icons.lightbulb_rounded),
  _TabItem('Affiliate', Icons.groups_rounded),
  _TabItem('Profile', Icons.person_outline_rounded),
];

final BoxDecoration _panelDecoration = BoxDecoration(
  color: TradeXColors.surfaceRaised,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: TradeXColors.border),
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: .19), blurRadius: 10),
  ],
);
