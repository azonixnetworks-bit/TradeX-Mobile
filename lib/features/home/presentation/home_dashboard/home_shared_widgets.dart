part of '../home_dashboard_screen.dart';

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE080), TradeXColors.goldBright],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF171308),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF171308),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseThumbnail extends StatelessWidget {
  const _CourseThumbnail({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 102.0 : 116.0;
    return Container(
      width: width,
      height: compact ? 88 : 102,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: const DecorationImage(
          image: AssetImage(
            'assets/branding/tradex_bull_bear_trading_emblem.png',
          ),
          fit: BoxFit.cover,
          alignment: Alignment(0, -.15),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x29000000), Color(0xD9000000)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: TradeXColors.primaryText,
                  height: 1.02,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: TradeXColors.goldBright,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCandles extends StatelessWidget {
  const _MiniCandles();

  @override
  Widget build(BuildContext context) {
    const values = [
      20.0,
      27.0,
      23.0,
      34.0,
      30.0,
      43.0,
      38.0,
      51.0,
      47.0,
      59.0,
      55.0,
      66.0,
    ];
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final positive = index != 2 && index != 6 && index != 9;
          return Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 5,
                height: values[index],
                decoration: BoxDecoration(
                  color: positive ? TradeXColors.success : TradeXColors.error,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MarketSession {
  const _MarketSession({
    required this.name,
    required this.isOpen,
    required this.timezone,
    required this.openLocal,
    required this.closeLocal,
    required this.dialSegments,
  });

  factory _MarketSession.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    return _MarketSession(
      name: json['name']?.toString() ?? 'Market',
      isOpen: status == 'open',
      timezone: json['timezone']?.toString() ?? 'UTC',
      openLocal: json['configured_open_local']?.toString() ?? '--:--',
      closeLocal: json['configured_close_local']?.toString() ?? '--:--',
      dialSegments: (json['dial_segments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (segment) =>
                _MarketDialSegment.fromJson(Map<String, dynamic>.from(segment)),
          )
          .toList(growable: false),
    );
  }

  factory _MarketSession.fromFallback(
    String name,
    int startHour,
    int endHour,
    int utcHour,
  ) {
    final isOpen = startHour < endHour
        ? utcHour >= startHour && utcHour < endHour
        : utcHour >= startHour || utcHour < endHour;
    final timezone = switch (name) {
      'Sydney' => 'Australia/Sydney',
      'Tokyo' => 'Asia/Tokyo',
      'London' => 'Europe/London',
      'New York' => 'America/New_York',
      _ => 'UTC',
    };
    final configuredHours = switch (name) {
      'Tokyo' => ('09:00', '18:00'),
      _ => ('08:00', '17:00'),
    };
    final startMinute = startHour * 60;
    final endMinute = endHour * 60;
    final segments = endMinute > startMinute
        ? [_MarketDialSegment(startMinute.toDouble(), endMinute.toDouble())]
        : [
            _MarketDialSegment(startMinute.toDouble(), 1440),
            _MarketDialSegment(0, endMinute.toDouble()),
          ];
    return _MarketSession(
      name: name,
      isOpen: isOpen,
      timezone: timezone,
      openLocal: configuredHours.$1,
      closeLocal: configuredHours.$2,
      dialSegments: segments,
    );
  }

  final String name;
  final bool isOpen;
  final String timezone;
  final String openLocal;
  final String closeLocal;
  final List<_MarketDialSegment> dialSegments;
}

class _MarketDialSegment {
  const _MarketDialSegment(this.startMinute, this.endMinute);

  factory _MarketDialSegment.fromJson(Map<String, dynamic> json) =>
      _MarketDialSegment(
        (json['start_minute'] as num?)?.toDouble() ?? 0,
        (json['end_minute'] as num?)?.toDouble() ?? 0,
      );

  final double startMinute;
  final double endMinute;
}

class _TabItem {
  const _TabItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _tabItems = [
  _TabItem('Home', Icons.home_rounded),
  _TabItem('Learn', Icons.menu_book_rounded),
  _TabItem('Trade Ideas', Icons.lightbulb_rounded),
  _TabItem('Affiliate', Icons.groups_rounded),
  _TabItem('Profile', Icons.person_outline_rounded),
];

BoxDecoration _panelDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: Theme.of(context).dividerColor),
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: .19), blurRadius: 10),
  ],
);
