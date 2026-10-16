import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_ideas_repository.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onLogout,
    required this.apiClient,
    required this.tradeIdeasRepository,
  });

  final Future<void> Function() onLogout;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;

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
          child: switch (_selectedTab) {
            0 => _HomeContent(
              key: const ValueKey('home'),
              onActionTap: _showComingSoon,
              onLogout: widget.onLogout,
              apiClient: widget.apiClient,
              tradeIdeasRepository: widget.tradeIdeasRepository,
            ),
            1 => _LearnTab(
              key: const ValueKey('learn'),
              onActionTap: _showComingSoon,
            ),
            2 => _TradeIdeasTab(
              key: const ValueKey('ideas'),
              onActionTap: _showComingSoon,
            ),
            3 => _AffiliateTab(
              key: const ValueKey('affiliate'),
              onActionTap: _showComingSoon,
            ),
            _ => _ProfileTab(
              key: const ValueKey('profile'),
              onActionTap: _showComingSoon,
              onLogout: widget.onLogout,
            ),
          },
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
    required this.apiClient,
    required this.tradeIdeasRepository,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;

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
              _SessionClockCard(apiClient: apiClient),
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
              _LiveTradeIdeasCarousel(
                repository: tradeIdeasRepository,
                onActionTap: onActionTap,
              ),
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
        height: 168,
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRADE SMARTER\nBUILD A FREER LIFE',
                      style: TextStyle(
                        color: TradeXColors.primaryText,
                        fontSize: 18,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Education  ·  Trade Ideas  ·  Opportunities',
                      style: TextStyle(
                        color: Color(0xFFD0D6D3),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _GoldButton(label: 'Continue Learning', onTap: onTap),
                  ],
                ),
              ),
              const Positioned(
                bottom: 9,
                right: 12,
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

class _SessionClockCard extends StatefulWidget {
  const _SessionClockCard({required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  State<_SessionClockCard> createState() => _SessionClockCardState();
}

class _SessionClockCardState extends State<_SessionClockCard> {
  static const _featuredNames = {'Sydney', 'Tokyo', 'London', 'New York'};

  List<_MarketSession> _dialSessions = const [];
  String _timezone = 'Local time';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLiveMarketClock();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadLiveMarketClock(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLiveMarketClock() async {
    var timezone = 'UTC';
    try {
      timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
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
        setState(() {
          _timezone = timezone;
          _dialSessions = sessions;
        });
      }
    } catch (_) {
      // The device clock remains useful offline; the next refresh reconnects
      // to Laravel and refreshes the authoritative session states.
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (tick) => tick),
      builder: (context, _) {
        final now = DateTime.now();
        final dialSessions = _dialSessions.isEmpty
            ? _fallbackSessions(now.toUtc())
            : _dialSessions;
        final sessions = dialSessions
            .where((session) => _featuredNames.contains(session.name))
            .toList(growable: false);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _panelDecoration,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    color: TradeXColors.goldBright,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}',
                          style: const TextStyle(
                            color: TradeXColors.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4,
                          ),
                        ),
                        Text(
                          _timezone == 'UTC' ? 'Your device time' : _timezone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _LivePill(),
                ],
              ),
              const SizedBox(height: 15),
              AspectRatio(
                aspectRatio: 1,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _MarketClockDialPainter(
                      sessions: dialSessions,
                      now: now,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _ClockLegend(),
              const SizedBox(height: 8),
              ...sessions.map((session) => _SessionRow(session: session)),
            ],
          ),
        );
      },
    );
  }

  List<_MarketSession> _fallbackSessions(DateTime utcNow) => [
    _MarketSession.fromFallback(
      'Sydney',
      '22:00 - 07:00 UTC',
      22,
      7,
      utcNow.hour,
    ),
    _MarketSession.fromFallback(
      'Tokyo',
      '00:00 - 09:00 UTC',
      0,
      9,
      utcNow.hour,
    ),
    _MarketSession.fromFallback(
      'London',
      '08:00 - 17:00 UTC',
      8,
      17,
      utcNow.hour,
    ),
    _MarketSession.fromFallback(
      'New York',
      '13:00 - 22:00 UTC',
      13,
      22,
      utcNow.hour,
    ),
  ];

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final _MarketSession session;

  @override
  Widget build(BuildContext context) {
    final stateColor = session.isOpen
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
            session.timeText,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            session.isOpen ? 'OPEN' : 'CLOSED',
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

class _ClockLegend extends StatelessWidget {
  const _ClockLegend();

  @override
  Widget build(BuildContext context) => const Wrap(
    alignment: WrapAlignment.center,
    spacing: 14,
    runSpacing: 5,
    children: [
      _LegendItem(color: Color(0xFFFF7A00), label: 'Session window'),
      _LegendItem(color: TradeXColors.success, label: 'Open now'),
      _LegendItem(color: Color(0xFFDCE8F2), label: 'Device time'),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: TradeXColors.secondaryText,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _MarketClockDialPainter extends CustomPainter {
  const _MarketClockDialPainter({required this.sessions, required this.now});

  final List<_MarketSession> sessions;
  final DateTime now;

  static const _orange = Color(0xFFFF7A00);
  static const _teal = Color(0xFF20C7A1);
  static const _dialBackground = Color(0xFF06182A);
  static const _ring = Color(0xFF1D3042);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final outer = radius * .94;

    canvas.drawCircle(center, outer, Paint()..color = _dialBackground);
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..color = const Color(0xFF2A4054)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      center,
      radius * .83,
      Paint()
        ..color = const Color(0xFF1B2D3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    _drawTicks(canvas, center, radius);
    _drawSessionTracks(canvas, center, radius);
    _drawClockHands(canvas, center, radius);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    for (var hour = 0; hour < 24; hour++) {
      final minute = hour * 60.0;
      final major = hour % 6 == 0;
      final inner = _polar(center, major ? radius * .84 : radius * .87, minute);
      final outer = _polar(center, radius * .92, minute);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = major ? _orange : const Color(0xFF587083)
          ..strokeWidth = major ? 1.8 : .75,
      );

      final labelPoint = _polar(center, radius * .8, minute);
      _text(
        canvas,
        hour == 0 ? '24' : hour.toString().padLeft(2, '0'),
        labelPoint,
        color: major ? _orange : const Color(0xFFD9E4EF),
        fontSize: major ? 10 : 8,
        weight: major ? FontWeight.w900 : FontWeight.w600,
      );
    }

    for (var minute = 15; minute < 1440; minute += 15) {
      if (minute % 60 == 0) continue;
      final inner = _polar(center, radius * .9, minute.toDouble());
      final outer = _polar(center, radius * .92, minute.toDouble());
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = const Color(0xFF395064)
          ..strokeWidth = .55,
      );
    }
  }

  void _drawSessionTracks(Canvas canvas, Offset center, double radius) {
    if (sessions.isEmpty) return;
    final outerTrack = radius * .75;
    const innerTrackFactor = .36;
    final available = outerTrack - radius * innerTrackFactor;
    final step = math.min(radius * .06, available / sessions.length);

    for (var index = 0; index < sessions.length; index++) {
      final session = sessions[index];
      final trackRadius = outerTrack - (index * step);
      if (trackRadius < radius * .34) break;
      final track = Rect.fromCircle(center: center, radius: trackRadius);
      canvas.drawArc(
        track,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = _ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(4, radius * .022),
      );

      for (final segment in session.dialSegments) {
        final sweep = _sweep(segment);
        if (sweep <= 0) continue;
        final start = _radians(segment.startMinute);
        if (session.isOpen) {
          canvas.drawArc(
            track,
            start,
            sweep,
            false,
            Paint()
              ..color = _teal.withValues(alpha: .38)
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(8, radius * .052)
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawArc(
          track,
          start,
          sweep,
          false,
          Paint()
            ..color = _orange
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(4.5, radius * .029)
            ..strokeCap = StrokeCap.round,
        );

        final marker = _polar(center, trackRadius, segment.endMinute % 1440);
        canvas.drawCircle(
          marker,
          session.isOpen ? math.max(2.8, radius * .015) : 2,
          Paint()..color = session.isOpen ? _teal : const Color(0xFF8BA1B6),
        );
      }

      if (session.dialSegments.isNotEmpty && radius > 120) {
        final segment = session.dialSegments.first;
        final span = segment.endMinute - segment.startMinute;
        if (span >= 150) {
          final midpoint = segment.startMinute + span / 2;
          final labelPoint = _polar(center, trackRadius, midpoint);
          _text(
            canvas,
            session.name.toUpperCase(),
            labelPoint,
            color: const Color(0xFF071421),
            fontSize: 6.5,
            weight: FontWeight.w900,
            rotation: _labelRotation(midpoint),
          );
        }
      }
    }
  }

  void _drawClockHands(Canvas canvas, Offset center, double radius) {
    final minuteOfDay = now.hour * 60 + now.minute + now.second / 60;
    final pointer = _polar(center, radius * .78, minuteOfDay);
    canvas.drawLine(
      center,
      pointer,
      Paint()
        ..color = _teal
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );

    final hourAngle = ((now.hour % 12) + now.minute / 60) * 30 - 90;
    final minuteAngle = (now.minute + now.second / 60) * 6 - 90;
    final secondAngle = (now.second * 6 - 90).toDouble();
    _hand(
      canvas,
      center,
      radius * .31,
      hourAngle,
      const Color(0xFFDCE8F2),
      5.0,
    );
    _hand(
      canvas,
      center,
      radius * .43,
      minuteAngle,
      const Color(0xFF8FA5BA),
      3.2,
    );
    _hand(canvas, center, radius * .51, secondAngle, _orange, 1.4);
    canvas.drawCircle(
      center,
      radius * .04,
      Paint()..color = const Color(0xFF0B2236),
    );
    canvas.drawCircle(
      center,
      radius * .04,
      Paint()
        ..color = _orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      center,
      radius * .012,
      Paint()..color = const Color(0xFFDCE8F2),
    );
  }

  void _hand(
    Canvas canvas,
    Offset center,
    double length,
    double degrees,
    Color color,
    double width,
  ) {
    final radians = degrees * math.pi / 180;
    final target = Offset(
      center.dx + length * math.cos(radians),
      center.dy + length * math.sin(radians),
    );
    canvas.drawLine(
      center,
      target,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  Offset _polar(Offset center, double radius, double minute) {
    final radians = _radians(minute);
    return Offset(
      center.dx + radius * math.cos(radians),
      center.dy + radius * math.sin(radians),
    );
  }

  double _radians(double minute) => (minute / 1440 * math.pi * 2) - math.pi / 2;

  double _sweep(_MarketDialSegment segment) => math.max(
    .001,
    (segment.endMinute - segment.startMinute) / 1440 * math.pi * 2,
  );

  double _labelRotation(double minute) {
    var rotation = minute / 1440 * math.pi * 2;
    if (rotation > math.pi / 2 && rotation < math.pi * 1.5) rotation += math.pi;
    return rotation;
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required double fontSize,
    required FontWeight weight,
    double? rotation,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (rotation != null) canvas.rotate(rotation);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarketClockDialPainter oldDelegate) => true;
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
          height: 266,
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
      decoration: _panelDecoration,
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
      decoration: _panelDecoration,
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

class _LearnTab extends StatelessWidget {
  const _LearnTab({super.key, required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      title: 'Learning Hub',
      subtitle: 'Build skill, discipline and consistency.',
      children: [
        _LearningProgressCard(onTap: () => onActionTap('Resume course')),
        const SizedBox(height: 22),
        const _SectionTitle(
          icon: Icons.auto_stories_rounded,
          title: 'Your Learning Path',
        ),
        const SizedBox(height: 10),
        _ModuleList(onTap: onActionTap),
        const SizedBox(height: 22),
        const _SectionTitle(
          icon: Icons.workspace_premium_rounded,
          title: 'Recommended for you',
        ),
        const SizedBox(height: 10),
        _RecommendedCourseCard(onTap: () => onActionTap('Recommended course')),
      ],
    );
  }
}

class _TradeIdeasTab extends StatelessWidget {
  const _TradeIdeasTab({super.key, required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      title: 'Trade Ideas',
      subtitle: 'Educational market ideas. Always manage your own risk.',
      children: [
        const _RiskNotice(),
        const SizedBox(height: 16),
        _MarketFilterBar(onActionTap: onActionTap),
        const SizedBox(height: 15),
        _ExpandedIdeaCard(
          symbol: 'XAUUSD',
          market: 'GOLD',
          direction: 'BUY',
          entry: '2340 - 2345',
          target: '2360 / 2375',
          stop: '2320',
          status: 'ACTIVE',
          isPositive: true,
          onTap: () => onActionTap('XAUUSD trade idea'),
        ),
        const SizedBox(height: 12),
        _ExpandedIdeaCard(
          symbol: 'BTCUSD',
          market: 'CRYPTO',
          direction: 'SELL',
          entry: '67,950 - 68,300',
          target: '66,800 / 66,200',
          stop: '68,800',
          status: 'WATCHING',
          isPositive: false,
          onTap: () => onActionTap('BTCUSD trade idea'),
        ),
        const SizedBox(height: 12),
        _ExpandedIdeaCard(
          symbol: 'EURUSD',
          market: 'FOREX',
          direction: 'BUY',
          entry: '1.0820 - 1.0830',
          target: '1.0880 / 1.0910',
          stop: '1.0790',
          status: 'ACTIVE',
          isPositive: true,
          onTap: () => onActionTap('EURUSD trade idea'),
        ),
      ],
    );
  }
}

class _AffiliateTab extends StatelessWidget {
  const _AffiliateTab({super.key, required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      title: 'Affiliate Centre',
      subtitle: 'Share TradeX. Build your community.',
      children: [
        _AffiliateHero(onShare: () => onActionTap('Share referral link')),
        const SizedBox(height: 20),
        const _SectionTitle(
          icon: Icons.account_tree_rounded,
          title: 'Your Performance',
        ),
        const SizedBox(height: 10),
        const _AffiliateMetrics(),
        const SizedBox(height: 20),
        const _SectionTitle(
          icon: Icons.emoji_events_rounded,
          title: 'Next Milestone',
        ),
        const SizedBox(height: 10),
        _MilestoneCard(onTap: () => onActionTap('Affiliate milestones')),
        const SizedBox(height: 20),
        _AffiliateTools(onActionTap: onActionTap),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    super.key,
    required this.onActionTap,
    required this.onLogout,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return _TabScrollView(
      title: 'My Profile',
      subtitle: 'Manage your TradeX account securely.',
      children: [
        _ProfileHero(onTap: () => onActionTap('Edit profile')),
        const SizedBox(height: 20),
        const _SectionTitle(
          icon: Icons.verified_user_rounded,
          title: 'Account & Security',
        ),
        const SizedBox(height: 10),
        _ProfileMenu(onActionTap: onActionTap, onLogout: onLogout),
        const SizedBox(height: 20),
        const _SectionTitle(
          icon: Icons.support_agent_rounded,
          title: 'Support',
        ),
        const SizedBox(height: 10),
        _SupportCard(onTap: () => onActionTap('Support centre')),
      ],
    );
  }
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
      decoration: _panelDecoration,
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
        decoration: _panelDecoration,
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
        decoration: _panelDecoration,
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
          decoration: _panelDecoration,
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
        decoration: _panelDecoration,
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

class _AffiliateTools extends StatelessWidget {
  const _AffiliateTools({required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration,
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Ink(
        padding: const EdgeInsets.all(17),
        decoration: _panelDecoration,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TradeXColors.goldBright, width: 1.3),
                image: const DecorationImage(
                  image: AssetImage('assets/branding/trade_x_final_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TradeX Client',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Secure account · Verified access',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 7),
                  _SmallPill(label: 'VERIFIED', color: TradeXColors.success),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: TradeXColors.goldBright),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.onActionTap, required this.onLogout});

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration,
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.person_outline_rounded,
            title: 'Personal details',
            subtitle: 'Name, email and mobile number',
            onTap: () => onActionTap('Personal details'),
          ),
          const Divider(height: 1, color: TradeXColors.border),
          _MenuRow(
            icon: Icons.lock_outline_rounded,
            title: 'Security',
            subtitle: 'Password, authenticator and sessions',
            onTap: () => onActionTap('Security'),
          ),
          const Divider(height: 1, color: TradeXColors.border),
          _MenuRow(
            icon: Icons.language_rounded,
            title: 'Learning language',
            subtitle: 'English',
            onTap: () => onActionTap('Learning language'),
          ),
          const Divider(height: 1, color: TradeXColors.border),
          _MenuRow(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'Sign out from this device',
            danger: true,
            onTap: () async => onLogout(),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: _panelDecoration,
        child: const Row(
          children: [
            Icon(
              Icons.forum_outlined,
              color: TradeXColors.goldBright,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help?',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Visit the TradeX Support Centre.',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: TradeXColors.goldBright),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

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
                  Text(
                    title,
                    style: TextStyle(
                      color: danger
                          ? TradeXColors.error
                          : TradeXColors.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
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
            Icon(Icons.chevron_right_rounded, color: color),
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

class _MarketSession {
  const _MarketSession({
    required this.name,
    required this.timeText,
    required this.isOpen,
    required this.dialSegments,
  });

  factory _MarketSession.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    return _MarketSession(
      name: json['name']?.toString() ?? 'Market',
      timeText: json['local_time']?.toString() ?? '--:--:--',
      isOpen: status == 'open',
      dialSegments: (json['dial_segments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (segment) =>
                _MarketDialSegment.fromJson(Map<String, dynamic>.from(segment)),
          )
          .toList(growable: false),
    );
  }

  factory _MarketSession.fromFallback(
    String name,
    String hours,
    int startHour,
    int endHour,
    int utcHour,
  ) {
    final isOpen = startHour < endHour
        ? utcHour >= startHour && utcHour < endHour
        : utcHour >= startHour || utcHour < endHour;
    final startMinute = startHour * 60;
    final endMinute = endHour * 60;
    final segments = endMinute > startMinute
        ? [_MarketDialSegment(startMinute.toDouble(), endMinute.toDouble())]
        : [
            _MarketDialSegment(startMinute.toDouble(), 1440),
            _MarketDialSegment(0, endMinute.toDouble()),
          ];
    return _MarketSession(
      name: name,
      timeText: hours,
      isOpen: isOpen,
      dialSegments: segments,
    );
  }

  final String name;
  final String timeText;
  final bool isOpen;
  final List<_MarketDialSegment> dialSegments;
}

class _MarketDialSegment {
  const _MarketDialSegment(this.startMinute, this.endMinute);

  factory _MarketDialSegment.fromJson(Map<String, dynamic> json) =>
      _MarketDialSegment(
        (json['start_minute'] as num?)?.toDouble() ?? 0,
        (json['end_minute'] as num?)?.toDouble() ?? 0,
      );

  final double startMinute;
  final double endMinute;
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
