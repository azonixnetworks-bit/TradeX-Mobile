import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/profile/pending_financial_form_store.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/sri_lanka_bank_directory.dart';

enum WithdrawalMethod { paypal, binance, usdtTrc20, localBank }

const _withdrawalDialogTransitionDuration = Duration(milliseconds: 240);

class WithdrawalMethodScreen extends StatefulWidget {
  const WithdrawalMethodScreen({
    super.key,
    required this.apiClient,
    required this.method,
  });

  final TradeXApiClient apiClient;
  final WithdrawalMethod method;

  @override
  State<WithdrawalMethodScreen> createState() => _WithdrawalMethodScreenState();
}

class _WithdrawalMethodScreenState extends State<WithdrawalMethodScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _primary = TextEditingController();
  final _confirmation = TextEditingController();
  final _bankName = TextEditingController();
  final _bankBranch = TextEditingController();
  final _holder = TextEditingController();
  final _bankNameFocus = FocusNode();
  final _bankBranchFocus = FocusNode();
  final _draftStore = PendingFinancialFormStore();
  Timer? _draftDebounce;
  bool _restoringDraft = true;
  bool _awaitingTotp = false;
  bool _editing = false;
  bool _submitting = false;
  late Future<_WithdrawalState> _state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final controller in _draftControllers) {
      controller.addListener(_scheduleDraftSave);
    }
    _state = _load();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeWithdrawalPage(),
    );
  }

  List<TextEditingController> get _draftControllers => <TextEditingController>[
    _primary,
    _confirmation,
    _bankName,
    _bankBranch,
    _holder,
  ];

  Future<void> _initializeWithdrawalPage() async {
    PendingFinancialFormDraft? draft;
    try {
      draft = await _draftStore.readWithdrawal();
      if (draft?.method != widget.method.name) draft = null;
      if (!mounted) return;
      if (draft != null) {
        _holder.text = draft.accountHolder;
        _bankName.text = draft.bankName;
        _bankBranch.text = draft.bankBranch;
        _primary.text = draft.accountNumber;
        _confirmation.text = draft.accountNumberConfirmation;
        _awaitingTotp = draft.awaitingTotp;
        setState(() => _editing = true);
      }
      _restoringDraft = false;
      final state = await _state;
      if (!mounted) return;
      if (draft == null && widget.method == WithdrawalMethod.localBank) {
        await _showBankNotice(state);
      } else if (draft?.awaitingTotp == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_save());
        });
      }
    } catch (_) {
      _restoringDraft = false;
      // The page-level load error provides the retry action.
    }
  }

  void _scheduleDraftSave() {
    if (_restoringDraft) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_persistDraft()),
    );
  }

  PendingFinancialFormDraft get _currentDraft => PendingFinancialFormDraft(
    method: widget.method.name,
    accountHolder: _holder.text,
    bankName: _bankName.text,
    bankBranch: _bankBranch.text,
    accountNumber: _primary.text,
    accountNumberConfirmation: _confirmation.text,
    awaitingTotp: _awaitingTotp,
    updatedAt: DateTime.now(),
  );

  bool get _hasDraftValues =>
      _draftControllers.any((controller) => controller.text.trim().isNotEmpty);

  Future<void> _persistDraft({bool? awaitingTotp}) async {
    if (_restoringDraft) return;
    _draftDebounce?.cancel();
    if (awaitingTotp != null) _awaitingTotp = awaitingTotp;
    try {
      if (!_hasDraftValues && !_awaitingTotp) {
        await _draftStore.clearWithdrawal();
      } else {
        await _draftStore.writeWithdrawal(_currentDraft);
      }
    } catch (_) {
      // Draft restoration is best-effort and never blocks the financial flow.
    }
  }

  Future<void> _clearDraft() async {
    _draftDebounce?.cancel();
    _awaitingTotp = false;
    try {
      await _draftStore.clearWithdrawal();
    } catch (_) {
      // The server-backed financial flow remains usable without restoration.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_persistDraft());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftDebounce?.cancel();
    for (final controller in _draftControllers) {
      controller.removeListener(_scheduleDraftSave);
    }
    _primary.dispose();
    _confirmation.dispose();
    _bankName.dispose();
    _bankBranch.dispose();
    _holder.dispose();
    _bankNameFocus.dispose();
    _bankBranchFocus.dispose();
    super.dispose();
  }

  Future<_WithdrawalState> _load() async {
    final settings = await widget.apiClient.getJson('/api/v1/profile/settings');
    final root = _map(settings['data']);
    final profile = _map(root['profile']);
    final identity = _map(profile['identity']);
    final financial = _map(profile['financial']);
    final methodData = _map(financial[_profileKey]);
    var payoutAllowed = false;
    String? payoutMessage;
    try {
      final response = await widget.apiClient.getJson(
        '/api/v1/payouts/methods',
      );
      final data = _map(response['data']);
      final items = data['items'];
      payoutAllowed =
          items is List &&
          items.whereType<Map>().any(
            (item) => item['code']?.toString().toUpperCase() == _payoutCode,
          );
    } on ApiException catch (error) {
      payoutMessage = error.message;
    }
    return _WithdrawalState(
      countryCode: identity['country_code']?.toString().toUpperCase() ?? '',
      configured: methodData['configured'] == true,
      masked: _maskedValue(methodData),
      payoutAllowed: payoutAllowed,
      payoutMessage: payoutMessage,
    );
  }

  String get _title => switch (widget.method) {
    WithdrawalMethod.paypal => 'PayPal',
    WithdrawalMethod.binance => 'Binance',
    WithdrawalMethod.usdtTrc20 => 'USDT TRC20',
    WithdrawalMethod.localBank => 'Local Bank Account',
  };

  String get _profileKey => switch (widget.method) {
    WithdrawalMethod.paypal => 'paypal',
    WithdrawalMethod.binance => 'binance',
    WithdrawalMethod.usdtTrc20 => 'usdt_trc20',
    WithdrawalMethod.localBank => 'bank',
  };

  String get _payoutCode => switch (widget.method) {
    WithdrawalMethod.paypal => 'PAYPAL',
    WithdrawalMethod.binance => 'BINANCE',
    WithdrawalMethod.usdtTrc20 => 'USDT_TRC20',
    WithdrawalMethod.localBank => 'LOCAL_BANK',
  };

  String? _maskedValue(Map<String, dynamic> data) => switch (widget.method) {
    WithdrawalMethod.paypal ||
    WithdrawalMethod.binance => data['email_masked']?.toString(),
    WithdrawalMethod.usdtTrc20 => data['address_masked']?.toString(),
    WithdrawalMethod.localBank => data['account_masked']?.toString(),
  };

  Future<void> _showBankNotice(_WithdrawalState state) async {
    final continueFlow = await _showAnimatedDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Local Bank Account — Sri Lanka Only'),
        content: const Text(
          'Local bank withdrawal details are available for eligible customers registered in Sri Lanka.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: state.countryCode == 'LK' && state.payoutAllowed
                ? () => Navigator.of(dialogContext).pop(true)
                : null,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (continueFlow != true) {
      await Future<void>.delayed(_withdrawalDialogTransitionDuration);
      if (mounted) Navigator.maybePop(context);
    }
  }

  Future<String?> _requestTotp() async {
    await _persistDraft(awaitingTotp: true);
    if (!mounted) return null;
    final value = await _showAnimatedDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TotpConfirmationDialog(),
    );
    await _persistDraft(awaitingTotp: false);
    return value;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true || _submitting) return;
    final totp = await _requestTotp();
    if (totp == null || !mounted) return;
    setState(() => _submitting = true);
    var leftScreen = false;
    try {
      await widget.apiClient.patchJson('/api/v1/profile/financial', {
        'totp_code': totp,
        ...switch (widget.method) {
          WithdrawalMethod.paypal => {'paypal_email': _primary.text.trim()},
          WithdrawalMethod.binance => {'binance_email': _primary.text.trim()},
          WithdrawalMethod.usdtTrc20 => {
            'usdt_trc20_address': _primary.text.trim(),
          },
          WithdrawalMethod.localBank => {
            'bank_account_holder': _holder.text.trim(),
            'bank_name': _bankName.text.trim(),
            'bank_branch': _bankBranch.text.trim(),
            'bank_account_number': _primary.text.trim(),
          },
        },
      });
      if (!mounted) return;
      await _clearDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_title details saved securely.')),
      );
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        leftScreen = true;
        navigator.pop(true);
        return;
      }
      _clearSensitiveInputs();
      setState(() {
        _editing = false;
        _state = _load();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: TradeXColors.error,
        ),
      );
    } finally {
      if (mounted && !leftScreen) setState(() => _submitting = false);
    }
  }

  void _clearSensitiveInputs() {
    _primary.clear();
    _confirmation.clear();
    _bankName.clear();
    _bankBranch.clear();
    _holder.clear();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  String? _validatePrimary(String? value) {
    final required = _required(value, _baseFieldLabel);
    if (required != null) return required;
    final input = value!.trim();
    if (widget.method == WithdrawalMethod.paypal ||
        widget.method == WithdrawalMethod.binance) {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input)) {
        return 'Enter a valid email address.';
      }
    } else if (widget.method == WithdrawalMethod.usdtTrc20 &&
        !RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$').hasMatch(input)) {
      return 'Enter a valid TRON address beginning with T.';
    } else if (widget.method == WithdrawalMethod.localBank &&
        !RegExp(r'^[A-Za-z0-9\-\/ ]+$').hasMatch(input)) {
      return 'Use only letters, numbers, spaces, - or /.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value?.trim() != _primary.text.trim()) {
      return widget.method == WithdrawalMethod.usdtTrc20
          ? 'Wallet addresses do not match.'
          : widget.method == WithdrawalMethod.localBank
          ? 'Bank account numbers do not match.'
          : 'Email addresses do not match.';
    }
    return null;
  }

  String get _baseFieldLabel => switch (widget.method) {
    WithdrawalMethod.paypal => 'PayPal Email Address',
    WithdrawalMethod.binance => 'Binance Email Address',
    WithdrawalMethod.usdtTrc20 => 'USDT TRC20 Wallet Address',
    WithdrawalMethod.localBank => 'Bank Account Number',
  };

  String _fieldLabel(bool configured) => switch (widget.method) {
    WithdrawalMethod.paypal =>
      configured ? 'New PayPal Email' : 'PayPal Email Address',
    WithdrawalMethod.binance =>
      configured ? 'New Binance Email' : 'Binance Email Address',
    WithdrawalMethod.usdtTrc20 =>
      configured
          ? 'New USDT TRC20 Address'
          : 'Add New USDT TRC20 Wallet Address',
    WithdrawalMethod.localBank =>
      configured ? 'New Bank Account Number' : 'Bank Account Number',
  };

  String _confirmLabel(bool configured) => switch (widget.method) {
    WithdrawalMethod.paypal =>
      configured ? 'Confirm New PayPal Email' : 'Confirm PayPal Email',
    WithdrawalMethod.binance =>
      configured ? 'Confirm New Binance Email' : 'Confirm Binance Email',
    WithdrawalMethod.usdtTrc20 =>
      configured
          ? 'Confirm New USDT TRC20 Address'
          : 'Confirm USDT TRC20 Address',
    WithdrawalMethod.localBank =>
      configured
          ? 'Confirm New Bank Account Number'
          : 'Confirm Bank Account Number',
  };

  String get _currentValueLabel => switch (widget.method) {
    WithdrawalMethod.paypal => 'Current PayPal Email',
    WithdrawalMethod.binance => 'Current Binance Email',
    WithdrawalMethod.usdtTrc20 => 'Current USDT TRC20 Address',
    WithdrawalMethod.localBank => 'Current Bank Account Number',
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) unawaited(_clearDraft());
    },
    child: Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: FutureBuilder<_WithdrawalState>(
        future: _state,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () {
                setState(() {
                  _state = _load();
                });
              },
            );
          }
          final state = snapshot.requireData;
          final bankEligible =
              widget.method != WithdrawalMethod.localBank ||
              state.countryCode == 'LK';
          final allowed = state.payoutAllowed && bankEligible;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              _MethodHeader(method: widget.method),
              const SizedBox(height: 14),
              if (!allowed)
                _EligibilityNotice(
                  message: !bankEligible
                      ? 'Local bank details are available only to accounts registered in Sri Lanka.'
                      : state.payoutMessage ?? 'This withdrawal method is not enabled for your account by the payout service.',
                ),
              if (state.configured && !_editing) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.verified_user_rounded,
                      color: TradeXColors.success,
                    ),
                    title: const Text('Configured destination'),
                    subtitle: Text(state.masked ?? 'Saved securely'),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: allowed
                      ? () => setState(() => _editing = true)
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(_updateLabel),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The backend does not support verifying the previous value. Your current destination remains masked, and the update is authorized with server-verified TOTP.',
                  style: TextStyle(fontSize: 12),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (state.configured)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            initialValue: state.masked ?? 'Configured securely',
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: _currentValueLabel,
                            ),
                          ),
                        ),
                      if (widget.method == WithdrawalMethod.localBank) ...[
                        _field(_holder, 'Customer / Account Holder Name'),
                        _autocompleteField(
                          controller: _bankName,
                          focusNode: _bankNameFocus,
                          label: 'Bank Name',
                          optionsBuilder: (value) =>
                              SriLankaBankDirectory.bankSuggestions(value.text),
                        ),
                        _autocompleteField(
                          controller: _bankBranch,
                          focusNode: _bankBranchFocus,
                          label: 'Bank Branch',
                          optionsBuilder: (value) =>
                              SriLankaBankDirectory.branchSuggestions(
                                bankName: _bankName.text,
                                query: value.text,
                              ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Suggestions are a non-exhaustive offline reference. You can enter any valid Sri Lankan bank and branch manually.',
                            style: TextStyle(fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                      _field(
                        _primary,
                        _fieldLabel(state.configured),
                        validator: _validatePrimary,
                        keyboardType:
                            widget.method == WithdrawalMethod.paypal ||
                                widget.method == WithdrawalMethod.binance
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                      ),
                      _field(
                        _confirmation,
                        _confirmLabel(state.configured),
                        validator: _validateConfirmation,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: allowed && !_submitting ? _save : null,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_outline_rounded),
                          label: Text(
                            _submitting
                                ? 'Saving…'
                                : state.configured
                                ? 'Update'
                                : 'Confirm',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: keyboardType == TextInputType.emailAddress
          ? const [AutofillHints.email]
          : null,
      decoration: InputDecoration(labelText: label),
      validator: validator ?? (value) => _required(value, label),
    ),
  );

  Widget _autocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required AutocompleteOptionsBuilder<String> optionsBuilder,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: optionsBuilder,
      displayStringForOption: (option) => option,
      onSelected: (option) {
        controller
          ..text = option
          ..selection = TextSelection.collapsed(offset: option.length);
      },
      fieldViewBuilder:
          (context, fieldController, fieldFocus, onFieldSubmitted) =>
              TextFormField(
                controller: fieldController,
                focusNode: fieldFocus,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: label,
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                validator: (value) => _required(value, label),
                onFieldSubmitted: (_) => onFieldSubmitted(),
              ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 220,
              maxWidth: MediaQuery.sizeOf(context).width - 32,
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.account_balance_outlined, size: 19),
                  title: Text(option),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  String get _updateLabel => switch (widget.method) {
    WithdrawalMethod.paypal => 'Update PayPal Email',
    WithdrawalMethod.binance => 'Update Binance Email',
    WithdrawalMethod.usdtTrc20 => 'Update Wallet Address',
    WithdrawalMethod.localBank => 'Update Bank Details',
  };
}

class _TotpConfirmationDialog extends StatefulWidget {
  const _TotpConfirmationDialog();

  @override
  State<_TotpConfirmationDialog> createState() =>
      _TotpConfirmationDialogState();
}

class _TotpConfirmationDialogState extends State<_TotpConfirmationDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final code = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter all 6 digits.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Security confirmation'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your current authenticator code. Fingerprint or app passcode cannot replace the server-required TOTP for financial changes.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '6-digit authenticator code',
            counterText: '',
            errorText: _error,
          ),
          onSubmitted: (_) => _confirm(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _confirm, child: const Text('Confirm')),
    ],
  );
}

