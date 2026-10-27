import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/support_repository.dart';

const _iconRoot = 'assets/support/icons';
const _imageRoot = 'assets/support/images';
const _globeAsset =
    'assets/affiliate/illustrations/dashboard_network_globe.png';

class SupportHomeScreen extends StatelessWidget {
  const SupportHomeScreen({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final repository = SupportRepository(apiClient);
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
                  onTap: () => _push(
                    context,
                    LiveChatWaitingScreen(repository: repository),
                  ),
                ),
                _SupportActionCard(
                  icon: 'support_document.svg',
                  title: 'Report an Issue',
                  body: 'Prepare a detailed support request securely.',
                  action: 'New Ticket',
                  onTap: () => _push(
                    context,
                    CreateSupportTicketScreen(repository: repository),
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
            onTap: () =>
                _push(context, HelpCenterScreen(repository: repository)),
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
                _push(context, MySupportTicketsScreen(repository: repository)),
          ),
          const SizedBox(height: 10),
          _SupportListTile(
            icon: 'file_text.svg',
            title: 'My Support Tickets',
            subtitle: 'Track requests and view verified responses.',
            onTap: () =>
                _push(context, MySupportTicketsScreen(repository: repository)),
          ),
          const SizedBox(height: 10),
          _SupportListTile(
            icon: 'faq.svg',
            title: 'Help Center & FAQ',
            subtitle: 'Read server-published support articles.',
            onTap: () =>
                _push(context, HelpCenterScreen(repository: repository)),
          ),
        ],
      ),
    );
  }
}

class CreateSupportTicketScreen extends StatefulWidget {
  const CreateSupportTicketScreen({super.key, required this.repository});

  final SupportRepository repository;

  @override
  State<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
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
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
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
  const MySupportTicketsScreen({super.key, required this.repository});

  final SupportRepository repository;

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
          message: SupportRepository.unavailableMessage,
          action: 'Back to Support',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    ),
  );
}

class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({super.key, required this.repository});

  final SupportRepository repository;

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

class LiveChatWaitingScreen extends StatefulWidget {
  const LiveChatWaitingScreen({super.key, required this.repository});

  final SupportRepository repository;

  @override
  State<LiveChatWaitingScreen> createState() => _LiveChatWaitingScreenState();
}

