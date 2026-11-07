part of '../secure_workflow_screens.dart';

class _WorkflowScaffold extends StatelessWidget {
  const _WorkflowScaffold({
    required this.title,
    required this.child,
    this.subtitle,
  });
  final String title;
  final Widget child;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _WorkflowIntro extends StatelessWidget {
  const _WorkflowIntro({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: TradeXElevation.surface(
          brightness: Theme.of(context).brightness,
          palette: palette,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.goldText, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: palette.secondaryText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowSectionTitle extends StatelessWidget {
  const _WorkflowSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: context.palette.goldText, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.goldSoft,
        borderRadius: TradeXRadii.control,
        border: Border.all(color: palette.gold.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: palette.goldText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final PickedImage? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: palette.surfaceRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: TradeXRadii.control,
        side: BorderSide(color: palette.border),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: palette.goldSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.image_outlined, color: palette.goldText),
        ),
        title: Text(label),
        subtitle: Text(
          file?.name ?? 'No image selected',
          style: TextStyle(color: palette.secondaryText),
        ),
        trailing: file == null
            ? IconButton(
                onPressed: onPick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              )
            : IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
        onTap: onPick,
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy();
  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

Map<String, dynamic>? _deepMap(Object? value, String requiredKey) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  if (map.containsKey(requiredKey)) return map;
  for (final child in map.values) {
    final found = _deepMap(child, requiredKey);
    if (found != null) return found;
  }
  return null;
}