class _MethodHeader extends StatelessWidget {
  const _MethodHeader({required this.method});
  final WithdrawalMethod method;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: TradeXColors.gold.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TradeXColors.goldDeep),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          method == WithdrawalMethod.localBank
              ? Icons.account_balance_rounded
              : method == WithdrawalMethod.usdtTrc20
              ? Icons.account_balance_wallet_rounded
              : Icons.payments_outlined,
          color: TradeXColors.goldBright,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            method == WithdrawalMethod.usdtTrc20
                ? 'Network: TRON (TRC20)\nSend only a TRON address. Format validation does not prove wallet ownership.'
                : 'Financial destination changes require an online connection and a fresh authenticator code.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _EligibilityNotice extends StatelessWidget {
  const _EligibilityNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline_rounded),
        title: const Text('Not currently eligible'),
        subtitle: Text(message),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Unable to load this withdrawal method.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class _WithdrawalState {
  const _WithdrawalState({
    required this.countryCode,
    required this.configured,
    required this.masked,
    required this.payoutAllowed,
    required this.payoutMessage,
  });

  final String countryCode;
  final bool configured;
  final String? masked;
  final bool payoutAllowed;
  final String? payoutMessage;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Future<T?> _showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: .62),
    transitionDuration: _withdrawalDialogTransitionDuration,
    pageBuilder: (context, _, _) => SafeArea(child: builder(context)),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
