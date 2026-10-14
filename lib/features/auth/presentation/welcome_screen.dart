import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';

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
    return Scaffold(
      backgroundColor: TradeXColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WelcomeBackground(),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 38,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: onSkip,
                              style: TextButton.styleFrom(
                                foregroundColor: TradeXColors.goldBright,
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          const _BrandSection(),

                          const SizedBox(height: 28),

                          const _FeatureCard(
                            icon: Icons.bar_chart_rounded,
                            title: 'Learn',
                            subtitle: 'Expert trading courses',
                          ),

                          const SizedBox(height: 12),

                          const _FeatureCard(
                            icon: Icons.lightbulb_rounded,
                            title: 'Trade',
                            subtitle: 'Real market opportunities',
                          ),

                          const SizedBox(height: 12),

                          const _FeatureCard(
                            icon: Icons.groups_rounded,
                            title: 'Grow',
                            subtitle: 'Build your financial freedom',
                          ),

                          const Spacer(),

                          const SizedBox(height: 28),

                          _GoldButton(
                            label: 'Get Started',
                            onPressed: onGetStarted,
                          ),

                          const SizedBox(height: 18),

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: TradeXColors.secondaryText,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: onSignIn,
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: TradeXColors.goldBright,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          const Text(
                            'DISCIPLINE CREATES FREEDOM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: TradeXColors.goldBright,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSection extends StatelessWidget {
  const _BrandSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        SizedBox(
          width: width * 0.52,
          height: 190,
          child: Image.asset(
            'assets/branding/trade_x_in_app_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'The OS for Every Trader.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Learn. Trade. Grow.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TradeXColors.goldBright,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(active: true),
            const SizedBox(width: 7),
            const _Dot(),
            const SizedBox(width: 7),
            const _Dot(),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? TradeXColors.goldBright : TradeXColors.borderStrong,
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111614), Color(0xFF090C0B)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: TradeXColors.gold.withValues(alpha: 0.30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: TradeXColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: TradeXColors.goldBright, size: 29),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD760),
              TradeXColors.goldBright,
              Color(0xFFF1A900),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: TradeXColors.goldBright.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

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
            ),
          ),
        ),

        Positioned(
          top: -160,
          right: -130,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TradeXColors.gold.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: -180,
          left: -120,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TradeXColors.goldDeep.withValues(alpha: 0.13),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
