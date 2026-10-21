import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/platform/app_background_service.dart';
import '../../../core/profile/local_profile_photo_store.dart';
import '../../../core/profile/pending_financial_form_store.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_ideas_repository.dart';
import '../data/learning_repository.dart';
import '../data/market_news_repository.dart';
import '../../profile/presentation/trusted_devices_screen.dart';
import '../../profile/presentation/mobile_number_details_screen.dart';
import '../../profile/presentation/withdrawal_method_screen.dart';
import '../../learn/data/learn_repository.dart';
import '../../learn/presentation/learn_module.dart';
import '../../auth/presentation/quick_unlock_settings_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../catalog/models/feature_spec.dart';
import '../../catalog/presentation/feature_catalog_screen.dart';

bool _timeZoneDatabaseInitialized = false;

void _ensureTimeZoneDatabase() {
  if (_timeZoneDatabaseInitialized) return;
  tz_data.initializeTimeZones();
  _timeZoneDatabaseInitialized = true;
}

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onLogout,
    required this.onForgetDevice,
    required this.onLogoutAll,
    required this.apiClient,
    required this.tradeIdeasRepository,
    required this.learningRepository,
    required this.authRepository,
  });

  final Future<void> Function() onLogout;
  final Future<void> Function() onForgetDevice;
  final Future<void> Function() onLogoutAll;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;
  final LearningRepository learningRepository;
  final AuthRepository authRepository;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late int _selectedTab;
  late final List<Widget?> _tabPages;

  @override
  void initState() {
    super.initState();
    _selectedTab = AppPreferences.instance.dashboardTab;
    _tabPages = List<Widget?>.filled(5, null);
    _tabPages[_selectedTab] = _buildTab(_selectedTab);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _restorePendingFinancialForm(),
    );
  }

  Future<void> _restorePendingFinancialForm() async {
    try {
      final draft = await PendingFinancialFormStore().readWithdrawal();
      if (!mounted || draft == null) return;
      WithdrawalMethod? method;
      for (final candidate in WithdrawalMethod.values) {
        if (candidate.name == draft.method) method = candidate;
      }
      final restoredMethod = method;
      if (restoredMethod == null) {
        await PendingFinancialFormStore().clearWithdrawal();
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
            apiClient: widget.apiClient,
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
    if (index == _selectedTab) return;
    setState(() {
      _selectedTab = index;
      _tabPages[index] ??= _buildTab(index);
    });
    unawaited(AppPreferences.instance.setDashboardTab(index));
  }

  Widget _buildTab(int index) => switch (index) {
    0 => _HomeContent(
      key: const PageStorageKey('home-tab'),
      onActionTap: _openAction,
      onLogout: widget.onLogout,
      apiClient: widget.apiClient,
      tradeIdeasRepository: widget.tradeIdeasRepository,
      learningRepository: widget.learningRepository,
    ),
    1 => _LearnTab(
      key: const PageStorageKey('learn-tab'),
      apiClient: widget.apiClient,
    ),
    2 => _TradeIdeasTab(
      key: const PageStorageKey('ideas-tab'),
      onActionTap: _openAction,
      apiClient: widget.apiClient,
    ),
    3 => _AffiliateTab(
      key: const PageStorageKey('affiliate-tab'),
      onActionTap: _openAction,
      apiClient: widget.apiClient,
    ),
    _ => _ProfileTab(
      key: const PageStorageKey('profile-tab'),
      onActionTap: _openAction,
      onLogout: widget.onLogout,
      onForgetDevice: widget.onForgetDevice,
      onLogoutAll: widget.onLogoutAll,
      apiClient: widget.apiClient,
      authRepository: widget.authRepository,
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
    if (normalized == 'services') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FeatureCatalogScreen(apiClient: widget.apiClient),
        ),
      );
      return;
    }
    if (normalized == 'tradex content') {
      openTradeXFeature(
        context,
        widget.apiClient,
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

    final id = switch (normalized) {
      'notifications' => 'notifications',
      'market categories' => 'market-screener',
      'economic news' => 'economic-news',
      'premium access' => 'products',
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
    openTradeXFeature(context, widget.apiClient, featureById(id));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(AppBackgroundService.moveToBackground());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: IndexedStack(
            index: _selectedTab,
            children: List<Widget>.generate(
              5,
              (index) => TickerMode(
                enabled: index == _selectedTab,
                child: _tabPages[index] ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _DashboardNavBar(
          selectedIndex: _selectedTab,
          onChanged: _selectTab,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    super.key,
    required this.onActionTap,
    required this.onLogout,
    required this.apiClient,
    required this.tradeIdeasRepository,
    required this.learningRepository,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;
  final LearningRepository learningRepository;

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
              _SessionClockCard(apiClient: apiClient),
              const SizedBox(height: 18),
              _MarketNewsSection(
                repository: MarketNewsRepository(apiClient),
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
              Icons.notifications_none_rounded,
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

class _SessionClockCard extends StatefulWidget {
  const _SessionClockCard({required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  State<_SessionClockCard> createState() => _SessionClockCardState();
}

class _SessionClockCardState extends State<_SessionClockCard>
    with WidgetsBindingObserver {
  static const _featuredNames = {'Sydney', 'Tokyo', 'London', 'New York'};

  List<_MarketSession> _dialSessions = const [];
  Timer? _refreshTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  late final Future<String> _deviceTimezone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureTimeZoneDatabase();
    _deviceTimezone = FlutterTimezone.getLocalTimezone().then(
      (timezone) => timezone.identifier,
    );
    _loadLiveMarketClock();
    _startTimers();
  }

  void _startTimers() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadLiveMarketClock(),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _stopTimers() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    _refreshTimer = null;
    _clockTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _now = DateTime.now());
      _loadLiveMarketClock();
      _startTimers();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTimers();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimers();
    super.dispose();
  }

  Future<void> _loadLiveMarketClock() async {
    var timezone = 'UTC';
    try {
      timezone = await _deviceTimezone;
      final response = await widget.apiClient.getJson(
        '/api/v1/market-clock?timezone=${Uri.encodeQueryComponent(timezone)}',
      );
      final data = response['data'];
      final rawSessions = data is Map ? data['sessions'] : null;
      if (rawSessions is! List) return;

      final sessions = rawSessions
          .whereType<Map>()
          .map((raw) => _MarketSession.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false);

      if (mounted && sessions.isNotEmpty) {
        setState(() => _dialSessions = sessions);
      }
    } catch (_) {
      // Local timezone clocks remain available offline; the next refresh
      // reconnects to Laravel for authoritative open/closed session states.
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final dialSessions = _dialSessions.isEmpty
        ? _fallbackSessions(now.toUtc())
        : _dialSessions;
    final sessions = dialSessions
        .where((session) => _featuredNames.contains(session.name))
        .toList(growable: false);
    return Container(
      key: const ValueKey('world-market-sessions'),
      padding: const EdgeInsets.all(5),
      decoration: _panelDecoration(context),
      child: _WorldClockGrid(now: now, sessions: sessions),
    );
  }

  List<_MarketSession> _fallbackSessions(DateTime utcNow) => [
    _MarketSession.fromFallback('Sydney', 22, 7, utcNow.hour),
    _MarketSession.fromFallback('Tokyo', 0, 9, utcNow.hour),
    _MarketSession.fromFallback('London', 8, 17, utcNow.hour),
    _MarketSession.fromFallback('New York', 13, 22, utcNow.hour),
  ];
}

class _WorldClockGrid extends StatelessWidget {
  const _WorldClockGrid({required this.now, required this.sessions});

  final DateTime now;
  final List<_MarketSession> sessions;

  @override
  Widget build(BuildContext context) {
    _MarketSession? sessionFor(String name) {
      for (final session in sessions) {
        if (session.name.toLowerCase() == name.toLowerCase()) return session;
      }
      return null;
    }

    _WorldClock clock(
      String label,
      String fallbackTimezone,
      String fallbackHours,
    ) {
      final session = sessionFor(label);
      final timezone = session?.timezone ?? fallbackTimezone;
      final hours = session == null
          ? fallbackHours
          : '${session.openLocal}–${session.closeLocal}';
      return _WorldClock(
        label: label,
        timezone: timezone,
        time: _inZone(timezone),
        hours: hours,
        session: session,
      );
    }

    final clocks = [
      clock('London', 'Europe/London', '08:00–17:00'),
      clock('New York', 'America/New_York', '08:00–17:00'),
      clock('Tokyo', 'Asia/Tokyo', '09:00–18:00'),
      clock('Sydney', 'Australia/Sydney', '08:00–17:00'),
    ];
    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < clocks.length; index++) ...[
            if (index > 0) const SizedBox(width: 5),
            Expanded(child: _WorldClockTile(clock: clocks[index])),
          ],
        ],
      ),
    );
  }

  DateTime _inZone(String timezone) {
    try {
      return tz.TZDateTime.now(tz.getLocation(timezone));
    } catch (_) {
      return now.toUtc();
    }
  }
}

class _WorldClock {
  const _WorldClock({
    required this.label,
    required this.timezone,
    required this.time,
    required this.hours,
    required this.session,
  });

  final String label;
  final String timezone;
  final DateTime time;
  final String hours;
  final _MarketSession? session;
}

class _WorldClockTile extends StatelessWidget {
  const _WorldClockTile({required this.clock});

  final _WorldClock clock;

  @override
  Widget build(BuildContext context) {
    final isOpen = clock.session?.isOpen ?? false;
    final stateColor = isOpen ? TradeXColors.success : const Color(0xFFFF6666);
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E0D),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF2B302D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clock.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TradeXColors.primaryText,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _digitalTime(clock.time),
            maxLines: 1,
            style: const TextStyle(
              color: TradeXColors.primaryText,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  maxLines: 1,
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${clock.hours} ${clock.time.timeZoneName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TradeXColors.tertiaryText,
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 29,
            width: double.infinity,
            child: CustomPaint(painter: _CitySkylinePainter(clock.label)),
          ),
        ],
      ),
    );
  }

  String _digitalTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _CitySkylinePainter extends CustomPainter {
  const _CitySkylinePainter(this.city);

  final String city;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00FFC83D), Color(0x66D4AF37)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final paint = Paint()..color = const Color(0xFFB78522);
    final dark = Paint()..color = const Color(0xFF6F5010);
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h - 3, w, 3), dark);

    switch (city) {
      case 'London':
        canvas.drawRect(
          Rect.fromLTWH(w * .08, h * .48, w * .16, h * .45),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * .27, h * .27, w * .16, h * .66),
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * .32, h * .10, w * .06, h * .2),
          paint,
        );
        canvas.drawCircle(Offset(w * .35, h * .47), w * .035, dark);
        canvas.drawRect(
          Rect.fromLTWH(w * .47, h * .58, w * .18, h * .35),
          paint,
        );
        canvas.drawRect(Rect.fromLTWH(w * .69, h * .4, w * .2, h * .53), paint);
      case 'New York':
        final widths = [.12, .14, .11, .17, .12, .15];
        final tops = [.5, .28, .43, .12, .38, .22];
        var x = w * .03;
        for (var index = 0; index < widths.length; index++) {
          final buildingWidth = w * widths[index];
          canvas.drawRect(
            Rect.fromLTWH(
              x,
              h * tops[index],
              buildingWidth,
              h * (1 - tops[index]),
            ),
            index.isEven ? paint : dark,
          );
          x += buildingWidth + w * .025;
        }
        canvas.drawRect(
          Rect.fromLTWH(w * .57, h * .03, w * .025, h * .14),
          paint,
        );
      case 'Tokyo':
        final mountain = Path()
          ..moveTo(0, h * .87)
          ..lineTo(w * .28, h * .48)
          ..lineTo(w * .52, h * .87)
          ..close();
        canvas.drawPath(mountain, dark);
        final tower = Path()
          ..moveTo(w * .58, h * .93)
          ..lineTo(w * .7, h * .15)
          ..lineTo(w * .82, h * .93)
          ..close();
        canvas.drawPath(tower, paint);
        canvas.drawRect(
          Rect.fromLTWH(w * .62, h * .49, w * .16, h * .04),
          dark,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * .59, h * .69, w * .22, h * .04),
          dark,
        );
      default:
        final roof = Path()
          ..moveTo(w * .04, h * .86)
          ..quadraticBezierTo(w * .22, h * .28, w * .48, h * .78)
          ..quadraticBezierTo(w * .62, h * .22, w * .92, h * .82)
          ..lineTo(w * .92, h * .92)
          ..lineTo(w * .04, h * .92)
          ..close();
        canvas.drawPath(roof, paint);
        canvas.drawLine(
          Offset(w * .5, h * .15),
          Offset(w * .5, h * .92),
          Paint()
            ..color = const Color(0xFFFFD65A)
            ..strokeWidth = 1,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CitySkylinePainter oldDelegate) =>
      oldDelegate.city != city;
}