class _LiveChatWaitingScreenState extends State<LiveChatWaitingScreen> {
  final _idempotencyKey = const Uuid().v4();
  SupportChatSession? _session;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;
  Object? _error;
  bool _loading = true;
  bool _polling = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.repository.startLiveChat(
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
      if (session.isConnected) {
        _openConversation(session);
        return;
      }
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_poll()),
      );
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => unawaited(_heartbeat()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _poll() async {
    final session = _session;
    if (_polling || session == null || session.isEnded) return;
    _polling = true;
    try {
      final updated = await widget.repository.chat(session.uuid);
      if (!mounted) return;
      setState(() => _session = updated);
      if (updated.isConnected) _openConversation(updated);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _polling = false;
    }
  }

  Future<void> _heartbeat() async {
    final session = _session;
    if (session == null || session.isEnded) return;
    try {
      final updated = await widget.repository.heartbeat(session.uuid);
      if (mounted) setState(() => _session = updated);
    } catch (_) {
      // The status poll surfaces persistent connection failures.
    }
  }

  void _openConversation(SupportChatSession session) {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => LiveChatConversationScreen(
            repository: widget.repository,
            session: session,
          ),
        ),
      );
    });
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    final session = _session;
    if (session == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _cancelling = true);
    try {
      await widget.repository.cancelChat(session.uuid);
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _cancelling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    eyebrow: 'LIVE SUPPORT',
    title: 'Finding the right support agent for you',
    subtitle:
        'Queue details appear only after the server confirms your request.',
    child: Column(
      children: [
        Image.asset(
          '$_imageRoot/support_headset_3d.png',
          height: 220,
          fit: BoxFit.contain,
          semanticLabel: 'Support headset illustration',
        ),
        const SizedBox(height: 12),
        _SupportPanel(
          child: Row(
            children: [
              Expanded(
                child: _QueueMetric(
                  value: _session?.queuePosition?.toString() ?? '—',
                  label: 'Queue position',
                ),
              ),
              _divider(),
              Expanded(
                child: _QueueMetric(
                  value: _session?.etaMinutes == null
                      ? '—'
                      : '${_session!.etaMinutes}m',
                  label: 'Estimated wait',
                ),
              ),
              _divider(),
              Expanded(
                child: _QueueMetric(
                  value: _session?.agentsOnline.toString() ?? '—',
                  label: 'Agents online',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const _LiveStatusBanner(
            icon: Icons.lock_clock_outlined,
            message: 'Creating your secure support request…',
          )
        else if (_error != null)
          _LiveStatusBanner(
            icon: Icons.error_outline,
            message: _friendlyError(_error!),
            error: true,
            action: 'Retry',
            onTap: _start,
          )
        else
          _LiveStatusBanner(
            icon: Icons.verified_user_outlined,
            message: _session!.agentsOnline > 0
                ? 'Your request is live. An online agent can claim it now.'
                : 'Your request is queued securely. We will connect the next available agent.',
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _cancelling ? null : _cancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: TradeXColors.error,
            side: const BorderSide(color: TradeXColors.error),
            minimumSize: const Size.fromHeight(54),
          ),
          icon: const Icon(Icons.stop_circle_outlined),
          label: Text(_cancelling ? 'Cancelling…' : 'Cancel Request'),
        ),
      ],
    ),
  );
}

class LiveChatConversationScreen extends StatefulWidget {
  const LiveChatConversationScreen({
    super.key,
    required this.repository,
    this.session,
  });

  final SupportRepository repository;
  final SupportChatSession? session;

  @override
  State<LiveChatConversationScreen> createState() =>
      _LiveChatConversationScreenState();
}

class _LiveChatConversationScreenState
    extends State<LiveChatConversationScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  final List<SupportMessage> _messages = [];
  Timer? _pollTimer;
  Timer? _heartbeatTimer;
  SupportChatSession? _session;
  Object? _error;
  int _cursor = 0;
  bool _loading = true;
  bool _polling = false;
  bool _sending = false;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    if (_session == null) {
      _loading = false;
      _error = StateError('No active support conversation was selected.');
      return;
    }
    unawaited(_loadEvents());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_loadEvents()),
    );
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_heartbeat()),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final session = _session;
    if (_polling || session == null || session.isEnded) return;
    _polling = true;
    try {
      final result = await widget.repository.events(
        session.uuid,
        after: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _session = result.chat;
        _cursor = result.nextCursor;
        for (final event in result.events) {
          if (_messages.every((item) => item.uuid != event.uuid)) {
            _messages.add(event);
          }
        }
        _loading = false;
        _error = null;
      });
      _scrollToLatest();
      if (result.chat.isEnded) {
        _pollTimer?.cancel();
        _heartbeatTimer?.cancel();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _heartbeat() async {
    final session = _session;
    if (session == null || session.isEnded) return;
    try {
      final updated = await widget.repository.heartbeat(session.uuid);
      if (mounted) setState(() => _session = updated);
    } catch (_) {}
  }

  Future<void> _send() async {
    final session = _session;
    final text = _message.text.trim();
    if (_sending || session == null || text.isEmpty || session.isEnded) return;
    setState(() => _sending = true);
    try {
      final sent = await widget.repository.sendMessage(
        ticketUuid: session.ticketUuid,
        message: text,
      );
      if (!mounted) return;
      setState(() {
        if (_messages.every((item) => item.uuid != sent.uuid)) {
          _messages.add(sent);
        }
        if (sent.cursor > _cursor) _cursor = sent.cursor;
        _message.clear();
        _error = null;
      });
      _scrollToLatest();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _end() async {
    final session = _session;
    if (_ending || session == null) return;
    setState(() => _ending = true);
    try {
      await widget.repository.endChat(session.uuid);
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _ending = false;
        });
      }
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    title: 'Live Support',
    subtitle: _session?.ticketReference.isNotEmpty == true
        ? 'Secure conversation · ${_session!.ticketReference}'
        : 'Authenticated support conversation',
    child: Column(
      children: [
        _LiveAgentHeader(
          name: _session?.assignedAgentName ?? 'Support agent',
          state: _session?.state ?? 'unavailable',
        ),
        const SizedBox(height: 14),
        _SupportPanel(
          child: SizedBox(
            height: 390,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Connected. Send a message to your support agent.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TradeXColors.secondaryText),
                    ),
                  )
                : ListView.separated(
                    controller: _scroll,
                    itemCount: _messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _LiveMessageBubble(message: _messages[index]),
                  ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _LiveStatusBanner(
            icon: Icons.error_outline,
            message: _friendlyError(_error!),
            error: true,
            action: 'Retry',
            onTap: _loadEvents,
          ),
        ],
        const SizedBox(height: 12),
        _LiveComposer(
          controller: _message,
          enabled: _session != null && !(_session?.isEnded ?? true),
          sending: _sending,
          onSend: _send,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _ending ? null : _end,
          icon: const Icon(Icons.call_end_outlined),
          label: Text(_ending ? 'Ending…' : 'End live chat'),
          style: TextButton.styleFrom(foregroundColor: TradeXColors.error),
        ),
      ],
    ),
  );
}

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner({
    required this.icon,
    required this.message,
    this.error = false,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String message;
  final bool error;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: error
          ? TradeXColors.error.withValues(alpha: .08)
          : TradeXColors.gold.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: error
            ? TradeXColors.error.withValues(alpha: .65)
            : TradeXColors.goldSoft.withValues(alpha: .72),
      ),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: error ? TradeXColors.error : TradeXColors.goldBright,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              height: 1.35,
              fontSize: 12,
            ),
          ),
        ),
        if (action != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class _LiveAgentHeader extends StatelessWidget {
  const _LiveAgentHeader({required this.name, required this.state});

  final String name;
  final String state;

  @override
  Widget build(BuildContext context) => _SupportPanel(
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TradeXColors.gold.withValues(alpha: .12),
            border: Border.all(color: TradeXColors.goldSoft),
          ),
          child: const Center(child: SupportSvgIcon('headset.svg', size: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state == 'active' ? '● Online · Live chat' : '● Connected',
                style: const TextStyle(
                  color: TradeXColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.lock_outline,
          color: TradeXColors.goldBright,
          size: 20,
        ),
      ],
    ),
  );
}

