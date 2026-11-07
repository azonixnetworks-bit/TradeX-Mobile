part of '../secure_workflow_screens.dart';

class ContactChangeScreen extends StatefulWidget {
  const ContactChangeScreen({
    super.key,
    required this.apiClient,
    this.initialChannel = 'whatsapp',
  });
  final ApiGateway apiClient;
  final String initialChannel;

  @override
  State<ContactChangeScreen> createState() => _ContactChangeScreenState();
}

class _ContactChangeScreenState extends State<ContactChangeScreen> {
  final _key = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _totp = TextEditingController();
  final _otp = TextEditingController();
  late String _channel;
  String? _challengeId;
  String? _challengeToken;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _channel = widget.initialChannel == 'telegram' ? 'telegram' : 'whatsapp';
  }

  @override
  void dispose() {
    _value.dispose();
    _totp.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Change Contact',
    subtitle: 'Verified profile update',
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _WorkflowIntro(
            icon: Icons.contact_phone_outlined,
            title: 'Update Contact Number',
            message: 'Change your WhatsApp number or Telegram username with protected verification.',
          ),
          const SizedBox(height: 18),
          const _SecurityNotice(
            'Authenticator verification is required before TradeX sends a confirmation code.',
          ),
          const SizedBox(height: 14),
          const _WorkflowSectionTitle(
            icon: Icons.forum_outlined,
            title: 'Select contact platform',
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'whatsapp', label: Text('WhatsApp')),
              ButtonSegment(value: 'telegram', label: Text('Telegram')),
            ],
            selected: {_channel},
            onSelectionChanged: _challengeId == null
                ? (value) => setState(() => _channel = value.first)
                : null,
          ),
          const SizedBox(height: 14),
          _ContactProgress(challengeCreated: _challengeId != null),
          const SizedBox(height: 14),
          if (_challengeId == null) ...[
            _input(
              _value,
              _channel == 'whatsapp'
                  ? 'New number (+country code)'
                  : 'New Telegram username',
            ),
            _input(_totp, '6-digit authenticator code', secret: true),
            FilledButton(
              onPressed: _working ? null : _request,
              child: const Text('Send confirmation code'),
            ),
          ] else ...[
            _input(_otp, 'Email confirmation code', secret: true),
            FilledButton(
              onPressed: _working ? null : _confirm,
              child: const Text('Confirm change'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _input(
    TextEditingController controller,
    String label, {
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: secret,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );

  Future<void> _request() async {
    if (_key.currentState?.validate() != true) return;
    setState(() => _working = true);
    try {
      final response = await widget.apiClient.postJson(
        '/api/v1/profile/$_channel/change/request',
        {
          _channel == 'whatsapp'
              ? 'new_whatsapp_number'
              : 'new_telegram_username': _value.text
              .trim(),
          'totp_code': _totp.text.trim(),
        },
      );
      final data = _deepMap(response, 'challenge_id');
      final id = data?['challenge_id']?.toString();
      final token = data?['challenge_token']?.toString();
      if (id == null || token == null) {
        throw const UserFacingFailure(
          message: 'TradeX did not return a valid confirmation challenge.',
        );
      }
      setState(() {
        _challengeId = id;
        _challengeToken = token;
      });
      _message('Confirmation code sent.');
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirm() async {
    if (_key.currentState?.validate() != true) return;
    setState(() => _working = true);
    try {
      await widget.apiClient.postJson(
        '/api/v1/profile/$_channel/change/confirm',
        {
          'challenge_id': _challengeId,
          'challenge_token': _challengeToken,
          'otp_code': _otp.text.trim(),
        },
      );
      _message(
        '${_channel == 'whatsapp' ? 'WhatsApp number' : 'Telegram username'} updated.',
      );
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

class _ContactProgress extends StatelessWidget {
  const _ContactProgress({required this.challengeCreated});

  final bool challengeCreated;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          _ContactStep(
            number: '1',
            label: 'Contact',
            active: !challengeCreated,
            complete: challengeCreated,
          ),
          Expanded(child: Divider(color: palette.border)),
          _ContactStep(
            number: '2',
            label: 'Verify',
            active: challengeCreated,
            complete: false,
          ),
          Expanded(child: Divider(color: palette.border)),
          const _ContactStep(
            number: '3',
            label: 'Updated',
            active: false,
            complete: false,
          ),
        ],
      ),
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.number,
    required this.label,
    required this.active,
    required this.complete,
  });

  final String number;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final highlighted = active || complete;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted ? palette.gold : palette.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(
              color: highlighted ? palette.gold : palette.border,
            ),
          ),
          child: complete
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
              : Text(
                  number,
                  style: TextStyle(
                    color: highlighted ? Colors.white : palette.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: highlighted ? palette.goldText : palette.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
