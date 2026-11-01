part of '../learn_module.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key, required this.repository});
  final LearnRepository repository;
  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String status = 'ALL';
  @override
  Widget build(BuildContext context) => _LearnScaffold(
    title: 'Assignments',
    child: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'PENDING', 'SUBMITTED', 'REVIEWED']
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: status == value,
                      onSelected: (_) => setState(() => status = value),
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
            future: widget.repository.assignments(status),
            builder: (data) {
              final items = LearnRepository.list(data['items']);
              if (items.isEmpty) {
                return const _EmptyState('No assignments available.');
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (_, i) {
                  final assignment = LearnRepository.map(items[i]);
                  return _PremiumCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.assignment_rounded,
                        color: _gold,
                      ),
                      title: Text(LearnRepository.text(assignment['title'])),
                      subtitle: Text(
                        '${LearnRepository.text(LearnRepository.map(assignment['course'])['title'])} • ${LearnRepository.text(assignment['state'], 'PENDING')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
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
        return ListView(
          children: [
            _InfoCard(
              title: LearnRepository.text(assignment['title'], 'Assignment'),
              body: LearnRepository.text(
                assignment['description'],
                LearnRepository.text(
                  assignment['submission_instructions'],
                  'Follow the assignment instructions and submit through the approved channel.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Submission',
              body: 'TradeX currently uses secure external WhatsApp submission. The app does not upload learner files or claim a submitted/reviewed state until the backend supports verified review tracking.',
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
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Continue in WhatsApp'),
            ),
          ],
        );
      },
    ),
  );
}
