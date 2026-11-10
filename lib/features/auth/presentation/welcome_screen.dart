import 'package:flutter/material.dart';

import '../../../core/theme/tradex_design_system.dart';

/// Welcome onboarding with swipeable introduction slides.
/// The existing registration/login/skip callbacks remain unchanged.
class WelcomeScreen extends StatefulWidget {
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
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _activePage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
                              onPressed: widget.onSkip,
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
                        SizedBox(
                          height: (viewport.maxHeight - 265).clamp(440.0, 720.0),
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _activePage = index);
                            },
                            children: const [
                              _WelcomePage(
                                titleFirstLine: 'Learn. Trade.',
                                titleSecondPrefix: 'Grow with ',
                                titleGold: 'TradeX.',
                                description:
                                    'Master the markets with expert education and access professional trading services — all in one app.',
                                heroAsset:
                                    'assets/auth_ui/welcome/bull_bear_stage.png',
                              ),
                              _WelcomePage(
                                titleFirstLine: 'Powerful Trading',
                                titleSecondPrefix: '',
                                titleGold: 'Tools & Insights',
                                description:
                                    'Plan, analyze and trade smarter with professional tools, trade ideas, market news and real-time insights.',
                                heroAsset:
                                    'assets/auth_ui/welcome/trading_tools_hero.png',
                              ),
                              _WelcomePage(
                                titleFirstLine: 'Build Your',
                                titleSecondPrefix: 'Trading ',
                                titleGold: 'Success',
                                description:
                                    'Learn, practice, copy trade, manage funded accounts and track your progress — all in one place.',
                                heroAsset:
                                    'assets/auth_ui/welcome/trading_success_hero.png',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PrimaryWelcomeButton(
                          label: 'Get Started',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: widget.onGetStarted,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: widget.onSignIn,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: palette.primaryText,
                              side: BorderSide(color: palette.borderStrong),
                              shape: RoundedRectangleBorder(
                                borderRadius: TradeXRadii.control,
                              ),
                              backgroundColor:
                                  palette.surface.withValues(alpha: .72),
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
                        Center(child: _PageIndicator(activeIndex: _activePage)),
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.titleFirstLine,
    required this.titleSecondPrefix,
    required this.titleGold,
    required this.description,
    required this.heroAsset,
  });

  final String titleFirstLine;
  final String titleSecondPrefix;
  final String titleGold;
  final String description;
  final String heroAsset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$titleFirstLine\n$titleSecondPrefix'),
              TextSpan(
                text: titleGold,
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
          description,
          style: TextStyle(
            color: palette.secondaryText,
            fontSize: 16,
            height: 1.42,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: Image.asset(
              heroAsset,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_outlined, size: 42),
              ),
            ),
          ),
        ),
      ],
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
  const _PageIndicator({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: index == activeIndex ? 9 : 8,
            height: index == activeIndex ? 9 : 8,
            decoration: BoxDecoration(
              color: index == activeIndex
                  ? palette.goldText
                  : palette.borderStrong,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
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