class _LiveMessageBubble extends StatelessWidget {
  const _LiveMessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromCustomer;
    final hour = message.createdAt.hour.toString().padLeft(2, '0');
    final minute = message.createdAt.minute.toString().padLeft(2, '0');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: mine
                  ? [
                      TradeXColors.goldDeep.withValues(alpha: .7),
                      TradeXColors.surfaceRaised,
                    ]
                  : [TradeXColors.surfaceMuted, TradeXColors.surfaceRaised],
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: Border.all(
              color: mine ? TradeXColors.goldSoft : TradeXColors.borderStrong,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.message,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$hour:$minute',
                style: const TextStyle(
                  color: TradeXColors.tertiaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveComposer extends StatelessWidget {
  const _LiveComposer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled && !sending,
    minLines: 1,
    maxLines: 4,
    maxLength: 10000,
    textCapitalization: TextCapitalization.sentences,
    style: const TextStyle(color: TradeXColors.primaryText),
    decoration: InputDecoration(
      counterText: '',
      hintText: enabled ? 'Type your message…' : 'Conversation ended',
      filled: true,
      fillColor: TradeXColors.surfaceRaised,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      suffixIcon: IconButton(
        tooltip: 'Send message',
        onPressed: enabled && !sending ? onSend : null,
        icon: sending
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const SupportSvgIcon('send.svg', size: 21),
      ),
    ),
  );
}

String _friendlyError(Object error) {
  if (error is ApiException) return error.message;
  if (error is StateError) return error.message;
  return 'Live support is temporarily unavailable. Please try again.';
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key, required this.repository});

