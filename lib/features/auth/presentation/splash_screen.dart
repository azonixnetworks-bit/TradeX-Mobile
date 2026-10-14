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
                  const Spacer(flex: 6),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: const _SplashTagline(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return _ProgressBar(value: _progressAnimation.value);
                    },
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

class _SplashTagline extends StatelessWidget {
  const _SplashTagline();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'The OS for Every Trader',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFFFFE08A),
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        shadows: [
          Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 3)),
          Shadow(color: Color(0x99F0A500), blurRadius: 16),
        ],
      ),
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
        const ColoredBox(color: Colors.black),
        Image.asset(
          'assets/branding/trade_x_splash_background.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33000000),
                Colors.transparent,
                Color(0x99000000),
              ],
              stops: [0, 0.52, 1],
            ),
          ),
        ),
      ],
    );
  }
}
