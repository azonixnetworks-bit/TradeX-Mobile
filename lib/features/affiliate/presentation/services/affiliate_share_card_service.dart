import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Creates and shares the API-backed premium affiliate card.
class AffiliateShareCardService {
  const AffiliateShareCardService();

  Future<void> share({
    required RenderBox? anchor,
    required String clientName,
    required String referralUrl,
    required String referralCode,
    required String earnings,
    required String averageEarningsPerSale,
    required int totalReferrals,
    required int qualifiedSales,
    required String commissionRate,
    required String currentLevel,
  }) async {
    final bytes = await renderCard(
      clientName: clientName,
      referralUrl: referralUrl,
      referralCode: referralCode,
      earnings: earnings,
      averageEarningsPerSale: averageEarningsPerSale,
      totalReferrals: totalReferrals,
      qualifiedSales: qualifiedSales,
      commissionRate: commissionRate,
      currentLevel: currentLevel,
    );
    final directory = await getTemporaryDirectory();
    final imageFile = File(
      '${directory.path}${Platform.pathSeparator}tradex_premium_affiliate_card.png',
    );
    await imageFile.writeAsBytes(bytes, flush: true);
    final message = referralUrl.isEmpty
        ? 'Join me on TradeX with referral code $referralCode.'
        : 'Join me on TradeX with referral code $referralCode: $referralUrl';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            imageFile.path,
            mimeType: 'image/png',
            name: 'TradeX_Premium_Affiliate_Card.png',
          ),
        ],
        text: message,
        sharePositionOrigin: anchor == null
            ? null
            : anchor.localToGlobal(Offset.zero) & anchor.size,
      ),
    );
  }

  /// Renders the shareable 1080 × 1920 card without platform file access.
  Future<Uint8List> renderCard({
    required String clientName,
    required String referralUrl,
    required String referralCode,
    required String earnings,
    required String averageEarningsPerSale,
    required int totalReferrals,
    required int qualifiedSales,
    required String commissionRate,
    required String currentLevel,
  }) async {
    const cardWidth = 1080.0;
    const cardHeight = 1920.0;
    const canvasSize = Size(cardWidth, cardHeight);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final conversion = totalReferrals <= 0
        ? 0.0
        : qualifiedSales * 100 / totalReferrals;

    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(cardWidth, cardHeight),
          const [
            Color(0xFF031225),
            Color(0xFF020806),
            Color(0xFF0B0B08),
            Color(0xFF171004),
          ],
          const [0, .38, .72, 1],
        ),
    );
    _paintAtmosphere(canvas, canvasSize);

    final outer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 34, 1012, 1852),
      const Radius.circular(48),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = ui.Gradient.linear(
          const Offset(34, 34),
          const Offset(1046, 1886),
          const [Color(0xFFFFE69B), Color(0xFF8B5C00), Color(0xFFFFD34D)],
          const [0, .5, 1],
        ),
    );

    final logo = await _loadAsset(
      'assets/branding/trade_x_final_logo.png',
      targetWidth: 310,
    );
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(385, 70, 310, 240),
      image: logo,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    logo.dispose();

    _paintText(
      canvas,
      'PREMIUM AFFILIATE EARNINGS',
      const Rect.fromLTWH(100, 310, 880, 48),
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFC8D4E6),
      letterSpacing: 6,
    );
    _paintText(
      canvas,
      clientName.toUpperCase(),
      const Rect.fromLTWH(120, 380, 840, 70),
      fontSize: 38,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: 1.5,
    );

    final valueBadge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(250, 458, 580, 68),
      const Radius.circular(34),
    );
    canvas.drawRRect(valueBadge, Paint()..color = const Color(0xB3111615));
    canvas.drawRRect(
      valueBadge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD6A721),
    );
    _paintText(
      canvas,
      'HIGH-VALUE PARTNER  •  $commissionRate% COMMISSION',
      const Rect.fromLTWH(270, 472, 540, 40),
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFFFDE73),
      letterSpacing: 1,
    );

    final incomePanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(70, 570, 940, 850),
      const Radius.circular(46),
    );
    canvas.drawRRect(
      incomePanel,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(70, 570),
          const Offset(1010, 1420),
          const [Color(0xE61B242B), Color(0xF208111A), Color(0xE6221805)],
          const [0, .55, 1],
        ),
    );
    canvas.drawRRect(
      incomePanel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = ui.Gradient.linear(
          const Offset(70, 570),
          const Offset(1010, 1420),
          const [Color(0xFFFFE39A), Color(0xFF9B6A09), Color(0xFFFFCC35)],
          const [0, .5, 1],
        ),
    );

    _paintText(
      canvas,
      'LIFETIME VERIFIED EARNINGS',
      const Rect.fromLTWH(120, 625, 840, 48),
      fontSize: 27,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFD7E0ED),
      letterSpacing: 2,
    );
    _paintText(
      canvas,
      earnings,
      const Rect.fromLTWH(105, 690, 870, 130),
      fontSize: 88,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD66B),
    );
    _paintText(
      canvas,
      'REAL REFERRALS  •  REAL EARNINGS',
      const Rect.fromLTWH(130, 820, 820, 42),
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF29DFA7),
      letterSpacing: 3,
    );

    final codePanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(105, 895, 630, 126),
      const Radius.circular(28),
    );
    canvas.drawRRect(codePanel, Paint()..color = const Color(0xD50A1116));
    canvas.drawRRect(
      codePanel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE2B53A),
    );
    _paintText(
      canvas,
      'REFERRAL CODE',
      const Rect.fromLTWH(140, 912, 560, 30),
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFAFC0D5),
      letterSpacing: 2.4,
    );
    _paintText(
      canvas,
      referralCode,
      const Rect.fromLTWH(130, 950, 580, 50),
      fontSize: 31,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD55C),
      letterSpacing: 3,
    );

    final qrData = referralUrl.isEmpty ? referralCode : referralUrl;
    final qrPanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(770, 875, 178, 178),
      const Radius.circular(22),
    );
    canvas.drawRRect(qrPanel, Paint()..color = Colors.white);
    final qrImage = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF0A1015),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF0A1015),
      ),
    ).toImage(154);
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(782, 887, 154, 154),
      image: qrImage,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );
    qrImage.dispose();

    _paintMetricPanel(
      canvas,
      const Rect.fromLTWH(105, 1085, 260, 170),
      label: 'TOTAL REFERRALS',
      value: '$totalReferrals',
    );
    _paintMetricPanel(
      canvas,
      const Rect.fromLTWH(410, 1085, 260, 170),
      label: 'CONVERSION RATE',
      value: '${conversion.toStringAsFixed(1)}%',
    );
    _paintMetricPanel(
      canvas,
      const Rect.fromLTWH(715, 1085, 260, 170),
      label: 'AVG / SALE',
      value: averageEarningsPerSale,
      accent: true,
    );

    final verifiedPanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(105, 1290, 870, 92),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      verifiedPanel,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(105, 1290),
          const Offset(975, 1382),
          const [Color(0xB13B270A), Color(0xD3111515), Color(0xB13B270A)],
          const [0, .5, 1],
        ),
    );
    canvas.drawRRect(
      verifiedPanel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFB98B20),
    );
    _paintTrustShield(canvas, const Offset(145, 1297));
    _paintText(
      canvas,
      'VERIFIED ${currentLevel.toUpperCase()} AFFILIATE',
      const Rect.fromLTWH(220, 1307, 700, 40),
      fontSize: 25,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFE5A0),
      letterSpacing: 1,
    );
    _paintText(
      canvas,
      'AUTHENTIC PROFILE  •  LIVE TRADEX DATA',
      const Rect.fromLTWH(220, 1346, 700, 25),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFC7D1DF),
      letterSpacing: 2,
    );

    _paintText(
      canvas,
      'Earn. Refer. Grow.',
      const Rect.fromLTWH(100, 1510, 880, 80),
      fontSize: 52,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFFFD267),
      letterSpacing: 1,
    );
    _paintText(
      canvas,
      'MORE TRADERS  •  A BRIGHTER TOMORROW',
      const Rect.fromLTWH(100, 1595, 880, 42),
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFD4DFED),
      letterSpacing: 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(170, 1725, 740, 96),
        const Radius.circular(48),
      ),
      Paint()..color = const Color(0xC90A121B),
    );
    _paintText(
      canvas,
      'SCAN THE QR  •  JOIN THE TRADEX COMMUNITY',
      const Rect.fromLTWH(205, 1748, 670, 46),
      fontSize: 19,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFBECBE0),
      letterSpacing: 1.4,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('Affiliate share card encoding failed.');
    }
    return bytes.buffer.asUint8List();
  }

  void _paintAtmosphere(Canvas canvas, Size size) {
    canvas.drawCircle(
      const Offset(870, 170),
      430,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(870, 170), 430, const [
          Color(0x4CFFC638),
          Colors.transparent,
        ]),
    );
    canvas.drawCircle(
      const Offset(120, 1640),
      440,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(120, 1640), 440, const [
          Color(0x351E88FF),
          Colors.transparent,
        ]),
    );
    final gridPaint = Paint()
      ..color = const Color(0x19FFC83D)
      ..strokeWidth = 1;
    for (var x = 40.0; x < size.width; x += 110) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 70.0; y < size.height; y += 110) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final chart = Path()
      ..moveTo(610, 550)
      ..lineTo(695, 500)
      ..lineTo(765, 532)
      ..lineTo(835, 430)
      ..lineTo(890, 468)
      ..lineTo(988, 348);
    canvas.drawPath(
      chart,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(610, 550),
          const Offset(988, 348),
          const [Color(0x00FFBD2E), Color(0xFFFFDA69)],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintMetricPanel(
    Canvas canvas,
    Rect rect, {
    required String label,
    required String value,
    bool accent = false,
  }) {
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          accent
              ? const [Color(0xFF2D2108), Color(0xFF11100B)]
              : const [Color(0xFF111B23), Color(0xFF090F14)],
        ),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent ? const Color(0xFFB98A1C) : const Color(0xFF334957),
    );
    _paintText(
      canvas,
      label,
      Rect.fromLTWH(rect.left + 15, rect.top + 26, rect.width - 30, 30),
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFB8C7D8),
      letterSpacing: 1.2,
    );
    _paintText(
      canvas,
      value,
      Rect.fromLTWH(rect.left + 10, rect.top + 75, rect.width - 20, 64),
      fontSize: value.length > 9 ? 31 : 41,
      fontWeight: FontWeight.w900,
      color: accent ? const Color(0xFFFFD25A) : Colors.white,
    );
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
      ..moveTo(origin.dx + 34, origin.dy)
      ..lineTo(origin.dx + 68, origin.dy + 13)
      ..lineTo(origin.dx + 62, origin.dy + 49)
      ..quadraticBezierTo(
        origin.dx + 53,
        origin.dy + 68,
        origin.dx + 34,
        origin.dy + 78,
      )
      ..quadraticBezierTo(
        origin.dx + 15,
        origin.dy + 68,
        origin.dx + 6,
        origin.dy + 49,
      )
      ..lineTo(origin.dx, origin.dy + 13)
      ..close();
    canvas.drawPath(shield, Paint()..color = const Color(0xFFFFCB38));
    final check = Path()
      ..moveTo(origin.dx + 19, origin.dy + 39)
      ..lineTo(origin.dx + 30, origin.dy + 50)
      ..lineTo(origin.dx + 52, origin.dy + 26);
    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFF09100D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