class _MarketNewsSection extends StatefulWidget {
  const _MarketNewsSection({required this.repository, required this.onOpenAll});

  final MarketNewsRepository repository;
  final VoidCallback onOpenAll;

  @override
  State<_MarketNewsSection> createState() => _MarketNewsSectionState();
}

class _MarketNewsSectionState extends State<_MarketNewsSection> {
  late Future<List<MarketNewsItem>> _news;

  @override
  void initState() {
    super.initState();
    _news = widget.repository.latest();
  }

  void _retry() => setState(() => _news = widget.repository.latest());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MarketNewsItem>>(
      future: _news,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            key: const ValueKey('market-news-section'),
            height: 178,
            decoration: _panelDecoration(context),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: TradeXColors.goldBright,
              strokeWidth: 2.4,
            ),
          );
        }

        if (snapshot.hasError) {
          return _MarketNewsMessage(
            key: const ValueKey('market-news-section'),
            icon: Icons.cloud_off_rounded,
            message: 'Market news is temporarily unavailable.',
            action: 'Retry',
            onTap: _retry,
          );
        }

        final items = snapshot.data ?? const <MarketNewsItem>[];
        if (items.isEmpty) {
          return _MarketNewsMessage(
            key: const ValueKey('market-news-section'),
            icon: Icons.event_available_rounded,
            message: 'No published market updates right now.',
            action: 'Open calendar',
            onTap: widget.onOpenAll,
          );
        }

        final visible = items.take(4).toList(growable: false);
        return Container(
          key: const ValueKey('market-news-section'),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: _panelDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.newspaper_rounded,
                    color: TradeXColors.goldBright,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Market News',
                      style: TextStyle(
                        color: TradeXColors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenAll,
                    style: TextButton.styleFrom(
                      foregroundColor: TradeXColors.goldBright,
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                  childAspectRatio: 1.52,
                ),
                itemBuilder: (context, index) => _MarketNewsCard(
                  key: ValueKey('market-news-card-$index'),
                  item: visible[index],
                  artworkIndex: index,
                  onTap: widget.onOpenAll,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarketNewsMessage extends StatelessWidget {
  const _MarketNewsMessage({
    super.key,
    required this.icon,
    required this.message,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 142,
    padding: const EdgeInsets.all(16),
    decoration: _panelDecoration(context),
    child: Row(
      children: [
        Icon(icon, color: TradeXColors.goldBright, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
            ),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

class _MarketNewsCard extends StatelessWidget {
  const _MarketNewsCard({
    super.key,
    required this.item,
    required this.artworkIndex,
    required this.onTap,
  });

  final MarketNewsItem item;
  final int artworkIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final impactColor = switch (item.impact.toUpperCase()) {
      'HIGH' => const Color(0xFFFF5D5D),
      'MEDIUM' => TradeXColors.goldBright,
      _ => TradeXColors.success,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E0D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2B302D)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _MarketNewsArtworkPainter(artworkIndex)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0xF2050706)],
                      stops: [.22, .82],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: impactColor.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: impactColor.withValues(alpha: .55),
                              ),
                            ),
                            child: Text(
                              item.isLiveUpdate ? 'LIVE' : item.impact,
                              style: TextStyle(
                                color: impactColor,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (item.currency.isNotEmpty)
                            Text(
                              item.currency,
                              maxLines: 1,
                              style: const TextStyle(
                                color: TradeXColors.goldBright,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TradeXColors.primaryText,
                          fontSize: 9.5,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const SizedBox(height: 4),
                      Text(
                        _marketNewsTime(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TradeXColors.tertiaryText,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _marketNewsTime(MarketNewsItem item) {
    final timestamp = item.occurredAt;
    if (timestamp == null) {
      return item.isLiveUpdate ? 'Live update' : 'Scheduled';
    }
    final local = timestamp.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return 'Today • $hour:$minute';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} • $hour:$minute';
  }
}

class _MarketNewsArtworkPainter extends CustomPainter {
  const _MarketNewsArtworkPainter(this.variant);

  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: variant.isEven
            ? const [Color(0xFF152018), Color(0xFF070A08)]
            : const [Color(0xFF261A08), Color(0xFF090806)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final grid = Paint()
      ..color = TradeXColors.gold.withValues(alpha: .12)
      ..strokeWidth = .6;
    for (var x = 0.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final chart = Path()..moveTo(0, size.height * .58);
    final points = variant % 3 == 0
        ? const [.56, .47, .52, .33, .38, .19, .27]
        : variant % 3 == 1
        ? const [.31, .42, .35, .48, .29, .21, .25]
        : const [.48, .38, .43, .26, .31, .18, .12];
    for (var index = 0; index < points.length; index++) {
      chart.lineTo(
        size.width * index / (points.length - 1),
        size.height * points[index],
      );
    }
    canvas.drawPath(
      chart,
      Paint()
        ..color = TradeXColors.goldBright.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .26),
      size.shortestSide * .12,
      Paint()..color = TradeXColors.gold.withValues(alpha: .18),
    );
  }

  @override
  bool shouldRepaint(covariant _MarketNewsArtworkPainter oldDelegate) =>
      oldDelegate.variant != variant;
}

class _ContinueLearningSection extends StatefulWidget {
  const _ContinueLearningSection({
    required this.repository,
    required this.onActionTap,
  });

  final LearningRepository repository;
  final ValueChanged<String> onActionTap;

  @override
  State<_ContinueLearningSection> createState() =>
      _ContinueLearningSectionState();
}

class _ContinueLearningSectionState extends State<_ContinueLearningSection> {
  late Future<HomeLearningData> _learning;

  @override
  void initState() {
    super.initState();
    _learning = widget.repository.loadHomeLearning();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HomeLearningData>(
    future: _learning,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 144,
          child: Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          ),
        );
      }

      final learning = snapshot.data;
      if (learning == null) {
        return _PremiumLockedLearningCard(
          onUnlock: () => widget.onActionTap('Premium Access'),
        );
      }

      if (learning.isPremium) {
        return _PremiumContinueLearningCard(
          item: learning.continueItem ?? learning.defaultPremiumItem,
          onTap: () => widget.onActionTap(
            learning.continueItem == null
                ? 'Start learning'
                : 'Continue learning',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PremiumLockedLearningCard(
            onUnlock: () => widget.onActionTap('Premium Access'),
          ),
          if (learning.freeLessons.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Free Lessons',
              style: TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            _FreeLearningHorizontalList(
              lessons: learning.freeLessons,
              onTap: (lesson) =>
                  widget.onActionTap('Free lesson: ${lesson.lessonTitle}'),
            ),
          ],
        ],
      );
    },
  );
}

class _PremiumLockedLearningCard extends StatelessWidget {
  const _PremiumLockedLearningCard({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => Container(
    decoration: _panelDecoration(context),
    child: Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Opacity(
              opacity: .46,
              child: IgnorePointer(
                child: _PremiumContinueLearningCard(
                  item: const LearningItem(
                    courseTitle: 'Premium Market Mastery',
                    moduleTitle: 'Advanced Market Structure',
                    lessonTitle: 'Institutional Trading Framework',
                    lessonUuid: '',
                    progressPercent: 68,
                    lastPositionSeconds: 0,
                    lastWatchedAt: null,
                    isFree: false,
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                color: TradeXColors.goldBright,
                size: 30,
              ),
              const SizedBox(height: 7),
              const Text(
                'Premium content. Upgrade to continue learning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              _GoldButton(label: 'Unlock Premium', onTap: onUnlock),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PremiumContinueLearningCard extends StatelessWidget {
  const _PremiumContinueLearningCard({required this.item, required this.onTap});

  final LearningItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasHistory = item?.lastWatchedAt != null;
    final title = hasHistory
        ? item!.courseTitle
        : 'Start Your Learning Journey';
    final subtitle = item == null
        ? 'New premium lessons will appear here.'
        : '${item!.moduleTitle} · ${item!.lessonTitle}';
    final progress = (item?.progressPercent ?? 0).clamp(0, 100);

    return InkWell(
      onTap: item == null ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration(context),
        child: Row(
          children: [
            _CourseThumbnail(
              label: hasHistory ? 'CONTINUE\nLEARNING' : 'PREMIUM\nLEARNING',
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(99)),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 7,
                      color: TradeXColors.goldBright,
                      backgroundColor: TradeXColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasHistory ? '$progress% complete' : 'Start learning',
                    style: const TextStyle(
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

class _FreeLearningHorizontalList extends StatelessWidget {
  const _FreeLearningHorizontalList({
    required this.lessons,
    required this.onTap,
  });

  final List<LearningItem> lessons;
  final ValueChanged<LearningItem> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 130,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: lessons.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return SizedBox(
          width: 172,
          child: InkWell(
            onTap: () => onTap(lesson),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TradeXColors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TradeXColors.border),
              ),
              child: Row(
                children: [
                  _CourseThumbnail(label: 'FREE', compact: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TradeXColors.goldBright.withValues(
                              alpha: .16,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: TradeXColors.goldBright,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.lessonTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.moduleTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _LiveTradeIdeasCarousel extends StatefulWidget {
  const _LiveTradeIdeasCarousel({
    required this.repository,
    required this.onActionTap,
  });

  final TradeIdeasRepository repository;
  final ValueChanged<String> onActionTap;

  @override
  State<_LiveTradeIdeasCarousel> createState() =>
      _LiveTradeIdeasCarouselState();
}

class _LiveTradeIdeasCarouselState extends State<_LiveTradeIdeasCarousel> {
  late Future<List<DashboardTradeIdea>> _ideas;

  @override
  void initState() {
    super.initState();
    _ideas = widget.repository.latestThree();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DashboardTradeIdea>>(
      future: _ideas,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 230,
            child: Center(
              child: CircularProgressIndicator(color: TradeXColors.goldBright),
            ),
          );
        }

        final ideas = snapshot.data ?? const <DashboardTradeIdea>[];
        if (ideas.isEmpty) {
          return _NoTradeIdeasCard(
            onTap: () => widget.onActionTap('Trade ideas'),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 16),
            itemCount: ideas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _LiveTradeIdeaCard(
              idea: ideas[index],
              position: index,
              repository: widget.repository,
            ),
          ),
        );
      },
    );
  }
}

class _NoTradeIdeasCard extends StatelessWidget {
  const _NoTradeIdeasCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      height: 146,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(context),
      child: const Row(
        children: [
          Icon(
            Icons.insights_outlined,
            color: TradeXColors.goldBright,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'New TradeX market analysis will appear here as soon as it is published.',
              style: TextStyle(color: TradeXColors.secondaryText, height: 1.35),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LiveTradeIdeaCard extends StatefulWidget {
  const _LiveTradeIdeaCard({
    required this.idea,
    required this.position,
    required this.repository,
  });

  final DashboardTradeIdea idea;
  final int position;
  final TradeIdeasRepository repository;

  @override
  State<_LiveTradeIdeaCard> createState() => _LiveTradeIdeaCardState();
}

class _LiveTradeIdeaCardState extends State<_LiveTradeIdeaCard> {
  late Future<Uint8List?> _chart;

  @override
  void initState() {
    super.initState();
    _chart = widget.repository.chartBytes(widget.idea);
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;
    final directionColor = idea.direction == 'BUY'
        ? TradeXColors.success
        : idea.direction == 'SELL'
        ? TradeXColors.error
        : TradeXColors.goldBright;
    final label = switch (widget.position) {
      0 => 'LATEST',
      1 => 'RECENT',
      _ => 'PREVIOUS',
    };

    return Container(
      width: 306,
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallPill(label: label, color: TradeXColors.goldBright),
              const Spacer(),
              Text(
                idea.timeframe,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TradeChartPreview(chart: _chart),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TradeXColors.primaryText,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        idea.direction,
                        style: TextStyle(
                          color: directionColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SignalValue(label: 'Entry', value: idea.entry),
                      _SignalValue(label: 'SL', value: idea.stopLoss),
                      if (idea.targets.isNotEmpty)
                        _SignalValue(
                          label: idea.targets.first.label,
                          value: idea.targets.first.price,
                          valueColor: TradeXColors.success,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (idea.latestUpdate != null)
            Text(
              idea.latestUpdate!.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 10,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ReactionButton(
                icon: Icons.thumb_up_alt_outlined,
                count: idea.likesCount,
                selected: idea.viewerReaction == 'LIKE',
                onTap: () => _react(idea, 'LIKE'),
              ),
              const SizedBox(width: 10),
              _ReactionButton(
                icon: Icons.thumb_down_alt_outlined,
                count: idea.dislikesCount,
                selected: idea.viewerReaction == 'DISLIKE',
                onTap: () => _react(idea, 'DISLIKE'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: idea.tradingViewUrl == null
                ? null
                : () => _openTradingView(context, idea.tradingViewUrl!),
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: TradeXColors.gold.withValues(alpha: .7),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 15,
                    color: TradeXColors.goldBright,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Open TradingView',
                    style: TextStyle(
                      color: TradeXColors.goldBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _react(DashboardTradeIdea idea, String reaction) async {
    final previous = idea.viewerReaction;
    final next = previous == reaction ? null : reaction;
    setState(() => idea.applyReaction(next));
    try {
      final summary = await widget.repository.react(idea, next);
      if (mounted) setState(() => idea.applyReactionSummary(summary));
    } catch (_) {
      if (mounted) {
        setState(() => idea.applyReaction(previous));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save your reaction.')),
        );
      }
    }
  }

  Future<void> _openTradingView(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open TradingView right now.'),
          ),
        );
      }
    }
  }
}

class _TradeChartPreview extends StatelessWidget {
  const _TradeChartPreview({required this.chart});

  final Future<Uint8List?> chart;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 126,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List?>(
        future: chart,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes != null) {
            return Image.memory(bytes, fit: BoxFit.cover);
          }
          return Container(
            color: const Color(0xFF0A1514),
            alignment: Alignment.center,
            child: const _MiniCandles(),
          );
        },
      ),
    ),
  );
}

class _SignalValue extends StatelessWidget {
  const _SignalValue({
    required this.label,
    required this.value,
    this.valueColor = TradeXColors.primaryText,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const categories = [
      (
        label: 'Forex',
        ideas: '30+ Ideas',
        accent: Color(0xFF45D6A8),
        imageAsset: 'assets/branding/market_forex.png',
      ),
      (
        label: 'Crypto',
        ideas: '20+ Ideas',
        accent: Color(0xFFFFA928),
        imageAsset: 'assets/branding/market_crypto.png',
      ),
      (
        label: 'Stocks',
        ideas: '50+ Ideas',
        accent: Color(0xFF39B9FF),
        imageAsset: 'assets/branding/market_stocks.png',
      ),
      (
        label: 'Deriv',
        ideas: '15+ Ideas',
        accent: Color(0xFFFF5A54),
        imageAsset: 'assets/branding/market_deriv.png',
      ),
    ];
    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            width: 264,
            child: _CategoryTile(
              label: category.label,
              ideas: category.ideas,
              accent: category.accent,
              imageAsset: category.imageAsset,
              onTap: () => onTap('${category.label} trade ideas'),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.ideas,
    required this.accent,
    required this.imageAsset,
    required this.onTap,
  });

  final String label;
  final String ideas;
  final Color accent;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imageAsset),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: .78)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .18), blurRadius: 14),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Trade Ideas',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .28),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: accent.withValues(alpha: .74),
                        ),
                      ),
                      child: Text(
                        ideas,
                        style: TextStyle(
                          color: TradeXColors.goldBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestContentCard extends StatefulWidget {
  const _LatestContentCard({
    required this.apiClient,
    required this.onActionTap,
  });

  final TradeXApiClient apiClient;
  final ValueChanged<String> onActionTap;

  @override
  State<_LatestContentCard> createState() => _LatestContentCardState();
}

class _LatestContentCardState extends State<_LatestContentCard> {
  late Future<List<_ChannelVideo>> _videos;

  @override
  void initState() {
    super.initState();
    _videos = _loadVideos();
  }

  Future<List<_ChannelVideo>> _loadVideos() async {
    final response = await widget.apiClient.getJson(
      '/api/v1/our-channel/videos?per_page=12',
    );
    final data = response['data'];
    final videos = data is Map ? data['videos'] : null;
    if (videos is! List) return const [];
    final result = videos
        .whereType<Map>()
        .map(
          (video) => _ChannelVideo.fromJson(Map<String, dynamic>.from(video)),
        )
        .toList();
    result.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return result;
  }

  Future<void> _react(_ChannelVideo video, String reaction) async {
    final previous = video.viewerReaction;
    final next = previous == reaction ? null : reaction;
    setState(() => video.applyReaction(next));
    try {
      final response = await widget.apiClient.putJson(
        '/api/v1/our-channel/videos/${video.uuid}/reaction',
        next == null ? const {} : {'reaction': next},
      );
      final data = response['data'];
      final raw = data is Map ? data['reaction'] : null;
      if (mounted && raw is Map) {
        setState(
          () => video.applyReactionSummary(Map<String, dynamic>.from(raw)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => video.applyReaction(previous));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save your reaction.')),
        );
      }
    }
  }

  Future<void> _openVideo(String? rawUrl) async {
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open YouTube right now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_ChannelVideo>>(
    future: _videos,
    builder: (context, snapshot) {
      final videos = snapshot.data ?? const <_ChannelVideo>[];
      if (videos.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: _panelDecoration(context),
          child: const Row(
            children: [
              Icon(
                Icons.ondemand_video_rounded,
                color: TradeXColors.goldBright,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New TradeX videos will appear here as soon as they are published.',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 16),
          itemCount: videos.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: 298,
            child: _LatestVideoCard(
              video: videos[index],
              onOpen: _openVideo,
              onReact: _react,
            ),
          ),
        ),
      );
    },
  );
}

class _LatestVideoCard extends StatelessWidget {
  const _LatestVideoCard({
    required this.video,
    required this.onOpen,
    required this.onReact,
  });

  final _ChannelVideo video;
  final ValueChanged<String?> onOpen;
  final Future<void> Function(_ChannelVideo, String) onReact;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onOpen(video.watchUrl),
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(context),
      child: Row(
        children: [
          _YoutubeThumbnail(video: video),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (video.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    _ReactionButton(
                      icon: Icons.thumb_up_alt_outlined,
                      count: video.likesCount,
                      selected: video.viewerReaction == 'LIKE',
                      onTap: () => onReact(video, 'LIKE'),
                    ),
                    const SizedBox(width: 8),
                    _ReactionButton(
                      icon: Icons.thumb_down_alt_outlined,
                      count: video.dislikesCount,
                      selected: video.viewerReaction == 'DISLIKE',
                      onTap: () => onReact(video, 'DISLIKE'),
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

class _YoutubeThumbnail extends StatelessWidget {
  const _YoutubeThumbnail({required this.video});

  final _ChannelVideo video;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 102,
      height: 78,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video.thumbnailUrl != null)
            Image.network(
              video.thumbnailUrl!,
              fit: BoxFit.cover,
              cacheWidth: 306,
              cacheHeight: 234,
              errorBuilder: (_, _, _) => _fallback(),
            )
          else
            _fallback(),
          const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: TradeXColors.goldBright,
              size: 29,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _fallback() => Image.asset(
    'assets/branding/tradex_bull_bear_trading_emblem.png',
    fit: BoxFit.cover,
    cacheWidth: 306,
  );
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: selected
                ? TradeXColors.goldBright
                : TradeXColors.secondaryText,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: selected
                  ? TradeXColors.goldBright
                  : TradeXColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChannelVideo {
  _ChannelVideo({
    required this.uuid,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.watchUrl,
    required this.likesCount,
    required this.dislikesCount,
    required this.viewerReaction,
    required this.publishedAt,
  });

  factory _ChannelVideo.fromJson(Map<String, dynamic> json) {
    final youtube = json['youtube'] is Map
        ? Map<String, dynamic>.from(json['youtube'] as Map)
        : const <String, dynamic>{};
    final reactions = json['reactions'] is Map
        ? Map<String, dynamic>.from(json['reactions'] as Map)
        : const <String, dynamic>{};
    return _ChannelVideo(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Latest from TradeX',
      description: json['short_description']?.toString() ?? '',
      thumbnailUrl: youtube['thumbnail_url']?.toString(),
      watchUrl: youtube['watch_url']?.toString(),
      likesCount: (reactions['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (reactions['dislikes_count'] as num?)?.toInt() ?? 0,
      viewerReaction: reactions['viewer_reaction']?.toString(),
      publishedAt:
          DateTime.tryParse(json['published_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String uuid;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? watchUrl;
  int likesCount;
  int dislikesCount;
  String? viewerReaction;
  final DateTime publishedAt;

  void applyReaction(String? next) {
    if (viewerReaction == next) return;
    if (viewerReaction == 'LIKE') likesCount--;
    if (viewerReaction == 'DISLIKE') dislikesCount--;
    if (next == 'LIKE') likesCount++;
    if (next == 'DISLIKE') dislikesCount++;
    viewerReaction = next;
  }

  void applyReactionSummary(Map<String, dynamic> json) {
    likesCount = (json['likes_count'] as num?)?.toInt() ?? likesCount;
    dislikesCount = (json['dislikes_count'] as num?)?.toInt() ?? dislikesCount;
    viewerReaction = json['viewer_reaction']?.toString();
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

class _LearnTab extends StatelessWidget {
  const _LearnTab({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) =>
      LearnHomeScreen(repository: LearnRepository(apiClient));
}

class _TradeIdeasTab extends StatelessWidget {
  const _TradeIdeasTab({
    super.key,
    required this.onActionTap,
    required this.apiClient,
  });

  final ValueChanged<String> onActionTap;
  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _EntitlementAwareTab(
      apiClient: apiClient,
      title: 'Trade Ideas',
      introduction: 'Explore TradeX market-analysis tools. Protected prices, levels, charts and full analysis are requested only after the server confirms your membership.',
      protectedFeatures: [featureById('trade-idea-details')],
    );
  }
}

class _AffiliateTab extends StatelessWidget {
  const _AffiliateTab({
    super.key,
    required this.onActionTap,
    required this.apiClient,
  });

  final ValueChanged<String> onActionTap;
  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _EntitlementAwareTab(
      apiClient: apiClient,
      title: 'Affiliate Centre',
      introduction: 'Share your TradeX referral after activation, then follow direct referrals, qualified sales, progressive stages and verified commission records.',
      protectedFeatures: const [
        FeatureSpec(
          id: 'affiliate-overview',
          group: 'Affiliate & Referrals',
          title: 'Affiliate Overview',
          subtitle: 'Verified referral progress and current stage',
          icon: Icons.hub_rounded,
          endpoint: '/api/v1/affiliate/overview',
        ),
        FeatureSpec(
          id: 'direct-referrals',
          group: 'Affiliate & Referrals',
          title: 'Direct Referrals',
          subtitle: 'Your authorized direct referral records',
          icon: Icons.people_alt_rounded,
          endpoint: '/api/v1/affiliate/referrals',
        ),
        FeatureSpec(
          id: 'qualified-sales',
          group: 'Affiliate & Referrals',
          title: 'Qualified Sales',
          subtitle: 'Server-verified sale qualification history',
          icon: Icons.point_of_sale_rounded,
          endpoint: '/api/v1/affiliate/sales',
        ),
        FeatureSpec(
          id: 'commissions',
          group: 'Affiliate & Referrals',
          title: 'Commission Earnings',
          subtitle: 'Protected commission ledger and adjustments',
          icon: Icons.savings_rounded,
          endpoint: '/api/v1/affiliate/commissions',
        ),
      ],
    );
  }
}

class _EntitlementAwareTab extends StatefulWidget {
  const _EntitlementAwareTab({
    required this.apiClient,
    required this.title,
    required this.introduction,
    required this.protectedFeatures,
  });

  final TradeXApiClient apiClient;
  final String title;
  final String introduction;
  final List<FeatureSpec> protectedFeatures;

  @override
  State<_EntitlementAwareTab> createState() => _EntitlementAwareTabState();
}

class _EntitlementAwareTabState extends State<_EntitlementAwareTab> {
  late Future<bool> _status = _loadStatus();
  late Future<JsonMap> _products = LearnRepository(widget.apiClient).products();

  Future<bool> _loadStatus() async {
    final response = await widget.apiClient.getJson(
      '/api/v1/payments/activation-status',
    );
    final data = response['data'];
    return data is Map && data['premium_active'] == true;
  }

  void _reload() => setState(() {
    _status = _loadStatus();
    _products = LearnRepository(widget.apiClient).products();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _status,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: CircularProgressIndicator(color: TradeXColors.goldBright),
        );
      }
      if (snapshot.data == true && widget.protectedFeatures.length == 1) {
        return TradeXFeatureScreen(
          apiClient: widget.apiClient,
          spec: widget.protectedFeatures.first,
        );
      }
      return _ProtectedFeaturePreview(
        title: widget.title,
        introduction: widget.introduction,
        statusUnavailable: snapshot.hasError,
        premiumActive: snapshot.data == true,
        products: _products,
        features: widget.protectedFeatures,
        onOpen: _openProtected,
        onRetry: _reload,
      );
    },
  );

  Future<void> _openProtected(FeatureSpec feature) async {
    var active = false;
    try {
      active = await _loadStatus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An internet connection is required to verify premium access.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    if (!active) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PremiumAccessScreen(
            repository: LearnRepository(widget.apiClient),
          ),
        ),
      );
      if (!mounted) return;
      try {
        active = await _loadStatus();
      } catch (_) {
        active = false;
      }
    }
    if (!mounted) return;
    if (active) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              TradeXFeatureScreen(apiClient: widget.apiClient, spec: feature),
        ),
      );
    }
    if (mounted) _reload();
  }
}

class _ProtectedFeaturePreview extends StatelessWidget {
  const _ProtectedFeaturePreview({
    required this.title,
    required this.introduction,
    required this.statusUnavailable,
    required this.premiumActive,
    required this.products,
    required this.features,
    required this.onOpen,
    required this.onRetry,
  });

  final String title;
  final String introduction;
  final bool statusUnavailable;
  final bool premiumActive;
  final Future<JsonMap> products;
  final List<FeatureSpec> features;
  final ValueChanged<FeatureSpec> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(introduction, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        FutureBuilder<JsonMap>(
          future: products,
          builder: (context, snapshot) {
            final items = LearnRepository.list(snapshot.data?['items']);
            if (items.isEmpty) return const SizedBox.shrink();
            final product = LearnRepository.map(items.first);
            final price = LearnRepository.map(product['price']);
            final amount = [
              LearnRepository.text(price['currency']),
              LearnRepository.text(price['amount']),
            ].where((part) => part.isNotEmpty).join(' ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.workspace_premium_rounded,
                    color: TradeXColors.goldBright,
                  ),
                  title: Text(
                    LearnRepository.text(product['name'], 'TradeX membership'),
                  ),
                  subtitle: Text(
                    [
                      amount,
                      LearnRepository.text(product['description']),
                    ].where((part) => part.isNotEmpty).join(' • '),
                  ),
                ),
              ),
            );
          },
        ),
        if (statusUnavailable)
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_rounded),
              title: const Text('Membership status unavailable'),
              subtitle: const Text(
                'Program information remains available. Reconnect to verify protected access.',
              ),
              trailing: IconButton(
                tooltip: 'Retry',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
        const _RiskNotice(),
        const SizedBox(height: 16),
        Text(
          premiumActive
              ? 'Your available membership features'
              : 'Protected membership features',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(feature.icon)),
                title: Text(feature.title),
                subtitle: Text(feature.subtitle),
                trailing: Icon(
                  premiumActive
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                ),
                onTap: () => onOpen(feature),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'No referral totals, earnings, trade levels or charts are stored in this preview. TradeX requests them only from the authorized backend.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    super.key,
    required this.onActionTap,
    required this.onLogout,
    required this.onForgetDevice,
    required this.onLogoutAll,
    required this.apiClient,
    required this.authRepository,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;
  final Future<void> Function() onForgetDevice;
  final Future<void> Function() onLogoutAll;
  final TradeXApiClient apiClient;
  final AuthRepository authRepository;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  static const _photoStore = LocalProfilePhotoStore();
  final _imagePicker = ImagePicker();
  late Future<_CustomerProfile> _profile;
  Uint8List? _profilePhoto;
  String? _profileEmail;
  bool _fingerprintAdded = false;
  bool _passcodeAdded = false;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<_CustomerProfile> _loadProfile() async {
    final response = await widget.apiClient.getJson('/api/v1/profile/settings');
    final raw = response['data'];
    if (raw is! Map) throw StateError('TradeX profile data is unavailable.');
    var premiumAccess = false;
    try {
      final dashboard = await widget.apiClient.getJson('/api/v1/dashboard');
      premiumAccess =
          _asMap(_asMap(dashboard['data'])['account'])['premium_access'] ==
          true;
    } catch (_) {
      // Referral information stays hidden unless entitlement is confirmed.
    }
    final profile = _CustomerProfile.fromJson(
      Map<String, dynamic>.from(raw),
      premiumAccess: premiumAccess,
    );
    _profileEmail = profile.email;
    try {
      _profilePhoto = await _photoStore
          .read(profile.email)
          .timeout(const Duration(seconds: 1));
      final quickUnlock = await widget.authRepository
          .readLocalQuickUnlockConfig()
          .timeout(const Duration(seconds: 1));
      _fingerprintAdded = quickUnlock?.hasBiometric == true;
      _passcodeAdded = quickUnlock?.hasPasscode == true;
    } catch (_) {
      // The remote profile remains usable if optional local state is missing.
    }
    return profile;
  }

  void _refresh() {
    setState(() {
      _profile = _loadProfile();
    });
  }

  Future<void> _openMobileDetails(_CustomerProfile profile) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MobileNumberDetailsScreen(
          apiClient: widget.apiClient,
          number: profile.whatsApp,
          verified: profile.whatsAppVerified,
          telegramUsername: profile.telegramUsername,
        ),
      ),
    );
    if (changed == true && mounted) _refresh();
  }

  Future<bool> _openWithdrawal(WithdrawalMethod method) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            WithdrawalMethodScreen(apiClient: widget.apiClient, method: method),
      ),
    );
    if (saved == true && mounted) _refresh();
    return saved == true;
  }

  Future<void> _openQuickUnlockSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            QuickUnlockSettingsScreen(repository: widget.authRepository),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _openAccountSection(_CustomerProfile profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (sectionContext) => _ProfileSectionScreen(
          title: 'Account',
          subtitle: 'Manage your account details and app preferences.',
          child: _ProfileMenuPanel(
            children: [
              _MenuRow(
                icon: Icons.mail_outline_rounded,
                title: profile.email,
                subtitle: profile.emailVerified
                    ? 'Verified email · Locked for your security'
                    : 'Unverified email',
                status: Icon(
                  profile.emailVerified
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: profile.emailVerified
                      ? TradeXColors.success
                      : TradeXColors.goldBright,
                ),
                onTap: null,
              ),
              _MenuRow(
                icon: Icons.phone_outlined,
                title: 'Mobile Number',
                subtitle: profile.whatsAppVerified
                    ? 'Registered number verified'
                    : 'Verification required',
                onTap: () => _openMobileDetails(profile),
              ),
              _MenuRow(
                icon: Icons.language_rounded,
                title: 'Learning language',
                subtitle: profile.languageLabel,
                onTap: () => widget.onActionTap('Learning language'),
              ),
              _MenuRow(
                icon: Icons.brightness_6_rounded,
                title: 'Appearance',
                subtitle: 'System, Light or Dark theme',
                onTap: () => Navigator.of(sectionContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LearnSettingsScreen(
                      repository: LearnRepository(widget.apiClient),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _openWithdrawalSection(_CustomerProfile profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (sectionContext) => _ProfileSectionScreen(
          title: 'Withdrawal methods',
          subtitle: 'Add or update your verified payout destinations.',
          child: _FinancialMethodsCard(
            profile: profile,
            onTap: (method) async {
              final saved = await _openWithdrawal(method);
              if (saved && sectionContext.mounted) {
                Navigator.of(sectionContext).pop();
              }
            },
          ),
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _openSecuritySection(_CustomerProfile profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (sectionContext) => _ProfileSectionScreen(
          title: 'Security centre',
          subtitle: 'Protect quick access and review trusted devices.',
          child: _ProfileMenuPanel(
            children: [
              _MenuRow(
                icon: Icons.security_rounded,
                title: profile.totpConfirmed
                    ? 'Authenticator protected'
                    : 'Set up authenticator',
                subtitle: profile.totpConfirmed
                    ? 'TOTP protects sensitive account changes'
                    : 'Required before sensitive changes',
                onTap: () => widget.onActionTap('Authenticator security'),
              ),
              _MenuRow(
                icon: Icons.devices_other_rounded,
                title: 'Trusted devices',
                subtitle: 'Review or revoke devices with TOTP',
                onTap: () => Navigator.of(sectionContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TrustedDevicesScreen(apiClient: widget.apiClient),
                  ),
                ),
              ),
              _MenuRow(
                icon: Icons.fingerprint_rounded,
                title:
                    'Fingerprint: ${_fingerprintAdded ? 'Added' : 'Not added'}',
                subtitle: _fingerprintAdded
                    ? 'Tap to manage or remove fingerprint login'
                    : 'Add fingerprint login on this mobile',
                onTap: _openQuickUnlockSettings,
              ),
              _MenuRow(
                icon: Icons.pin_rounded,
                title: 'Passcode: ${_passcodeAdded ? 'Added' : 'Not added'}',
                subtitle: _passcodeAdded
                    ? 'Tap to change or remove your passcode'
                    : 'Add a secure 4-digit passcode',
                onTap: _openQuickUnlockSettings,
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _closeSectionAndRun(
    BuildContext sectionContext,
    Future<void> Function() action,
  ) async {
    Navigator.of(sectionContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (mounted) await action();
  }

  Future<void> _openHelpSection() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (sectionContext) => _ProfileSectionScreen(
          title: 'Help & account',
          subtitle: 'Get support or securely end active sessions.',
          child: _ProfileMenuPanel(
            children: [
              _MenuRow(
                icon: Icons.forum_outlined,
                title: 'Support centre',
                subtitle: 'Get help with your TradeX account',
                onTap: () => widget.onActionTap('Support centre'),
              ),
              _MenuRow(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'Keep quick login on this trusted device',
                danger: true,
                onTap: () => unawaited(
                  _closeSectionAndRun(sectionContext, widget.onLogout),
                ),
              ),
              _MenuRow(
                icon: Icons.phonelink_erase_rounded,
                title: 'Sign out and forget this device',
                subtitle: 'Remove fingerprint or passcode quick login',
                danger: true,
                onTap: () => unawaited(
                  _closeSectionAndRun(sectionContext, widget.onForgetDevice),
                ),
              ),
              _MenuRow(
                icon: Icons.logout_rounded,
                title: 'Sign out from all devices',
                subtitle: 'Revoke every active TradeX session',
                danger: true,
                onTap: () => unawaited(
                  _closeSectionAndRun(sectionContext, widget.onLogoutAll),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseProfilePhoto() async {
    final email = _profileEmail;
    if (email == null) return;
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 86,
      );
      if (selected == null) return;
      final bytes = await _photoStore.saveFromPath(
        accountEmail: email,
        sourcePath: selected.path,
      );
      if (mounted) setState(() => _profilePhoto = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the profile picture.')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    final email = _profileEmail;
    if (email == null) return;
    await _photoStore.remove(email);
    if (mounted) setState(() => _profilePhoto = null);
  }

  Future<void> _showProfilePhotoActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: TradeXColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: TradeXColors.goldBright,
                ),
                title: Text(
                  _profilePhoto == null
                      ? 'Add profile picture'
                      : 'Change profile picture',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _chooseProfilePhoto();
                },
              ),
              if (_profilePhoto != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: TradeXColors.error,
                  ),
                  title: const Text('Remove profile picture'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeProfilePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CustomerProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          );
        }
        if (snapshot.hasError) {
          return _TabScrollView(
            title: 'My Profile',
            subtitle: 'Manage your TradeX account securely.',
            children: [
              _ProfileStatusCard(
                icon: Icons.cloud_off_rounded,
                title: 'Profile unavailable',
                message:
                    'Pull down or tap Retry when your connection is ready.',
                actionLabel: 'Retry',
                onTap: _refresh,
              ),
            ],
          );
        }
        final profile = snapshot.requireData;
        return _TabScrollView(
          title: 'My Profile',
          subtitle: 'Your account, security and payment preferences.',
          children: [
            _CustomerProfileHero(
              profile: profile,
              photo: _profilePhoto,
              onPhotoTap: _showProfilePhotoActions,
            ),
            const SizedBox(height: 20),
            _ProfileMenuPanel(
              children: [
                _MenuRow(
                  key: const ValueKey('profile-main-account'),
                  icon: Icons.person_outline_rounded,
                  title: 'Account',
                  subtitle: 'Email, mobile number, language and appearance',
                  onTap: () => _openAccountSection(profile),
                ),
                _MenuRow(
                  key: const ValueKey('profile-main-withdrawal'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Withdrawal methods',
                  subtitle: 'PayPal, Binance, USDT TRC20 and bank account',
                  onTap: () => _openWithdrawalSection(profile),
                ),
                _MenuRow(
                  key: const ValueKey('profile-main-security'),
                  icon: Icons.verified_user_rounded,
                  title: 'Security centre',
                  subtitle: 'Authenticator, trusted devices, fingerprint and passcode',
                  onTap: () => _openSecuritySection(profile),
                ),
                _MenuRow(
                  key: const ValueKey('profile-main-help'),
                  icon: Icons.support_agent_rounded,
                  title: 'Help & account',
                  subtitle: 'Support and secure sign-out options',
                  onTap: _openHelpSection,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProfileSectionScreen extends StatelessWidget {
  const _ProfileSectionScreen({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: TradeXColors.secondaryText),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _ProfileMenuPanel extends StatelessWidget {
  const _ProfileMenuPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: _panelDecoration(context),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: List<Widget>.generate(children.length * 2 - 1, (index) {
        if (index.isOdd) {
          return const Divider(height: 1, color: TradeXColors.border);
        }
        return children[index ~/ 2];
      }),
    ),
  );
}

class _CustomerProfile {
  const _CustomerProfile({
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.accountType,
    required this.referralCode,
    required this.premiumAccess,
    required this.whatsApp,
    required this.whatsAppVerified,
    required this.telegramUsername,
    required this.languageLabel,
    required this.totpConfirmed,
    required this.financialMethods,
  });

  factory _CustomerProfile.fromJson(
    Map<String, dynamic> json, {
    required bool premiumAccess,
  }) {
    final profile = _asMap(json['profile']);
    final identity = _asMap(profile['identity']);
    final contact = _asMap(profile['contact']);
    final preferences = _asMap(profile['preferences']);
    final security = _asMap(profile['security']);
    final accountSecurity = _asMap(json['account_security']);
    final verification = _asMap(accountSecurity['verification']);
    final financial = _asMap(profile['financial']);
    final language = preferences['language_code']?.toString().toLowerCase();
    return _CustomerProfile(
      name: identity['name']?.toString() ?? 'TradeX Customer',
      email: identity['email']?.toString() ?? 'Email unavailable',
      emailVerified: verification['email_verified'] == true,
      accountType: identity['account_type']?.toString() ?? 'MEMBER',
      referralCode: premiumAccess
          ? identity['referral_code']?.toString() ?? ''
          : '',
      premiumAccess: premiumAccess,
      whatsApp: contact['whatsapp_number']?.toString() ?? 'Add WhatsApp number',
      whatsAppVerified: contact['whatsapp_verified'] == true,
      telegramUsername: contact['telegram_username']?.toString() ?? '',
      languageLabel:
          const {
            'en': 'English',
            'ta': 'Tamil',
            'si': 'Sinhala',
            'hi': 'Hindi',
            'ml': 'Malayalam',
            'te': 'Telugu',
            'ur': 'Urdu',
          }[language] ??
          'English',
      totpConfirmed: security['totp_confirmed'] == true,
      financialMethods: [
        _FinancialMethod(
          label: 'PayPal',
          icon: Icons.paypal_rounded,
          detail: _asMap(financial['paypal'])['email_masked']?.toString(),
          configured: _asMap(financial['paypal'])['configured'] == true,
        ),
        _FinancialMethod(
          label: 'Binance',
          icon: Icons.currency_bitcoin_rounded,
          detail: _asMap(financial['binance'])['email_masked']?.toString(),
          configured: _asMap(financial['binance'])['configured'] == true,
        ),
        _FinancialMethod(
          label: 'USDT TRC20',
          icon: Icons.account_balance_wallet_outlined,
          detail: _asMap(financial['usdt_trc20'])['address_masked']?.toString(),
          configured: _asMap(financial['usdt_trc20'])['configured'] == true,
        ),
        _FinancialMethod(
          label: 'Bank account',
          icon: Icons.account_balance_outlined,
          detail: _asMap(financial['bank'])['account_masked']?.toString(),
          configured: _asMap(financial['bank'])['configured'] == true,
        ),
      ],
    );
  }

  final String name;
  final String email;
  final bool emailVerified;
  final String accountType;
  final String referralCode;
  final bool premiumAccess;
  final String whatsApp;
  final bool whatsAppVerified;
  final String telegramUsername;
  final String languageLabel;
  final bool totpConfirmed;
  final List<_FinancialMethod> financialMethods;
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

class _FinancialMethod {
  const _FinancialMethod({
    required this.label,
    required this.icon,
    required this.detail,
    required this.configured,
  });

  final String label;
  final IconData icon;
  final String? detail;
  final bool configured;
}

class _CustomerProfileHero extends StatelessWidget {
  const _CustomerProfileHero({
    required this.profile,
    required this.photo,
    required this.onPhotoTap,
  });

  final _CustomerProfile profile;
  final Uint8List? photo;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF31250A), Color(0xFF111614)],
        ),
        border: Border.all(color: TradeXColors.gold.withValues(alpha: .65)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Change profile picture',
            child: InkWell(
              onTap: onPhotoTap,
              customBorder: const CircleBorder(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TradeXColors.gold.withValues(alpha: .16),
                      border: Border.all(
                        color: TradeXColors.goldBright,
                        width: 1.3,
                      ),
                      image: photo == null
                          ? null
                          : DecorationImage(
                              image: MemoryImage(photo!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: photo == null
                        ? Text(
                            profile.name.isEmpty
                                ? 'T'
                                : profile.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: TradeXColors.goldBright,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TradeXColors.goldBright,
                        border: Border.all(
                          color: TradeXColors.background,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 13,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  children: [
                    _SmallPill(
                      label: profile.accountType.toUpperCase(),
                      color: TradeXColors.goldBright,
                    ),
                    if (profile.premiumAccess &&
                        profile.referralCode.trim().isNotEmpty &&
                        profile.referralCode != '—')
                      _SmallPill(
                        label: 'REF ${profile.referralCode}',
                        color: TradeXColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialMethodsCard extends StatelessWidget {
  const _FinancialMethodsCard({required this.profile, required this.onTap});

  final _CustomerProfile profile;
  final Future<void> Function(WithdrawalMethod) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(context),
      child: Column(
        children: List.generate(profile.financialMethods.length, (index) {
          final method = profile.financialMethods[index];
          return Column(
            children: [
              _MenuRow(
                icon: method.icon,
                title: method.label,
                subtitle: method.configured
                    ? method.detail ?? 'Configured securely'
                    : 'Not configured',
                onTap: () => unawaited(
                  onTap(switch (method.label) {
                    'PayPal' => WithdrawalMethod.paypal,
                    'Binance' => WithdrawalMethod.binance,
                    'USDT TRC20' => WithdrawalMethod.usdtTrc20,
                    _ => WithdrawalMethod.localBank,
                  }),
                ),
              ),
              if (index != profile.financialMethods.length - 1)
                const Divider(height: 1, color: TradeXColors.border),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileStatusCard extends StatelessWidget {
  const _ProfileStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _panelDecoration(context),
    child: Column(
      children: [
        Icon(icon, size: 38, color: TradeXColors.goldBright),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        _GoldButton(label: actionLabel, onTap: onTap),
      ],
    ),
  );
}

class _TabScrollView extends StatelessWidget {
  const _TabScrollView({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Image.asset(
                'assets/branding/trade_x_wordmark.png',
                width: 128,
                height: 32,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ]),
          ),
        ),
      ],
    );
  }
}

// Kept temporarily for backwards-compatible golden references.
// ignore: unused_element
class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF30240A), Color(0xFF131A16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: TradeXColors.gold.withValues(alpha: .65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KEEP BUILDING YOUR EDGE',
              style: TextStyle(
                color: TradeXColors.goldBright,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Smart Money Concepts',
              style: TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Module 3 · Lesson 2: Break of Structure',
              style: TextStyle(color: TradeXColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 18),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                value: .68,
                minHeight: 8,
                color: TradeXColors.goldBright,
                backgroundColor: TradeXColors.surfaceMuted,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Text(
                  '68% complete',
                  style: TextStyle(
                    color: TradeXColors.goldBright,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _GoldButton(label: 'Resume', onTap: onTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ModuleList extends StatelessWidget {
  const _ModuleList({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const modules = [
      ('1', 'Trading Foundations', 'Complete', true),
      ('2', 'Risk Management', 'Complete', true),
      ('3', 'Market Structure', 'In progress', false),
      ('4', 'Trade Execution', 'Locked', false),
    ];
    return Container(
      decoration: _panelDecoration(context),
      child: Column(
        children: modules.map((module) {
          final index = modules.indexOf(module);
          final complete = module.$4;
          final locked = module.$3 == 'Locked';
          return InkWell(
            onTap: locked ? null : () => onTap(module.$2),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: complete
                          ? TradeXColors.success.withValues(alpha: .16)
                          : locked
                          ? TradeXColors.surfaceMuted
                          : TradeXColors.goldDeep.withValues(alpha: .38),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      complete
                          ? Icons.check_rounded
                          : locked
                          ? Icons.lock_outline_rounded
                          : Icons.play_arrow_rounded,
                      color: complete
                          ? TradeXColors.success
                          : locked
                          ? TradeXColors.tertiaryText
                          : TradeXColors.goldBright,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Module ${module.$1}: ${module.$2}',
                      style: TextStyle(
                        color: locked
                            ? TradeXColors.secondaryText
                            : TradeXColors.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    module.$3,
                    style: TextStyle(
                      color: complete
                          ? TradeXColors.success
                          : locked
                          ? TradeXColors.tertiaryText
                          : TradeXColors.goldBright,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (index != modules.length - 1) const SizedBox(width: 0),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ignore: unused_element
class _RecommendedCourseCard extends StatelessWidget {
  const _RecommendedCourseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: _panelDecoration(context),
        child: Row(
          children: [
            _CourseThumbnail(label: 'RISK\nMANAGEMENT'),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Management Mastery',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Protect capital before you pursue profit.',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: TradeXColors.goldBright,
            ),
          ],
        ),
      ),
    );
  }
}

// Kept as the original partial-screen visual reference.
// ignore: unused_element
class _RiskNotice extends StatelessWidget {
  const _RiskNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: TradeXColors.warning.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TradeXColors.warning.withValues(alpha: .35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: TradeXColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trade ideas are for educational purposes only. Trade at your own risk and always use your own analysis.',
              style: TextStyle(
                color: Color(0xFFE9DDAE),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _MarketFilterBar extends StatelessWidget {
  const _MarketFilterBar({required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    const markets = ['All', 'Forex', 'Crypto', 'Gold'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: markets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return InkWell(
            onTap: () => onActionTap('${markets[index]} trade ideas'),
            borderRadius: BorderRadius.circular(99),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: selected
                    ? TradeXColors.goldBright
                    : TradeXColors.surfaceRaised,
                border: Border.all(
                  color: selected
                      ? TradeXColors.goldBright
                      : TradeXColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  markets[index],
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF171308)
                        : TradeXColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ignore: unused_element
class _ExpandedIdeaCard extends StatelessWidget {
  const _ExpandedIdeaCard({
    required this.symbol,
    required this.market,
    required this.direction,
    required this.entry,
    required this.target,
    required this.stop,
    required this.status,
    required this.isPositive,
    required this.onTap,
  });

  final String symbol;
  final String market;
  final String direction;
  final String entry;
  final String target;
  final String stop;
  final String status;
  final bool isPositive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final directionColor = isPositive
        ? TradeXColors.success
        : TradeXColors.error;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(context),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                _SmallPill(label: market, color: TradeXColors.goldBright),
                const Spacer(),
                _SmallPill(
                  label: status,
                  color: status == 'ACTIVE'
                      ? TradeXColors.success
                      : TradeXColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _IdeaValue(
                    label: 'Direction',
                    value: direction,
                    color: directionColor,
                  ),
                ),
                Expanded(
                  child: _IdeaValue(label: 'Entry', value: entry),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IdeaValue(label: 'Take profit', value: target),
                ),
                Expanded(
                  child: _IdeaValue(
                    label: 'Stop loss',
                    value: stop,
                    color: TradeXColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Divider(color: TradeXColors.border, height: 1),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: TradeXColors.secondaryText,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'Updated moments ago',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: TradeXColors.goldBright,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IdeaValue extends StatelessWidget {
  const _IdeaValue({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color ?? TradeXColors.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .43)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// Kept as the original partial-screen visual reference.
// ignore: unused_element
class _AffiliateHero extends StatelessWidget {
  const _AffiliateHero({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D230B), Color(0xFF0F1915)],
        ),
        border: Border.all(color: TradeXColors.gold.withValues(alpha: .65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: TradeXColors.goldBright,
            size: 34,
          ),
          const SizedBox(height: 12),
          const Text(
            'Invite. Empower. Earn.',
            style: TextStyle(
              color: TradeXColors.primaryText,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your unique referral code is ready to share.',
            style: TextStyle(color: TradeXColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TradeXColors.borderStrong),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color: TradeXColors.goldBright,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TRADEX.OS/REF/TRXADMIN',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.copy_rounded,
                  color: TradeXColors.goldBright,
                  size: 17,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _GoldButton(label: 'Share Your Link', onTap: onShare),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AffiliateMetrics extends StatelessWidget {
  const _AffiliateMetrics();

  @override
  Widget build(BuildContext context) {
    const metrics = [
      ('0', 'Total referrals', Icons.groups_rounded),
      ('0', 'Qualified clients', Icons.verified_rounded),
      ('LKR 0.00', 'Available rewards', Icons.account_balance_wallet_rounded),
    ];
    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        childAspectRatio: .83,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: _panelDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metric.$3, color: TradeXColors.goldBright, size: 21),
              const Spacer(),
              Text(
                metric.$1,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                metric.$2,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: TradeXColors.goldBright,
                ),
                SizedBox(width: 8),
                Text(
                  'Community Builder',
                  style: TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Invite 5 qualified clients to unlock your first reward tier.',
              style: TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 13),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: 7,
                color: TradeXColors.goldBright,
                backgroundColor: TradeXColors.surfaceMuted,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '0 of 5 qualified clients',
              style: TextStyle(color: TradeXColors.secondaryText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AffiliateTools extends StatelessWidget {
  const _AffiliateTools({required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.people_alt_outlined,
            title: 'My Referrals',
            subtitle: 'See your referral network',
            onTap: () => onActionTap('My referrals'),
          ),
          const Divider(height: 1, color: TradeXColors.border),
          _MenuRow(
            icon: Icons.history_rounded,
            title: 'Rewards History',
            subtitle: 'Track your affiliate rewards',
            onTap: () => onActionTap('Rewards history'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final color = danger ? TradeXColors.error : TradeXColors.goldBright;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: danger
                                ? TradeXColors.error
                                : TradeXColors.primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 6),
                        status!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _DashboardNavBar extends StatefulWidget {
  const _DashboardNavBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<_DashboardNavBar> createState() => _DashboardNavBarState();
}

class _DashboardNavBarState extends State<_DashboardNavBar> {
  late double _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant _DashboardNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _tabItems.length;
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            tween: Tween<double>(
              begin: _previousIndex,
              end: widget.selectedIndex.toDouble(),
            ),
            builder: (context, activeIndex, child) {
              final activeCenter = (activeIndex + .5) * itemWidth;
              return SizedBox(
                key: const ValueKey('dashboard-nav-root'),
                height: 82,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 17,
                      child: ClipPath(
                        clipper: _TradeXNavNotchClipper(
                          notchCenter: activeCenter,
                        ),
                        child: Container(
                          key: const ValueKey('dashboard-nav-surface'),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF0A100E)
                                : theme.colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .38),
                                blurRadius: 18,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: activeCenter - 25,
                      top: 0,
                      child: Container(
                        key: ValueKey(
                          'dashboard-nav-selected-${widget.selectedIndex}',
                        ),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFE58E), TradeXColors.gold],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFF1AD),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TradeXColors.goldBright.withValues(
                                alpha: .45,
                              ),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          _tabItems[widget.selectedIndex].icon,
                          color: const Color(0xFF171308),
                          size: 25,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 15,
                      child: Row(
                        children: List.generate(_tabItems.length, (index) {
                          final item = _tabItems[index];
                          final selected = index == widget.selectedIndex;
                          return Expanded(
                            child: InkWell(
                              onTap: () => widget.onChanged(index),
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      opacity: selected ? 0 : 1,
                                      child: Icon(
                                        item.icon,
                                        size: 21,
                                        color: dark
                                            ? TradeXColors.secondaryText
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: selected ? 19 : 3),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      style: TextStyle(
                                        color: selected
                                            ? TradeXColors.goldBright
                                            : dark
                                            ? TradeXColors.secondaryText
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        fontSize: 9.5,
                                        fontWeight: selected
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                      ),
                                      child: Text(
                                        item.label,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TradeXNavNotchClipper extends CustomClipper<Path> {
  const _TradeXNavNotchClipper({required this.notchCenter});

  final double notchCenter;

  @override
  Path getClip(Size size) {
    const radius = 34.0;
    const depth = 25.0;
    final start = (notchCenter - radius).clamp(0.0, size.width).toDouble();
    final end = (notchCenter + radius).clamp(0.0, size.width).toDouble();
    final path = Path()..lineTo(start, 0);
    path.cubicTo(start + 10, 0, notchCenter - 19, depth, notchCenter, depth);
    path.cubicTo(notchCenter + 19, depth, end - 10, 0, end, 0);
    path
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TradeXNavNotchClipper oldClipper) {
    return oldClipper.notchCenter != notchCenter;
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

class _MarketSession {
  const _MarketSession({
    required this.name,
    required this.isOpen,
    required this.timezone,
    required this.openLocal,
    required this.closeLocal,
  });

  factory _MarketSession.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    return _MarketSession(
      name: json['name']?.toString() ?? 'Market',
      isOpen: status == 'open',
      timezone: json['timezone']?.toString() ?? 'UTC',
      openLocal: json['configured_open_local']?.toString() ?? '--:--',
      closeLocal: json['configured_close_local']?.toString() ?? '--:--',
    );
  }

  factory _MarketSession.fromFallback(
    String name,
    int startHour,
    int endHour,
    int utcHour,
  ) {
    final isOpen = startHour < endHour
        ? utcHour >= startHour && utcHour < endHour
        : utcHour >= startHour || utcHour < endHour;
    final timezone = switch (name) {
      'Sydney' => 'Australia/Sydney',
      'Tokyo' => 'Asia/Tokyo',
      'London' => 'Europe/London',
      'New York' => 'America/New_York',
      _ => 'UTC',
    };
    final configuredHours = switch (name) {
      'Tokyo' => ('09:00', '18:00'),
      _ => ('08:00', '17:00'),
    };
    return _MarketSession(
      name: name,
      isOpen: isOpen,
      timezone: timezone,
      openLocal: configuredHours.$1,
      closeLocal: configuredHours.$2,
    );
  }

  final String name;
  final bool isOpen;
  final String timezone;
  final String openLocal;
  final String closeLocal;
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

BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: Theme.of(context).dividerColor),
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: .19), blurRadius: 10),
  ],
);
