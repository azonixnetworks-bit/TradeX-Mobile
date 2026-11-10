part of '../home_dashboard_screen.dart';

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const categories = [
      (
        label: 'Forex',
        ideas: '30+ Ideas',
        accent: Color(0xFF45D6A8),
        imageAsset: 'assets/branding/market_forex.png',
        iconAsset: 'assets/home_ui/simple_svg/market_forex.svg',
      ),
      (
        label: 'Commodities',
        ideas: '15+ Ideas',
        accent: Color(0xFFFFA928),
        imageAsset:
            'assets/home_ui/complex_png/polished_gold_bullion_stack.png',
        iconAsset: 'assets/home_ui/simple_svg/market_commodities.svg',
      ),
      (
        label: 'Indices',
        ideas: '50+ Ideas',
        accent: Color(0xFF39B9FF),
        imageAsset: 'assets/branding/market_stocks.png',
        iconAsset: 'assets/home_ui/simple_svg/market_indices.svg',
      ),
      (
        label: 'Crypto',
        ideas: '20+ Ideas',
        accent: Color(0xFFFF5A54),
        imageAsset: 'assets/branding/market_crypto.png',
        iconAsset: 'assets/home_ui/simple_svg/market_crypto.svg',
      ),
    ];
    return SizedBox(
      key: const ValueKey('home-market-categories-scroll'),
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            key: ValueKey('home-market-category-${category.label.toLowerCase()}'),
            width: 184,
            child: _CategoryTile(
              label: category.label,
              ideas: category.ideas,
              accent: category.accent,
              imageAsset: category.imageAsset,
              iconAsset: category.iconAsset,
              onTap: () => onTap('${category.label} trade ideas'),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.ideas,
    required this.accent,
    required this.imageAsset,
    required this.iconAsset,
    required this.onTap,
  });

  final String label;
  final String ideas;
  final Color accent;
  final String imageAsset;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The category data and existing navigation callbacks are intentionally
    // untouched. This styling matches the compact white/gold session cards.
    const cornerRadius = BorderRadius.all(Radius.circular(18));
    const gold = Color(0xFFD6A23A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 2, 1, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: cornerRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87601B).withValues(alpha: .18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .045),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: cornerRadius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: cornerRadius,
              border: Border.all(
                color: const Color(0xFFDAAA45),
                width: 1.1,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFEFB),
                  Color(0xFFFBF6EE),
                ],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SessionCardFinishPainter(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: 0,
                    width: 137,
                    height: 65,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: .16,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            gold,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            imageAsset,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomRight,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF101827),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            SvgPicture.asset(
                              iconAsset,
                              width: 23,
                              height: 23,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFB7831E),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 26,
                          height: 2,
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Trade Ideas',
                          style: TextStyle(
                            color: Color(0xFF5D6878),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E8),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: gold.withValues(alpha: .55),
                              width: .8,
                            ),
                          ),
                          child: Text(
                            ideas,
                            style: const TextStyle(
                              color: Color(0xFF8B5C12),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                        // Keep existing per-market accent in the visual
                        // treatment without recoloring the common gold theme.
                        const Spacer(),
                        Container(
                          width: 24,
                          height: 1,
                          color: accent.withValues(alpha: .12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestContentCard extends StatefulWidget {
  const _LatestContentCard({
    required this.apiClient,
    required this.onActionTap,
  });

  final ApiGateway apiClient;
  final ValueChanged<String> onActionTap;

  @override
  State<_LatestContentCard> createState() => _LatestContentCardState();
}

class _LatestContentCardState extends State<_LatestContentCard> {
  late Future<List<_ChannelVideo>> _videos;

  @override
  void initState() {
    super.initState();
    _videos = _loadVideos();
  }

  Future<List<_ChannelVideo>> _loadVideos() async {
    final response = await widget.apiClient.getJson(
      '/api/v1/our-channel/videos?per_page=12',
    );
    final data = response['data'];
    final videos = data is Map ? data['videos'] : null;
    if (videos is! List) return const [];
    final result = videos
        .whereType<Map>()
        .map(
          (video) => _ChannelVideo.fromJson(Map<String, dynamic>.from(video)),
        )
        .toList();
    result.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return result;
  }

  Future<void> _react(_ChannelVideo video, String reaction) async {
    final previous = video.viewerReaction;
    final next = previous == reaction ? null : reaction;
    setState(() => video.applyReaction(next));
    try {
      final response = await widget.apiClient.putJson(
        '/api/v1/our-channel/videos/${video.uuid}/reaction',
        next == null ? const {} : {'reaction': next},
      );
      final data = response['data'];
      final raw = data is Map ? data['reaction'] : null;
      if (mounted && raw is Map) {
        setState(
          () => video.applyReactionSummary(Map<String, dynamic>.from(raw)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => video.applyReaction(previous));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save your reaction.')),
        );
      }
    }
  }

  Future<void> _openVideo(String? rawUrl) async {
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null ||
        !await AppPlatformRegistry.current.launchExternal(uri.toString())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open YouTube right now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => BlocFutureBuilder<List<_ChannelVideo>>(
    future: _videos,
    builder: (context, snapshot) {
      final videos = snapshot.data ?? const <_ChannelVideo>[];
      if (videos.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: _panelDecoration(context),
          child: const Row(
            children: [
              Icon(
                Icons.ondemand_video_rounded,
                color: TradeXColors.goldBright,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New TradeX videos will appear here as soon as they are published.',
                  style: TextStyle(
                    color: TradeXColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 16),
          itemCount: videos.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: 298,
            child: _LatestVideoCard(
              video: videos[index],
              onOpen: _openVideo,
              onReact: _react,
            ),
          ),
        ),
      );
    },
  );
}

class _LatestVideoCard extends StatelessWidget {
  const _LatestVideoCard({
    required this.video,
    required this.onOpen,
    required this.onReact,
  });

  final _ChannelVideo video;
  final ValueChanged<String?> onOpen;
  final Future<void> Function(_ChannelVideo, String) onReact;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onOpen(video.watchUrl),
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(context),
      child: Row(
        children: [
          _YoutubeThumbnail(video: video),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TradeXColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (video.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TradeXColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    _ReactionButton(
                      icon: Icons.thumb_up_alt_outlined,
                      count: video.likesCount,
                      selected: video.viewerReaction == 'LIKE',
                      onTap: () => onReact(video, 'LIKE'),
                    ),
                    const SizedBox(width: 8),
                    _ReactionButton(
                      icon: Icons.thumb_down_alt_outlined,
                      count: video.dislikesCount,
                      selected: video.viewerReaction == 'DISLIKE',
                      onTap: () => onReact(video, 'DISLIKE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _YoutubeThumbnail extends StatelessWidget {
  const _YoutubeThumbnail({required this.video});

  final _ChannelVideo video;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 102,
      height: 78,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video.thumbnailUrl != null)
            Image.network(
              video.thumbnailUrl!,
              fit: BoxFit.cover,
              cacheWidth: 306,
              cacheHeight: 234,
              errorBuilder: (_, _, _) => _fallback(),
            )
          else
            _fallback(),
          const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: TradeXColors.goldBright,
              size: 29,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _fallback() => Image.asset(
    'assets/branding/tradex_bull_bear_trading_emblem.png',
    fit: BoxFit.cover,
    cacheWidth: 306,
  );
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: selected
                ? TradeXColors.goldBright
                : TradeXColors.secondaryText,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: selected
                  ? TradeXColors.goldBright
                  : TradeXColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChannelVideo {
  _ChannelVideo({
    required this.uuid,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.watchUrl,
    required this.likesCount,
    required this.dislikesCount,
    required this.viewerReaction,
    required this.publishedAt,
  });

  factory _ChannelVideo.fromJson(Map<String, dynamic> json) {
    final youtube = json['youtube'] is Map
        ? Map<String, dynamic>.from(json['youtube'] as Map)
        : const <String, dynamic>{};
    final reactions = json['reactions'] is Map
        ? Map<String, dynamic>.from(json['reactions'] as Map)
        : const <String, dynamic>{};
    return _ChannelVideo(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Latest from TradeX',
      description: json['short_description']?.toString() ?? '',
      thumbnailUrl: youtube['thumbnail_url']?.toString(),
      watchUrl: youtube['watch_url']?.toString(),
      likesCount: (reactions['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (reactions['dislikes_count'] as num?)?.toInt() ?? 0,
      viewerReaction: reactions['viewer_reaction']?.toString(),
      publishedAt:
          DateTime.tryParse(json['published_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String uuid;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? watchUrl;
  int likesCount;
  int dislikesCount;
  String? viewerReaction;
  final DateTime publishedAt;

  void applyReaction(String? next) {
    if (viewerReaction == next) return;
    if (viewerReaction == 'LIKE') likesCount--;
    if (viewerReaction == 'DISLIKE') dislikesCount--;
    if (next == 'LIKE') likesCount++;
    if (next == 'DISLIKE') dislikesCount++;
    viewerReaction = next;
  }

  void applyReactionSummary(Map<String, dynamic> json) {
    likesCount = (json['likes_count'] as num?)?.toInt() ?? likesCount;
    dislikesCount = (json['dislikes_count'] as num?)?.toInt() ?? dislikesCount;
    viewerReaction = json['viewer_reaction']?.toString();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.titleColor,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final Color? titleColor;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TradeXColors.goldBright, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: titleColor ?? TradeXColors.primaryText,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(action!),
            style: TextButton.styleFrom(
              foregroundColor: TradeXColors.goldBright,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}
