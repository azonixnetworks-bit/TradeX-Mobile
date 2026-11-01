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
      final bytes = file.bytes;
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _photoName = file.name;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    title: 'Create Support Ticket',
    subtitle: 'Tell us about the issue you’re facing and we’ll get you the right help.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIndicator(),
        const SizedBox(height: 20),
        const _FieldLabel('Issue Category'),
        const SizedBox(height: 8),
        const _SupportUnavailableField(
          icon: 'file_text.svg',
          label: 'Categories unavailable',
          helper: 'Categories and questions must come from Laravel.',
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Related Account (Optional)'),
        const SizedBox(height: 8),
        const _SupportUnavailableField(
          icon: 'credit_card.svg',
          label: 'No verified accounts loaded',
          helper: 'Only customer-owned accounts can appear here.',
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Subject'),
        const SizedBox(height: 8),
        _SupportTextField(
          controller: _subject,
          hint: 'Briefly describe your issue',
          maxLength: 100,
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Description'),
        const SizedBox(height: 8),
        _SupportTextField(
          controller: _description,
          hint: 'Include what happened, when it started and any error message.',
          maxLength: 1000,
          minLines: 5,
          maxLines: 8,
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            _FieldLabel('Attachment (Optional)'),
            Spacer(),
            Text(
              'Image selection only',
              style: TextStyle(color: TradeXColors.secondaryText, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photo == null)
          _AttachmentAction(
            icon: 'image.svg',
            label: _picking ? 'Opening gallery…' : 'Add Photo',
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
        const SizedBox(height: 18),
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
    subtitle: 'Track requests, check status and view verified responses.',
    child: Column(
      children: [
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
        const SizedBox(height: 14),
        const _SupportSearchField(
          hint: 'Search tickets by ID, issue, or category',
          enabled: false,
        ),
        const SizedBox(height: 18),
        _UnavailableContent(
          icon: 'support_document.svg',
          title: 'Ticket history is not connected',
          message: SupportPolicy.unavailableMessage,
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
    subtitle: 'Track your request and communicate securely with our team.',
    child: Column(
      children: [
        const _SupportUnavailableField(
          icon: 'support_document.svg',
          label: 'No verified ticket selected',
          helper: 'Ticket identity and assigned agent must come from Laravel.',
        ),
        const SizedBox(height: 14),
        Row(
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
        const SizedBox(height: 18),
        const _UnavailableContent(
          icon: 'message_circle.svg',
          title: 'Secure conversation unavailable',
          message: 'No authenticated support message endpoint or private realtime channel is published yet.',
        ),
        const SizedBox(height: 14),
        const _DisabledComposer(),
      ],
    ),
  );
}
