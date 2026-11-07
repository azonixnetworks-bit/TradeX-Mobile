import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/bloc/bloc_future_builder.dart';
import '../../../core/domain/api_gateway.dart';
import '../../../core/domain/user_facing_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../../../core/widgets/security_screen_shell.dart';

class TrustedDevicesScreen extends StatefulWidget {
  const TrustedDevicesScreen({super.key, required this.apiClient});

  final ApiGateway apiClient;

  @override
  State<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends State<TrustedDevicesScreen> {
  late Future<_TrustedDeviceState> _devices;
  String? _revokingUuid;

  @override
  void initState() {
    super.initState();
    _devices = _loadDevices();
  }

  Future<_TrustedDeviceState> _loadDevices() async {
    final response = await widget.apiClient.getJson(
      '/api/v1/profile/settings/devices',
    );
    final data = response['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) {
      throw const FormatException('Trusted devices are unavailable.');
    }
    final devices = items
        .whereType<Map>()
        .map((item) => _TrustedDevice.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final policy = data is Map ? data['policy'] : null;
    return _TrustedDeviceState(
      devices: devices,
      maximumMobileDevices: _positivePolicyValue(
        policy,
        'maximum_active_mobile_devices',
        2,
      ),
      maximumDesktopDevices: _positivePolicyValue(
        policy,
        'maximum_active_desktop_devices',
        1,
      ),
    );
  }

  int _positivePolicyValue(Object? policy, String key, int fallback) {
    if (policy is! Map) return fallback;
    final raw = policy[key];
    final parsed = raw is num ? raw.toInt() : int.tryParse('$raw');
    return parsed != null && parsed > 0 ? parsed : fallback;
  }

  Future<void> _refresh() async {
    final future = _loadDevices();
    setState(() {
      _devices = future;
    });
    await future;
  }

  Future<void> _revoke(_TrustedDevice device) async {
    final totpCode = await _requestTotp();
    if (totpCode == null || !mounted) return;

    setState(() => _revokingUuid = device.uuid);
    try {
      await widget.apiClient.patchJson(
        '/api/v1/profile/settings/devices/${device.uuid}/revoke',
        <String, dynamic>{'totp_code': totpCode},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.displayName} access revoked.')),
      );
      await _refresh();
    } on UserFacingException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: TradeXColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _revokingUuid = null);
    }
  }

  Future<String?> _requestTotp() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _RevokeDeviceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecurityScreenShell(
      title: 'Trusted Devices',
      subtitle: 'Review the devices that currently have access to your TradeX account.',
      child: BlocFutureBuilder<_TrustedDeviceState>(
        future: _devices,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: TradeXColors.goldBright),
            );
          }
          if (snapshot.hasError) {
            return _DeviceLoadError(onRetry: _refresh);
          }

          final state = snapshot.requireData;
          final devices = state.devices;
          final mobile = devices
              .where((device) => device.slot == 'MOBILE')
              .toList(growable: false);
          final desktop = devices
              .where((device) => device.slot == 'DESKTOP')
              .toList(growable: false);
          return RefreshIndicator(
            color: TradeXColors.goldBright,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
              children: [
                const _SecurityNotice(),
                const SizedBox(height: 18),
                _DeviceGroup(
                  title: 'Mobile Devices',
                  subtitle:
                      'Android and iOS · up to ${state.maximumMobileDevices} active devices',
                  devices: mobile,
                  revokingUuid: _revokingUuid,
                  onRevoke: _revoke,
                ),
                const SizedBox(height: 16),
                _DeviceGroup(
                  title: 'Desktop Devices',
                  subtitle:
                      'Windows, macOS and Web · up to ${state.maximumDesktopDevices} active device',
                  devices: desktop,
                  revokingUuid: _revokingUuid,
                  onRevoke: _revoke,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RevokeDeviceDialog extends StatefulWidget {
  const _RevokeDeviceDialog();

  @override
  State<_RevokeDeviceDialog> createState() => _RevokeDeviceDialogState();
}

class _RevokeDeviceDialogState extends State<_RevokeDeviceDialog> {
  final _controller = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _validationMessage = 'Enter all 6 digits.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: TradeXColors.surfaceRaised,
    title: const Text(
      'Confirm device revoke',
      style: TextStyle(color: TradeXColors.primaryText),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your current 6-digit authenticator code.',
          style: TextStyle(color: TradeXColors.secondaryText),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: TradeXColors.primaryText,
            letterSpacing: 8,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            counterText: '',
            labelText: 'Authenticator code',
            errorText: _validationMessage,
            labelStyle: const TextStyle(color: TradeXColors.secondaryText),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: TradeXColors.borderStrong),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: TradeXColors.goldBright),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: TradeXColors.error),
        onPressed: _submit,
        child: const Text('Revoke device'),
      ),
    ],
  );
}

class _DeviceGroup extends StatelessWidget {
  const _DeviceGroup({
    required this.title,
    required this.subtitle,
    required this.devices,
    required this.revokingUuid,
    required this.onRevoke,
  });

