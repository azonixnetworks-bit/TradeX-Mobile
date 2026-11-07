part of '../secure_workflow_screens.dart';

class _BrokerConnectionScreenState extends State<BrokerConnectionScreen> {
  final _key = GlobalKey<FormState>();
  final _intent = TextEditingController();
  final _account = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _intent.dispose();
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Connect Broker Account',
    subtitle: 'Secure account linking',
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _WorkflowIntro(
            icon: Icons.link_rounded,
            title: 'Connect Broker',
            message: 'Link your approved trading account to TradeX for activation review.',
          ),
          const SizedBox(height: 18),
          const _WorkflowSectionTitle(
            icon: Icons.manage_accounts_outlined,
            title: 'Account details',
          ),
          const _SecurityNotice(
            'TradeX accepts an onboarding intent and numeric account number. Never enter a broker password here.',
          ),
          const SizedBox(height: 14),
          _input(_intent, 'Onboarding intent UUID'),
          _input(_account, 'Broker account number'),
          FilledButton.icon(
            onPressed: _working ? null : _submit,
            icon: _working ? const _Busy() : const Icon(Icons.link_rounded),
            label: const Text('Submit connection request'),
          ),
        ],
      ),
    ),
  );

  Widget _input(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: label.contains('number')
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );

  Future<void> _submit() async {
    if (_key.currentState?.validate() != true) return;
    setState(() => _working = true);
    try {
      await widget.apiClient.postJson('/api/v1/copy-trade/broker-accounts', {
        'onboarding_intent_uuid': _intent.text.trim(),
        'account_number': _account.text.trim(),
      });
      _message('Broker account submitted for activation review.');
      if (mounted) Navigator.pop(context, true);
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
