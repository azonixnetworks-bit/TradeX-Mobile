part of '../home_dashboard_screen.dart';

class _SessionClockCard extends StatefulWidget {
  const _SessionClockCard({required this.apiClient});

  final ApiGateway apiClient;

  @override
  State<_SessionClockCard> createState() => _SessionClockCardState();
}

class _SessionClockCardState extends State<_SessionClockCard>
    with WidgetsBindingObserver {
  static const _featuredNames = {'Sydney', 'Tokyo', 'London', 'New York'};

  List<_MarketSession> _dialSessions = const [];
  String _timezone = 'UTC';
  Timer? _refreshTimer;
  Timer? _clockTimer;
  Timer? _dialHoldTimer;
  DateTime _now = DateTime.now();
  late final Future<String> _deviceTimezone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deviceTimezone = AppPlatformRegistry.current.timezoneId();
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
    _dialHoldTimer?.cancel();
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

      if (mounted) {
        setState(() {
          _timezone = timezone;
          if (sessions.isNotEmpty) _dialSessions = sessions;
        });
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: _panelDecoration(context),
      child: Stack(
        children: [
          Positioned(
            left: -8,
            right: -8,
            top: 42,
            child: IgnorePointer(
              child: Opacity(
                opacity: context.isDarkMode ? .06 : .25,
                child: Image.asset(
                  'assets/home_ui/complex_png/soft_beige_london_skyline.png',
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    color: TradeXColors.goldBright,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'World Market Sessions',
                          style: TextStyle(
                            color: context.isDarkMode
                                ? Colors.white
                                : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}  $_timezone',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TradeXColors.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _LivePill(),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final dialSize = math.min(450.0, constraints.maxWidth);
                  return Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: (_) {
                        _dialHoldTimer?.cancel();
                        _dialHoldTimer = Timer(
                          const Duration(milliseconds: 3500),
                          () => _showClockPopup(dialSessions),
                        );
                      },
                      onLongPressEnd: (_) {
                        _dialHoldTimer?.cancel();
                        _dialHoldTimer = null;
                      },
                      child: SizedBox.square(
                        dimension: dialSize,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            key: const ValueKey('market-24h-clock'),
                            painter: _MarketClockDialPainter(
                              sessions: dialSessions,
                              now: now,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 7),
              const _ClockLegend(),
              const SizedBox(height: 12),
              _WorldClockGrid(now: now, sessions: sessions),
            ],
          ),
        ],
      ),
    );
  }

  List<_MarketSession> _fallbackSessions(DateTime utcNow) => [
    _MarketSession.fromFallback('Sydney', 22, 7, utcNow.hour),
    _MarketSession.fromFallback('Tokyo', 0, 9, utcNow.hour),
    _MarketSession.fromFallback('London', 8, 17, utcNow.hour),
    _MarketSession.fromFallback('New York', 13, 22, utcNow.hour),
  ];

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  void _showClockPopup(List<_MarketSession> sessions) {
    if (!mounted) return;
    _dialHoldTimer = null;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .72),
      builder: (_) => _MarketClockPopup(sessions: sessions),
    );
  }
}

class _MarketClockPopup extends StatefulWidget {
  const _MarketClockPopup({required this.sessions});
  final List<_MarketSession> sessions;
  @override
  State<_MarketClockPopup> createState() => _MarketClockPopupState();
}

class _MarketClockPopupState extends State<_MarketClockPopup> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('market-clock-popup'),
    elevation: 0,
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(18),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(520.0, constraints.maxWidth);
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('market-24h-clock-popup-dial'),
                painter: _MarketClockDialPainter(
                  sessions: widget.sessions,
                  now: _now,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
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
      key: const ValueKey('market-session-scroll'),
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: clocks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) =>
            SizedBox(width: 156, child: _WorldClockTile(clock: clocks[index])),
      ),
    );
  }

  DateTime _inZone(String timezone) {
    try {
      return AppPlatformRegistry.current.timeInZone(timezone, now);
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
    // Presentation only: time, status and session hours continue to be
    // supplied by the existing live market-clock API and timezone logic.
    final isOpen = clock.session?.isOpen ?? false;
    final stateColor = isOpen
        ? const Color(0xFF087E62)
        : const Color(0xFFBC2026);
    const radius = BorderRadius.all(Radius.circular(18));

    return Padding(
      key: ValueKey('market-session-card-${clock.label}'),
      padding: const EdgeInsets.fromLTRB(1, 2, 1, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87601B).withValues(alpha: .18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .045),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFDAAA45), width: 1.1),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFFEFB), Color(0xFFFBF6EE)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SessionCardFinishPainter()),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 2,
                height: 34,
                child: IgnorePointer(
                  child: Image.asset(
                    key: ValueKey('market-session-art-${clock.label}'),
                    _cityAsset(clock.label),
                    alignment: Alignment.bottomCenter,
                    fit: BoxFit.contain,
                    cacheWidth: 420,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 8, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clock.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101827),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 24,
                      height: 1.6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD79D20),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _digitalTime(clock.time),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: stateColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isOpen ? 'Open' : 'Closed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: stateColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${clock.hours} ${clock.time.timeZoneName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5D6878),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        fontFeatures: [FontFeature.tabularFigures()],
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
  }

  String _digitalTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _cityAsset(String city) => switch (city) {
    'London' => 'assets/market_sessions/london.png',
    'New York' => 'assets/market_sessions/new_york.png',
    'Tokyo' => 'assets/market_sessions/tokyo.png',
    'Sydney' => 'assets/market_sessions/sydney.png',
    _ => 'assets/market_sessions/london.png',
  };
}

/// Subtle ivory highlights and gold bottom waves, matching the approved card
/// reference. Pure paint: does not affect taps, scrolling or clock updates.
class _SessionCardFinishPainter extends CustomPainter {
  const _SessionCardFinishPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sheen = Path()
      ..moveTo(w * .72, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * .24)
      ..quadraticBezierTo(w * .87, h * .13, w * .72, 0)
      ..close();
    canvas.drawPath(sheen, Paint()..color = const Color(0x55FFFFFF));

    final ivoryWave = Path()
      ..moveTo(0, h - 18)
      ..quadraticBezierTo(w * .27, h - 29, w * .49, h - 18)
      ..quadraticBezierTo(w * .78, h - 9, w, h - 23)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ivoryWave, Paint()..color = const Color(0x50F9E4B1));

    final goldWave = Path()
      ..moveTo(0, h - 15)
      ..quadraticBezierTo(w * .25, h - 26, w * .49, h - 15)
      ..quadraticBezierTo(w * .8, h - 5, w, h - 19);
    canvas.drawPath(
      goldWave,
      Paint()
        ..color = const Color(0x66D8AA4B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SessionCardFinishPainter oldDelegate) => false;
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
