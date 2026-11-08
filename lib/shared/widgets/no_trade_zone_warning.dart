import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tradex_colors.dart';
import '../../core/theme/tradex_palette.dart';
import '../../features/home/domain/no_trade_zone_warning.dart';

class NoTradeZoneWarningBanner extends StatefulWidget {
  const NoTradeZoneWarningBanner({
    super.key,
    required this.source,
    this.applicableSymbolsOrCurrencies = const <String>[],
  });

  final NoTradeWarningSource source;
  final Iterable<String> applicableSymbolsOrCurrencies;

  @override
  State<NoTradeZoneWarningBanner> createState() =>
      _NoTradeZoneWarningBannerState();
}

class _NoTradeZoneWarningBannerState extends State<NoTradeZoneWarningBanner>
    with WidgetsBindingObserver {
  static const _evaluator = NoTradeZoneWarningEvaluator();

  List<EconomicNewsSnapshot> _events = const <EconomicNewsSnapshot>[];
  Timer? _clock;
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_load(forceRefresh: true)),
    );
    unawaited(_load(forceRefresh: true));
  }

  @override
  void didUpdateWidget(covariant NoTradeZoneWarningBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.source, oldWidget.source)) {
      unawaited(_load(forceRefresh: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _now = DateTime.now());
      unawaited(_load(forceRefresh: true));
    }
  }

  Future<void> _load({required bool forceRefresh}) async {
    if (_loading) return;
    _loading = true;
    try {
      final events = await widget.source.load(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _events = events;
          _now = DateTime.now();
        });
      }
    } catch (_) {
      // Keep a still-fresh in-memory result. The evaluator suppresses stale data.
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = _evaluator.evaluate(
      _events,
      _now,
      applicableSymbolsOrCurrencies: widget.applicableSymbolsOrCurrencies,
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: evaluation.isVisible
          ? Padding(
              key: ValueKey('no-trade-warning-${evaluation.phase.name}'),
              padding: const EdgeInsets.only(bottom: 14),
              child: _NoTradeWarningPanel(evaluation: evaluation, now: _now),
            )
          : const SizedBox.shrink(key: ValueKey('no-trade-warning-normal')),
    );
  }
}

class EconomicNewsTradeWarning extends StatelessWidget {
  const EconomicNewsTradeWarning({
    super.key,
    required this.event,
    required this.now,
  });

  final EconomicNewsSnapshot event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    const evaluator = NoTradeZoneWarningEvaluator();
    final evaluation = evaluator.evaluateEvent(event, now);
    if (!evaluation.isVisible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _NoTradeWarningPanel(
        evaluation: evaluation,
        now: now,
        compact: true,
      ),
    );
  }
}

class _NoTradeWarningPanel extends StatelessWidget {
  const _NoTradeWarningPanel({
    required this.evaluation,
    required this.now,
    this.compact = false,
  });

  final NoTradeWarningEvaluation evaluation;
  final DateTime now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = TradeXPalette.of(context);
    final active = evaluation.phase == NoTradeWarningPhase.active;
    final accent = active ? palette.error : palette.success;
    final event = evaluation.primaryEvent!;
    final scheduled = event.scheduledAtUtc?.toLocal();
    final countdownTarget = active ? evaluation.windowEndsAtUtc : null;
    final extra = evaluation.relevantEvents.length - 1;
    return Container(
      key: ValueKey(active ? 'no-trade-active-panel' : 'no-trade-ended-panel'),
      padding: EdgeInsets.all(compact ? 12 : 15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: accent.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: .08), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                active
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: accent,
                size: compact ? 23 : 27,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active
                          ? "Don't Trade in Funded Accounts"
                          : 'You Can Trade on Funded Accounts',
                      style: TextStyle(
                        color: accent,
                        fontSize: compact ? 14 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active
                          ? 'High-impact economic news is active. Avoid trading on funded accounts during this period.'
                          : "The news caution window has ended. Follow your funded account provider's trading rules.",
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _WarningChip(icon: Icons.newspaper_rounded, label: event.title),
              _WarningChip(
                icon: Icons.currency_exchange_rounded,
                label: event.currency.isEmpty ? 'Currency —' : event.currency,
              ),
              if (scheduled != null)
                _WarningChip(
                  icon: Icons.schedule_rounded,
                  label: _localTime(scheduled),
                ),
              if (countdownTarget != null)
                _WarningChip(
                  key: const ValueKey('no-trade-countdown'),
                  icon: Icons.timer_outlined,
                  label: 'Ends in ${_countdown(countdownTarget, now)}',
                ),
              if (extra > 0)
                _WarningChip(
                  icon: Icons.layers_outlined,
                  label: '+$extra overlapping',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarningChip extends StatelessWidget {
  const _WarningChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = TradeXPalette.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: palette.goldText, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.primaryText,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _countdown(DateTime target, DateTime now) {
  final remaining = target.toUtc().difference(now.toUtc());
  final seconds = remaining.isNegative ? 0 : remaining.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secondPart = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${secondPart.toString().padLeft(2, '0')}';
}

String _localTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')} local';
