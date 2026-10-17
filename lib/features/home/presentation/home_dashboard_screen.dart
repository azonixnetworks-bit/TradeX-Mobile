import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_ideas_repository.dart';
import '../data/learning_repository.dart';

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
    required this.apiClient,
    required this.tradeIdeasRepository,
    required this.learningRepository,
  });

  final Future<void> Function() onLogout;
  final TradeXApiClient apiClient;
  final TradeIdeasRepository tradeIdeasRepository;
  final LearningRepository learningRepository;

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
              learningRepository: widget.learningRepository,
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
              apiClient: widget.apiClient,
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
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ensureTimeZoneDatabase();
    _loadLiveMarketClock();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadLiveMarketClock(),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
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
    final now = _now;
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
          const SizedBox(height: 16),
          _WorldClockGrid(now: now, deviceTimezone: _timezone),
        ],
      ),
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

class _WorldClockGrid extends StatelessWidget {
  const _WorldClockGrid({required this.now, required this.deviceTimezone});

  final DateTime now;
  final String deviceTimezone;

  @override
  Widget build(BuildContext context) {
    final clocks = [
      _WorldClock(
        'New Zealand',
        'Pacific/Auckland',
        _inZone('Pacific/Auckland'),
      ),
      _WorldClock('Device Time', deviceTimezone, now),
      _WorldClock('London', 'Europe/London', _inZone('Europe/London')),
      _WorldClock('New York', 'America/New_York', _inZone('America/New_York')),
    ];
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 8),
        itemCount: clocks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) =>
            SizedBox(width: 142, child: _WorldClockTile(clock: clocks[index])),
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
  const _WorldClock(this.label, this.timezone, this.time);

  final String label;
  final String timezone;
  final DateTime time;
}

class _WorldClockTile extends StatelessWidget {
  const _WorldClockTile({required this.clock});

