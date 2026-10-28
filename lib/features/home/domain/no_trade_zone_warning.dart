enum NoTradeWarningPhase { normal, active, ended }

class EconomicNewsSnapshot {
  const EconomicNewsSnapshot({
    required this.uuid,
    required this.title,
    required this.currency,
    required this.impact,
    required this.status,
    required this.scheduledAtUtc,
    required this.affectedPairs,
    required this.observedAtUtc,
  });

  final String uuid;
  final String title;
  final String currency;
  final String impact;
  final String status;
  final DateTime? scheduledAtUtc;
  final List<String> affectedPairs;
  final DateTime observedAtUtc;
}

class NoTradeWarningEvaluation {
  const NoTradeWarningEvaluation({
    required this.phase,
    required this.primaryEvent,
    required this.relevantEvents,
    required this.windowStartsAtUtc,
    required this.windowEndsAtUtc,
  });

  const NoTradeWarningEvaluation.normal()
    : phase = NoTradeWarningPhase.normal,
      primaryEvent = null,
      relevantEvents = const <EconomicNewsSnapshot>[],
      windowStartsAtUtc = null,
      windowEndsAtUtc = null;

  final NoTradeWarningPhase phase;
  final EconomicNewsSnapshot? primaryEvent;
  final List<EconomicNewsSnapshot> relevantEvents;
  final DateTime? windowStartsAtUtc;
  final DateTime? windowEndsAtUtc;

  bool get isVisible => phase != NoTradeWarningPhase.normal;
}

abstract interface class NoTradeWarningSource {
  Future<List<EconomicNewsSnapshot>> load({bool forceRefresh = false});
}

class NoTradeZoneWarningEvaluator {
  const NoTradeZoneWarningEvaluator({
    this.window = const Duration(minutes: 30),
    this.endedVisibility = const Duration(minutes: 5),
    this.maximumDataAge = const Duration(minutes: 15),
  });

  final Duration window;
  final Duration endedVisibility;
  final Duration maximumDataAge;

  NoTradeWarningEvaluation evaluateEvent(
    EconomicNewsSnapshot event,
    DateTime now,
  ) => evaluate(<EconomicNewsSnapshot>[event], now);

  NoTradeWarningEvaluation evaluate(
    List<EconomicNewsSnapshot> events,
    DateTime now, {
    Iterable<String> applicableSymbolsOrCurrencies = const <String>[],
  }) {
    final nowUtc = now.toUtc();
    final filters = applicableSymbolsOrCurrencies
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    final candidates = events
        .where((event) {
          if (event.impact.toUpperCase() != 'HIGH') return false;
          if (event.status.toUpperCase() == 'CANCELLED') return false;
          if (event.scheduledAtUtc == null) return false;
          final age = nowUtc.difference(event.observedAtUtc.toUtc());
          if (age > maximumDataAge) return false;
          if (filters.isEmpty) return true;
          final currency = _normalize(event.currency);
          final pairs = event.affectedPairs.map(_normalize).toSet();
          return filters.any(
            (filter) =>
                filter == currency ||
                (currency.isNotEmpty && filter.contains(currency)) ||
                pairs.contains(filter),
          );
        })
        .toList(growable: false);

    final active = candidates
        .where((event) {
          final scheduled = event.scheduledAtUtc!.toUtc();
          return !nowUtc.isBefore(scheduled.subtract(window)) &&
              nowUtc.isBefore(scheduled.add(window));
        })
        .toList(growable: false);
    if (active.isNotEmpty) {
      active.sort((left, right) {
        final leftDistance = left.scheduledAtUtc!
            .toUtc()
            .difference(nowUtc)
            .abs();
        final rightDistance = right.scheduledAtUtc!
            .toUtc()
            .difference(nowUtc)
            .abs();
        return leftDistance.compareTo(rightDistance);
      });
      final starts =
          active
              .map((event) => event.scheduledAtUtc!.toUtc().subtract(window))
              .toList()
            ..sort();
      final ends =
          active
              .map((event) => event.scheduledAtUtc!.toUtc().add(window))
              .toList()
            ..sort();
      return NoTradeWarningEvaluation(
        phase: NoTradeWarningPhase.active,
        primaryEvent: active.first,
        relevantEvents: active,
        windowStartsAtUtc: starts.first,
        windowEndsAtUtc: ends.last,
      );
    }

    final ended =
        candidates
            .where((event) {
              final end = event.scheduledAtUtc!.toUtc().add(window);
              return !nowUtc.isBefore(end) &&
                  nowUtc.isBefore(end.add(endedVisibility));
            })
            .toList(growable: false)
          ..sort(
            (left, right) =>
                right.scheduledAtUtc!.compareTo(left.scheduledAtUtc!),
          );
    if (ended.isNotEmpty) {
      final primary = ended.first;
      return NoTradeWarningEvaluation(
        phase: NoTradeWarningPhase.ended,
        primaryEvent: primary,
        relevantEvents: ended,
        windowStartsAtUtc: primary.scheduledAtUtc!.toUtc().subtract(window),
        windowEndsAtUtc: primary.scheduledAtUtc!.toUtc().add(window),
      );
    }

    return const NoTradeWarningEvaluation.normal();
  }

  String _normalize(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