  final SupportRepository repository;

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
            CreateSupportTicketScreen(repository: widget.repository),
          ),
        ),
      ],
    ),
  );
}

class TicketFeedbackScreen extends StatefulWidget {
  const TicketFeedbackScreen({super.key, required this.repository});

  final SupportRepository repository;

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

class _SupportScaffold extends StatelessWidget {
  const _SupportScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.eyebrow,
    this.showBack = true,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    body: Stack(
      children: [
        Positioned(
          top: -35,
          right: -100,
          child: IgnorePointer(
            child: Opacity(
              opacity: .22,
              child: Image.asset(
                _globeAsset,
                width: 360,
                height: 290,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: -60,
          child: IgnorePointer(
            child: Opacity(
              opacity: .22,
              child: Image.asset(
                '$_imageRoot/gold_orbit_lines.png',
                width: 330,
              ),
            ),
          ),
        ),
        SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                sliver: SliverList.list(
                  children: [
                    if (showBack)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    if (showBack) const SizedBox(height: 16),
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!,
                        style: const TextStyle(
                          color: TradeXColors.goldBright,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: TradeXColors.primaryText,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TradeXColors.secondaryText,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SupportPanel(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconTile(icon),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            height: 1.35,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        _GoldButton(label: action, onPressed: onTap, compact: true),
      ],
    ),
  );
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TradeXColors.surfaceRaised,
          TradeXColors.surface,
          TradeXColors.goldDeep.withValues(alpha: .09),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TradeXColors.borderStrong),
      boxShadow: [
        BoxShadow(
          color: TradeXColors.gold.withValues(alpha: .05),
          blurRadius: 20,
        ),
      ],
    ),
    child: child,
  );
}

class _SupportUnavailableBanner extends StatelessWidget {
  const _SupportUnavailableBanner({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 12 : 14),
    decoration: BoxDecoration(
      color: TradeXColors.warning.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TradeXColors.warning.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: TradeXColors.goldBright,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            SupportRepository.unavailableMessage,
            style: TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: compact ? 11 : 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SupportUnavailableField extends StatelessWidget {
  const _SupportUnavailableField({
    required this.icon,
    required this.label,
    required this.helper,
  });

  final String icon;
  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) => _SupportPanel(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        _IconTile(icon, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                helper,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onTap,
  });

  final String icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _SupportPanel(
    child: Column(
      children: [
        _IconTile(icon, size: 60),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            height: 1.4,
          ),
        ),
        if (action != null && onTap != null) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(action!),
          ),
        ],
      ],
    ),
  );
}

class _SupportListTile extends StatelessWidget {
  const _SupportListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _SupportPanel(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            _IconTile(icon, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _SupportMetric extends StatelessWidget {
  const _SupportMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SupportSvgIcon(icon, size: 22),
      const SizedBox(height: 7),
      Text(
        value,
        style: const TextStyle(
          color: TradeXColors.primaryText,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: TradeXColors.secondaryText, fontSize: 10),
      ),
    ],
  );
}

class _QueueMetric extends StatelessWidget {
  const _QueueMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: TradeXColors.primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: TradeXColors.secondaryText, fontSize: 10),
      ),
    ],
  );
}

class _SupportSearchField extends StatelessWidget {
  const _SupportSearchField({
    required this.hint,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final TextEditingController? controller;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    readOnly: readOnly,
    onTap: onTap,
    style: const TextStyle(color: TradeXColors.primaryText),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Padding(
        padding: EdgeInsets.all(14),
        child: SupportSvgIcon('search.svg', size: 22),
      ),
      filled: true,
      fillColor: TradeXColors.surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TradeXColors.borderStrong),
      ),
    ),
  );
}

class _SupportTextField extends StatelessWidget {
  const _SupportTextField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLength: maxLength,
    minLines: minLines,
    maxLines: maxLines,
    style: const TextStyle(color: TradeXColors.primaryText),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: TradeXColors.surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: TradeXColors.borderStrong),
      ),
    ),
  );
}

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final String icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(62),
      side: const BorderSide(color: TradeXColors.borderStrong),
      foregroundColor: TradeXColors.goldBright,
    ),
    icon: SupportSvgIcon(icon, size: 22),
    label: Text(label),
  );
}

