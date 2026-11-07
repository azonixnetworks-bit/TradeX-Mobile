import 'package:flutter/material.dart';

import '../../../core/theme/tradex_design_system.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
    required this.onSkip,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewport.maxHeight - 32,
                      maxWidth: 560,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/branding/trade_x_wordmark.png',
                              width: 142,
                              height: 48,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: onSkip,
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  color: palette.goldText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Learn. Trade.\nGrow with '),
                              TextSpan(
                                text: 'TradeX.',
                                style: TextStyle(color: palette.goldText),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            color: palette.primaryText,
                            fontSize: 39,
                            height: 1.08,
                            letterSpacing: -1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Master the markets with expert education and access professional trading services — all in one app.',
                          style: TextStyle(
                            color: palette.secondaryText,
                            fontSize: 16,
                            height: 1.42,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: (viewport.maxHeight * .34).clamp(
                            250.0,
                            360.0,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 250,
                                maxHeight: 360,
                              ),
                              child: const _WelcomeHero(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PrimaryWelcomeButton(
                          label: 'Get Started',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: onGetStarted,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: onSignIn,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: palette.primaryText,
                              side: BorderSide(color: palette.borderStrong),
                              shape: RoundedRectangleBorder(
                                borderRadius: TradeXRadii.control,
                              ),
                              backgroundColor: palette.surface.withValues(
                                alpha: .72,
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(child: _PageIndicator()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryWelcomeButton extends StatelessWidget {
  const _PrimaryWelcomeButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.gold, const Color(0xFFB77A08)],
          ),
          borderRadius: TradeXRadii.control,
          boxShadow: [
            BoxShadow(
              color: palette.gold.withValues(alpha: .24),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: TradeXRadii.control,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.primaryButtonText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: palette.primaryButtonText, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: context.palette.goldText,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 10),
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: context.palette.borderStrong,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 10),
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: context.palette.borderStrong,
          shape: BoxShape.circle,
        ),
      ),
    ],
  );
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          right: bounds.maxWidth * .05,
          top: 0,
          width: bounds.maxWidth * .58,
          child: Image.asset(
            'assets/auth_ui/welcome/3d_smartphone_with_rising_trading_chart.png',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: bounds.maxWidth * .01,
          bottom: 0,
          width: bounds.maxWidth * .56,
          child: Image.asset(
            'assets/auth_ui/welcome/trading_strategy_market_analysis_books.png',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: bounds.maxWidth * .08,
          bottom: bounds.maxHeight * .29,
          width: bounds.maxWidth * .40,
          child: Image.asset(
            'assets/auth_ui/welcome/elegant_gold_tasseled_graduation_cap.png',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          width: bounds.maxWidth * .35,
          child: Image.asset(
            'assets/auth_ui/welcome/ascending_gold_growth_bars.png',
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          right: bounds.maxWidth * .03,
          bottom: bounds.maxHeight * .08,
          width: bounds.maxWidth * .46,
          child: Image.asset(
            'assets/auth_ui/welcome/polished_golden_ascending_arrow.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
  );
}

class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop();
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, palette.background, const Color(0xFFFBF8F0)],
          stops: const [0, .62, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 52,
            right: -40,
            width: 230,
            child: Opacity(
              opacity: .12,
              child: Image.asset(
                'assets/auth_ui/shared/minimalist_ascending_candlestick_overlay.png',
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: Opacity(
              opacity: .7,
              child: Image.asset(
                'assets/auth_ui/shared/soft_cream_layered_wave_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          CustomPaint(painter: _WelcomeWavePainter(palette.border)),
        ],
      ),
    );
  }
}

class _WelcomeWavePainter extends CustomPainter {
  const _WelcomeWavePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      final y = size.height * (.86 + index * .035);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * .25,
          y - 34 - index * 7,
          size.width * .55,
          y + 28,
          size.width,
          y - 22 - index * 4,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomeWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
