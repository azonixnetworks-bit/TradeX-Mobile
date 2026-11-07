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
  String? submittedQuestion;
  String? errorMessage;
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
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 14),
            children: [
              Text(
                'Your AI learning assistant for trading.',
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  'assets/progress_ai_premium_ui/illustrations/ai_robot_white_gold_mascot.png',
                  height: 172,
                  fit: BoxFit.contain,
                  semanticLabel: 'TradeX AI assistant',
                ),
              ),
              const SizedBox(height: 8),
              _AiStatusCard(lessonTitle: widget.lessonTitle),
              if (submittedQuestion != null) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 310),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.goldSoft,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(5),
                      ),
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Text(submittedQuestion!),
                  ),
                ),
              ],
              if (answer != null) ...[
                const SizedBox(height: 14),
                _AiAnswerCard(answer: answer!),
              ],
              if (loading) ...[
                const SizedBox(height: 14),
                const _AiThinkingCard(),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 14),
                _InfoCard(
                  title: 'Unable to get an answer',
                  body: errorMessage!,
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.border),
            boxShadow: TradeXElevation.surface(
              brightness: Theme.of(context).brightness,
              palette: context.palette,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !loading,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.lessonUuid == null
                        ? 'Message TradeX AI…'
                        : 'Ask about this lesson…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                key: const ValueKey('ask-tradex-ai-send'),
                tooltip: 'Send question',
                onPressed: loading ? null : _submit,
                style: IconButton.styleFrom(
                  backgroundColor: context.palette.gold,
                  foregroundColor: context.palette.primaryButtonText,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    final question = controller.text.trim();
    if (question.length < 3) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      submittedQuestion = question;
      answer = null;
      errorMessage = null;
      loading = true;
    });
    try {
      final result = await widget.repository.askAi(
        question,
        lessonUuid: widget.lessonUuid,
      );
      if (!mounted) return;
      setState(() {
        answer = result;
        controller.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _AiStatusCard extends StatelessWidget {
  const _AiStatusCard({this.lessonTitle});

  final String? lessonTitle;

  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: context.palette.goldSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome, color: context.palette.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TradeX Second Brain',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                lessonTitle?.trim().isNotEmpty == true
                    ? 'Answers use the approved TradeX knowledge for “${lessonTitle!.trim()}”.'
                    : 'Answers prioritize approved TradeX course knowledge.',
                style: TextStyle(
                  color: context.palette.secondaryText,
                  height: 1.35,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AiAnswerCard extends StatelessWidget {
  const _AiAnswerCard({required this.answer});

  final JsonMap answer;

  @override
  Widget build(BuildContext context) {
    final body = LearnRepository.text(answer['answer']);
    final sources = LearnRepository.list(answer['sources']);
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: context.palette.gold, size: 19),
              const SizedBox(width: 8),
              const Text(
                'TradeX AI',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            SelectableText(body, style: const TextStyle(height: 1.45)),
          ],
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: context.palette.border),
            ...sources.map((raw) {
              final source = LearnRepository.map(raw);
              final title = LearnRepository.text(source['title']);
              if (title.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: context.palette.gold,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: context.palette.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _AiThinkingCard extends StatelessWidget {
  const _AiThinkingCard();

  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Row(
      children: [
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.palette.gold,
          ),
        ),
        const SizedBox(width: 12),
        const Text('Reviewing approved TradeX knowledge…'),
      ],
    ),
  );
}
