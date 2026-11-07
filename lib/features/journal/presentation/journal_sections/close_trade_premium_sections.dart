part of '../trade_journal_close_sections.dart';

class PremiumCloseTradeSection extends StatelessWidget {
  const PremiumCloseTradeSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.subtitle,
    this.prominentBorder = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;
  final bool prominentBorder;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: _premiumDecoration(
      context,
      accent: accent,
      radius: 20,
      prominent: prominentBorder,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.help_outline_rounded,
              color: closeTradeBlue.withValues(alpha: .9),
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class PremiumCloseTradePicker extends StatelessWidget {
  const PremiumCloseTradePicker({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: label,
    icon: icon,
    accent: accent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: _inputBoxDecoration(context),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(icon, color: context.palette.secondaryText, size: 18),
          ],
        ),
      ),
    ),
  );
}

class PremiumCloseTradeNumberField extends StatelessWidget {
  const PremiumCloseTradeNumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accent,
    this.signed = false,
    this.validator,
    this.onChanged,
    this.helperText,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accent;
  final bool signed;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: label,
    icon: icon,
    accent: accent,
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      inputFormatters: [_DecimalTextInputFormatter(signed: signed)],
      style: TextStyle(color: context.palette.primaryText, fontSize: 15),
      decoration: _inputDecoration(
        context,
        hint,
      ).copyWith(helperText: helperText, suffixIcon: suffix),
      validator: validator,
      onChanged: onChanged,
    ),
  );
}

String formatCloseTradePrice(double value) {
  final decimals = value >= 1000
      ? 2
      : value >= 1
      ? 4
      : 8;
  return value.toStringAsFixed(decimals);
}

class PremiumCloseTradeTextField extends StatelessWidget {
  const PremiumCloseTradeTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accent,
    this.maxLength,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accent;
  final int? maxLength;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => _PremiumFieldShell(
    label: label,
    icon: icon,
    accent: accent,
    child: TextFormField(
      controller: controller,
      maxLength: maxLength,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      style: TextStyle(color: context.palette.primaryText),
      decoration: _inputDecoration(context, hint),
      validator: validator,
    ),
  );
}

class PremiumCloseTradeDropdown extends StatelessWidget {
  const PremiumCloseTradeDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final selected = items.contains(value) ? value : null;
    return _PremiumFieldShell(
      label: label,
      icon: icon,
      accent: accent,
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        dropdownColor: context.palette.surfaceRaised,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: TextStyle(color: context.palette.primaryText, fontSize: 14),
        decoration: _inputDecoration(context, ''),
        hint: hint == null
            ? null
            : Text(
                hint!,
                style: TextStyle(color: context.palette.secondaryText),
              ),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(titleCase(item))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _PremiumFieldShell extends StatelessWidget {
  const _PremiumFieldShell({
    required this.label,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF09213E), Color(0xFF151D27)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: closeTradeBorder.withValues(alpha: .75)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: closeTradeText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(
              Icons.help_outline_rounded,
              color: closeTradeBlue,
              size: 17,
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.first,
    required this.second,
    this.breakpoint = 315,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < breakpoint) {
        return Column(children: [first, const SizedBox(height: 10), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );
}

class _ResultSegment extends StatelessWidget {
  const _ResultSegment({
    super.key,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 43,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(colors: [accent, accent.withValues(alpha: .72)])
            : null,
        color: selected ? null : const Color(0xFF111923),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: selected ? accent : closeTradeMuted),
        boxShadow: selected
            ? [BoxShadow(color: accent.withValues(alpha: .30), blurRadius: 10)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? (accent == closeTradeGold
                          ? const Color(0xFF111923)
                          : closeTradeText)
                    : closeTradeText,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DecimalTextInputFormatter extends TextInputFormatter {
  const _DecimalTextInputFormatter({required this.signed});

  final bool signed;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final expression = signed
        ? RegExp(r'^-?\d*\.?\d*$')
        : RegExp(r'^\d*\.?\d*$');
    return expression.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

BoxDecoration _premiumDecoration(
  BuildContext context, {
  required Color accent,
  required double radius,
  bool prominent = false,
}) => BoxDecoration(
  color: context.palette.surface,
  gradient: context.isDarkMode
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.palette.surfaceRaised,
            context.palette.surface,
            context.palette.background,
          ],
        )
      : null,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(
    color: accent.withValues(alpha: prominent ? .9 : .42),
    width: prominent ? 1.2 : 1,
  ),
  boxShadow: TradeXElevation.surface(
    brightness: Theme.of(context).brightness,
    palette: context.palette,
  ),
);

BoxDecoration _inputBoxDecoration(BuildContext context) => BoxDecoration(
  color: context.palette.surfaceMuted,
  borderRadius: BorderRadius.circular(11),
  border: Border.all(color: context.palette.border),
);

InputDecoration _inputDecoration(BuildContext context, String hint) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6F84A3)),
      filled: true,
      fillColor: context.palette.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: context.palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: context.palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: closeTradeBlue, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: closeTradeRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: closeTradeRed, width: 1.3),
      ),
      errorStyle: const TextStyle(color: closeTradeRed, fontSize: 10),
    );

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'open' => closeTradeGreen,
  'closed' => closeTradeBlue,
  'cancelled' => closeTradeRed,
  _ => closeTradeGold,
};

String closeTradeSymbolInitials(String symbol) {
  final normalized = symbol.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (normalized.isEmpty) return '—';
  const quotes = [
    'USDT',
    'USDC',
    'BUSD',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'BTC',
    'ETH',
  ];
  var base = normalized;
  for (final quote in quotes) {
    if (base.length > quote.length && base.endsWith(quote)) {
      base = base.substring(0, base.length - quote.length);
      break;
    }
  }
  final source = base.isEmpty ? normalized : base;
  return source.substring(0, source.length.clamp(0, 3));
}
