import 'package:flutter/material.dart';

import '../../../core/theme/tradex_colors.dart';
import 'widgets/auth_form_components.dart';

class RegistrationLanguageScreen extends StatefulWidget {
  const RegistrationLanguageScreen({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final Future<void> Function(String languageCode) onContinue;

  @override
  State<RegistrationLanguageScreen> createState() =>
      _RegistrationLanguageScreenState();
}

class _RegistrationLanguageScreenState extends State<RegistrationLanguageScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  String _selectedLanguage = 'en';
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TradeXAuthPage(
      title: 'Choose Learning Language',
      subtitle: 'Your learning videos will be available in this language. This choice cannot be changed later.',
      onBack: widget.onBack,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, 4 * _bounceController.value),
              child: child,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.drag_handle_rounded, color: TradeXColors.goldBright),
                SizedBox(width: 6),
                Text(
                  'Drag to explore languages',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final selected = language.code == _selectedLanguage;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () =>
                        setState(() => _selectedLanguage = language.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? TradeXColors.gold.withValues(alpha: 0.14)
                            : const Color(0xFF090D0B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? TradeXColors.goldBright
                              : TradeXColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            color: selected
                                ? TradeXColors.goldBright
                                : TradeXColors.secondaryText,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            language.name,
                            style: TextStyle(
                              color: TradeXColors.primaryText,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: TradeXColors.goldBright,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            TradeXErrorBanner(message: _errorMessage!),
            const SizedBox(height: 12),
          ],
          TradeXGoldButton(
            label: 'Confirm Language & Verify Email',
            icon: Icons.arrow_forward_rounded,
            loading: _submitting,
            onPressed: _continue,
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onContinue(_selectedLanguage);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _LearningLanguage {
  const _LearningLanguage(this.name, this.code);

  final String name;
  final String code;
}

const List<_LearningLanguage> _languages = <_LearningLanguage>[
  _LearningLanguage('English', 'en'),
  _LearningLanguage('Tamil', 'ta'),
  _LearningLanguage('Sinhala', 'si'),
  _LearningLanguage('Hindi', 'hi'),
  _LearningLanguage('Malayalam', 'ml'),
  _LearningLanguage('Telugu', 'te'),
  _LearningLanguage('Urdu', 'ur'),
];
