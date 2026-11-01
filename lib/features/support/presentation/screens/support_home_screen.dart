part of '../support_module.dart';

class SupportHomeScreen extends StatelessWidget {
  const SupportHomeScreen({super.key, required this.useCases});

  final SupportUseCases useCases;

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      eyebrow: 'SUPPORT CENTER',
      title: 'How can we help you?',
      subtitle:
          'Get instant support, find helpful resources, or report an issue.',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _SupportActionCard(
                  icon: 'live_chat.svg',
                  title: 'Live Chat',
                  body: 'Chat securely with an online support agent.',
                  action: 'Start Chat',
                  onTap: () =>
                      _push(context, LiveChatWaitingScreen(useCases: useCases)),
                ),
                _SupportActionCard(
                  icon: 'support_document.svg',
                  title: 'Report an Issue',
                  body: 'Prepare a detailed support request securely.',
                  action: 'New Ticket',
                  onTap: () => _push(
                    context,
                    CreateSupportTicketScreen(useCases: useCases),
                  ),
                ),
              ];
              if (constraints.maxWidth < 365) {
                return Column(
                  children: [
                    cards.first,
                    const SizedBox(height: 12),
                    cards.last,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards.first),
                  const SizedBox(width: 12),
                  Expanded(child: cards.last),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _SupportSearchField(
            hint: 'Search for help topics',
            readOnly: true,
            onTap: () => _push(context, HelpCenterScreen(useCases: useCases)),
          ),
          const SizedBox(height: 14),
          _SupportPanel(
            child: Row(
              children: [
                const Expanded(
                  child: _SupportMetric(
                    icon: 'file_text.svg',
                    value: '—',
                    label: 'Open Tickets',
                  ),
                ),
                _divider(),
                const Expanded(
                  child: _SupportMetric(
                    icon: 'clock.svg',
                    value: '—',
                    label: 'In Progress',
                  ),
                ),
                _divider(),
                const Expanded(
                  child: _SupportMetric(
                    icon: 'check_circle.svg',
                    value: '—',
                    label: 'Resolved',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeading(
            title: 'Support Services',
            action: 'My Tickets',
            onTap: () =>
                _push(context, MySupportTicketsScreen(useCases: useCases)),
          ),
          const SizedBox(height: 10),
          _SupportListTile(
            icon: 'file_text.svg',
            title: 'My Support Tickets',
            subtitle: 'Track requests and view verified responses.',
            onTap: () =>
                _push(context, MySupportTicketsScreen(useCases: useCases)),
          ),
          const SizedBox(height: 10),
          _SupportListTile(
            icon: 'faq.svg',
            title: 'Help Center & FAQ',
            subtitle: 'Read server-published support articles.',
            onTap: () => _push(context, HelpCenterScreen(useCases: useCases)),
          ),
        ],
      ),
    );
  }
}