class _SelectedAttachment extends StatelessWidget {
  const _SelectedAttachment({
    required this.bytes,
    required this.name,
    required this.onRemove,
  });
  final Uint8List bytes;
  final String name;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => _SupportPanel(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, width: 62, height: 62, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TradeXColors.primaryText),
          ),
        ),
        IconButton(
          tooltip: 'Remove attachment',
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, color: TradeXColors.error),
        ),
      ],
    ),
  );
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool compact;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD97C), TradeXColors.goldBright, TradeXColors.gold],
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: TradeXColors.goldBright.withValues(alpha: .18),
          blurRadius: 16,
        ),
      ],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.black,
        minimumSize: Size.fromHeight(compact ? 44 : 54),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            SupportSvgIcon(icon!, size: 20, color: Colors.black),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 7),
          const Icon(Icons.arrow_forward_rounded, size: 19),
        ],
      ),
    ),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon, {this.size = 54});
  final String icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          TradeXColors.goldDeep.withValues(alpha: .36),
          TradeXColors.surfaceRaised,
        ],
      ),
      borderRadius: BorderRadius.circular(size * .28),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .35)),
    ),
    child: SupportSvgIcon(icon, size: size * .46),
  );
}

class SupportSvgIcon extends StatelessWidget {
  const SupportSvgIcon(this.name, {super.key, this.size = 24, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    '$_iconRoot/$name',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back',
    child: IconButton.outlined(
      tooltip: 'Back',
      onPressed: onTap,
      icon: const SupportSvgIcon('arrow_left.svg'),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: BorderSide(color: TradeXColors.gold.withValues(alpha: .4)),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: TradeXColors.primaryText,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 1; index <= 3; index++) ...[
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: index == 1
                ? TradeXColors.goldBright
                : TradeXColors.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(
              color: index == 1
                  ? TradeXColors.goldBright
                  : TradeXColors.borderStrong,
            ),
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: index == 1 ? Colors.black : TradeXColors.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (index < 3)
          Expanded(
            child: Container(
              height: 2,
              color: index == 1
                  ? TradeXColors.goldBright
                  : TradeXColors.borderStrong,
            ),
          ),
      ],
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    label: Text(label),
    selectedColor: TradeXColors.goldBright,
    backgroundColor: TradeXColors.surfaceRaised,
    side: BorderSide(
      color: selected ? TradeXColors.goldBright : TradeXColors.borderStrong,
    ),
    labelStyle: TextStyle(
      color: selected ? Colors.black : TradeXColors.primaryText,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _StaticChip extends StatelessWidget {
  const _StaticChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    backgroundColor: TradeXColors.surfaceRaised,
    side: const BorderSide(color: TradeXColors.borderStrong),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      decoration: BoxDecoration(
        color: selected
            ? TradeXColors.goldDeep.withValues(alpha: .3)
            : TradeXColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? TradeXColors.gold : TradeXColors.borderStrong,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected
              ? TradeXColors.goldBright
              : TradeXColors.secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _DisabledComposer extends StatelessWidget {
  const _DisabledComposer();
  @override
  Widget build(BuildContext context) => TextField(
    enabled: false,
    decoration: InputDecoration(
      hintText: 'Messaging unavailable',
      prefixIcon: const Padding(
        padding: EdgeInsets.all(14),
        child: SupportSvgIcon('paperclip.svg', size: 20),
      ),
      suffixIcon: const Padding(
        padding: EdgeInsets.all(14),
        child: SupportSvgIcon('send.svg', size: 20),
      ),
      filled: true,
      fillColor: TradeXColors.surfaceRaised,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

Widget _divider() => Container(
  width: 1,
  height: 62,
  margin: const EdgeInsets.symmetric(horizontal: 8),
  color: TradeXColors.borderStrong,
);

Future<void> _push(BuildContext context, Widget screen) =>
    Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => screen));

void _showUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(SupportRepository.unavailableMessage)),
  );
}
