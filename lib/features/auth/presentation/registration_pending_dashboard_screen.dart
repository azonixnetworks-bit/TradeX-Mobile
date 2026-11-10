import 'package:flutter/material.dart';

/// Read-only onboarding preview: no authenticated dashboard API is accessed.
class RegistrationPendingDashboardScreen extends StatefulWidget {
  const RegistrationPendingDashboardScreen({
    super.key,
    required this.email,
    required this.onVerifyNow,
    required this.onExit,
  });

  final String email;
  final VoidCallback onVerifyNow;
  final VoidCallback onExit;

  @override
  State<RegistrationPendingDashboardScreen> createState() =>
      _RegistrationPendingDashboardScreenState();
}

class _RegistrationPendingDashboardScreenState
    extends State<RegistrationPendingDashboardScreen> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dialogShown) {
        _dialogShown = true;
        _showVerificationDialog();
      }
    });
  }

  Future<void> _showVerificationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Color(0xFFC28D12)),
            SizedBox(width: 10),
            Expanded(child: Text('Complete Your Verification')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your account registration is pending. Verify your identity to unlock all TradeX features.'),
            SizedBox(height: 18),
            _VerificationPreviewRow(Icons.mail_outline, 'Email Verification'),
            _VerificationPreviewRow(Icons.chat_outlined, 'WhatsApp Verification'),
            _VerificationPreviewRow(Icons.shield_outlined, 'Authenticator Setup'),
            SizedBox(height: 10),
            Text(
              'Trading, payments, account access and private dashboard data remain locked.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Complete Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD5A017)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onVerifyNow();
            },
            child: const Text('Verify Now', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/branding/trade_x_wordmark.png',
                  width: 138,
                  height: 44,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onExit,
                  child: const Text('Sign In'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'TradeX Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF101827)),
            ),
            const SizedBox(height: 10),
            Text(
              widget.email,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [
                  Color(0xFFFFEFC3),
                  Color(0xFFFFF9E9),
                ]),
                border: Border.all(color: const Color(0xFFE8C574)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_clock_outlined, color: Color(0xFF906411)),
                      SizedBox(width: 9),
                      Text('Verification pending',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('This is a limited dashboard preview. Your registration has started, but no authenticated session has been issued.'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Discover TradeX',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            const _LockedPreviewCard(
              icon: Icons.school_outlined,
              title: 'Learning Courses',
              description: 'Unlock your learning progress after verification',
            ),
            const SizedBox(height: 12),
            const _LockedPreviewCard(
              icon: Icons.show_chart_rounded,
              title: 'Trade Ideas & Market Insights',
              description: 'Complete verification to access account features',
            ),
            const SizedBox(height: 12),
            const _LockedPreviewCard(
              icon: Icons.book_outlined,
              title: 'Trade Journal & Trading Tools',
              description: 'Your personal tools become available after secure sign-in',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onVerifyNow,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Complete Verification'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD3A122),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationPreviewRow extends StatelessWidget {
  const _VerificationPreviewRow(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFFC28D12)),
        const SizedBox(width: 10),
        Expanded(child: Text(title)),
        const Text('Pending', style: TextStyle(color: Color(0xFF8E620D), fontSize: 12)),
      ],
    ),
  );
}

class _LockedPreviewCard extends StatelessWidget {
  const _LockedPreviewCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E8E8)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFC28D12), size: 27),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
            ],
          ),
        ),
        const Icon(Icons.lock_outline, color: Color(0xFF98A2B3), size: 19),
      ],
    ),
  );
}
