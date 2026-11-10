import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen branded splash. Existing onFinished navigation is unchanged.
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
    _finishTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onFinished?.call();
    });
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
            image: AssetImage('assets/branding/tradex_bull_bear_trading_emblem.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
