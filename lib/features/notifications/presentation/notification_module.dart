import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/tradex_colors.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';
import '../platform/notification_permission_service.dart';
import 'bloc/notification_cubit.dart';

typedef NotificationActionCallback = FutureOr<void> Function(
  TradeXNotification notification,
);

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

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({
    super.key,
    required this.repository,
    required this.initial,
    this.onOpenAction,
  });

  final NotificationDataSource repository;
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
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _absoluteTime(item.publishedAt),
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: TradeXColors.border),
                  const SizedBox(height: 20),
                  Text(
                    item.body,
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontSize: 18,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'NOTIFICATION INFORMATION',
                    style: TextStyle(
                      color: TradeXColors.tertiaryText,
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
                        : TradeXColors.primaryText,
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
                foregroundColor: TradeXColors.primaryText,
                side: const BorderSide(color: TradeXColors.borderStrong),
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

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key, required this.repository});

  final NotificationDataSource repository;

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  NotificationPreferences? _value;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final value = await widget.repository.preferences();
    if (mounted) setState(() => _value = value);
  }

  Future<void> _update(NotificationPreferences value) async {
    setState(() => _value = value);
    await widget.repository.savePreferences(value);
  }

  @override
  Widget build(BuildContext context) => _NotificationScaffold(
    child: _value == null
        ? const Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
            children: [
              const _PageHeading(
                eyebrow: 'NOTIFICATION CONTROL',
                title: 'Preferences',
                subtitle: 'Choose which updates matter to you.',
              ),
              const SizedBox(height: 20),
              _PremiumCard(
                borderColor: const Color(0xFF315D49),
                color: const Color(0xFF102019),
                padding: const EdgeInsets.all(16),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PushNotificationScreen(repository: widget.repository),
                  ),
                ),
                child: const Row(
                  children: [
                    _ToneIcon(
                      tone: _NotificationTone(
                        label: 'Settings',
                        color: Color(0xFF5CE2AE),
                        background: Color(0xFF103A2D),
                        icon: Icons.done_rounded,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage device permission and registration',
                            style: TextStyle(color: TradeXColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _PreferenceHeading('Market & trading'),
              const SizedBox(height: 10),
              _PreferenceTile(
                title: 'Trade ideas',
                subtitle: 'New ideas, entry and target updates',
                icon: Icons.show_chart_rounded,
                tone: _goldTone,
                value: _value!.tradeIdeas,
                onChanged: (enabled) =>
                    _update(_value!.copyWith(tradeIdeas: enabled)),
              ),
              _PreferenceTile(
                title: 'Economic news',
                subtitle: 'High-impact news and risk reminders',
                icon: Icons.warning_amber_rounded,
                tone: _redTone,
                value: _value!.economicNews,
                onChanged: (enabled) =>
                    _update(_value!.copyWith(economicNews: enabled)),
              ),
              _PreferenceTile(
                title: 'Funded accounts',
                subtitle: 'Account rules and risk notifications',
                icon: Icons.shield_outlined,
                tone: _goldTone,
                value: _value!.fundedAccounts,
                onChanged: (enabled) =>
                    _update(_value!.copyWith(fundedAccounts: enabled)),
              ),
              _PreferenceTile(
                title: 'Copy trading',
                subtitle: 'Verification and account activity',
                icon: Icons.done_rounded,
                tone: _greenTone,
                value: _value!.copyTrading,
                onChanged: (enabled) =>
                    _update(_value!.copyWith(copyTrading: enabled)),
              ),
              const SizedBox(height: 22),
              const _PreferenceHeading('Your account'),
              const SizedBox(height: 10),
              _PreferenceTile(
                title: 'Learning',
                subtitle: 'New lessons and assignments',
                icon: Icons.menu_book_rounded,
                tone: _blueTone,
                value: _value!.learning,
                onChanged: (enabled) =>
                    _update(_value!.copyWith(learning: enabled)),
              ),
              _PreferenceTile(
                title: 'Affiliate',
                subtitle: 'Referrals and commissions',
                icon: Icons.groups_rounded,
                tone: _purpleTone,
                value: _value!.affiliate,
                onChanged: (enabled) =>
                    _update(_value!.copyWith(affiliate: enabled)),
              ),
              _PreferenceTile(
                title: 'Support',
                subtitle: 'Ticket replies and status changes',
                icon: Icons.support_agent_rounded,
                tone: _goldTone,
                value: _value!.support,
                onChanged: (enabled) =>
                    _update(_value!.copyWith(support: enabled)),
              ),
            ],
          ),
  );
}

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({
    super.key,
    required this.repository,
    this.permissionService = const NotificationPermissionService(),
  });

  final NotificationDataSource repository;
  final NotificationPermissionService permissionService;

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen>
    with WidgetsBindingObserver {
  DeviceNotificationPermission? _permission;
  PushDeviceStatus? _device;
  String? _error;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  Future<void> _load() async {
    final permission = await widget.permissionService.status();
    PushDeviceStatus device = const PushDeviceStatus.unavailable();
    String? error;
    try {
      device = await widget.repository.pushStatus();
    } catch (_) {
      error = 'Device registration status is temporarily unavailable.';
    }
    if (!mounted) return;
    setState(() {
      _permission = permission;
      _device = device;
      _error = error;
    });
  }

  Future<void> _requestPermission() async {
    if (_working) return;
    setState(() => _working = true);
    final result = await widget.permissionService.request();
    if (!mounted) return;
    setState(() {
      _permission = result;
      _working = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final permission = _permission;
    final device = _device;
    final granted = permission == DeviceNotificationPermission.granted;
    return _NotificationScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
        children: [
          const _PageHeading(
            eyebrow: 'DEVICE NOTIFICATIONS',
            title: 'Push notifications',
            subtitle: 'Manage alerts on this device.',
          ),
          const SizedBox(height: 20),
          _PremiumCard(
            borderColor: TradeXColors.goldDeep,
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3A2E17),
                    border: Border.all(color: TradeXColors.goldSoft),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 48,
                    color: TradeXColors.goldBright,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  granted ? 'Notifications enabled' : 'Never miss an alert',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enable device notifications for important trade updates and account activity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _working || granted ? null : _requestPermission,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: TradeXColors.goldBright,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: granted
                        ? const Color(0xFF234A37)
                        : TradeXColors.surfaceMuted,
                    disabledForegroundColor: granted
                        ? const Color(0xFF76E8B9)
                        : TradeXColors.secondaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _working
                        ? 'Checking permission…'
                        : granted
                        ? 'Enabled on this device'
                        : 'Enable notifications',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _PreferenceHeading('Device status'),
          const SizedBox(height: 10),
          _PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const _ToneIcon(
                      tone: _NotificationTone(
                        label: 'Device',
                        color: TradeXColors.goldBright,
                        background: Color(0xFF352A15),
                        icon: Icons.phone_android_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This device',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            device?.platform.isNotEmpty == true
                                ? _titleCase(device!.platform)
                                : 'Android / iOS supported',
                            style: const TextStyle(
                              color: TradeXColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: TradeXColors.border),
                _StatusRow(
                  label: 'Push permission',
                  value: _permissionLabel(permission),
                  active: granted,
                ),
                const Divider(color: TradeXColors.border),
                _StatusRow(
                  label: 'Device registration',
                  value: device?.registered == true ? 'Registered' : 'Pending',
                  active: device?.registered == true,
                ),
                const Divider(color: TradeXColors.border),
                _StatusRow(
                  label: 'Delivery service',
                  value: device?.deliveryEnabled == true
                      ? 'Available'
                      : 'Not configured',
                  active: device?.deliveryEnabled == true,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: TradeXColors.warning)),
          ],
          const SizedBox(height: 18),
          _PremiumCard(
            borderColor: const Color(0xFF514727),
            color: const Color(0xFF171912),
            padding: const EdgeInsets.all(16),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_rounded, color: TradeXColors.goldBright),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your information stays private',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Notification details load securely after you open the app.',
                        style: TextStyle(
                          color: TradeXColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
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
}

class _NotificationScaffold extends StatelessWidget {
  const _NotificationScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TradeXColors.background,
    body: SafeArea(child: child),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: TradeXColors.goldBright,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .55,
        ),
      ),
      const SizedBox(height: 7),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onAction != null)
            IconButton(
              onPressed: onAction,
              tooltip: actionTooltip,
              style: IconButton.styleFrom(
                minimumSize: const Size(50, 50),
                backgroundColor: const Color(0xFF181D25),
                side: const BorderSide(color: TradeXColors.borderStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(actionIcon, color: TradeXColors.goldBright, size: 24),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          color: TradeXColors.secondaryText,
          fontSize: 16,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 18),
      const Divider(color: TradeXColors.border),
    ],
  );
}

class _BackHeading extends StatelessWidget {
  const _BackHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: const Color(0xFF181D25),
          side: const BorderSide(color: TradeXColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

class _UnreadSummary extends StatelessWidget {
  const _UnreadSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => _PremiumCard(
    borderColor: TradeXColors.goldDeep,
    color: const Color(0xFF171C18),
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        const _ToneIcon(
          tone: _NotificationTone(
            label: 'Unread',
            color: TradeXColors.goldBright,
            background: Color(0xFF362B16),
            icon: Icons.notifications_active_outlined,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UNREAD ALERTS',
                style: TextStyle(
                  color: TradeXColors.goldBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count new notification${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Review your important market and account alerts',
                style: TextStyle(color: TradeXColors.secondaryText),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeedFilters extends StatelessWidget {
  const _FeedFilters({required this.state, required this.cubit});

  final NotificationState state;
  final NotificationCubit cubit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 18) / 4;
      return Wrap(
        spacing: 6,
        runSpacing: 8,
        children: [
          _FilterButton(
            width: width,
            label: 'All',
            suffix: state.filter == NotificationFeedFilter.all
                ? state.total
                : null,
            selected: state.filter == NotificationFeedFilter.all,
            onTap: () => cubit.selectFilter(NotificationFeedFilter.all),
          ),
          _FilterButton(
            width: width,
            label: 'Unread',
            suffix: state.unreadCount,
            selected: state.filter == NotificationFeedFilter.unread,
            onTap: () => cubit.selectFilter(NotificationFeedFilter.unread),
          ),
          _FilterButton(
            width: width,
            label: 'Trading',
            selected: state.filter == NotificationFeedFilter.trading,
            onTap: () => cubit.selectFilter(NotificationFeedFilter.trading),
          ),
          _FilterButton(
            width: width,
            label: 'System',
            selected: state.filter == NotificationFeedFilter.system,
            onTap: () => cubit.selectFilter(NotificationFeedFilter.system),
          ),
        ],
      );
    },
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
    this.suffix,
  });

  final double width;
  final String label;
  final int? suffix;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        backgroundColor: selected
            ? const Color(0xFFF0BE50)
            : const Color(0xFF1A2029),
        foregroundColor: selected ? Colors.black : const Color(0xFFC7CBD3),
        side: BorderSide(
          color: selected ? TradeXColors.goldSoft : TradeXColors.borderStrong,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: FittedBox(
        child: Text(
          '$label${suffix == null ? '' : '  $suffix'}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            action!,
            style: const TextStyle(color: TradeXColors.goldBright),
          ),
        ),
    ],
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final TradeXNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(notification);
    return _PremiumCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToneIcon(tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Badge(label: tone.label, color: tone.color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(notification.publishedAt),
                      style: const TextStyle(
                        color: TradeXColors.tertiaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!notification.isRead) ...[
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: TradeXColors.goldBright,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = const Color(0xFF12171E),
    this.borderColor = TradeXColors.borderStrong,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class _ToneIcon extends StatelessWidget {
  const _ToneIcon({required this.tone, this.size = 50});

  final _NotificationTone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: BorderRadius.circular(size * .27),
    ),
    child: Icon(tone.icon, color: tone.color, size: size * .46),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .17),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label.replaceAll('_', ' '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = TradeXColors.primaryText,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _PreferenceHeading extends StatelessWidget {
  const _PreferenceHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
  );
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _NotificationTone tone;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _PremiumCard(
      padding: const EdgeInsets.all(13),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          _ToneIcon(
            tone: _NotificationTone(
              label: tone.label,
              color: tone.color,
              background: tone.background,
              icon: icon,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: TradeXColors.goldBright,
            activeThumbColor: const Color(0xFFFFF1C7),
          ),
        ],
      ),
    ),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.active,
  });

  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: TradeXColors.secondaryText),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: active ? const Color(0xFF5CE2AE) : TradeXColors.goldBright,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: TradeXColors.goldBright,
          size: 48,
        ),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.notifications_none_rounded,
          color: TradeXColors.goldBright,
          size: 52,
        ),
        SizedBox(height: 14),
        Text(
          'You are all caught up',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 6),
        Text(
          'New market and account updates will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: TradeXColors.secondaryText),
        ),
      ],
    ),
  );
}

class _NotificationTone {
  const _NotificationTone({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;
}

const _goldTone = _NotificationTone(
  label: 'TRADE IDEAS',
  color: Color(0xFFF0BE50),
  background: Color(0xFF352A15),
  icon: Icons.show_chart_rounded,
);
const _redTone = _NotificationTone(
  label: 'SECURITY',
  color: Color(0xFFFF7474),
  background: Color(0xFF402123),
  icon: Icons.warning_amber_rounded,
);
const _greenTone = _NotificationTone(
  label: 'ACCOUNT',
  color: Color(0xFF5CE2AE),
  background: Color(0xFF12372C),
  icon: Icons.done_rounded,
);
const _blueTone = _NotificationTone(
  label: 'LEARNING',
  color: Color(0xFF7CB9FF),
  background: Color(0xFF172E49),
  icon: Icons.menu_book_rounded,
);
const _purpleTone = _NotificationTone(
  label: 'AFFILIATE',
  color: Color(0xFFC98CFF),
  background: Color(0xFF342044),
  icon: Icons.groups_rounded,
);

_NotificationTone _toneFor(TradeXNotification notification) =>
    switch (notification.category) {
      'TRADE_IDEA' => _goldTone,
      'SYSTEM' => const _NotificationTone(
        label: 'SYSTEM',
        color: Color(0xFF7CB9FF),
        background: Color(0xFF172E49),
        icon: Icons.settings_outlined,
      ),
      'SECURITY' => _redTone,
      'EDUCATION' => _blueTone,
      'AFFILIATE' => _purpleTone,
      'PAYMENT' => const _NotificationTone(
        label: 'PAYMENT',
        color: Color(0xFF5CE2AE),
        background: Color(0xFF12372C),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _ => const _NotificationTone(
        label: 'UPDATE',
        color: TradeXColors.goldBright,
        background: Color(0xFF352A15),
        icon: Icons.notifications_none_rounded,
      ),
    };

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} h ago';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} d ago';
}

String _absoluteTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} · $hour:$minute $period';
}

String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').toLowerCase();
  if (normalized.isEmpty) return '—';
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}

String _permissionLabel(DeviceNotificationPermission? permission) =>
    switch (permission) {
      DeviceNotificationPermission.granted => 'Enabled',
      DeviceNotificationPermission.denied => 'Not enabled',
      DeviceNotificationPermission.notDetermined => 'Not requested',
      DeviceNotificationPermission.unsupported => 'Unavailable',
      null => 'Checking…',
    };
