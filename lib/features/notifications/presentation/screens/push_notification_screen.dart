part of '../notification_module.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({
    super.key,
    required this.repository,
    this.permissionService,
  });

  final NotificationRepository repository;
  final NotificationPermissionRepository? permissionService;

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
    final permission =
        await widget.permissionService?.status() ??
        DeviceNotificationPermission.unsupported;
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
    final result =
        await widget.permissionService?.request() ??
        DeviceNotificationPermission.unsupported;
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
            title: 'Enable Notifications',
            subtitle: 'Stay informed with market updates, trade ideas and important account alerts.',
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
                    color: context.palette.goldSoft,
                    border: Border.all(
                      color: context.palette.gold.withValues(alpha: .35),
                    ),
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
          const _PreferenceHeading('Why enable notifications?'),
          const SizedBox(height: 10),
          const _PushBenefit(
            icon: Icons.bolt_rounded,
            title: 'Real-Time Alerts',
            subtitle: 'Market moves, trade ideas and important events.',
          ),
          const _PushBenefit(
            icon: Icons.shield_outlined,
            title: 'Account Security',
            subtitle: 'Important account and payment notifications.',
          ),
          const _PushBenefit(
            icon: Icons.menu_book_outlined,
            title: 'Learning & Product Updates',
            subtitle: 'New features, lessons and market guides.',
          ),
          const SizedBox(height: 14),
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
            borderColor: context.palette.gold.withValues(alpha: .3),
            color: context.palette.goldSoft,
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

class _PushBenefit extends StatelessWidget {
  const _PushBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: _PremiumCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.palette.goldSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: context.palette.goldText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.palette.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
