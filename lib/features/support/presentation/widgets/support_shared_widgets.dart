part of '../support_module.dart';

class _SupportScaffold extends StatelessWidget {
  const _SupportScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.eyebrow,
    this.showBack = true,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Positioned(
            top: -35,
            right: -100,
            child: IgnorePointer(
              child: Opacity(
                opacity: context.isDarkMode ? .18 : .055,
                child: Image.asset(
                  _globeAsset,
                  width: 360,
                  height: 290,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: -60,
            child: IgnorePointer(
              child: Opacity(
                opacity: context.isDarkMode ? .18 : .045,
                child: Image.asset(
                  '$_imageRoot/gold_orbit_lines.png',
                  width: 330,
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                  sliver: SliverList.list(
                    children: [
                      if (showBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BackButton(
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      if (showBack) const SizedBox(height: 16),
                      if (eyebrow != null) ...[
                        Text(
                          eyebrow!,
                          style: TextStyle(
                            color: palette.goldText,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        title,
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: textTheme.bodyLarge?.copyWith(
                          color: palette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 22),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _SupportPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: palette.secondaryText,
              height: 1.35,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          _GoldButton(label: action, onPressed: onTap, compact: true),
        ],
      ),
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        gradient: context.isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.surfaceRaised, palette.surface],
              )
            : null,
        borderRadius: TradeXRadii.card,
        border: Border.all(color: palette.border),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
      ),
      child: child,
    );
  }
}

class _SupportUnavailableBanner extends StatelessWidget {
  const _SupportUnavailableBanner({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 12 : 14),
    decoration: BoxDecoration(
      color: TradeXColors.warning.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: TradeXColors.warning.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: TradeXColors.goldBright,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            SupportPolicy.unavailableMessage,
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: compact ? 11 : 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SupportUnavailableField extends StatelessWidget {
  const _SupportUnavailableField({
    required this.icon,
    required this.label,
    required this.helper,
  });

  final String icon;
  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) => _SupportPanel(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        _IconTile(icon, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.palette.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                helper,
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onTap,
  });

  final String icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _SupportPanel(
    child: Column(
      children: [
        _IconTile(icon, size: 60),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.palette.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.secondaryText, height: 1.4),
        ),
        if (action != null && onTap != null) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(action!),
          ),
        ],
      ],
    ),
  );
}

class _SupportListTile extends StatelessWidget {
  const _SupportListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _SupportPanel(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            _IconTile(icon, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _SupportMetric extends StatelessWidget {
  const _SupportMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SupportSvgIcon(icon, size: 22),
      const SizedBox(height: 7),
      Text(
        value,
        style: TextStyle(
          color: context.palette.primaryText,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.palette.secondaryText, fontSize: 10),
      ),
    ],
  );
}

class _QueueMetric extends StatelessWidget {
  const _QueueMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: context.palette.primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.palette.secondaryText, fontSize: 10),
      ),
    ],
  );
}

class _SupportSearchField extends StatelessWidget {
  const _SupportSearchField({
    required this.hint,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final TextEditingController? controller;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: palette.primaryText),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(14),
          child: SupportSvgIcon('search.svg', size: 22),
        ),
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}

class _SupportTextField extends StatelessWidget {
  const _SupportTextField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(color: palette.primaryText),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: palette.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}

class _SelectedAttachment extends StatelessWidget {
  const _SelectedAttachment({
    required this.bytes,
    required this.name,
    required this.onRemove,
  });
  final Uint8List bytes;
  final String name;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => _SupportPanel(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, width: 62, height: 62, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.palette.primaryText),
          ),
        ),
        IconButton(
          tooltip: 'Remove attachment',
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, color: TradeXColors.error),
        ),
      ],
    ),
  );
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool compact;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: TradeXGradients.primaryGold,
      borderRadius: TradeXRadii.control,
      boxShadow: [
        BoxShadow(
          color: TradeXColors.goldBright.withValues(alpha: .18),
          blurRadius: 16,
        ),
      ],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.black,
        minimumSize: Size.fromHeight(compact ? 44 : 54),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            SupportSvgIcon(icon!, size: 20, color: Colors.black),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 7),
          const Icon(Icons.arrow_forward_rounded, size: 19),
        ],
      ),
    ),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon, {this.size = 54});
  final String icon;
  final double size;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.goldSoft,
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(color: palette.gold.withValues(alpha: .28)),
      ),
      child: SupportSvgIcon(icon, size: size * .46),
    );
  }
}

class SupportSvgIcon extends StatelessWidget {
  const SupportSvgIcon(this.name, {super.key, this.size = 24, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    '$_iconRoot/$name',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back',
    child: IconButton.outlined(
      tooltip: 'Back',
      onPressed: onTap,
      icon: const SupportSvgIcon('arrow_left.svg'),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: BorderSide(color: TradeXColors.gold.withValues(alpha: .4)),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            color: context.palette.primaryText,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      label: Text(label),
      selectedColor: palette.gold,
      backgroundColor: palette.surfaceRaised,
      side: BorderSide(color: selected ? palette.gold : palette.borderStrong),
      labelStyle: TextStyle(
        color: selected ? palette.primaryButtonText : palette.primaryText,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? palette.goldSoft : palette.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? palette.gold : palette.borderStrong,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? palette.goldText : palette.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DisabledComposer extends StatelessWidget {
  const _DisabledComposer();
  @override
  Widget build(BuildContext context) => TextField(
    enabled: false,
    decoration: InputDecoration(
      hintText: 'Messaging unavailable',
      prefixIcon: const Padding(
        padding: EdgeInsets.all(14),
        child: SupportSvgIcon('paperclip.svg', size: 20),
      ),
      suffixIcon: const Padding(
        padding: EdgeInsets.all(14),
        child: SupportSvgIcon('send.svg', size: 20),
      ),
      filled: true,
      fillColor: context.palette.surfaceRaised,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}

Widget _divider(BuildContext context) => Container(
  width: 1,
  height: 62,
  margin: const EdgeInsets.symmetric(horizontal: 8),
  color: context.palette.borderStrong,
);

Future<void> _push(BuildContext context, Widget screen) =>
    Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => screen));

void _showUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(SupportPolicy.unavailableMessage)),
  );
}