  final String title;
  final String subtitle;
  final List<_TrustedDevice> devices;
  final String? revokingUuid;
  final ValueChanged<_TrustedDevice> onRevoke;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 2),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 10),
      if (devices.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.palette.surfaceRaised,
            borderRadius: TradeXRadii.control,
            border: Border.all(color: context.palette.border),
          ),
          child: Text(
            'No registered devices in this category.',
            style: TextStyle(color: context.palette.secondaryText),
          ),
        )
      else
        ...devices.map(
          (device) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DeviceCard(
              device: device,
              busy: revokingUuid == device.uuid,
              onRevoke: () => onRevoke(device),
            ),
          ),
        ),
    ],
  );
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: context.palette.goldSoft,
      borderRadius: TradeXRadii.control,
      border: Border.all(color: context.palette.gold.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: context.palette.goldText),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            'Your account supports two active mobile devices and one active desktop device. Revoking a device immediately removes its access and refresh tokens.',
            style: TextStyle(color: context.palette.secondaryText, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.busy,
    required this.onRevoke,
  });

  final _TrustedDevice device;
  final bool busy;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.palette.surfaceRaised,
      borderRadius: TradeXRadii.card,
      border: Border.all(
        color: device.isCurrent ? context.palette.gold : context.palette.border,
      ),
      boxShadow: TradeXElevation.surface(
        brightness: Theme.of(context).brightness,
        palette: context.palette,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.palette.goldSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                _deviceAsset(device),
                fit: BoxFit.contain,
                color: device.active ? null : context.palette.tertiaryText,
                colorBlendMode: BlendMode.saturation,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${device.platform} · ${device.osVersion}',
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _DeviceBadge(device: device),
          ],
        ),
        const SizedBox(height: 13),
        if (device.deviceModel.isNotEmpty)
          _DeviceFact(label: 'Model', value: device.deviceModel),
        _DeviceFact(
          label: 'Trust',
          value: device.trusted ? 'Trusted' : 'Untrusted',
        ),
        _DeviceFact(
          label: 'Status',
          value: device.active ? 'Active' : 'Revoked',
        ),
        _DeviceFact(label: 'Registered', value: device.registeredLabel),
        if (device.revokedAt != null)
          _DeviceFact(label: 'Revoked', value: device.revokedLabel),
        Text(
          'Last active ${device.lastSeenLabel}',
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            fontSize: 11,
          ),
        ),
        if (!device.isCurrent && device.active) ...[
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onRevoke,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.phonelink_erase_rounded),
              label: Text(busy ? 'Revoking…' : 'Revoke device'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.goldText,
                side: BorderSide(color: context.palette.gold),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  String _deviceAsset(_TrustedDevice device) {
    final platform = device.platform.toLowerCase();
    final model = device.deviceModel.toLowerCase();
    if (model.contains('tablet') || model.contains('ipad')) {
      return 'assets/security_ui/premium_light_tablet_tile_icon.png';
    }
    if (device.slot == 'DESKTOP') {
      if (platform.contains('mac') || model.contains('laptop')) {
        return 'assets/security_ui/premium_laptop_icon_tile.png';
      }
      return 'assets/security_ui/premium_desktop_monitor_icon.png';
    }
    return 'assets/security_ui/trusted_device_smartphone_icon.png';
  }
}

class _DeviceFact extends StatelessWidget {
  const _DeviceFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: TradeXColors.tertiaryText,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: TradeXColors.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DeviceBadge extends StatelessWidget {
  const _DeviceBadge({required this.device});

  final _TrustedDevice device;

  @override
  Widget build(BuildContext context) {
    final label = device.isCurrent
        ? 'CURRENT'
        : device.active
        ? 'ACTIVE'
        : 'REVOKED';
    final color = device.isCurrent
        ? TradeXColors.success
        : device.active
        ? TradeXColors.success
        : TradeXColors.tertiaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DeviceLoadError extends StatelessWidget {
  const _DeviceLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.devices_other_rounded,
            color: TradeXColors.gold,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load trusted devices.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TradeXColors.primaryText),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _TrustedDeviceState {
  const _TrustedDeviceState({
    required this.devices,
    required this.maximumMobileDevices,
    required this.maximumDesktopDevices,
  });

  final List<_TrustedDevice> devices;
  final int maximumMobileDevices;
  final int maximumDesktopDevices;
}

class _TrustedDevice {
  const _TrustedDevice({
    required this.uuid,
    required this.isCurrent,
    required this.slot,
    required this.platform,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    required this.trusted,
    required this.active,
    required this.registeredAt,
    required this.lastSeenAt,
    required this.revokedAt,
  });

  factory _TrustedDevice.fromJson(Map<String, dynamic> json) => _TrustedDevice(
    uuid: json['uuid']?.toString() ?? '',
    isCurrent: json['is_current'] == true,
    slot: json['slot']?.toString().toUpperCase() ?? 'MOBILE',
    platform: json['platform']?.toString().toUpperCase() ?? 'UNKNOWN',
    deviceName: json['device_name']?.toString() ?? '',
    deviceModel: json['device_model']?.toString() ?? '',
    osVersion: json['os_version']?.toString() ?? 'Unknown OS',
    trusted: json['trusted'] == true,
    active: json['active'] == true,
    registeredAt: DateTime.tryParse(json['registered_at']?.toString() ?? ''),
    lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? ''),
    revokedAt: DateTime.tryParse(json['revoked_at']?.toString() ?? ''),
  );

  final String uuid;
  final bool isCurrent;
  final String slot;
  final String platform;
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final bool trusted;
  final bool active;
  final DateTime? registeredAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;

  String get displayName => deviceName.isNotEmpty
      ? deviceName
      : deviceModel.isNotEmpty
      ? deviceModel
      : 'TradeX device';

  String get lastSeenLabel {
    return _dateLabel(lastSeenAt);
  }

  String get registeredLabel => _dateLabel(registeredAt);
  String get revokedLabel => _dateLabel(revokedAt);

  String _dateLabel(DateTime? dateTime) {
    final value = dateTime?.toLocal();
    if (value == null) return 'not available';
    final date = '${value.year}-${_two(value.month)}-${_two(value.day)}';
    final time = '${_two(value.hour)}:${_two(value.minute)}';
    return '$date $time';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
