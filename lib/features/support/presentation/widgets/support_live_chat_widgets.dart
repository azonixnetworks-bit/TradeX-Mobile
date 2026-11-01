part of '../support_module.dart';

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
