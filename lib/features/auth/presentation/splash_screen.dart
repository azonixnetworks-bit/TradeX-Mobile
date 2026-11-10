// import 'package:flutter/material.dart';

// import '../../../core/theme/tradex_design_system.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key, this.onFinished});

//   final VoidCallback? onFinished;

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late final AnimationController _introController;
//   late final AnimationController _progressController;

//   late final Animation<double> _fadeAnimation;
//   late final Animation<double> _scaleAnimation;
//   late final Animation<double> _progressAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _introController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1300),
//     );

//     _progressController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2400),
//     );

//     _fadeAnimation = CurvedAnimation(
//       parent: _introController,
//       curve: Curves.easeOut,
//     );

//     _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
//       CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
//     );

//     _progressAnimation = CurvedAnimation(
//       parent: _progressController,
//       curve: Curves.easeInOut,
//     );

//     _startAnimations();
//   }

//   Future<void> _startAnimations() async {
//     _introController.forward();

//     await Future<void>.delayed(const Duration(milliseconds: 350));

//     if (!mounted) return;

//     await _progressController.forward();

//     if (!mounted) return;

//     await Future<void>.delayed(const Duration(milliseconds: 250));

//     if (!mounted) return;

//     widget.onFinished?.call();
//   }

//   @override
//   void dispose() {
//     _introController.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: context.palette.background,
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           const _SplashBackground(),

//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
//               child: Column(
//                 children: [
//                   const Spacer(),

//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: ScaleTransition(
//                       scale: _scaleAnimation,
//                       child: const _SplashIdentity(),
//                     ),
//                   ),

//                   const SizedBox(height: 28),

//                   Text(
//                     'Loading TradeX...',
//                     style: TextStyle(
//                       color: context.palette.secondaryText,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   AnimatedBuilder(
//                     animation: _progressAnimation,
//                     builder: (context, child) {
//                       return _ProgressBar(value: _progressAnimation.value);
//                     },
//                   ),

//                   const SizedBox(height: 14),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SplashIdentity extends StatelessWidget {
//   const _SplashIdentity();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Image.asset(
//           'assets/branding/trade_x_final_logo.png',
//           width: 210,
//           height: 100,
//           fit: BoxFit.contain,
//         ),
//         Text(
//           'TRADING EDUCATION  •  TRADING SERVICES',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: context.palette.secondaryText,
//             fontSize: 9,
//             fontWeight: FontWeight.w700,
//             letterSpacing: 1.7,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ProgressBar extends StatelessWidget {
//   const _ProgressBar({required this.value});

//   final double value;

//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 300),
//       child: Container(
//         height: 5,
//         decoration: BoxDecoration(
//           color: context.palette.surfaceMuted,
//           borderRadius: BorderRadius.circular(100),
//           border: Border.all(color: context.palette.border, width: 0.8),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(100),
//           child: Align(
//             alignment: Alignment.centerLeft,
//             child: FractionallySizedBox(
//               widthFactor: value,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [context.palette.goldText, context.palette.gold],
//                   ),
//                   borderRadius: BorderRadius.circular(100),
//                   boxShadow: [
//                     BoxShadow(
//                       color: context.palette.gold.withValues(alpha: 0.40),
//                       blurRadius: 10,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SplashBackground extends StatelessWidget {
//   const _SplashBackground();

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         ColoredBox(color: context.palette.background),
//         Positioned.fill(
//           child: Opacity(
//             opacity: .56,
//             child: Image.asset(
//               'assets/auth_ui/splash/subtle_layered_mountain_silhouettes.png',
//               fit: BoxFit.cover,
//               alignment: Alignment.bottomCenter,
//             ),
//           ),
//         ),
//         Positioned(
//           left: -20,
//           right: -20,
//           top: 250,
//           child: Opacity(
//             opacity: .36,
//             child: Image.asset(
//               'assets/auth_ui/shared/minimalist_ascending_candlestick_overlay.png',
//               fit: BoxFit.contain,
//             ),
//           ),
//         ),
//         Positioned(
//           left: 18,
//           right: 18,
//           bottom: 150,
//           height: 390,
//           child: Stack(
//             alignment: Alignment.bottomCenter,
//             children: [
//               Image.asset(
//                 'assets/auth_ui/splash/rocky_mountain_pedestal.png',
//                 width: 370,
//                 fit: BoxFit.contain,
//               ),
//               Positioned(
//                 bottom: 85,
//                 child: Image.asset(
//                   'assets/auth_ui/splash/golden_low_poly_bull_statue.png',
//                   width: 285,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned.fill(
//           child: DecoratedBox(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.transparent,
//                   Colors.transparent,
//                   context.palette.background,
//                 ],
//                 stops: [0, .76, 1],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }



import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();

    _finishTimer = Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;
        widget.onFinished?.call();
      },
    );
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: const Scaffold(
        backgroundColor: Color(0xFF020A12),
        body: SizedBox.expand(
          child: Image(
            image: AssetImage(
              'assets/branding/tradex_bull_bear_trading_emblem.png',
            ),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
