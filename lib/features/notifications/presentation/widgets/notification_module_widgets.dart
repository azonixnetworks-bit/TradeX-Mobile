part of '../notification_module.dart';

class _NotificationScaffold extends StatelessWidget {
  const _NotificationScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.background,
    body: SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: context.isDarkMode ? .12 : .38,
                child: Image.asset(
                  'assets/home_ui/complex_png/delicate_golden_candlestick_trend.png',
                  width: 180,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -16,
            child: IgnorePointer(
              child: Opacity(
                opacity: context.isDarkMode ? .06 : .5,
                child: Image.asset(
                  'assets/home_ui/complex_png/soft_ivory_wave_footer.png',
                  height: 125,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    ),
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
      Row(
        children: [
          if (Navigator.of(context).canPop()) ...[
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Image.asset(
            'assets/branding/trade_x_final_logo.png',
            width: 54,
            height: 54,
            fit: BoxFit.contain,
          ),
        ],
      ),
      const SizedBox(height: 8),
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
                backgroundColor: context.palette.surfaceRaised,
                side: BorderSide(color: context.palette.border),
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
          backgroundColor: context.palette.surfaceRaised,
          side: BorderSide(color: context.palette.border),
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
    color: context.palette.goldSoft,
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
            : context.palette.surfaceMuted,
        foregroundColor: selected
            ? Colors.black
            : context.palette.secondaryText,
        side: BorderSide(
          color: selected ? TradeXColors.goldSoft : context.palette.border,
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
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
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
          color: color ?? context.palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor ?? context.palette.border),
          boxShadow: TradeXElevation.surface(
            brightness: Theme.of(context).brightness,
            palette: context.palette,
          ),
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
  Widget build(BuildContext context) {
    final asset = switch (tone.label) {
      'TRADE IDEAS' => 'assets/home_ui/simple_svg/section_trade_alerts.svg',
      'LEARNING' => 'assets/home_ui/simple_svg/section_course_updates.svg',
      'PAYMENT' ||
      'ACCOUNT' => 'assets/home_ui/simple_svg/section_payment_updates.svg',
      _ => null,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(size * .27),
      ),
      child: asset == null
          ? Icon(tone.icon, color: tone.color, size: size * .46)
          : Padding(
              padding: EdgeInsets.all(size * .24),
              child: SvgPicture.asset(
                asset,
                colorFilter: ColorFilter.mode(tone.color, BlendMode.srcIn),
              ),
            ),
    );
  }
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
