part of '../trade_journal_trade_screens.dart';

class TradeJournalScreenshotsScreen extends StatefulWidget {
  const TradeJournalScreenshotsScreen({
    super.key,
    required this.repository,
    required this.entry,
  });

  final TradeJournalRepositoryContract repository;
  final TradeJournalEntry entry;

  @override
  State<TradeJournalScreenshotsScreen> createState() =>
      _TradeJournalScreenshotsScreenState();
}

class _TradeJournalScreenshotsScreenState
    extends State<TradeJournalScreenshotsScreen> {
  late TradeJournalEntry _entry;
  String? _workingType;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  @override
  Widget build(BuildContext context) => JournalScaffold(
    title: 'Trade Screenshots',
    subtitle: '${_entry.symbol} · private and secure',
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TradeHeader(entry: _entry),
        const SizedBox(height: 14),
        _screenshotCard(
          'before',
          'Before Trade',
          _entry.beforeScreenshotAvailable,
        ),
        const SizedBox(height: 14),
        _screenshotCard(
          'after',
          'After Trade',
          _entry.afterScreenshotAvailable,
        ),
      ],
    ),
  );

  Widget _screenshotCard(
    String type,
    String title,
    bool available,
  ) => JournalPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    type == 'before'
                        ? 'Entry overview and setup'
                        : 'Exit and final result',
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const JournalBadge(label: 'Private & Secure', color: journalGreen),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 190,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF111923),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: available
              ? FutureBuilder<Uint8List>(
                  future: widget.repository.screenshot(_entry.uuid, type),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return GestureDetector(
                        onTap: () => _preview(snapshot.data!),
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Unable to load image'));
                    }
                    return const JournalLoading();
                  },
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 38,
                        color: TradeXColors.secondaryText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type == 'after' && _entry.status != 'closed'
                            ? 'Close the trade before adding the after screenshot.'
                            : 'No screenshot added yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: TradeXColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _workingType != null ||
                        (type == 'after' && _entry.status != 'closed')
                    ? null
                    : () => _upload(type),
                icon: _workingType == type
                    ? const SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined),
                label: Text(available ? 'Replace' : 'Upload'),
              ),
            ),
            if (available &&
                !['closed', 'cancelled'].contains(_entry.status)) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Delete screenshot',
                onPressed: _workingType == null ? () => _delete(type) : null,
                color: journalRed,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
      ],
    ),
  );

  Future<void> _upload(String type) async {
    final file = await AppPlatformRegistry.current.pickImage(
      camera: false,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (file == null) return;
    setState(() => _workingType = type);
    try {
      await widget.repository.uploadScreenshot(_entry.uuid, type, file.path);
      _entry = await widget.repository.entry(_entry.uuid);
      if (mounted) setState(() {});
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _workingType = null);
    }
  }

  Future<void> _delete(String type) async {
    setState(() => _workingType = type);
    try {
      await widget.repository.deleteScreenshot(_entry.uuid, type);
      _entry = await widget.repository.entry(_entry.uuid);
      if (mounted) setState(() {});
    } on UserFacingException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _workingType = null);
    }
  }

  void _preview(Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Center(child: Image.memory(bytes)),
          ),
        ),
      ),
    );
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }
}
