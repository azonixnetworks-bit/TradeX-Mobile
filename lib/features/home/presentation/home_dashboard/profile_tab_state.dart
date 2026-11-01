part of '../home_dashboard_screen.dart';

class _ProfileTabState extends State<_ProfileTab> {
  final _imagePicker = ImagePicker();
  late Future<_CustomerProfile> _profile;
  Uint8List? _profilePhoto;
  String? _profileEmail;
  bool _profilePhotoBusy = false;
  bool _fingerprintAdded = false;
  bool _passcodeAdded = false;
  _ProfileSection? _expandedSection;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<_CustomerProfile> _loadProfile() async {
    final response = await widget.apiClient.getJson('/api/v1/profile/settings');
    final raw = response['data'];
    if (raw is! Map) throw StateError('TradeX profile data is unavailable.');
    var premiumAccess = false;
    try {
      final dashboard = await widget.apiClient.getJson('/api/v1/dashboard');
      premiumAccess =
          _asMap(_asMap(dashboard['data'])['account'])['premium_access'] ==
          true;
    } catch (_) {
      // Referral information stays hidden unless entitlement is confirmed.
    }
    final profile = _CustomerProfile.fromJson(
      Map<String, dynamic>.from(raw),
      premiumAccess: premiumAccess,
    );
    _profileEmail = profile.email;
    await _syncProfilePhoto(profile);
    try {
      final quickUnlock = await widget.authRepository
          .readLocalQuickUnlockConfig()
          .timeout(const Duration(seconds: 1));
      _fingerprintAdded = quickUnlock?.hasBiometric == true;
      _passcodeAdded = quickUnlock?.hasPasscode == true;
    } catch (_) {
      // The remote profile remains usable if optional local state is missing.
    }
    return profile;
  }

  Future<void> _syncProfilePhoto(_CustomerProfile profile) async {
    CachedProfilePhoto? cached;
    try {
      cached = await widget.profilePhotoStore
          .read(profile.email)
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      // Remote profile state remains authoritative if disk cache is unavailable.
    }

    if (!profile.photoAvailable) {
      _profilePhoto = null;
      try {
        await widget.profilePhotoStore.remove(profile.email);
      } catch (_) {
        // A stale local cache must not block the server-backed profile.
      }
      return;
    }

    if (cached != null && cached.version == profile.photoVersion) {
      _profilePhoto = cached.bytes;
      return;
    }

    try {
      final bytes = await widget.apiClient.getBytes(
        '${profile.photoEndpoint}?v=${profile.photoVersion}',
      );
      _profilePhoto = bytes;
      try {
        await widget.profilePhotoStore.saveBytes(
          accountEmail: profile.email,
          bytes: bytes,
          version: profile.photoVersion,
        );
      } catch (_) {
        // The authenticated bytes can still be shown if local caching fails.
      }
    } catch (_) {
      _profilePhoto = cached?.bytes;
    }
  }

  void _refresh() {
    setState(() {
      _profile = _loadProfile();
    });
  }

