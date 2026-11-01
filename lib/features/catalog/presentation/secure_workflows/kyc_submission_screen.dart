part of '../secure_workflow_screens.dart';

class KycSubmissionScreen extends StatefulWidget {
  const KycSubmissionScreen({super.key, required this.apiClient});
  final TradeXApiClient apiClient;

  @override
  State<KycSubmissionScreen> createState() => _KycSubmissionScreenState();
}

class _KycSubmissionScreenState extends State<KycSubmissionScreen> {
  final _key = GlobalKey<FormState>();
  final _documentType = TextEditingController();
  final _legalName = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _identityNumber = TextEditingController();
  final _address = TextEditingController();
  final _files = <String, XFile>{};
  bool _working = false;

  @override
  void dispose() {
    for (final controller in [
      _documentType,
      _legalName,
      _dateOfBirth,
      _identityNumber,
      _address,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'KYC Document Submission',
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SecurityNotice(
            'Your country and document requirements are validated by TradeX. Images are uploaded only when you submit.',
          ),
          const SizedBox(height: 14),
          _field(_documentType, 'Document type code'),
          _field(_legalName, 'Legal name'),
          _field(_dateOfBirth, 'Date of birth (YYYY-MM-DD)'),
          _field(_identityNumber, 'Identity number'),
          _field(_address, 'Residential address', lines: 3),
          for (final item in const [
            ('identity_front', 'Identity document front'),
            ('identity_back', 'Identity document back'),
            ('selfie', 'Selfie'),
          ])
            _FileTile(
              label: item.$2,
              file: _files[item.$1],
              onPick: () => _pick(item.$1, item.$1 == 'selfie'),
              onRemove: () => setState(() => _files.remove(item.$1)),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _working ? null : _submit,
            icon: _working
                ? const _Busy()
                : const Icon(Icons.verified_user_rounded),
            label: Text(_working ? 'Uploading…' : 'Submit for verification'),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );

  Future<void> _pick(String key, bool selfie) async {
    final file = await ImagePicker().pickImage(
      source: selfie ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file != null && mounted) setState(() => _files[key] = file);
  }

  Future<void> _submit() async {
    if (_key.currentState?.validate() != true) return;
    if (_files.isEmpty) {
      _message('Select the documents required for your account country.');
      return;
    }
    setState(() => _working = true);
    try {
      await widget.apiClient.postMultipart(
        '/api/v1/kyc/submissions',
        {
          'document_type': _documentType.text.trim(),
          'legal_name': _legalName.text.trim(),
          'date_of_birth': _dateOfBirth.text.trim(),
          'identity_number': _identityNumber.text.trim(),
          'address': _address.text.trim(),
        },
        {for (final entry in _files.entries) entry.key: entry.value.path},
      );
      _message('KYC submission received for review.');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
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
