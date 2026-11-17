import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../../../core/theme/tradex_palette.dart';
import '../domain/repositories/learn_repository.dart';
import 'learn_dashboard_widgets.dart';

class CourseVideoPlayerScreen extends StatefulWidget {
  const CourseVideoPlayerScreen({
    super.key,
    required this.repository,
    required this.lessonUuid,
    required this.videoUuid,
    required this.title,
    required this.playbackUrl,
    this.resumeSeconds = 0,
    this.sources = const <String, String>{},
    this.thumbnailPath = '',
    this.startFullscreen = false,
  });
  final LearnRepository repository;
  final String lessonUuid, videoUuid, title, playbackUrl, thumbnailPath;
  final int resumeSeconds;
  final Map<String, String> sources;
  final bool startFullscreen;
  @override
  State<CourseVideoPlayerScreen> createState() =>
      _CourseVideoPlayerScreenState();
}

class _CourseVideoPlayerScreenState extends State<CourseVideoPlayerScreen> {
  late bool fullscreen = widget.startFullscreen;
  @override
  void initState() {
    super.initState();
    if (fullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
    }
  }

  Future<void> _enter() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restore() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _toggle() async {
    if (widget.startFullscreen && fullscreen) {
      await _restore();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    fullscreen ? await _restore() : await _enter();
    if (mounted) setState(() => fullscreen = !fullscreen);
  }

  @override
  void dispose() {
    if (fullscreen) unawaited(_restore());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TradeXPalette.of(context);
    final sources = widget.sources.isEmpty
        ? <String, String>{'Auto': widget.playbackUrl}
        : widget.sources;
    return Scaffold(
      backgroundColor: fullscreen ? Colors.black : palette.background,
      appBar: fullscreen
          ? null
          : AppBar(
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: fullscreen ? EdgeInsets.zero : const EdgeInsets.all(16),
            child: TradeXVideoPlayer(
              repository: widget.repository,
              lessonUuid: widget.lessonUuid,
              videoUuid: widget.videoUuid,
              sources: sources,
              thumbnailPath: widget.thumbnailPath,
              resumeSeconds: widget.resumeSeconds,
              fullscreen: fullscreen,
              autoplay: true,
              onFullscreen: _toggle,
            ),
          ),
        ),
      ),
    );
  }
}

class TradeXVideoPlayer extends StatefulWidget {
  const TradeXVideoPlayer({
    super.key,
    required this.repository,
    required this.lessonUuid,
    required this.videoUuid,
    required this.sources,
    required this.thumbnailPath,
    this.resumeSeconds = 0,
    this.fullscreen = false,
    this.autoplay = false,
    this.onFullscreen,
  });
  final LearnRepository repository;
  final String lessonUuid, videoUuid, thumbnailPath;
  final Map<String, String> sources;
  final int resumeSeconds;
  final bool fullscreen, autoplay;
  final VoidCallback? onFullscreen;
  @override
  State<TradeXVideoPlayer> createState() => _TradeXVideoPlayerState();
}

