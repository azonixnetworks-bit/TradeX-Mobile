import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/tradex_colors.dart';

/// Creates and shares the premium affiliate success card.
///
/// Keeping image rendering and temporary-file handling outside the dashboard
/// widget prevents platform concerns from leaking into the presentation code.
class AffiliateShareCardService {
  const AffiliateShareCardService();

  Future<void> share({
    required RenderBox? anchor,
    required String referralUrl,
    required String referralCode,
    required String earnings,
  }) async {
    final imageFile = await _createCard(
      earnings: earnings,
      referralCode: referralCode,
    );
    final message = referralUrl.isEmpty
        ? 'Join me on TradeX with referral code $referralCode.'
        : 'Join me on TradeX with referral code $referralCode: $referralUrl';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            imageFile.path,
            mimeType: 'image/png',
            name: 'TradeX_Affiliate_Success.png',
          ),
        ],
        text: message,
        sharePositionOrigin: anchor == null
            ? null
            : anchor.localToGlobal(Offset.zero) & anchor.size,
      ),
    );
  }

  Future<File> _createCard({
    required String earnings,
    required String referralCode,
  }) async {
    const cardWidth = 1080.0;
    const cardHeight = 1350.0;
    const canvasSize = Size(cardWidth, cardHeight);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(cardWidth, cardHeight),
          const [Color(0xFF010706), Color(0xFF071411), Color(0xFF241A05)],
          const [0, .58, 1],
        ),
    );

    canvas.drawCircle(
      const Offset(920, 120),
      360,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(920, 120), 360, const [
          Color(0x58FFC83D),
          Colors.transparent,
        ]),
    );
    canvas.drawCircle(
      const Offset(80, 1200),
      310,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(80, 1200), 310, const [
          Color(0x281E88FF),
          Colors.transparent,
        ]),
    );

    final gridPaint = Paint()
      ..color = const Color(0x22FFC83D)
      ..strokeWidth = 1;
    for (var x = 80.0; x < cardWidth; x += 120) {
      canvas.drawLine(Offset(x, 0), Offset(x, cardHeight), gridPaint);
    }
    for (var y = 90.0; y < cardHeight; y += 120) {
      canvas.drawLine(Offset(0, y), Offset(cardWidth, y), gridPaint);
    }

    final outer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 34, 1012, 1282),
      const Radius.circular(46),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = ui.Gradient.linear(
          const Offset(34, 34),
          const Offset(1046, 1316),
          const [Color(0xFFFFE37C), Color(0xFF9B6600), Color(0xFFFFD64F)],
        ),
    );

    final logo = await _loadAsset(
      'assets/branding/trade_x_final_logo.png',
      targetWidth: 250,
    );
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(415, 72, 250, 250),
      image: logo,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    logo.dispose();

    _paintText(
      canvas,
      'TRADEX AFFILIATE',
      const Rect.fromLTWH(90, 330, 900, 64),
      fontSize: 42,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: 3,
    );
    _paintText(
      canvas,
      'PREMIUM SUCCESS CARD',
      const Rect.fromLTWH(90, 390, 900, 50),
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: TradeXColors.goldBright,
      letterSpacing: 4,
    );

    final trustBadge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(286, 462, 508, 70),
      const Radius.circular(35),
    );
    canvas.drawRRect(trustBadge, Paint()..color = const Color(0xCC111A17));
    canvas.drawRRect(
      trustBadge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE0B62E),
    );
    _paintTrustShield(canvas, const Offset(330, 476));
    _paintText(
      canvas,
      'PREMIUM • TRUSTED • SECURE',
      const Rect.fromLTWH(370, 480, 390, 38),
      fontSize: 19,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFFFE68B),
      letterSpacing: 1.1,
    );

    final incomePanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(80, 570, 920, 330),
      const Radius.circular(34),
    );
    canvas.drawRRect(
      incomePanel,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(80, 570),
          const Offset(1000, 900),
          const [Color(0xF20B1715), Color(0xF2151409), Color(0xF2070C0B)],
        ),
    );
    canvas.drawRRect(
      incomePanel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFC89B16),
    );
    _paintText(
      canvas,
      'TOTAL AFFILIATE EARNINGS',
      const Rect.fromLTWH(130, 630, 820, 50),
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFAFC0D4),
      letterSpacing: 2.5,
    );
    _paintText(
      canvas,
      earnings,
      const Rect.fromLTWH(120, 704, 840, 116),
      fontSize: 82,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF00E6AD),
    );
    _paintText(
      canvas,
      'Earned through the TradeX affiliate network',
      const Rect.fromLTWH(130, 835, 820, 42),
      fontSize: 23,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFC4D0DE),
    );

    _paintText(
      canvas,
      'Grow your network. Earn premium rewards.',
      const Rect.fromLTWH(90, 950, 900, 54),
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    );

    final codePanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(170, 1035, 740, 112),
      const Radius.circular(22),
    );
    canvas.drawRRect(codePanel, Paint()..color = const Color(0xE5101918));
    canvas.drawRRect(
      codePanel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF52666A),
    );
    _paintText(
      canvas,
      'MY REFERRAL CODE',
      const Rect.fromLTWH(210, 1052, 660, 32),
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF9EB3C8),
      letterSpacing: 2,
    );
    _paintText(
      canvas,
      referralCode,
      const Rect.fromLTWH(210, 1084, 660, 48),
      fontSize: 30,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD44D),
      letterSpacing: 3,
    );
    _paintText(
      canvas,
      'Generated from the live TradeX affiliate dashboard',
      const Rect.fromLTWH(90, 1218, 900, 38),
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF8296A8),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('Affiliate share card encoding failed.');
    }
    final directory = await getTemporaryDirectory();
    final output = File(
      '${directory.path}${Platform.pathSeparator}tradex_affiliate_success.png',
    );
    await output.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return output;
  }

  Future<ui.Image> _loadAsset(String path, {required int targetWidth}) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Rect bounds, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double letterSpacing = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: bounds.width);
    painter.paint(
      canvas,
      Offset(
        bounds.left + (bounds.width - painter.width) / 2,
        bounds.top + (bounds.height - painter.height) / 2,
      ),
    );
  }

  void _paintTrustShield(Canvas canvas, Offset origin) {
    final shield = Path()
      ..moveTo(origin.dx + 20, origin.dy)
      ..lineTo(origin.dx + 40, origin.dy + 8)
      ..lineTo(origin.dx + 36, origin.dy + 31)
      ..quadraticBezierTo(
        origin.dx + 31,
        origin.dy + 42,
        origin.dx + 20,
        origin.dy + 48,
      )
      ..quadraticBezierTo(
        origin.dx + 9,
        origin.dy + 42,
        origin.dx + 4,
        origin.dy + 31,
      )
      ..lineTo(origin.dx, origin.dy + 8)
      ..close();
    canvas.drawPath(shield, Paint()..color = const Color(0xFFFFCB38));
    final check = Path()
      ..moveTo(origin.dx + 11, origin.dy + 24)
      ..lineTo(origin.dx + 18, origin.dy + 31)
      ..lineTo(origin.dx + 31, origin.dy + 17);
    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFF09100D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
