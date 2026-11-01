import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/domain/app_platform.dart';

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
    final message = referralUrl.isEmpty
        ? 'Join me on TradeX with referral code $referralCode.'
        : 'Join me on TradeX with referral code $referralCode: $referralUrl';
    final origin = anchor == null
        ? null
        : anchor.localToGlobal(Offset.zero) & anchor.size;
    await AppPlatformRegistry.current.shareImage(
      bytes: bytes,
      fileName: 'TradeX_Premium_Affiliate_Card.png',
      text: message,
      originLeft: origin?.left,
      originTop: origin?.top,
      originWidth: origin?.width,
      originHeight: origin?.height,
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
      'assets/affiliate/referral/01_TRADEX_Logo.png',
      targetWidth: 320,
    );
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(380, 52, 320, 302),
      image: logo,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    logo.dispose();

    await _paintAsset(
      canvas,
      'assets/affiliate/referral/02_Premium_Affiliate_Earnings_Title.png',
      const Rect.fromLTWH(146, 316, 788, 124),
      targetWidth: 788,
    );
    _paintText(
      canvas,
      clientName.toUpperCase(),
      const Rect.fromLTWH(120, 442, 840, 64),
      fontSize: 34,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: 1.5,
    );

    final valueBadge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(250, 518, 580, 62),
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
      const Rect.fromLTWH(270, 529, 540, 38),
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFFFDE73),
      letterSpacing: 1,
    );

    await _paintAsset(
      canvas,
      'assets/affiliate/referral/05_Gold_Growth_Arrow.png',
      const Rect.fromLTWH(785, 388, 220, 268),
      targetWidth: 220,
    );

    final incomePanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(70, 610, 940, 820),
      const Radius.circular(46),
    );
    canvas.drawRRect(
      incomePanel,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(70, 610),
          const Offset(1010, 1430),
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
          const Offset(70, 610),
          const Offset(1010, 1430),
          const [Color(0xFFFFE39A), Color(0xFF9B6A09), Color(0xFFFFCC35)],
          const [0, .5, 1],
        ),
    );

    await _paintAsset(
      canvas,
      'assets/affiliate/referral/13_Lifetime_Earnings_Badge.png',
      const Rect.fromLTWH(120, 650, 280, 123),
      targetWidth: 280,
    );
    _paintText(
      canvas,
      earnings,
      const Rect.fromLTWH(340, 650, 610, 123),
      fontSize: 88,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD66B),
    );
    await _paintAsset(
      canvas,
      'assets/affiliate/referral/15_Real_Referrals_Badge.png',
      const Rect.fromLTWH(385, 792, 310, 128),
      targetWidth: 310,
    );

    final codePanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(105, 930, 630, 126),
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
    await _paintAsset(
      canvas,
      'assets/affiliate/referral/06_Share_Icon.png',
      const Rect.fromLTWH(120, 948, 82, 86),
      targetWidth: 82,
    );
    _paintText(
      canvas,
      'REFERRAL CODE',
      const Rect.fromLTWH(210, 947, 490, 30),
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFAFC0D5),
      letterSpacing: 2.4,
    );
    _paintText(
      canvas,
      referralCode,
      const Rect.fromLTWH(205, 985, 500, 50),
      fontSize: 31,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFD55C),
      letterSpacing: 3,
    );

    final qrData = referralUrl.isEmpty ? referralCode : referralUrl;
    final qrPanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(770, 910, 178, 178),
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
      rect: const Rect.fromLTWH(782, 922, 154, 154),
      image: qrImage,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );
    qrImage.dispose();

    final inviteIcon = await _loadAsset(
      'assets/affiliate/referral/07_Invite_Icon.png',
      targetWidth: 84,
    );
    final growthIcon = await _loadAsset(
      'assets/affiliate/referral/08_Growth_Icon.png',
      targetWidth: 84,
    );
    final earningsIcon = await _loadAsset(
      'assets/affiliate/referral/09_Earnings_Icon.png',
      targetWidth: 84,
    );
    _paintMetricPanel(
      canvas,
      const Rect.fromLTWH(105, 1120, 260, 170),
      label: 'TOTAL REFERRALS',
      value: '$totalReferrals',
      icon: inviteIcon,
    );
    _paintMetricPanel(
      canvas,
      const Rect.fromLTWH(410, 1120, 260, 170),
      label: 'CONVERSION RATE',
      value: '${conversion.toStringAsFixed(1)}%',
      icon: growthIcon,
    );
    _paintMetricPanel(
      canvas,
      const Rect.fromLTWH(715, 1120, 260, 170),
      label: 'AVG / SALE',
      value: averageEarningsPerSale,
      accent: true,
      icon: earningsIcon,
    );
    inviteIcon.dispose();
    growthIcon.dispose();
    earningsIcon.dispose();

    final verifiedPanel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(105, 1312, 870, 90),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      verifiedPanel,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(105, 1312),
          const Offset(975, 1402),
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
    await _paintAsset(
      canvas,
      'assets/affiliate/referral/14_Verified_Affiliate_Badge.png',
      const Rect.fromLTWH(120, 1290, 285, 130),
      targetWidth: 285,
    );
    _paintText(
      canvas,
      '${currentLevel.toUpperCase()} • $commissionRate% COMMISSION',
      const Rect.fromLTWH(405, 1322, 530, 38),
      fontSize: 23,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFFFE5A0),
      letterSpacing: 1,
    );
    _paintText(
      canvas,
      'AUTHENTIC PROFILE  •  LIVE TRADEX DATA',
      const Rect.fromLTWH(405, 1362, 530, 25),
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFC7D1DF),
      letterSpacing: 2,
    );

    await _paintAsset(
      canvas,
      'assets/affiliate/referral/03_Refer_And_Earn_Title.png',
      const Rect.fromLTWH(165, 1490, 750, 120),
      targetWidth: 750,
    );
    await _paintAsset(
      canvas,
      'assets/affiliate/referral/04_Grow_Together_Tagline.png',
      const Rect.fromLTWH(166, 1610, 748, 107),
      targetWidth: 748,
    );
    await _paintAsset(
      canvas,
      'assets/affiliate/referral/12_Gold_Affiliate_Button.png',
      const Rect.fromLTWH(260, 1740, 560, 164),
      targetWidth: 560,
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
    ui.Image? icon,
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
    if (icon != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(rect.left + 86, rect.top + 8, 88, 82),
        image: icon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
    _paintText(
      canvas,
      label,
      Rect.fromLTWH(rect.left + 15, rect.top + 88, rect.width - 30, 27),
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFB8C7D8),
      letterSpacing: 1.2,
    );
    _paintText(
      canvas,
      value,
      Rect.fromLTWH(rect.left + 10, rect.top + 115, rect.width - 20, 48),
      fontSize: value.length > 9 ? 25 : 34,
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

  Future<void> _paintAsset(
    Canvas canvas,
    String path,
    Rect rect, {
    required int targetWidth,
  }) async {
    final image = await _loadAsset(path, targetWidth: targetWidth);
    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    image.dispose();
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
}
