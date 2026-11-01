part of '../learn_module.dart';

class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({super.key, required this.repository});
  final LearnRepository repository;
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Learning Progress',
    child: _FutureBody(
      future: repository.progress(),
      builder: (data) {
        final overall = LearnRepository.map(data['overall']);
        final courses = LearnRepository.list(data['courses']);
        final history = LearnRepository.list(data['recent_completions']);
        return ListView(
          children: [
            _ProgressSummary(
              completed: LearnRepository.number(overall['completed_lessons']),
              total: LearnRepository.number(overall['total_lessons']),
              percent: LearnRepository.number(overall['percent']),
            ),
            const SizedBox(height: 18),
            const _SectionHeading(icon: Icons.school, title: 'Active Courses'),
            const SizedBox(height: 8),
            ...courses.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CourseCard(course: LearnRepository.map(c)),
              ),
            ),
            const SizedBox(height: 12),
            const _SectionHeading(
              icon: Icons.history,
              title: 'Recent Completions',
            ),
            ...history.map(
              (item) => ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: TradeXColors.success,
                ),
                title: Text(
                  LearnRepository.text(
                    LearnRepository.map(
                      LearnRepository.map(item)['lesson'],
                    )['title'],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class LearnSettingsScreen extends StatelessWidget {
  const LearnSettingsScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AppPreferences, AppPreferencesState>(
        bloc: AppPreferences.instance,
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode ||
            previous.courseLanguage != current.courseLanguage,
        builder: (context, preferences) => _LearnScaffold(
          title: 'Learn Settings',
          child: ListView(
            children: [
              const _InfoCard(
                title: 'Learning Preferences',
                body: 'Choose the preferred display language for supported TradeX course translations.',
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.language_rounded, color: _gold),
                title: const Text('Course language'),
                subtitle: Text(preferences.courseLanguage.toUpperCase()),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          LearnLanguageSelectionScreen(repository: repository),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const _SectionHeading(
                icon: Icons.palette_outlined,
                title: 'Appearance',
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.settings_suggest_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {preferences.themeMode},
                onSelectionChanged: (selection) async {
                  await AppPreferences.instance.setThemeMode(selection.first);
                },
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.cloud_off_rounded, color: _gold),
                title: Text('Protected online learning'),
                subtitle: Text('Downloads and offline exports are disabled.'),
              ),
            ],
          ),
        ),
      );
}

class LearnLanguageSelectionScreen extends StatefulWidget {
  const LearnLanguageSelectionScreen({
    super.key,
    required this.repository,
    this.firstEntry = false,
  });

  final LearnRepository repository;
  final bool firstEntry;

  @override
  State<LearnLanguageSelectionScreen> createState() =>
      _LearnLanguageSelectionScreenState();
}

class _LearnLanguageSelectionScreenState
    extends State<LearnLanguageSelectionScreen> {
  late Future<JsonMap> _future = widget.repository.languages();
  String selected = AppPreferences.instance.courseLanguage;
  bool saving = false;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.firstEntry || AppPreferences.instance.learnLanguageSelected,
    child: _LearnScaffold(
      title: widget.firstEntry ? 'Choose Course Language' : 'Course Language',
      child: _FutureBody(
        future: _future,
        onRetry: () {
          setState(() {
            _future = widget.repository.languages();
          });
        },
        builder: (data) {
          final languages = _languageEntries(data);
          return ListView(
            children: [
              const _InfoCard(
                title: 'Learn in your language',
                body: 'TradeX will show translated course content when it is published. You can change this later in Learn Settings.',
              ),
              const SizedBox(height: 12),
              for (final language in languages)
                ListTile(
                  leading: Icon(
                    selected == language.$1
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected == language.$1
                        ? _gold
                        : TradeXColors.secondaryText,
                  ),
                  title: Text(language.$2),
                  subtitle: Text(language.$1.toUpperCase()),
                  onTap: () => setState(() => selected = language.$1),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(saving ? 'Saving…' : 'Continue'),
              ),
            ],
          );
        },
      ),
    ),
  );

  List<(String, String)> _languageEntries(JsonMap data) {
    final raw = LearnRepository.list(data['languages']).isNotEmpty
        ? LearnRepository.list(data['languages'])
        : LearnRepository.list(data['items']).isNotEmpty
        ? LearnRepository.list(data['items'])
        : data.values.whereType<Map>().toList();
    final parsed = raw
        .map(LearnRepository.map)
        .map(
          (item) => (
            LearnRepository.text(
              item['code'],
              LearnRepository.text(item['language_code']),
            ).toLowerCase(),
            LearnRepository.text(
              item['native_name'],
              LearnRepository.text(item['name'], 'Language'),
            ),
          ),
        )
        .where((item) => item.$1.isNotEmpty)
        .toList(growable: false);
    return parsed.isEmpty ? const [('en', 'English')] : parsed;
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.repository.updateLanguage(selected);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
