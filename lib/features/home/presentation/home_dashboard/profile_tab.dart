part of '../home_dashboard_screen.dart';

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    super.key,
    required this.onActionTap,
    required this.onLogout,
    required this.onForgetDevice,
    required this.onLogoutAll,
    required this.apiClient,
    required this.authRepository,
    required this.profilePhotoStore,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;
  final Future<void> Function() onForgetDevice;
  final Future<void> Function() onLogoutAll;
  final TradeXApiClient apiClient;
  final AuthRepository authRepository;
  final LocalProfilePhotoStore profilePhotoStore;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

enum _ProfileSection { account, withdrawal, security, help }
