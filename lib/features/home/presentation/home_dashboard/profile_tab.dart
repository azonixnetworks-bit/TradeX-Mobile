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
    required this.learnRepository,
    required this.withdrawalDraftStore,
  });

  final ValueChanged<String> onActionTap;
  final Future<void> Function() onLogout;
  final Future<void> Function() onForgetDevice;
  final Future<void> Function() onLogoutAll;
  final ApiGateway apiClient;
  final AuthRepositoryContract authRepository;
  final ProfilePhotoStore profilePhotoStore;
  final LearnRepository learnRepository;
  final WithdrawalDraftStore withdrawalDraftStore;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

enum _ProfileSection { account, withdrawal, security, help }
