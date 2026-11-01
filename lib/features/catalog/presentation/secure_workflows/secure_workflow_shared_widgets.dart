part of '../secure_workflow_screens.dart';

class _WorkflowScaffold extends StatelessWidget {
  const _WorkflowScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    ),
    body: SafeArea(child: child),
  );
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: TradeXColors.gold.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TradeXColors.gold.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: TradeXColors.gold),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final XFile? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: const Icon(Icons.image_outlined, color: TradeXColors.gold),
      title: Text(label),
      subtitle: Text(file?.name ?? 'No image selected'),
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
