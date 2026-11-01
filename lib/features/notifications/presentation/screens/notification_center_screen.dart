part of '../notification_module.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    required this.repository,
    this.onOpenAction,
  });

  final NotificationDataSource repository;
  final NotificationActionCallback? onOpenAction;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with WidgetsBindingObserver {
  late final NotificationCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = NotificationCubit(widget.repository)..initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_cubit.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<NotificationCubit, NotificationState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!))),
        child: _NotificationScaffold(
          child: BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) => RefreshIndicator(
              color: TradeXColors.goldBright,
              onRefresh: _cubit.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                    sliver: SliverList.list(
                      children: [
                        _PageHeading(
                          eyebrow: 'YOUR ACTIVITY',
                          title: 'Notifications',
                          subtitle: 'Your market activity, all in one place.',
                          actionIcon: Icons.tune_rounded,
                          actionTooltip: 'Notification preferences',
                          onAction: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => NotificationPreferencesScreen(
                                repository: widget.repository,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _UnreadSummary(count: state.unreadCount),
                        const SizedBox(height: 16),
                        _FeedFilters(state: state, cubit: _cubit),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  if (state.status == NotificationLoadStatus.loading &&
                      state.items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TradeXColors.goldBright,
                        ),
                      ),
                    )
                  else if (state.status == NotificationLoadStatus.failure &&
                      state.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(
                        message:
                            state.error ?? 'Notifications are unavailable.',
                        onRetry: _cubit.initialize,
                      ),
                    )
                  else if (state.items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    ..._notificationSlivers(context, state.items),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _notificationSlivers(
    BuildContext context,
    List<TradeXNotification> items,
  ) {
    final now = DateTime.now();
    final today = items
        .where((item) => _sameDate(item.publishedAt, now))
        .toList(growable: false);
    final earlier = items
        .where((item) => !_sameDate(item.publishedAt, now))
        .toList(growable: false);
    return [
      if (today.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Today',
              action: 'Mark all as read',
              onAction: _cubit.markAllRead,
            ),
          ),
        ),
        _notificationList(context, today),
      ],
      if (earlier.isNotEmpty) ...[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, today.isEmpty ? 0 : 18, 20, 10),
          sliver: const SliverToBoxAdapter(
            child: _SectionHeader(title: 'Earlier'),
          ),
        ),
        _notificationList(context, earlier),
      ],
    ];
  }

  Widget _notificationList(
    BuildContext context,
    List<TradeXNotification> items,
  ) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = items[index];
        return _NotificationTile(
          notification: notification,
          onTap: () async {
            unawaited(_cubit.markRead(notification.uuid));
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => NotificationDetailScreen(
                  repository: widget.repository,
                  initial: notification,
                  onOpenAction: widget.onOpenAction,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
