part of '../notification_module.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({
    super.key,
    required this.repository,
    required this.initial,
    this.onOpenAction,
  });

  final NotificationRepository repository;
  final TradeXNotification initial;
  final NotificationActionCallback? onOpenAction;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late Future<TradeXNotification> _request;

  @override
  void initState() {
    super.initState();
    _request = widget.repository.detail(widget.initial.uuid);
  }

  @override
  Widget build(BuildContext context) => _NotificationScaffold(
    child: FutureBuilder<TradeXNotification>(
      future: _request,
      initialData: widget.initial,
      builder: (context, snapshot) {
        final item = snapshot.data ?? widget.initial;
        final tone = _toneFor(item);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: [
            _BackHeading(title: 'Notification details'),
            const SizedBox(height: 8),
            Text(
              'View the complete message and available related action.',
              style: TextStyle(
                color: context.palette.secondaryText,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            _PremiumCard(
              borderColor: tone.color.withValues(alpha: .45),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ToneIcon(tone: tone, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Badge(
                              label: item.priority,
                              color: item.priority == 'CRITICAL'
                                  ? const Color(0xFFFF7272)
                                  : tone.color,
                            ),
                            _Badge(
                              label: tone.label,
                              color: TradeXColors.goldBright,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _absoluteTime(item.publishedAt),
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: context.palette.border),
                  const SizedBox(height: 20),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 18,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'NOTIFICATION INFORMATION',
                    style: TextStyle(
                      color: context.palette.tertiaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Priority',
                    value: _titleCase(item.priority),
                    valueColor: item.priority == 'CRITICAL'
                        ? const Color(0xFFFF7272)
                        : context.palette.primaryText,
                  ),
                  _InfoRow(label: 'Category', value: tone.label),
                ],
              ),
            ),
            if (item.hasAction && widget.onOpenAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => widget.onOpenAction!(item),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Open related screen'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: TradeXColors.goldBright,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: context.palette.primaryText,
                side: BorderSide(color: context.palette.borderStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Back to notifications'),
            ),
          ],
        );
      },
    ),
  );
}