  final _WorldClock clock;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF081B2B),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFF1A3850)),
    ),
    child: Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(painter: _AnalogClockPainter(time: clock.time)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          clock.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _digitalTime(clock.time),
          style: const TextStyle(
            color: TradeXColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          clock.timezone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: TradeXColors.tertiaryText, fontSize: 7),
        ),
      ],
    ),
  );

  String _digitalTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _AnalogClockPainter extends CustomPainter {
  const _AnalogClockPainter({required this.time});

  final DateTime time;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius * .93,
      Paint()..color = const Color(0xFFF9FAFB),
    );
    canvas.drawCircle(
      center,
      radius * .93,
      Paint()
        ..color = const Color(0xFF122237)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * .035),
    );
    for (var hour = 1; hour <= 12; hour++) {
      final radians = hour * math.pi / 6 - math.pi / 2;
      final position = Offset(
        center.dx + radius * .7 * math.cos(radians),
        center.dy + radius * .7 * math.sin(radians),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: TextStyle(
            color: const Color(0xFF101827),
            fontSize: math.max(6, radius * .16),
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        position - Offset(painter.width / 2, painter.height / 2),
      );
    }
    _drawHand(
      canvas,
      center,
      radius * .44,
      ((time.hour % 12) + time.minute / 60) * 30 - 90,
      const Color(0xFF172238),
      math.max(2.2, radius * .09),
    );
    _drawHand(
      canvas,
      center,
      radius * .62,
      (time.minute + time.second / 60) * 6 - 90,
      const Color(0xFF172238),
      math.max(1.6, radius * .055),
    );
    _drawHand(
      canvas,
      center,
      radius * .7,
      (time.second * 6 - 90).toDouble(),
      const Color(0xFFFF4247),
      math.max(.8, radius * .02),
    );
    canvas.drawCircle(
      center,
      math.max(2.3, radius * .075),
      Paint()..color = const Color(0xFFFF4247),
    );
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double length,
    double degrees,
    Color color,
    double width,
  ) {
    final radians = degrees * math.pi / 180;
    final endpoint = Offset(
      center.dx + length * math.cos(radians),
      center.dy + length * math.sin(radians),
    );
    canvas.drawLine(
      center,
      endpoint,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) => true;
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
    decoration: _panelDecoration,
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
        decoration: _panelDecoration,
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
          decoration: _panelDecoration,
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
      decoration: _panelDecoration,
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

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    super.key,
    required this.onActionTap,
    required this.onLogout,
    required this.apiClient,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;
  final TradeXApiClient apiClient;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late Future<_CustomerProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<_CustomerProfile> _loadProfile() async {
    final response = await widget.apiClient.getJson('/api/v1/profile/settings');
    final raw = response['data'];
    if (raw is! Map) throw StateError('TradeX profile data is unavailable.');
    return _CustomerProfile.fromJson(Map<String, dynamic>.from(raw));
  }

  void _refresh() => setState(() => _profile = _loadProfile());

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
            _CustomerProfileHero(profile: profile),
            const SizedBox(height: 20),
            const _SectionTitle(
              icon: Icons.person_outline_rounded,
              title: 'Account',
            ),
            const SizedBox(height: 10),
            Container(
              decoration: _panelDecoration,
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.mail_outline_rounded,
                    title: profile.email,
                    subtitle: 'Verified email · Locked for your security',
                    onTap: () => widget.onActionTap('Email details'),
                  ),
                  const Divider(height: 1, color: TradeXColors.border),
                  _MenuRow(
                    icon: Icons.phone_outlined,
                    title: profile.whatsApp,
                    subtitle: profile.whatsAppVerified
                        ? 'WhatsApp verified'
                        : 'WhatsApp verification required',
                    onTap: () => widget.onActionTap('WhatsApp contact'),
                  ),
                  const Divider(height: 1, color: TradeXColors.border),
                  _MenuRow(
                    icon: Icons.language_rounded,
                    title: 'Learning language',
                    subtitle: profile.languageLabel,
                    onTap: () => widget.onActionTap('Learning language'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Withdrawal methods',
            ),
            const SizedBox(height: 10),
            _FinancialMethodsCard(profile: profile, onTap: widget.onActionTap),
            const SizedBox(height: 20),
            const _SectionTitle(
              icon: Icons.verified_user_rounded,
              title: 'Security centre',
            ),
            const SizedBox(height: 10),
            Container(
              decoration: _panelDecoration,
              child: Column(
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
                  const Divider(height: 1, color: TradeXColors.border),
                  _MenuRow(
                    icon: Icons.devices_other_rounded,
                    title: 'Trusted devices',
                    subtitle: 'Review or revoke devices with TOTP',
                    onTap: () => widget.onActionTap('Trusted devices'),
                  ),
                  const Divider(height: 1, color: TradeXColors.border),
                  _MenuRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Quick unlock',
                    subtitle: 'Fingerprint or passcode on this device',
                    onTap: () => widget.onActionTap('Quick unlock'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              icon: Icons.support_agent_rounded,
              title: 'Help & account',
            ),
            const SizedBox(height: 10),
            Container(
              decoration: _panelDecoration,
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.forum_outlined,
                    title: 'Support centre',
                    subtitle: 'Get help with your TradeX account',
                    onTap: () => widget.onActionTap('Support centre'),
                  ),
                  const Divider(height: 1, color: TradeXColors.border),
                  _MenuRow(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    subtitle: 'Sign out from this device',
                    danger: true,
                    onTap: () => widget.onLogout(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerProfile {
  const _CustomerProfile({
    required this.name,
    required this.email,
    required this.accountType,
    required this.referralCode,
    required this.whatsApp,
    required this.whatsAppVerified,
    required this.languageLabel,
    required this.totpConfirmed,
    required this.financialMethods,
  });

  factory _CustomerProfile.fromJson(Map<String, dynamic> json) {
    final profile = _asMap(json['profile']);
    final identity = _asMap(profile['identity']);
    final contact = _asMap(profile['contact']);
    final preferences = _asMap(profile['preferences']);
    final security = _asMap(profile['security']);
    final financial = _asMap(profile['financial']);
    final language = preferences['language_code']?.toString().toLowerCase();
    return _CustomerProfile(
      name: identity['name']?.toString() ?? 'TradeX Customer',
      email: identity['email']?.toString() ?? 'Email unavailable',
      accountType: identity['account_type']?.toString() ?? 'MEMBER',
      referralCode: identity['referral_code']?.toString() ?? '—',
      whatsApp: contact['whatsapp_number']?.toString() ?? 'Add WhatsApp number',
      whatsAppVerified: contact['whatsapp_verified'] == true,
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
  final String accountType;
  final String referralCode;
  final String whatsApp;
  final bool whatsAppVerified;
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
  const _CustomerProfileHero({required this.profile});

  final _CustomerProfile profile;

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
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TradeXColors.gold.withValues(alpha: .16),
              border: Border.all(color: TradeXColors.goldBright, width: 1.3),
            ),
            child: Text(
              profile.name.isEmpty ? 'T' : profile.name[0].toUpperCase(),
              style: const TextStyle(
                color: TradeXColors.goldBright,
                fontSize: 25,
                fontWeight: FontWeight.w900,
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
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration,
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
                onTap: () => onTap('${method.label} withdrawal method'),
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
    decoration: _panelDecoration,
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
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A100E),
                            border: Border.all(
                              color: TradeXColors.gold.withValues(alpha: .42),
                            ),
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
                                        color: TradeXColors.secondaryText,
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
                                            : TradeXColors.secondaryText,
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
