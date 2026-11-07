import 'package:flutter/material.dart';

import '../theme/tradex_design_system.dart';

class SecurityScreenShell extends StatelessWidget {
  const SecurityScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            right: -18,
            child: IgnorePointer(
              child: Opacity(
                opacity: context.isDarkMode ? .16 : .46,
                child: Image.asset(
                  'assets/security_ui/subtle_gray_candlestick_trend.png',
                  width: 190,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -16,
            child: IgnorePointer(
              child: Opacity(
                opacity: context.isDarkMode ? .08 : .68,
                child: Image.asset(
                  'assets/security_ui/layered_cream_wave_footer.png',
                  height: 145,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      Image.asset(
                        'assets/branding/trade_x_final_logo.png',
                        width: 66,
                        height: 66,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: palette.primaryText,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: palette.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
