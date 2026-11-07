part of '../support_module.dart';

class CreateSupportTicketScreen extends StatefulWidget {
  const CreateSupportTicketScreen({super.key, required this.useCases});
  final SupportUseCases useCases;
  @override
  State<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  Uint8List? _photo;
  String? _photoName;
  bool _picking = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await AppPlatformRegistry.current.pickImage(
        camera: false,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _photo = file.bytes;
        _photoName = file.name;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    title: 'Create Support Ticket',
    subtitle: 'Describe your issue and our support team will guide you.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TicketFormPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TicketFieldHeading(
                icon: 'file_text.svg',
                label: 'Issue Category',
                isRequired: true,
              ),
              const SizedBox(height: 8),
              const _SupportUnavailableField(
                icon: 'file_text.svg',
                label: 'Categories unavailable',
                helper: 'Categories must be supplied by the support service.',
              ),
              const SizedBox(height: 18),
              const _TicketFieldHeading(
                icon: 'credit_card.svg',
                label: 'Related Account',
                trailing: 'Optional',
              ),
              const SizedBox(height: 8),
              const _SupportUnavailableField(
                icon: 'credit_card.svg',
                label: 'No verified accounts loaded',
                helper: 'Only customer-owned accounts can appear here.',
              ),
              const SizedBox(height: 18),
              const _TicketFieldHeading(
                icon: 'file_plus.svg',
                label: 'Subject',
                isRequired: true,
              ),
              const SizedBox(height: 8),
              _SupportTextField(
                controller: _subject,
                hint: 'Briefly describe your issue',
                maxLength: 100,
              ),
              const SizedBox(height: 14),
              const _TicketFieldHeading(
                icon: 'message_circle.svg',
                label: 'Issue Description',
                isRequired: true,
              ),
              const SizedBox(height: 8),
              _SupportTextField(
                controller: _description,
                hint: 'Include what happened, when it started and any error message.',
                maxLength: 1000,
                minLines: 5,
                maxLines: 8,
              ),
              const SizedBox(height: 16),
              const _TicketFieldHeading(
                icon: 'paperclip.svg',
                label: 'Attachment',
                trailing: 'Optional · images only',
              ),
              const SizedBox(height: 8),
              if (_photo == null)
                _TicketUploadArea(
                  busy: _picking,
                  onTap: _picking ? null : _pickPhoto,
                )
              else
                _SelectedAttachment(
                  bytes: _photo!,
                  name: _photoName ?? 'Selected image',
                  onRemove: () => setState(() {
                    _photo = null;
                    _photoName = null;
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SupportUnavailableBanner(compact: true),
        const SizedBox(height: 12),
        _GoldButton(
          label: 'Submit Ticket',
          icon: 'send.svg',
          onPressed: () => _showUnavailable(context),
        ),
      ],
    ),
  );
}

class MySupportTicketsScreen extends StatefulWidget {
  const MySupportTicketsScreen({super.key, required this.useCases});
  final SupportUseCases useCases;
  @override
  State<MySupportTicketsScreen> createState() => _MySupportTicketsScreenState();
}

class _MySupportTicketsScreenState extends State<MySupportTicketsScreen> {
  static const _filters = ['All', 'Open', 'In Progress', 'Waiting', 'Resolved'];
  var _selected = 'All';

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    eyebrow: 'SUPPORT CENTER',
    title: 'My Support Tickets',
    subtitle: 'Track and manage your support requests in one place.',
    child: Column(
      children: [
        const _SupportSearchField(
          hint: 'Search tickets by ID, issue, or category',
          enabled: false,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final filter = _filters[index];
              return _FilterChip(
                label: filter,
                selected: filter == _selected,
                onTap: () => setState(() => _selected = filter),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _UnavailableContent(
          icon: 'file_text.svg',
          title: 'No verified tickets to show',
          message: 'Ticket history, search and status filters will appear when the secure ticket service is connected.',
          action: 'Back to Support',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    ),
  );
}

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({super.key, required this.useCases});
  final SupportUseCases useCases;
  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    eyebrow: 'SUPPORT CENTER',
    title: 'Ticket Details',
    subtitle: 'View the conversation, updates and resolution securely.',
    child: Column(
      children: [
        const _TicketSummaryPlaceholder(),
        const SizedBox(height: 12),
        const _SupportUnavailableBanner(compact: true),
        const SizedBox(height: 16),
        _SupportPanel(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (var index = 0; index < 3; index++) ...[
                Expanded(
                  child: _TabButton(
                    label: const [
                      'Conversation',
                      'Details',
                      'Attachments',
                    ][index],
                    selected: _tab == index,
                    onTap: () => setState(() => _tab = index),
                  ),
                ),
                if (index < 2) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _UnavailableContent(
          icon: _tab == 2 ? 'attachment.svg' : 'message_circle.svg',
          title: const [
            'No verified conversation',
            'No verified ticket details',
            'No verified attachments',
          ][_tab],
          message: 'Open this screen from a backend-provided ticket to display its private support data.',
        ),
        const SizedBox(height: 14),
        const _DisabledComposer(),
      ],
    ),
  );
}

class _TicketFormPanel extends StatelessWidget {
  const _TicketFormPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => _SupportPanel(
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
    child: child,
  );
}

class _TicketFieldHeading extends StatelessWidget {
  const _TicketFieldHeading({
    required this.icon,
    required this.label,
    this.isRequired = false,
    this.trailing,
  });
  final String icon;
  final String label;
  final bool isRequired;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        SupportSvgIcon(icon, size: 18, color: palette.goldText),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: TradeXColors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(color: palette.secondaryText, fontSize: 10),
          ),
      ],
    );
  }
}

class _TicketUploadArea extends StatelessWidget {
  const _TicketUploadArea({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: palette.goldSoft.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.gold.withValues(alpha: .4)),
          ),
          child: Column(
            children: [
              SupportSvgIcon('image.svg', size: 30, color: palette.goldText),
              const SizedBox(height: 8),
              Text(
                busy ? 'Opening gallery…' : 'Upload an image',
                style: TextStyle(
                  color: palette.goldText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Tap to browse your device',
                style: TextStyle(color: palette.secondaryText, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketSummaryPlaceholder extends StatelessWidget {
  const _TicketSummaryPlaceholder();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _SupportPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const _IconTile('headset.svg', size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No verified ticket selected',
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ticket ID, subject and status come from Laravel.',
                  style: TextStyle(color: palette.secondaryText, fontSize: 11),
                ),
              ],
            ),
          ),
          SupportSvgIcon(
            'chevron_right.svg',
            size: 20,
            color: palette.secondaryText,
          ),
        ],
      ),
    );
  }
}
