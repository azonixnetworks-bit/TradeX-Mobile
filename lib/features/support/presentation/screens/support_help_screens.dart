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
        const SizedBox(height: 14),
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
    eyebrow: 'Ticket Resolved',
    title: 'Ticket Feedback',
    subtitle: 'Share feedback only when an eligible ticket is provided.',
    child: Column(
      children: [
        _SupportPanel(
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.palette.goldSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  '$_imageRoot/ticket_success_3d.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Support ticket illustration',
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket details unavailable',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Open feedback from an eligible resolved ticket to show its verified details.',
                      style: TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                color: TradeXColors.goldBright,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SupportPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How would you rate your support experience?',
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
        const SizedBox(height: 18),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Additional Comments (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 9),
        _SupportTextField(
          controller: _feedback,
          hint: 'Tell us what went well or how we can improve…',
          maxLength: 500,
          minLines: 4,
          maxLines: 6,
        ),
        const SizedBox(height: 14),
        const _SupportUnavailableBanner(compact: true),
        const SizedBox(height: 12),
        _GoldButton(
          label: 'Submit Feedback',
          icon: 'send.svg',
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
