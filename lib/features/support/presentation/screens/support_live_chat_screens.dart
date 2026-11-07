part of '../support_module.dart';

class LiveChatWaitingScreen extends StatefulWidget {
  const LiveChatWaitingScreen({super.key, required this.useCases});

  final SupportUseCases useCases;

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
      final session = await widget.useCases.startLiveChat(
        StartSupportLiveChatParams(_idempotencyKey),
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
      final updated = await widget.useCases.getChat(session.uuid);
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
      final updated = await widget.useCases.heartbeat(session.uuid);
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
            useCases: widget.useCases,
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
      await widget.useCases.cancelChat(session.uuid);
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
    eyebrow: 'LIVE CHAT QUEUE',
    title: 'Finding the right support agent for you',
    subtitle: 'Your live position and wait estimate appear only after server confirmation.',
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
    required this.useCases,
    this.session,
  });

  final SupportUseCases useCases;
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
      final result = await widget.useCases.getEvents(
        SupportChatEventsParams(chatUuid: session.uuid, after: _cursor),
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
      final updated = await widget.useCases.heartbeat(session.uuid);
      if (mounted) setState(() => _session = updated);
    } catch (_) {}
  }

  Future<void> _send() async {
    final session = _session;
    final text = _message.text.trim();
    if (_sending || session == null || text.isEmpty || session.isEnded) return;
    setState(() => _sending = true);
    try {
      final sent = await widget.useCases.sendMessage(
        SendSupportMessageParams(ticketUuid: session.ticketUuid, message: text),
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
      await widget.useCases.endChat(session.uuid);
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
    eyebrow: 'LIVE CHAT',
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
