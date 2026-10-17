import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';

class TrustedDevicesScreen extends StatefulWidget {
  const TrustedDevicesScreen({super.key, required this.apiClient});

  final TradeXApiClient apiClient;

  @override
  State<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends State<TrustedDevicesScreen> {
  late Future<List<_TrustedDevice>> _devices;
  String? _revokingUuid;

  @override
  void initState() {
    super.initState();
    _devices = _loadDevices();
  }

  Future<List<_TrustedDevice>> _loadDevices() async {
    final response = await widget.apiClient.getJson(
      '/api/v1/profile/settings/devices',
    );
    final data = response['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) {
      throw const ApiException(message: 'Trusted devices are unavailable.');
    }
    return items
        .whereType<Map>()
        .map((item) => _TrustedDevice.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    final future = _loadDevices();
    setState(() => _devices = future);
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
    } on ApiException catch (error) {
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
    final controller = TextEditingController();
    String? validationMessage;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                controller: controller,
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
                  errorText: validationMessage,
                  labelStyle: const TextStyle(
                    color: TradeXColors.secondaryText,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: TradeXColors.borderStrong),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: TradeXColors.goldBright),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TradeXColors.error,
              ),
              onPressed: () {
                final code = controller.text.trim();
                if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                  setDialogState(
                    () => validationMessage = 'Enter all 6 digits.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, code);
              },
              child: const Text('Revoke device'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeXColors.background,
      appBar: AppBar(
        backgroundColor: TradeXColors.background,
        foregroundColor: TradeXColors.primaryText,
        title: const Text('Trusted devices'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<_TrustedDevice>>(
          future: _devices,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  color: TradeXColors.goldBright,
                ),
              );
            }
            if (snapshot.hasError) {
              return _DeviceLoadError(onRetry: _refresh);
            }

            final devices = snapshot.data ?? const <_TrustedDevice>[];
            return RefreshIndicator(
              color: TradeXColors.goldBright,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  const _SecurityNotice(),
                  const SizedBox(height: 16),
                  ...devices.map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeviceCard(
                        device: device,
                        busy: _revokingUuid == device.uuid,
                        onRevoke: () => _revoke(device),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: TradeXColors.gold.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TradeXColors.goldDeep),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: TradeXColors.goldBright),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Only your current device stays signed in. Revoking another device immediately removes its access and refresh tokens.',
            style: TextStyle(color: TradeXColors.secondaryText, height: 1.4),
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
      color: TradeXColors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: device.isCurrent ? TradeXColors.gold : TradeXColors.border,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              device.slot == 'DESKTOP'
                  ? Icons.computer_rounded
                  : Icons.phone_android_rounded,
              color: device.active
                  ? TradeXColors.goldBright
                  : TradeXColors.tertiaryText,
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
                    style: const TextStyle(
                      color: TradeXColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${device.platform} · ${device.osVersion}',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
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
                foregroundColor: TradeXColors.error,
                side: const BorderSide(color: TradeXColors.error),
              ),
            ),
          ),
        ],
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
        ? TradeXColors.goldBright
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

class _TrustedDevice {
  const _TrustedDevice({
    required this.uuid,
    required this.isCurrent,
    required this.slot,
    required this.platform,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    required this.active,
    required this.lastSeenAt,
  });

  factory _TrustedDevice.fromJson(Map<String, dynamic> json) => _TrustedDevice(
    uuid: json['uuid']?.toString() ?? '',
    isCurrent: json['is_current'] == true,
    slot: json['slot']?.toString().toUpperCase() ?? 'MOBILE',
    platform: json['platform']?.toString().toUpperCase() ?? 'UNKNOWN',
    deviceName: json['device_name']?.toString() ?? '',
    deviceModel: json['device_model']?.toString() ?? '',
    osVersion: json['os_version']?.toString() ?? 'Unknown OS',
    active: json['active'] == true,
    lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? ''),
  );

  final String uuid;
  final bool isCurrent;
  final String slot;
  final String platform;
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final bool active;
  final DateTime? lastSeenAt;

  String get displayName => deviceName.isNotEmpty
      ? deviceName
      : deviceModel.isNotEmpty
      ? deviceModel
      : 'TradeX device';

  String get lastSeenLabel {
    final value = lastSeenAt?.toLocal();
    if (value == null) return 'not available';
    final date = '${value.year}-${_two(value.month)}-${_two(value.day)}';
    final time = '${_two(value.hour)}:${_two(value.minute)}';
    return '$date $time';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