  Future<void> _openMobileDetails(_CustomerProfile profile) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MobileNumberDetailsScreen(
          apiClient: widget.apiClient,
          number: profile.whatsApp,
          verified: profile.whatsAppVerified,
          telegramUsername: profile.telegramUsername,
        ),
      ),
    );
    if (changed == true && mounted) _refresh();
  }

  Future<bool> _openWithdrawal(WithdrawalMethod method) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            WithdrawalMethodScreen(apiClient: widget.apiClient, method: method),
      ),
    );
    if (saved == true && mounted) _refresh();
    return saved == true;
  }

  Future<void> _openQuickUnlockSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            QuickUnlockSettingsScreen(repository: widget.authRepository),
      ),
    );
    if (mounted) _refresh();
  }

  void _toggleSection(_ProfileSection section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  List<Widget> _accountItems(_CustomerProfile profile) => [
    _MenuRow(
      icon: Icons.mail_outline_rounded,
      title: profile.email,
      subtitle: profile.emailVerified
          ? 'Verified email · Locked for your security'
          : 'Unverified email',
      status: Icon(
        profile.emailVerified
            ? Icons.verified_rounded
            : Icons.warning_amber_rounded,
        size: 18,
        color: profile.emailVerified
            ? TradeXColors.success
            : TradeXColors.goldBright,
      ),
      onTap: null,
    ),
    _MenuRow(
      icon: Icons.phone_outlined,
      title: 'Mobile Number',
      subtitle: profile.whatsAppVerified
          ? 'Registered number verified'
          : 'Verification required',
      onTap: () => _openMobileDetails(profile),
    ),
    _MenuRow(
      icon: Icons.language_rounded,
      title: 'Learning language',
      subtitle: profile.languageLabel,
      onTap: () => widget.onActionTap('Learning language'),
    ),
    _MenuRow(
      icon: Icons.brightness_6_rounded,
      title: 'Appearance',
      subtitle: 'System, Light or Dark theme',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LearnSettingsScreen(
            repository: LearnRepository(widget.apiClient),
          ),
        ),
      ),
    ),
  ];

  List<Widget> _withdrawalItems(_CustomerProfile profile) => profile
      .financialMethods
      .map(
        (method) => _MenuRow(
          icon: method.icon,
          title: method.label,
          subtitle: method.configured
              ? method.detail ?? 'Configured securely'
              : 'Not configured',
          onTap: () => unawaited(
            _openWithdrawal(switch (method.label) {
              'PayPal' => WithdrawalMethod.paypal,
              'Binance' => WithdrawalMethod.binance,
              'USDT TRC20' => WithdrawalMethod.usdtTrc20,
              _ => WithdrawalMethod.localBank,
            }),
          ),
        ),
      )
      .toList(growable: false);

  List<Widget> _securityItems(_CustomerProfile profile) => [
    _MenuRow(
      icon: Icons.security_rounded,
      title: profile.totpConfirmed
          ? 'Authenticator protected'
          : 'Set up authenticator',
      subtitle: profile.totpConfirmed
          ? 'TOTP protects sensitive account changes'
          : 'Required before sensitive changes',
      onTap: () => widget.onActionTap('Authenticator security'),
    ),
    _MenuRow(
      icon: Icons.devices_other_rounded,
      title: 'Trusted devices',
      subtitle: 'Review or revoke devices with TOTP',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TrustedDevicesScreen(apiClient: widget.apiClient),
        ),
      ),
    ),
    _MenuRow(
      icon: Icons.fingerprint_rounded,
      title: 'Fingerprint: ${_fingerprintAdded ? 'Added' : 'Not added'}',
      subtitle: _fingerprintAdded
          ? 'Tap to manage or remove fingerprint login'
          : 'Add fingerprint login on this mobile',
      onTap: _openQuickUnlockSettings,
    ),
    _MenuRow(
      icon: Icons.pin_rounded,
      title: 'Passcode: ${_passcodeAdded ? 'Added' : 'Not added'}',
      subtitle: _passcodeAdded
          ? 'Tap to change or remove your passcode'
          : 'Add a secure 4-digit passcode',
      onTap: _openQuickUnlockSettings,
    ),
  ];

  List<Widget> _helpItems() => [
    _MenuRow(
      icon: Icons.forum_outlined,
      title: 'Support centre',
      subtitle: 'Get help with your TradeX account',
      onTap: () => widget.onActionTap('Support centre'),
    ),
    _MenuRow(
      icon: Icons.logout_rounded,
      title: 'Sign out',
      subtitle: 'Keep quick login on this trusted device',
      danger: true,
      onTap: () => unawaited(widget.onLogout()),
    ),
    _MenuRow(
      icon: Icons.phonelink_erase_rounded,
      title: 'Sign out and forget this device',
      subtitle: 'Remove fingerprint or passcode quick login',
      danger: true,
      onTap: () => unawaited(widget.onForgetDevice()),
    ),
    _MenuRow(
      icon: Icons.logout_rounded,
      title: 'Sign out from all devices',
      subtitle: 'Revoke every active TradeX session',
      danger: true,
      onTap: () => unawaited(widget.onLogoutAll()),
    ),
  ];

  Future<void> _chooseProfilePhoto() async {
    final email = _profileEmail;
    if (email == null || _profilePhotoBusy) return;
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 86,
      );
      if (selected == null) return;
      if (mounted) setState(() => _profilePhotoBusy = true);
      final response = await widget.apiClient.postMultipart(
        '/api/v1/profile/settings/photo',
        const {},
        {'photo': selected.path},
      );
      final metadata = _asMap(_asMap(response['data'])['profile_photo']);
      final version = metadata['version'] is num
          ? (metadata['version'] as num).toInt()
          : 0;
      final endpoint = metadata['endpoint']?.toString().trim();
      if (version < 1 || endpoint == null || endpoint.isEmpty) {
        throw const ApiException(
          message: 'The server did not confirm the profile photo.',
        );
      }
      final bytes = await widget.apiClient.getBytes('$endpoint?v=$version');
      try {
        await widget.profilePhotoStore.saveBytes(
          accountEmail: email,
          bytes: bytes,
          version: version,
        );
      } catch (_) {
        // Upload succeeded; a local cache failure must not hide that result.
      }
      if (mounted) setState(() => _profilePhoto = bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated securely.')),
        );
        _refresh();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not upload the profile picture securely.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _profilePhotoBusy = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final email = _profileEmail;
    if (email == null || _profilePhotoBusy) return;
    setState(() => _profilePhotoBusy = true);
    try {
      await widget.apiClient.deleteJson('/api/v1/profile/settings/photo');
      try {
        await widget.profilePhotoStore.remove(email);
      } catch (_) {
        // Server deletion is authoritative even if local cleanup fails.
      }
      if (mounted) {
        setState(() => _profilePhoto = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed.')),
        );
        _refresh();
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _profilePhotoBusy = false);
    }
  }

  Future<void> _showProfilePhotoActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: TradeXColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: TradeXColors.goldBright,
                ),
                title: Text(
                  _profilePhoto == null
                      ? 'Add profile picture'
                      : 'Change profile picture',
                ),
                enabled: !_profilePhotoBusy,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _chooseProfilePhoto();
                },
              ),
              if (_profilePhoto != null)
                ListTile(
                  enabled: !_profilePhotoBusy,
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: TradeXColors.error,
                  ),
                  title: const Text('Remove profile picture'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeProfilePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocFutureBuilder<_CustomerProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: TradeXColors.goldBright),
          );
        }
        if (snapshot.hasError) {
          return _TabScrollView(
            title: 'My Profile',
            subtitle: 'Manage your TradeX account securely.',
            children: [
              _ProfileStatusCard(
                icon: Icons.cloud_off_rounded,
                title: 'Profile unavailable',
                message:
                    'Pull down or tap Retry when your connection is ready.',
                actionLabel: 'Retry',
                onTap: _refresh,
              ),
            ],
          );
        }
        final profile = snapshot.requireData;
        return _TabScrollView(
          title: 'My Profile',
          subtitle: 'Your account, security and payment preferences.',
          children: [
            _CustomerProfileHero(
              profile: profile,
              photo: _profilePhoto,
              onPhotoTap: _profilePhotoBusy ? null : _showProfilePhotoActions,
              photoBusy: _profilePhotoBusy,
            ),
            const SizedBox(height: 20),
            _ProfileAccordionPanel(
              sections: [
                _ProfileAccordionSection(
                  section: _ProfileSection.account,
                  key: const ValueKey('profile-main-account'),
                  icon: Icons.person_outline_rounded,
                  title: 'Account',
                  subtitle: 'Email, mobile number, language and appearance',
                  children: _accountItems(profile),
                ),
                _ProfileAccordionSection(
                  section: _ProfileSection.withdrawal,
                  key: const ValueKey('profile-main-withdrawal'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Withdrawal methods',
                  subtitle: 'PayPal, Binance, USDT TRC20 and bank account',
                  children: _withdrawalItems(profile),
                ),
                _ProfileAccordionSection(
                  section: _ProfileSection.security,
                  key: const ValueKey('profile-main-security'),
                  icon: Icons.verified_user_rounded,
                  title: 'Security centre',
                  subtitle: 'Authenticator, trusted devices, fingerprint and passcode',
                  children: _securityItems(profile),
                ),
                _ProfileAccordionSection(
                  section: _ProfileSection.help,
                  key: const ValueKey('profile-main-help'),
                  icon: Icons.support_agent_rounded,
                  title: 'Help & account',
                  subtitle: 'Support and secure sign-out options',
                  children: _helpItems(),
                ),
              ],
              expandedSection: _expandedSection,
              onToggle: _toggleSection,
            ),
          ],
        );
      },
    );
  }
}
