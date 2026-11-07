part of '../home_dashboard_screen.dart';

class _ProfileAccordionSection {
  const _ProfileAccordionSection({
    required this.section,
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final _ProfileSection section;
  final Key key;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
}

class _ProfileAccordionPanel extends StatelessWidget {
  const _ProfileAccordionPanel({
    required this.sections,
    required this.expandedSection,
    required this.onToggle,
  });

  final List<_ProfileAccordionSection> sections;
  final _ProfileSection? expandedSection;
  final ValueChanged<_ProfileSection> onToggle;

  @override
  Widget build(BuildContext context) => Container(
    decoration: _panelDecoration(context),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: List<Widget>.generate(sections.length * 2 - 1, (index) {
        if (index.isOdd) {
          return const Divider(height: 1, color: TradeXColors.border);
        }
        final section = sections[index ~/ 2];
        return _ProfileAccordionTile(
          section: section,
          expanded: expandedSection == section.section,
          onTap: () => onToggle(section.section),
        );
      }),
    ),
  );
}

class _ProfileAccordionTile extends StatelessWidget {
  const _ProfileAccordionTile({
    required this.section,
    required this.expanded,
    required this.onTap,
  });

  final _ProfileAccordionSection section;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _MenuRow(
        key: section.key,
        icon: section.icon,
        title: section.title,
        subtitle: section.subtitle,
        expanded: expanded,
        onTap: onTap,
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 240),
        reverseDuration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: expanded
            ? Container(
                key: ValueKey(
                  'profile-section-${section.section.name}-options',
                ),
                decoration: BoxDecoration(
                  color: TradeXColors.background.withValues(alpha: .34),
                  border: const Border(
                    top: BorderSide(color: TradeXColors.border),
                  ),
                ),
                child: Column(
                  children: List<Widget>.generate(
                    section.children.length * 2 - 1,
                    (index) {
                      if (index.isOdd) {
                        return const Divider(
                          height: 1,
                          indent: 48,
                          color: TradeXColors.border,
                        );
                      }
                      return section.children[index ~/ 2];
                    },
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}

class _CustomerProfile {
  const _CustomerProfile({
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.accountType,
    required this.referralCode,
    required this.premiumAccess,
    required this.whatsApp,
    required this.whatsAppVerified,
    required this.telegramUsername,
    required this.languageLabel,
    required this.totpConfirmed,
    required this.financialMethods,
    required this.photoAvailable,
    required this.photoVersion,
    required this.photoEndpoint,
  });

  factory _CustomerProfile.fromJson(
    Map<String, dynamic> json, {
    required bool premiumAccess,
  }) {
    final profile = _asMap(json['profile']);
    final identity = _asMap(profile['identity']);
    final contact = _asMap(profile['contact']);
    final preferences = _asMap(profile['preferences']);
    final security = _asMap(profile['security']);
    final accountSecurity = _asMap(json['account_security']);
    final verification = _asMap(accountSecurity['verification']);
    final financial = _asMap(profile['financial']);
    final photo = _asMap(profile['photo']);
    final language = preferences['language_code']?.toString().toLowerCase();
    return _CustomerProfile(
      name: identity['name']?.toString() ?? 'TradeX Customer',
      email: identity['email']?.toString() ?? 'Email unavailable',
      emailVerified: verification['email_verified'] == true,
      accountType: identity['account_type']?.toString() ?? 'MEMBER',
      referralCode: premiumAccess
          ? identity['referral_code']?.toString() ?? ''
          : '',
      premiumAccess: premiumAccess,
      whatsApp: contact['whatsapp_number']?.toString() ?? 'Add WhatsApp number',
      whatsAppVerified: contact['whatsapp_verified'] == true,
      telegramUsername: contact['telegram_username']?.toString() ?? '',
      languageLabel:
          const {
            'en': 'English',
            'ta': 'Tamil',
            'si': 'Sinhala',
            'hi': 'Hindi',
            'ml': 'Malayalam',
            'te': 'Telugu',
            'ur': 'Urdu',
          }[language] ??
          'English',
      totpConfirmed: security['totp_confirmed'] == true,
      financialMethods: [
        _FinancialMethod(
          label: 'PayPal',
          icon: Icons.paypal_rounded,
          detail: _asMap(financial['paypal'])['email_masked']?.toString(),
          configured: _asMap(financial['paypal'])['configured'] == true,
        ),
        _FinancialMethod(
          label: 'Binance',
          icon: Icons.currency_bitcoin_rounded,
          detail: _asMap(financial['binance'])['email_masked']?.toString(),
          configured: _asMap(financial['binance'])['configured'] == true,
        ),
        _FinancialMethod(
          label: 'USDT TRC20',
          icon: Icons.account_balance_wallet_outlined,
          detail: _asMap(financial['usdt_trc20'])['address_masked']?.toString(),
          configured: _asMap(financial['usdt_trc20'])['configured'] == true,
        ),
        _FinancialMethod(
          label: 'Bank account',
          icon: Icons.account_balance_outlined,
          detail: _asMap(financial['bank'])['account_masked']?.toString(),
          configured: _asMap(financial['bank'])['configured'] == true,
        ),
      ],
      photoAvailable: photo['available'] == true,
      photoVersion: photo['version'] is num
          ? (photo['version'] as num).toInt()
          : 0,
      photoEndpoint:
          photo['endpoint']?.toString() ?? '/api/v1/profile/settings/photo',
    );
  }

  final String name;
  final String email;
  final bool emailVerified;
  final String accountType;
  final String referralCode;
  final bool premiumAccess;
  final String whatsApp;
  final bool whatsAppVerified;
  final String telegramUsername;
  final String languageLabel;
  final bool totpConfirmed;
  final List<_FinancialMethod> financialMethods;
  final bool photoAvailable;
  final int photoVersion;
  final String photoEndpoint;
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

class _FinancialMethod {
  const _FinancialMethod({
    required this.label,
    required this.icon,
    required this.detail,
    required this.configured,
  });

  final String label;
  final IconData icon;
  final String? detail;
  final bool configured;
}

class _CustomerProfileHero extends StatelessWidget {
  const _CustomerProfileHero({
    required this.profile,
    required this.photo,
    required this.onPhotoTap,
    required this.photoBusy,
  });

  final _CustomerProfile profile;
  final Uint8List? photo;
  final VoidCallback? onPhotoTap;
  final bool photoBusy;

  @override
  Widget build(BuildContext context) {
    final palette = TradeXPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.goldSoft, palette.surface],
        ),
        border: Border.all(color: palette.gold.withValues(alpha: .55)),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Change profile picture',
            child: InkWell(
              onTap: onPhotoTap,
              customBorder: const CircleBorder(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    key: const ValueKey('profile-photo-avatar'),
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.goldSoft,
                      border: Border.all(
                        color: TradeXColors.goldBright,
                        width: 1.3,
                      ),
                      image: photo == null
                          ? null
                          : DecorationImage(
                              image: MemoryImage(photo!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: photoBusy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TradeXColors.goldBright,
                            ),
                          )
                        : photo == null
                        ? Text(
                            profile.name.isEmpty
                                ? 'T'
                                : profile.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: TradeXColors.goldBright,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TradeXColors.goldBright,
                        border: Border.all(color: palette.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 13,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.secondaryText, fontSize: 11),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  children: [
                    _SmallPill(
                      label: profile.accountType.toUpperCase(),
                      color: TradeXColors.goldBright,
                    ),
                    if (profile.premiumAccess &&
                        profile.referralCode.trim().isNotEmpty &&
                        profile.referralCode != '—')
                      _SmallPill(
                        label: 'REF ${profile.referralCode}',
                        color: TradeXColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusCard extends StatelessWidget {
  const _ProfileStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _panelDecoration(context),
    child: Column(
      children: [
        Icon(icon, size: 38, color: TradeXColors.goldBright),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: TradeXColors.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TradeXColors.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        _GoldButton(label: actionLabel, onTap: onTap),
      ],
    ),
  );
}
