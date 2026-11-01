part of '../trade_journal_trade_screens.dart';

class TradeJournalPlanScreen extends StatefulWidget {
  const TradeJournalPlanScreen({
    super.key,
    required this.repository,
    this.entry,
  });

  final TradeJournalRepositoryContract repository;
  final TradeJournalEntry? entry;

  @override
  State<TradeJournalPlanScreen> createState() => _TradeJournalPlanScreenState();
}
