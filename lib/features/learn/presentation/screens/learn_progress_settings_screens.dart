part of '../learn_module.dart';

class LearningProgressScreen extends StatefulWidget {
  const LearningProgressScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  State<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends State<LearningProgressScreen> {
  late Future<JsonMap> _future = widget.repository.progress();

  Future<void> _refresh() async {
    final next = widget.repository.progress();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Learning Progress',
    child: _FutureBody(
      future: _future,
      onRetry: _refresh,
      builder: (data) {
        final overall = LearnRepository.map(data['overall']);
        final courses = LearnRepository.list(data['courses']);
        final history = LearnRepository.list(data['recent_completions']);
        final completed = LearnRepository.number(overall['completed_lessons']);
        final total = LearnRepository.number(overall['total_lessons']);
        final percent = total <= 0
            ? 0
            : LearnRepository.number(overall['percent']).clamp(0, 100);
        return RefreshIndicator(
          color: context.palette.gold,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 42),
            children: [
              Text(
                'Track your learning, continue your courses, and build your trading expertise.',
                style: TextStyle(
                  color: context.palette.secondaryText,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _LearningProgressOverview(
                completed: completed,
                total: total,
                percent: percent,
                activeCourses: courses.length,
              ),
              const SizedBox(height: 22),
              const _ProgressSectionTitle(title: 'Active Courses'),
              const SizedBox(height: 10),
              if (courses.isEmpty)
                const _InfoCard(
                  title: 'No active courses',
                  body: 'Your enrolled courses will appear here.',
                )
              else
                ...courses.map((raw) {
                  final course = LearnRepository.map(raw);
                  final uuid = LearnRepository.text(course['uuid']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _ProgressCourseCard(
                      course: course,
                      onTap: uuid.isEmpty
                          ? null
                          : () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => SubjectDetailsScreen(
                                  repository: widget.repository,
                                  courseUuid: uuid,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              const SizedBox(height: 14),
              const _ProgressSectionTitle(title: 'Recent Completions'),
              const SizedBox(height: 10),
              if (history.isEmpty)
                const _InfoCard(
                  title: 'No recent completions',
                  body: 'Completed lessons will appear here as you progress.',
                )
              else
                ...history.map(
                  (raw) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _RecentCompletionTile(
                      item: LearnRepository.map(raw),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _ProgressSectionTitle extends StatelessWidget {
  const _ProgressSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
  );
}

class _ProgressCourseCard extends StatelessWidget {
  const _ProgressCourseCard({required this.course, this.onTap});

  final JsonMap course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress = LearnRepository.map(course['progress']);
    final completed = LearnRepository.number(progress['completed_lessons']);
    final total = LearnRepository.number(
      progress['total_lessons'] ?? course['lesson_count'],
    );
    final percent = total <= 0
        ? 0
        : LearnRepository.number(progress['percent']).clamp(0, 100);
    final thumbnail = LearnRepository.text(
      course['thumbnail_url'],
      LearnRepository.text(course['thumbnail_path']),
    );
    return _PremiumCard(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            CourseThumbnail(thumbnailPath: thumbnail, width: 58, height: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LearnRepository.text(course['title'], 'Course'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    total > 0
                        ? '$completed of $total lessons'
                        : 'Progress unavailable',
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 7,
                            color: context.palette.gold,
                            backgroundColor: context.palette.surfaceMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: context.palette.gold),
          ],
        ),
      ),
    );
  }
}

class _LearningProgressOverview extends StatelessWidget {
  const _LearningProgressOverview({
    required this.completed,
    required this.total,
    required this.percent,
    required this.activeCourses,
  });

  final int completed;
  final int total;
  final int percent;
  final int activeCourses;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _PremiumCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final ring = SizedBox.square(
            dimension: compact ? 112 : 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: compact ? 108 : 124,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 11,
                    strokeCap: StrokeCap.round,
                    color: palette.gold,
                    backgroundColor: palette.surfaceMuted,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      key: const ValueKey('progress-overall-percent'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Overall\nProgress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 11,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          final metrics = Column(
            children: [
              _ProgressMetric(
                icon: Icons.check_box_outlined,
                value: '$completed',
                label: total > 0
                    ? 'Completed Lessons · $total total'
                    : 'Completed Lessons',
              ),
              Divider(color: palette.border, height: 24),
              _ProgressMetric(
                icon: Icons.layers_outlined,
                value: '$activeCourses',
                label: 'Active Courses',
              ),
            ],
          );
          if (compact) {
            return Column(
              children: [ring, const SizedBox(height: 18), metrics],
            );
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: 16),
              Container(width: 1, height: 120, color: palette.border),
              const SizedBox(width: 16),
              Expanded(child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: context.palette.gold, size: 27),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: TextStyle(
                color: context.palette.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RecentCompletionTile extends StatelessWidget {
  const _RecentCompletionTile({required this.item});

  final JsonMap item;

  @override
  Widget build(BuildContext context) {
    final lesson = LearnRepository.map(item['lesson']);
    final course = LearnRepository.map(item['course']);
    final title = LearnRepository.text(
      lesson['title'],
      LearnRepository.text(item['lesson_title'], 'Completed lesson'),
    );
    final courseTitle = LearnRepository.text(
      course['title'],
      LearnRepository.text(item['course_title']),
    );
    final timestamp = LearnRepository.text(
      item['completed_at'],
      LearnRepository.text(item['updated_at']),
    );
    return _PremiumCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.palette.goldSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.school_outlined, color: context.palette.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (courseTitle.isNotEmpty || timestamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      courseTitle,
                      timestamp,
                    ].where((value) => value.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle, color: context.palette.success),
        ],
      ),
    );
  }
}

class LearnSettingsScreen extends StatelessWidget {
  const LearnSettingsScreen({super.key, required this.repository});
  final LearnRepository repository;

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeMode.values.firstWhere(
      (value) => value.name == repository.themeModeName,
      orElse: () => ThemeMode.system,
    );
    return _LearnScaffold(
      title: 'Learn Settings',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Text(
            'Customize your learning experience, language, appearance, and content preferences.',
            style: TextStyle(
              color: context.palette.secondaryText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _LearnSettingCard(
            icon: Icons.language_rounded,
            title: 'Course Language',
            subtitle: 'Choose the preferred language for supported course translations.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  repository.courseLanguage.toUpperCase(),
                  style: TextStyle(
                    color: context.palette.goldText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
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
          _PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LearnSettingIcon(Icons.palette_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Use your preferred app theme.',
                            style: TextStyle(
                              color: TradeXColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) async {
                      await repository.setThemeModeName(selection.first.name);
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _LearnSettingCard(
            icon: Icons.cloud_off_rounded,
            title: 'Protected Online Learning',
            subtitle: 'Downloads and offline exports are disabled for protected course content.',
            trailing: Icon(Icons.lock_outline_rounded),
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _LearnSettingCard extends StatelessWidget {
  const _LearnSettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .72,
    child: _PremiumCard(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _LearnSettingIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.palette.secondaryText,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconTheme(
              data: IconThemeData(color: context.palette.goldText),
              child: trailing,
            ),
          ],
        ),
      ),
    ),
  );
}

class _LearnSettingIcon extends StatelessWidget {
  const _LearnSettingIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: context.palette.goldSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: context.palette.goldText),
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
  late String selected = widget.repository.courseLanguage;
  bool saving = false;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.firstEntry || widget.repository.learnLanguageSelected,
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
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              Text(
                'Choose your preferred lesson language for a personalized learning experience.',
                style: TextStyle(
                  color: context.palette.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 158,
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.palette.border),
                  boxShadow: TradeXElevation.surface(
                    brightness: Theme.of(context).brightness,
                    palette: context.palette,
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learn Trading in Your Language',
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 9),
                          _LanguageBenefit('Expert lessons'),
                          _LanguageBenefit('Step-by-step guides'),
                          _LanguageBenefit('Supported translations'),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/language_chart_screener_ui/learning_hero_books_tablet_cap.png',
                      width: 140,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Language',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: languages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  childAspectRatio: 2.25,
                ),
                itemBuilder: (context, index) {
                  final language = languages[index];
                  return _LanguageOptionCard(
                    code: language.$1,
                    label: language.$2,
                    selected: selected == language.$1,
                    onTap: () => setState(() => selected = language.$1),
                  );
                },
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(saving ? 'Saving…' : 'Save Language'),
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

class _LanguageBenefit extends StatelessWidget {
  const _LanguageBenefit(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(Icons.check_rounded, size: 16, color: context.palette.goldText),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: context.palette.secondaryText,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final asset = _languageFlagAsset(code);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? context.palette.goldSoft
                : context.palette.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? context.palette.goldText
                  : context.palette.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: TradeXElevation.surface(
              brightness: Theme.of(context).brightness,
              palette: context.palette,
            ),
          ),
          child: Row(
            children: [
              if (asset != null)
                Image.asset(asset, width: 38, height: 38, fit: BoxFit.contain)
              else
                CircleAvatar(
                  radius: 19,
                  backgroundColor: context.palette.surfaceMuted,
                  child: Text(
                    code.toUpperCase(),
                    style: TextStyle(
                      color: context.palette.goldText,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: context.palette.goldText,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _languageFlagAsset(String rawCode) {
  final code = rawCode.toLowerCase().split(RegExp('[-_]')).first;
  const assets = <String, String>{
    'en': 'flag_en_gb_english.png',
    'es': 'flag_es_es_spanish.png',
    'fr': 'flag_fr_fr_french.png',
    'de': 'flag_de_de_german.png',
    'zh': 'flag_zh_cn_chinese.png',
    'ja': 'flag_ja_jp_japanese.png',
    'ko': 'flag_ko_kr_korean.png',
    'ar': 'flag_ar_sa_arabic.png',
    'hi': 'flag_hi_in_hindi.png',
    'id': 'flag_id_id_indonesian.png',
  };
  final name = assets[code];
  return name == null ? null : 'assets/language_chart_screener_ui/$name';
}
