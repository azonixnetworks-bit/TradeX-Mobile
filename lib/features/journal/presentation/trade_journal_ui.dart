import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';

const journalPanel = Color(0xFF0C1723);
const journalPanelRaised = Color(0xFF102033);
const journalGreen = Color(0xFF21DB9A);
const journalRed = Color(0xFFFF5D69);
const journalBlue = Color(0xFF58A6FF);

class JournalScaffold extends StatelessWidget {
  const JournalScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.accentLastTitleWord = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final bool accentLastTitleWord;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF06101A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF07111C),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          accentLastTitleWord
              ? Text.rich(
                  TextSpan(children: _accentedTitle(title)),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                )
              : Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: actions,
    ),
    body: SafeArea(top: false, child: body),
    floatingActionButton: floatingActionButton,
  );

  List<InlineSpan> _accentedTitle(String value) {
    final separator = value.lastIndexOf(' ');
    if (separator <= 0 || separator >= value.length - 1) {
      return [TextSpan(text: value)];
    }
    return [
      TextSpan(text: value.substring(0, separator + 1)),
      TextSpan(
        text: value.substring(separator + 1),
        style: const TextStyle(color: TradeXColors.goldBright),
      ),
    ];
  }
}

class JournalPanel extends StatelessWidget {
  const JournalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [journalPanelRaised, journalPanel],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: .08),
          ),
        ),
        child: child,
      ),
    ),
  );
}

class JournalSectionTitle extends StatelessWidget {
  const JournalSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class JournalMetricCard extends StatelessWidget {
  const JournalMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = TradeXColors.goldBright,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? caption;

  @override
  Widget build(BuildContext context) => JournalPanel(
    padding: const EdgeInsets.all(13),
    borderColor: accent.withValues(alpha: .22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 3),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 9,
            ),
          ),
        ],
      ],
    ),
  );
}

class JournalBadge extends StatelessWidget {
  const JournalBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({super.key, required this.entry, this.onTap});

  final TradeJournalEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pnl = entry.netPnl;
    final pnlColor = pnl == null
        ? TradeXColors.secondaryText
        : pnl >= 0
        ? journalGreen
        : journalRed;
    return JournalPanel(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TradeXColors.goldBright.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(
                color: TradeXColors.goldBright.withValues(alpha: .35),
              ),
            ),
            child: Text(
              _symbolLetters(entry.symbol),
              style: const TextStyle(
                color: TradeXColors.goldBright,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 7),
                    JournalBadge(
                      label: entry.direction,
                      color: entry.direction.toLowerCase() == 'buy'
                          ? journalGreen
                          : journalRed,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${titleCase(entry.market)} · ${entry.sessionLabel.isEmpty ? 'No session' : entry.sessionLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              JournalBadge(
                label: entry.status,
                color: statusColor(entry.status),
              ),
              const SizedBox(height: 5),
              Text(
                pnl == null
                    ? (entry.result?.toUpperCase() ?? '—')
                    : formatMoney(pnl, entry.pnlCurrency),
                style: TextStyle(
                  color: pnlColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: TradeXColors.tertiaryText,
          ),
        ],
      ),
    );
  }
}

class JournalValueRow extends StatelessWidget {
  const JournalValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: TradeXColors.secondaryText),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class JournalPrimaryButton extends StatelessWidget {
  const JournalPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.save_rounded,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: TradeXColors.goldBright,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class JournalLoading extends StatelessWidget {
  const JournalLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      color: TradeXColors.goldBright,
      strokeWidth: 2,
    ),
  );
}

class JournalError extends StatelessWidget {
  const JournalError({super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: TradeXColors.secondaryText,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            error is ApiException
                ? (error! as ApiException).message
                : 'Trade Journal is temporarily unavailable.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class JournalMiniChart extends StatelessWidget {
  const JournalMiniChart({super.key, required this.values, this.height = 140});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _JournalChartPainter(values)),
  );
}

class _JournalChartPainter extends CustomPainter {
  const _JournalChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final data = values.length > 1 ? values : const <double>[0, 0];
    final minValue = data.reduce(math.min);
    final maxValue = data.reduce(math.max);
    final range = math.max(.0001, maxValue - minValue);
    final path = Path();
    for (var index = 0; index < data.length; index++) {
      final x = size.width * index / (data.length - 1);
      final y = size.height - ((data[index] - minValue) / range * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66FFC83D), Color(0x00FFC83D)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = TradeXColors.goldBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _JournalChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

Color statusColor(String status) => switch (status.toLowerCase()) {
  'open' => journalGreen,
  'closed' => journalBlue,
  'cancelled' => journalRed,
  _ => TradeXColors.goldBright,
};

String titleCase(String value) => value
    .split(RegExp(r'[_\s]+'))
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
    .join(' ');

String formatNumber(Object? value, {int decimals = 2}) {
  final number = journalNumber(value);
  return number == null ? '—' : number.toStringAsFixed(decimals);
}

String formatPercent(Object? value) {
  final number = journalNumber(value);
  return number == null ? '—' : '${number.toStringAsFixed(1)}%';
}

String formatMoney(double? value, String? currency) {
  if (value == null) return '—';
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}${currency == null ? '' : ' $currency'}';
}

String formatDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _symbolLetters(String symbol) {
  final clean = symbol.replaceAll(RegExp('[^A-Za-z]'), '').toUpperCase();
  return clean.isEmpty ? '?' : clean.substring(0, math.min(3, clean.length));
}
