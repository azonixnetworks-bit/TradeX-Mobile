import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/tradex_palette.dart';
import '../../domain/market_news_repository.dart';

/// Presentation-only spotlight for an existing published HIGH-impact event.
/// Reads the same cached Laravel Economic News repository as the full screen.
/// It does not set, calculate, or modify any funded-account trading restriction.
class HomeHighImpactNewsPreview extends StatefulWidget {
  const HomeHighImpactNewsPreview({
    super.key,
    required this.repository,
    required this.onOpenAll,
  });

  final MarketNewsRepositoryContract repository;
  final VoidCallback onOpenAll;

  @override
  State<HomeHighImpactNewsPreview> createState() =>
      _HomeHighImpactNewsPreviewState();
}

class _HomeHighImpactNewsPreviewState extends State<HomeHighImpactNewsPreview>
    with WidgetsBindingObserver {
  late Future<List<MarketNewsItem>> _events;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _events = widget.repository.today();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _reload(),
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _events = widget.repository.today(forceRefresh: true);
    });
  }

  @override
  void didUpdateWidget(covariant HomeHighImpactNewsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.repository, oldWidget.repository)) {
      _reload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MarketNewsItem>>(
      future: _events,
      builder: (context, snapshot) {
        // Do not show invented events or an alarming placeholder while offline.
        final events = snapshot.data;
        if (events == null || events.isEmpty) {
          return const SizedBox.shrink();
        }

        final highImpact = events
            .where((event) =>
                event.impact.trim().toUpperCase() == 'HIGH' &&
                event.status.trim().toUpperCase() != 'CANCELLED')
            .toList(growable: false)
          ..sort((a, b) {
            final left = a.occurredAt;
            final right = b.occurredAt;
            if (left == null) return right == null ? 0 : 1;
            if (right == null) return -1;
            return left.compareTo(right);
          });

        if (highImpact.isEmpty) return const SizedBox.shrink();
        final event = highImpact.first;
        final palette = TradeXPalette.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scheduled = event.occurredAt?.toLocal();
        final scheduleText = scheduled == null
            ? 'Published update'
            : '${_twoDigits(scheduled.day)}/${_twoDigits(scheduled.month)} '
                '${_twoDigits(scheduled.hour)}:${_twoDigits(scheduled.minute)} local';
        final currency = event.currency.trim();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('home-high-impact-news'),
              onTap: widget.onOpenAll,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: palette.error.withValues(alpha: isDark ? .55 : .32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.priority_high_rounded,
                          size: 17,
                          color: palette.error,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'HIGH IMPACT NEWS',
                          style: TextStyle(
                            color: palette.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'View all',
                          style: TextStyle(
                            color: palette.goldText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: palette.goldText,
                          size: 17,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      event.title,
                      key: const ValueKey('home-high-impact-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        _NewsPreviewFact(
                          icon: Icons.schedule_rounded,
                          label: scheduleText,
                          color: palette.secondaryText,
                        ),
                        if (currency.isNotEmpty)
                          _NewsPreviewFact(
                            icon: Icons.currency_exchange_rounded,
                            label: currency,
                            color: palette.secondaryText,
                          ),
                        if (event.actual != null)
                          _NewsPreviewFact(
                            icon: Icons.insights_rounded,
                            label: 'Actual ${event.actual}',
                            color: palette.goldText,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _NewsPreviewFact extends StatelessWidget {
  const _NewsPreviewFact({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
