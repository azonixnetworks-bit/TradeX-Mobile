part of '../home_dashboard_screen.dart';

// Light-theme-only visual rendition of the live 24-hour dial.
// Dynamic sessions, open/closed data, time geometry, and animation behavior
// intentionally mirror the original dark painter without hardcoded time data.
class _LightMarketClockDialPainter extends CustomPainter {
  const _LightMarketClockDialPainter({required this.sessions, required this.now});

  final List<_MarketSession> sessions;
  final DateTime now;

  static const _orange = Color(0xFFFF7A00);
  static const _teal = Color(0xFF20C7A1);
  static const _lightTrack = Color(0xFFD9DFEA);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    // Reference light dial: navy outer hours, silver concentric face,
    // thin gold bezel. The background outside the circle stays transparent.
    _drawLightFace(canvas, center, radius);

    _drawTicks(canvas, center, radius);
    _drawSessionTracks(canvas, center, radius);
    _drawClockHands(canvas, center, radius);
  }

  void _drawLightFace(Canvas canvas, Offset center, double radius) {
    final outer = radius * .94;
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF203349), Color(0xFF142538), Color(0xFF071627)],
          stops: [0, .78, 1],
        ).createShader(Rect.fromCircle(center: center, radius: outer)),
    );
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..color = const Color(0xFFE8AE11).withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..color = const Color(0xFFFFC62C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      center,
      radius * .831,
      Paint()
        ..color = const Color(0xFF53647B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final faceRadius = radius * .773;
    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8F9FC),
            Color(0xFFDCE2F0),
          ],
          stops: [0, .52, 1],
        ).createShader(Rect.fromCircle(center: center, radius: faceRadius)),
    );
    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    for (var factor = .741; factor >= .34; factor -= .035) {
      canvas.drawCircle(
        center,
        radius * factor,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, radius * .009),
      );
    }
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
          ..color = major
              ? const Color(0xFFFFC32B)
              : const Color(0xFFFFC026)
          ..strokeWidth = major ? 2.2 : .75,
      );

      final labelPoint = _polar(center, radius * .8, minute);
      _text(
        canvas,
        hour == 0 ? '24' : hour.toString().padLeft(2, '0'),
        labelPoint,
        color: major ? const Color(0xFFFFC12B) : const Color(0xFFE6EDF7),
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
          ..color = const Color(0xFFAD8A2F)
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
          ..color = _lightTrack
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
            ..shader = const SweepGradient(
              colors: [
                Color(0xFFFFA000),
                Color(0xFFFFD400),
                Color(0xFFFFEA00),
                Color(0xFFFF8000),
                Color(0xFFFFA000),
              ],
            ).createShader(track)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(4.5, radius * .029)
            ..strokeCap = StrokeCap.round,
        );

        final marker = _polar(center, trackRadius, segment.endMinute % 1440);
        final dotRadius = math.max(2, radius * .015);
        canvas.drawCircle(marker, dotRadius, Paint()..color = Colors.white);
        canvas.drawCircle(
          marker,
          dotRadius,
          Paint()
            ..color = session.isOpen ? _teal : const Color(0xFFFFA000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
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
      const Color(0xFF172336),
      5.0,
    );
    _hand(
      canvas,
      center,
      radius * .43,
      minuteAngle,
      const Color(0xFFB8C4D4),
      3.2,
    );
    _hand(canvas, center, radius * .51, secondAngle, _orange, 1.4);
    canvas.drawCircle(
      center,
      radius * .04,
      Paint()..color = const Color(0xFF142337),
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
      Paint()..color = Colors.white,
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
  bool shouldRepaint(covariant _LightMarketClockDialPainter oldDelegate) => true;
}
