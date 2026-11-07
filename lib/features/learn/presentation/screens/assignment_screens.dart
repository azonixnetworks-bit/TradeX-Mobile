part of '../learn_module.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key, required this.repository});
  final LearnRepository repository;
  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String status = 'ALL';
  late Future<JsonMap> future = widget.repository.assignments(status);

  void _selectStatus(String value) {
    if (value == status) return;
    setState(() {
      status = value;
      future = widget.repository.assignments(value);
    });
  }

  Future<void> _refresh() async {
    final next = widget.repository.assignments(status);
    setState(() => future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Assignments',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Track and manage your course assignments across all your learning programs.',
          style: TextStyle(color: context.palette.secondaryText, height: 1.35),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'PENDING', 'SUBMITTED', 'REVIEWED']
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_assignmentStatusLabel(value)),
                      selected: status == value,
                      showCheckmark: false,
                      selectedColor: context.palette.gold,
                      backgroundColor: context.palette.surface,
                      side: BorderSide(color: context.palette.border),
                      labelStyle: TextStyle(
                        color: status == value
                            ? context.palette.primaryButtonText
                            : context.palette.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => _selectStatus(value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _FutureBody(
            key: ValueKey(status),
            future: future,
            onRetry: _refresh,
            builder: (data) {
              final items = LearnRepository.list(data['items']);
              if (items.isEmpty) {
                return const _EmptyState('No assignments available.');
              }
              return RefreshIndicator(
                color: context.palette.gold,
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 28),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, i) {
                    final assignment = LearnRepository.map(items[i]);
                    return _AssignmentCard(
                      assignment: assignment,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AssignmentDetailsScreen(
                            repository: widget.repository,
                            assignmentUuid: LearnRepository.text(
                              assignment['uuid'],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.onTap});

  final JsonMap assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final course = LearnRepository.map(assignment['course']);
    final state = LearnRepository.text(
      assignment['state'],
      LearnRepository.text(assignment['status'], 'PENDING'),
    );
    final due = LearnRepository.text(
      assignment['due_at'],
      LearnRepository.text(assignment['due_date']),
    );
    return _PremiumCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.palette.goldSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _assignmentIcon(LearnRepository.text(course['title'])),
                color: context.palette.goldText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LearnRepository.text(assignment['title'], 'Assignment'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (LearnRepository.text(course['title']).isNotEmpty)
                        _AssignmentTag(LearnRepository.text(course['title'])),
                      _AssignmentStatusBadge(state),
                    ],
                  ),
                  if (due.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: context.palette.secondaryText,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            due,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.palette.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.palette.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class AssignmentDetailsScreen extends StatelessWidget {
  const AssignmentDetailsScreen({
    super.key,
    required this.repository,
    required this.assignmentUuid,
  });
  final LearnRepository repository;
  final String assignmentUuid;
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Assignment Details',
    child: _FutureBody(
      future: repository.assignment(assignmentUuid),
      builder: (data) {
        final assignment = LearnRepository.map(
          data['assignment'].toString().isEmpty ? data : data['assignment'],
        );
        final course = LearnRepository.map(assignment['course']);
        final state = LearnRepository.text(
          assignment['state'],
          LearnRepository.text(assignment['status']),
        );
        final brief = LearnRepository.text(assignment['description']);
        final instructions = LearnRepository.text(
          assignment['submission_instructions'],
        );
        final due = LearnRepository.text(
          assignment['due_at'],
          LearnRepository.text(assignment['due_date']),
        );
        final points = LearnRepository.number(
          assignment['points'] ?? assignment['max_points'],
        );
        final attachments = LearnRepository.list(
          assignment['attachments'] ?? assignment['files'],
        );
        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _PremiumCard(
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: context.palette.goldSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _assignmentIcon(LearnRepository.text(course['title'])),
                      color: context.palette.goldText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LearnRepository.text(
                            assignment['title'],
                            'Assignment',
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 7,
                          children: [
                            if (LearnRepository.text(course['title'])
                                .isNotEmpty)
                              _AssignmentTag(
                                LearnRepository.text(course['title']),
                              ),
                            if (state.isNotEmpty) _AssignmentStatusBadge(state),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (brief.isNotEmpty)
              _AssignmentDetailSection(
                icon: Icons.description_outlined,
                title: 'Assignment Brief',
                body: brief,
              ),
            if (brief.isNotEmpty) const SizedBox(height: 10),
            if (instructions.isNotEmpty)
              _AssignmentDetailSection(
                icon: Icons.track_changes_rounded,
                title: 'Submission Instructions',
                body: instructions,
              ),
            if (instructions.isNotEmpty) const SizedBox(height: 10),
            if (due.isNotEmpty || points > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (due.isNotEmpty)
                    Expanded(
                      child: _AssignmentMetric(
                        icon: Icons.calendar_month_outlined,
                        title: 'Due Date',
                        value: due,
                      ),
                    ),
                  if (due.isNotEmpty && points > 0) const SizedBox(width: 10),
                  if (points > 0)
                    Expanded(
                      child: _AssignmentMetric(
                        icon: Icons.emoji_events_outlined,
                        title: 'Points / Grading',
                        value: '$points Points',
                      ),
                    ),
                ],
              ),
            if (due.isNotEmpty || points > 0) const SizedBox(height: 10),
            if (attachments.isNotEmpty)
              _AssignmentAttachments(attachments: attachments),
            if (attachments.isNotEmpty) const SizedBox(height: 10),
            const _AssignmentDetailSection(
              icon: Icons.verified_user_outlined,
              title: 'Secure Submission',
              body: 'Continue through the approved TradeX WhatsApp submission channel.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final result = await repository.whatsappAction(assignmentUuid);
                final uri = Uri.tryParse(
                  LearnRepository.text(
                    result['url'],
                    LearnRepository.text(result['whatsapp_url']),
                  ),
                );
                if (uri != null) {
                  await AppPlatformRegistry.current.launchExternal(
                    uri.toString(),
                  );
                }
              },
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Continue in WhatsApp'),
            ),
          ],
        );
      },
    ),
  );
}

class _AssignmentDetailSection extends StatelessWidget {
  const _AssignmentDetailSection({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.palette.goldText),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(color: context.palette.secondaryText, height: 1.4),
        ),
      ],
    ),
  );
}

