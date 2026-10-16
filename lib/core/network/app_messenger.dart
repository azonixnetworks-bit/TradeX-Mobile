import 'package:flutter/material.dart';

import '../theme/tradex_colors.dart';

/// Displays network feedback outside individual screens, so a failed request
/// always has the same clear, non-blocking message.
abstract final class AppMessenger {
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static bool _showingOfflineMessage = false;

  static void showNoInternetConnection() {
    if (_showingOfflineMessage) return;

    final messenger = key.currentState;
    if (messenger == null) return;

    _showingOfflineMessage = true;
    messenger
        .showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: TradeXColors.surfaceRaised,
            content: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: TradeXColors.goldBright),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No internet connection. Connect your internet and try again.',
                  ),
                ),
              ],
            ),
          ),
        )
        .closed
        .whenComplete(() => _showingOfflineMessage = false);
  }

  static void markConnectionAvailable() {
    _showingOfflineMessage = false;
  }
}
