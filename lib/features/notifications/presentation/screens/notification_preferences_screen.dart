part of '../notification_module.dart';

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
