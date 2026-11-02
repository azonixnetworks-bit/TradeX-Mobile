part of '../home_dashboard_screen.dart';

class _TabScrollView extends StatelessWidget {
  const _TabScrollView({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                title,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: TradeXColors.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ]),
          ),
        ),
      ],
    );
  }
}

// Kept temporarily for backwards-compatible golden references.
// ignore: unused_element
class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF30240A), Color(0xFF131A16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: TradeXColors.gold.withValues(alpha: .65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KEEP BUILDING YOUR EDGE',
              style: TextStyle(
                color: TradeXColors.goldBright,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Smart Money Concepts',
              style: TextStyle(
                color: TradeXColors.primaryText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Module 3 · Lesson 2: Break of Structure',
              style: TextStyle(color: TradeXColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 18),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                value: .68,
                minHeight: 8,
                color: TradeXColors.goldBright,
                backgroundColor: TradeXColors.surfaceMuted,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Text(
                  '68% complete',
                  style: TextStyle(
                    color: TradeXColors.goldBright,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _GoldButton(label: 'Resume', onTap: onTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ModuleList extends StatelessWidget {
  const _ModuleList({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const modules = [
      ('1', 'Trading Foundations', 'Complete', true),
      ('2', 'Risk Management', 'Complete', true),
      ('3', 'Market Structure', 'In progress', false),
      ('4', 'Trade Execution', 'Locked', false),
    ];
    return Container(
      decoration: _panelDecoration(context),
      child: Column(
        children: modules.map((module) {
          final index = modules.indexOf(module);
          final complete = module.$4;
          final locked = module.$3 == 'Locked';
          return InkWell(
            onTap: locked ? null : () => onTap(module.$2),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: complete
                          ? TradeXColors.success.withValues(alpha: .16)
                          : locked
                          ? TradeXColors.surfaceMuted
                          : TradeXColors.goldDeep.withValues(alpha: .38),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      complete
                          ? Icons.check_rounded
                          : locked
                          ? Icons.lock_outline_rounded
                          : Icons.play_arrow_rounded,
                      color: complete
                          ? TradeXColors.success
                          : locked
                          ? TradeXColors.tertiaryText
                          : TradeXColors.goldBright,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Module ${module.$1}: ${module.$2}',
                      style: TextStyle(
                        color: locked
                            ? TradeXColors.secondaryText
                            : TradeXColors.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    module.$3,
                    style: TextStyle(
                      color: complete
                          ? TradeXColors.success
                          : locked
                          ? TradeXColors.tertiaryText
                          : TradeXColors.goldBright,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (index != modules.length - 1) const SizedBox(width: 0),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ignore: unused_element
class _RecommendedCourseCard extends StatelessWidget {
  const _RecommendedCourseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: _panelDecoration(context),
        child: Row(
          children: [
            _CourseThumbnail(label: 'RISK\nMANAGEMENT'),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Management Mastery',
                    style: TextStyle(
                      color: TradeXColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Protect capital before you pursue profit.',
                    style: TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: TradeXColors.goldBright,
            ),
          ],
        ),
      ),
    );
  }
}

// Kept as the original partial-screen visual reference.
// ignore: unused_element
class _RiskNotice extends StatelessWidget {
  const _RiskNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: TradeXColors.warning.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TradeXColors.warning.withValues(alpha: .35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: TradeXColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trade ideas are for educational purposes only. Trade at your own risk and always use your own analysis.',
              style: TextStyle(
                color: Color(0xFFE9DDAE),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