class _TradeXVideoPlayerState extends State<TradeXVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? controller;
  Timer? checkpoint;
  Future<void>? saveInFlight;
  Object? error;
  bool loading = true, started = false, muted = false, foreground = true;
  double speed = 1;
  int? lastSavedPosition;
  late String quality = widget.sources.keys.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize(quality, autoplay: widget.autoplay);
  }

  Future<void> _initialize(
    String label, {
    required bool autoplay,
    Duration? resumeAt,
  }) async {
    final url = widget.sources[label];
    if (url == null || url.trim().isEmpty) {
      if (mounted) setState(() => error = StateError('Video unavailable'));
      return;
    }
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    final next = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await next.initialize();
      final requested = resumeAt ?? Duration(seconds: widget.resumeSeconds);
      final bounded = boundedVideoPosition(requested, next.value.duration);
      if (bounded > Duration.zero) await next.seekTo(bounded);
      await next.setPlaybackSpeed(speed);
      await next.setVolume(muted ? 0 : 1);
      final old = controller;
      old?.removeListener(_refresh);
      controller = next;
      next.addListener(_refresh);
      await old?.dispose();
      checkpoint?.cancel();
      checkpoint = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _saveProgress(),
      );
      if (autoplay && foreground) {
        started = true;
        await next.play();
      }
      if (mounted) setState(() => loading = false);
    } catch (caught) {
      await next.dispose();
      if (mounted) {
        setState(() {
          loading = false;
          error = caught;
        });
      }
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      foreground = true;
      return;
    }
    foreground = false;
    checkpoint?.cancel();
    unawaited(controller?.pause());
    unawaited(_saveProgress());
  }

  Future<void> _saveProgress() async {
    final player = controller;
    if (player == null || !player.value.isInitialized) return;
    final position = player.value.position.inSeconds;
    if (position == lastSavedPosition) return;
    if (saveInFlight != null) await saveInFlight;
    final duration = player.value.duration.inSeconds;
    final operation = widget.repository.updateProgress(
      widget.lessonUuid,
      status: duration > 0 && position >= duration - 3
          ? 'COMPLETED'
          : 'IN_PROGRESS',
      videoUuid: widget.videoUuid,
      positionSeconds: position,
    );
    saveInFlight = operation;
    try {
      await operation;
      lastSavedPosition = position;
    } finally {
      if (identical(saveInFlight, operation)) saveInFlight = null;
    }
  }

  Future<void> _seek(Duration delta) async {
    final player = controller;
    if (player == null) return;
    await player.seekTo(
      boundedVideoPosition(
        player.value.position + delta,
        player.value.duration,
      ),
    );
  }

  Future<void> _quality(String next) async {
    if (next == quality) return;
    final position = controller?.value.position ?? Duration.zero;
    final playing = controller?.value.isPlaying ?? false;
    quality = next;
    await _initialize(next, autoplay: playing, resumeAt: position);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    checkpoint?.cancel();
    controller?.removeListener(_refresh);
    unawaited(_saveProgress());
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = controller;
    final ready = player?.value.isInitialized ?? false;
    final value = player?.value;
    final ratio = ready && value!.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
    return ClipRRect(
      borderRadius: widget.fullscreen ? BorderRadius.zero : TradeXRadii.card,
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ready) VideoPlayer(player!),
              if (!started && widget.thumbnailPath.isNotEmpty)
                CourseThumbnail(
                  thumbnailPath: widget.thumbnailPath,
                  height: double.infinity,
                ),
              if (loading || (ready && value!.isBuffering))
                const Center(
                  child: CircularProgressIndicator(
                    color: TradeXColors.goldBright,
                  ),
                ),
              if (error != null)
                PlayerError(
                  onRetry: () => _initialize(quality, autoplay: true),
                ),
              if (ready && error == null) ...[
                if (!started)
                  Center(
                    child: IconButton.filled(
                      key: const ValueKey('video-play-overlay'),
                      onPressed: () async {
                        started = true;
                        await player!.play();
                        if (mounted) setState(() {});
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: TradeXColors.goldBright,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.square(58),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 34),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: PlayerControls(
                    controller: player!,
                    quality: quality,
                    qualities: widget.sources.keys.toList(growable: false),
                    speed: speed,
                    muted: muted,
                    fullscreen: widget.fullscreen,
                    onBack: () => _seek(const Duration(seconds: -10)),
                    onForward: () => _seek(const Duration(seconds: 10)),
                    onQuality: _quality,
                    onSpeed: (next) async {
                      speed = next;
                      await player.setPlaybackSpeed(next);
                      if (mounted) setState(() {});
                    },
                    onMute: () async {
                      muted = !muted;
                      await player.setVolume(muted ? 0 : 1);
                      if (mounted) setState(() {});
                    },
                    onFullscreen: widget.onFullscreen == null
                        ? null
                        : () async {
                            await player.pause();
                            await _saveProgress();
                            widget.onFullscreen!();
                          },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.controller,
    required this.quality,
    required this.qualities,
    required this.speed,
    required this.muted,
    required this.fullscreen,
    required this.onBack,
    required this.onForward,
    required this.onQuality,
    required this.onSpeed,
    required this.onMute,
    required this.onFullscreen,
  });
  final VideoPlayerController controller;
  final String quality;
  final List<String> qualities;
  final double speed;
  final bool muted, fullscreen;
  final VoidCallback onBack, onForward, onMute;
  final ValueChanged<String> onQuality;
  final ValueChanged<double> onSpeed;
  final VoidCallback? onFullscreen;
  @override
  Widget build(BuildContext context) {
    final duration = controller.value.duration;
    final position = controller.value.position;
    final max = duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();
    final current = position.inMilliseconds.toDouble().clamp(0, max).toDouble();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xF0080909)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 20, 5, 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              key: const ValueKey('video-progress-slider'),
              value: current,
              max: max,
              activeColor: TradeXColors.goldBright,
              onChanged: (v) =>
                  controller.seekTo(Duration(milliseconds: v.round())),
            ),
            Row(
              children: [
                PlayerIcon(
                  tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
                  icon: controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: () => controller.value.isPlaying
                      ? controller.pause()
                      : controller.play(),
                ),
                PlayerIcon(
                  tooltip: 'Back 10 seconds',
                  icon: Icons.replay_10_rounded,
                  onTap: onBack,
                ),
                PlayerIcon(
                  tooltip: 'Forward 10 seconds',
                  icon: Icons.forward_10_rounded,
                  onTap: onForward,
                ),
                Text(
                  '${videoClock(position)} / ${videoClock(duration)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
                const Spacer(),
                PopupMenuButton<double>(
                  tooltip: 'Playback speed',
                  initialValue: speed,
                  onSelected: onSpeed,
                  itemBuilder: (_) => const [.5, 1.0, 1.25, 1.5, 2.0]
                      .map((v) => PopupMenuItem(value: v, child: Text('${v}x')))
                      .toList(),
                  child: Text(
                    '${speed}x',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Video quality',
                  initialValue: quality,
                  onSelected: onQuality,
                  itemBuilder: (_) => qualities
                      .map((v) => PopupMenuItem(value: v, child: Text(v)))
                      .toList(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      quality,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
                PlayerIcon(
                  tooltip: muted ? 'Unmute' : 'Mute',
                  icon: muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  onTap: onMute,
                ),
                if (onFullscreen != null)
                  PlayerIcon(
                    tooltip: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                    icon: fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    onTap: onFullscreen!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerIcon extends StatelessWidget {
  const PlayerIcon({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    color: Colors.white,
    onPressed: onTap,
    icon: Icon(icon, size: 19),
  );
}

class PlayerError extends StatelessWidget {
  const PlayerError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 36),
        const SizedBox(height: 8),
        const Text(
          'Video could not be played.',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

Duration boundedVideoPosition(Duration value, Duration duration) {
  if (value < Duration.zero) return Duration.zero;
  if (duration > Duration.zero && value > duration) return duration;
  return value;
}

String videoClock(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return duration.inHours > 0
      ? '${duration.inHours}:$minutes:$seconds'
      : '$minutes:$seconds';
}

Map<String, String> playbackSources(JsonMap token) {
  final result = <String, String>{};
  final auto = LearnRepository.text(
    token['playback_url'],
    LearnRepository.text(token['url']),
  );
  if (auto.isNotEmpty) result['Auto'] = auto;
  for (final raw in LearnRepository.list(
    token['renditions'] ?? token['qualities'] ?? token['sources'],
  )) {
    final rendition = LearnRepository.map(raw);
    final url = LearnRepository.text(
      rendition['playback_url'],
      LearnRepository.text(rendition['url']),
    );
    if (url.isEmpty) continue;
    final height = LearnRepository.number(
      rendition['height'] ?? rendition['resolution_height'],
    );
    final label = height > 0
        ? '${height}p'
        : LearnRepository.text(
            rendition['label'],
            LearnRepository.text(rendition['quality']),
          );
    if (label.isNotEmpty) result[label] = url;
  }
  return result;
}
