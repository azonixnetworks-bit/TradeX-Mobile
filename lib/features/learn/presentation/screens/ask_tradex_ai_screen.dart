part of '../learn_module.dart';

class AskTradeXAiScreen extends StatefulWidget {
  const AskTradeXAiScreen({
    super.key,
    required this.repository,
    this.lessonUuid,
    this.lessonTitle,
  });
  final LearnRepository repository;
  final String? lessonUuid;
  final String? lessonTitle;
  @override
  State<AskTradeXAiScreen> createState() => _AskTradeXAiScreenState();
}

class _AskTradeXAiScreenState extends State<AskTradeXAiScreen> {
  final controller = TextEditingController();
  JsonMap? answer;
  bool loading = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Ask TradeX AI',
    child: Column(
      children: [
        if (widget.lessonTitle != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text('Based on: ${widget.lessonTitle}')),
          ),
        Expanded(
          child: ListView(
            children: [
              const _InfoCard(
                title: 'TradeX Second Brain',
                body: 'Answers prioritize founder-approved TradeX course knowledge. Generic internet content is not silently substituted.',
              ),
              if (answer != null) ...[
                const SizedBox(height: 14),
                _InfoCard(
                  title: 'Answer',
                  body: LearnRepository.text(answer!['answer']),
                ),
                ...LearnRepository.list(answer!['sources']).map(
                  (source) => ListTile(
                    leading: const Icon(Icons.verified_rounded, color: _gold),
                    title: Text(
                      LearnRepository.text(
                        LearnRepository.map(source)['title'],
                      ),
                    ),
                    subtitle: const Text('Approved TradeX source'),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ask about this lesson…',
                ),
              ),
            ),
            IconButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (controller.text.trim().length < 3) return;
                      setState(() => loading = true);
                      try {
                        answer = await widget.repository.askAi(
                          controller.text.trim(),
                          lessonUuid: widget.lessonUuid,
                        );
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              icon: loading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.send_rounded, color: _gold),
            ),
          ],
        ),
      ],
    ),
  );
}
