import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _progressController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    _introController.forward();

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    await _progressController.forward();

    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _introController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: const _LogoSection(),
                    ),
                  ),

                  const Spacer(flex: 2),

                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return _ProgressBar(value: _progressAnimation.value);
                    },
                  ),

                  const SizedBox(height: 28),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'DISCIPLINE CREATES FREEDOM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TradeXColors.goldBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final logoWidth = screenWidth < 380
        ? screenWidth * 0.72
        : screenWidth * 0.68;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 350, maxHeight: 350),
          child: Image.asset(
            'assets/branding/tradex_logo.png',
            width: logoWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'The OS for Every Trader.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Learn. Trade. Grow.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TradeXColors.goldBright,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: TradeXColors.surfaceMuted,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: TradeXColors.border, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      TradeXColors.goldDeep,
                      TradeXColors.gold,
                      TradeXColors.goldBright,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: TradeXColors.goldBright.withValues(alpha: 0.40),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF080A08),
                TradeXColors.background,
                Color(0xFF020302),
              ],
              stops: [0, 0.55, 1],
            ),
          ),
        ),

        Positioned(
          top: -140,
          left: -100,
          child: _GlowOrb(
            size: 320,
            color: TradeXColors.gold.withValues(alpha: 0.12),
          ),
        ),

        Positioned(
          bottom: -180,
          right: -100,
          child: _GlowOrb(
            size: 380,
            color: TradeXColors.goldDeep.withValues(alpha: 0.14),
          ),
        ),

        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TradeXColors.gold.withValues(alpha: 0.035)
      ..strokeWidth = 0.7;

    const spacing = 48.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
