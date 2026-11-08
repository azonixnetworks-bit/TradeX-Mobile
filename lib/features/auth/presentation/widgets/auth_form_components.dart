import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tradex_colors.dart';
import '../../../../core/theme/tradex_design_system.dart';

class TradeXAuthPage extends StatelessWidget {
  const TradeXAuthPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.footer,
    this.titleIconAsset,
    this.securityDecor = false,
    this.centerContentVertically = false,
    this.keepDecorationFixedOnKeyboard = false,
    this.highContrastText = false,
    this.decorTopAsset,
    this.decorFooterAsset,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final String? titleIconAsset;
  final bool securityDecor;
  // Registration-only UI options. Existing auth screens keep their defaults.
  final bool centerContentVertically;
  final bool keepDecorationFixedOnKeyboard;
  final bool highContrastText;
  final String? decorTopAsset;
  final String? decorFooterAsset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      // Keep the background's bottom wave pinned to the device viewport;
      // the keyboard covers it instead of pushing it upward.
      resizeToAvoidBottomInset: !keepDecorationFixedOnKeyboard,
      backgroundColor: palette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AuthBackground(
            securityDecor: securityDecor,
            decorTopAsset: decorTopAsset,
            decorFooterAsset: decorFooterAsset,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Gently center the registration content on tall displays.
                // Do not offset the form while a keyboard is visible.
                final extraTopInset =
                    centerContentVertically &&
                        MediaQuery.viewInsetsOf(context).bottom == 0
                    ? ((constraints.maxHeight - 600.0) * 0.45)
                        .clamp(0.0, 96.0)
                        .toDouble()
                    : 0.0;
                final keyboardInset = keepDecorationFixedOnKeyboard
                    ? MediaQuery.viewInsetsOf(context).bottom
                    : 0.0;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20, 10 + extraTopInset, 20, 26 + keyboardInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 36 - extraTopInset)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (onBack != null)
                              IconButton(
                                onPressed: onBack,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: palette.primaryText,
                                ),
                              )
                            else
                              const SizedBox(width: 48),
                            const Spacer(),
                            SizedBox(
                              width: 76,
                              height: 76,
                              child: Image.asset(
                                'assets/branding/trade_x_final_logo.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: highContrastText
                                      ? const Color(0xFF111827)
                                      : null,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.4,
                                ),
                              ),
                            ),
                            if (titleIconAsset != null) ...[
                              const SizedBox(width: 8),
                              Image.asset(
                                titleIconAsset!,
                                width: 27,
                                height: 27,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: highContrastText
                                ? const Color(0xFF344054)
                                : palette.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TradeXAuthCard(child: child),
                        if (footer != null) ...[
                          const SizedBox(height: 22),
                          footer!,
                        ],
                        const SizedBox(height: 28),
                        Text(
                          'DISCIPLINE CREATES FREEDOM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: highContrastText
                                ? const Color(0xFF344054)
                                : palette.goldText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TradeXAuthCard extends StatelessWidget {
  const TradeXAuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: palette.surface,
        gradient: context.isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.surfaceRaised, palette.surface],
              )
            : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isDarkMode ? palette.borderStrong : palette.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? .2 : .07,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TradeXAuthField extends StatelessWidget {
  const TradeXAuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.suffixIcon,
    this.prefixText,
    this.onFieldSubmitted,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.highContrastText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Widget? suffixIcon;
  final String? prefixText;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool highContrastText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      onTap: onTap,
      textCapitalization: textCapitalization,
      cursorColor: palette.goldText,
      style: TextStyle(
        color: highContrastText ? const Color(0xFF182230) : palette.primaryText,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        labelStyle: TextStyle(
          color: highContrastText
              ? const Color(0xFF344054)
              : palette.secondaryText,
          fontWeight: highContrastText ? FontWeight.w600 : null,
        ),
        floatingLabelStyle: highContrastText
            ? const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              )
            : null,
        prefixIcon: Icon(icon, color: palette.goldText, size: 21),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: TradeXColors.goldBright,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: palette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: palette.goldText, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: TradeXColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: TradeXColors.error, width: 1.3),
        ),
        errorStyle: const TextStyle(color: TradeXColors.error, fontSize: 11),
      ),
    );
  }
}

class TradeXGoldButton extends StatelessWidget {
  const TradeXGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD760),
              TradeXColors.goldBright,
              Color(0xFFF0A500),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: TradeXColors.goldBright.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Icon(icon, color: Colors.black, size: 21),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class TradeXErrorBanner extends StatelessWidget {
  const TradeXErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TradeXColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TradeXColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: TradeXColors.error,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: TradeXColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class TradeXInfoBanner extends StatelessWidget {
  const TradeXInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TradeXColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TradeXColors.gold.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TradeXColors.goldBright, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: TradeXColors.secondaryText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({
    this.securityDecor = false,
    this.decorTopAsset,
    this.decorFooterAsset,
  });

  final bool securityDecor;
  final String? decorTopAsset;
  final String? decorFooterAsset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.background,
                palette.surfaceMuted.withValues(alpha: .55),
                palette.background,
              ],
            ),
          ),
        ),
        Positioned(
          top: -150,
          right: -140,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.gold.withValues(
                    alpha: context.isDarkMode ? .12 : .07,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -180,
          left: -140,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  palette.gold.withValues(
                    alpha: context.isDarkMode ? .1 : .045,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (securityDecor ||
            decorTopAsset != null ||
            decorFooterAsset != null) ...[
          if (securityDecor || decorTopAsset != null)
            Positioned(
              top: 8,
              right: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: context.isDarkMode ? .16 : .48,
                  child: Image.asset(
                    decorTopAsset ??
                        'assets/security_ui/subtle_gray_candlestick_trend.png',
                    width: 190,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          if (securityDecor || decorFooterAsset != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: -18,
              child: IgnorePointer(
                child: Opacity(
                  opacity: context.isDarkMode ? .09 : .72,
                  child: Image.asset(
                    decorFooterAsset ??
                        'assets/security_ui/layered_cream_wave_footer.png',
                    height: 150,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