class _AssignmentMetric extends StatelessWidget {
  const _AssignmentMetric({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.palette.goldText),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.palette.secondaryText, fontSize: 11),
        ),
      ],
    ),
  );
}

class _AssignmentAttachments extends StatelessWidget {
  const _AssignmentAttachments({required this.attachments});
  final List<dynamic> attachments;

  @override
  Widget build(BuildContext context) => _PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_rounded, color: context.palette.goldText),
            const SizedBox(width: 8),
            Text(
              'Attached Files (${attachments.length})',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final raw in attachments)
          Builder(
            builder: (context) {
              final file = LearnRepository.map(raw);
              final name = LearnRepository.text(
                file['name'],
                LearnRepository.text(file['filename'], 'Attachment'),
              );
              final size = LearnRepository.text(
                file['size'],
                LearnRepository.text(file['human_size']),
              );
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.insert_drive_file_outlined,
                  color: context.palette.goldText,
                ),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: size.isEmpty ? null : Text(size),
              );
            },
          ),
      ],
    ),
  );
}

class _AssignmentTag extends StatelessWidget {
  const _AssignmentTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.palette.goldSoft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: context.palette.goldText,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _AssignmentStatusBadge extends StatelessWidget {
  const _AssignmentStatusBadge(this.state);
  final String state;
  @override
  Widget build(BuildContext context) {
    final complete =
        state.toUpperCase() == 'SUBMITTED' || state.toUpperCase() == 'REVIEWED';
    final color = complete ? context.palette.success : context.palette.goldText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _assignmentStatusLabel(state),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _assignmentStatusLabel(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('_', ' ');
  if (normalized.isEmpty) return 'Pending';
  return normalized
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

IconData _assignmentIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('risk')) return Icons.layers_outlined;
  if (value.contains('portfolio')) return Icons.pie_chart_outline_rounded;
  if (value.contains('strategy')) return Icons.candlestick_chart_outlined;
  return Icons.bar_chart_rounded;
}
