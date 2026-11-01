part of '../support_module.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key, required this.useCases});

  final SupportUseCases useCases;

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    eyebrow: 'SUPPORT CENTER',
    title: 'Help Center',
    subtitle: 'Find verified answers published by TradeX Support.',
    child: Column(
      children: [
        _SupportSearchField(
          controller: _search,
          hint: 'Search for help articles',
          enabled: false,
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StaticChip('All'),
            _StaticChip('Account'),
            _StaticChip('Trading'),
            _StaticChip('Payments'),
            _StaticChip('Technical'),
          ],
        ),
        const SizedBox(height: 20),
        _UnavailableContent(
          icon: 'book_open.svg',
          title: 'FAQ feed is not connected',
          message: 'TradeX has not published an authenticated mobile FAQ contract. No production answers are hard-coded in the app.',
          action: 'Prepare a Ticket',
          onTap: () => _push(
            context,
            CreateSupportTicketScreen(useCases: widget.useCases),
          ),
        ),
      ],
    ),
  );
}

class TicketFeedbackScreen extends StatefulWidget {
  const TicketFeedbackScreen({super.key, required this.useCases});

  final SupportUseCases useCases;

  @override
  State<TicketFeedbackScreen> createState() => _TicketFeedbackScreenState();
}

class _TicketFeedbackScreenState extends State<TicketFeedbackScreen> {
  final _feedback = TextEditingController();
  var _rating = 0;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    title: 'Ticket Resolved',
    subtitle:
        'Feedback is accepted only for a server-confirmed resolved ticket.',
    child: Column(
      children: [
        Image.asset(
          '$_imageRoot/ticket_success_3d.png',
          height: 200,
          fit: BoxFit.contain,
          semanticLabel: 'Resolved ticket illustration',
        ),
        const SizedBox(height: 12),
        _SupportPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How would you rate our support?',
                style: TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var star = 1; star <= 5; star++)
                    Semantics(
                      button: true,
                      label: '$star stars',
                      child: IconButton(
                        onPressed: () => setState(() => _rating = star),
                        iconSize: 38,
                        color: TradeXColors.goldBright,
                        icon: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SupportTextField(
          controller: _feedback,
          hint: 'Share your feedback about your support experience',
          maxLength: 500,
          minLines: 4,
          maxLines: 6,
        ),
        const SizedBox(height: 14),
        const _SupportUnavailableBanner(compact: true),
        const SizedBox(height: 12),
        _GoldButton(
          label: 'Submit Feedback',
          icon: 'star.svg',
          onPressed: () => _showUnavailable(context),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: TradeXColors.goldBright,
            side: const BorderSide(color: TradeXColors.gold),
          ),
          child: const Text('Back to Support'),
        ),
      ],
    ),
  );
}
