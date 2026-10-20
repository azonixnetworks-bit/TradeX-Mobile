import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/tradex_colors.dart';
import '../data/learn_repository.dart';

class CourseVideoPlayerScreen extends StatefulWidget {
  const CourseVideoPlayerScreen({
    super.key,
    required this.repository,
    required this.lessonUuid,
    required this.videoUuid,
    required this.title,
    required this.playbackUrl,
    this.resumeSeconds = 0,
  });

  final LearnRepository repository;
  final String lessonUuid;
  final String videoUuid;
  final String title;
  final String playbackUrl;
  final int resumeSeconds;

  @override
  State<CourseVideoPlayerScreen> createState() =>
      _CourseVideoPlayerScreenState();
}

class _CourseVideoPlayerScreenState extends State<CourseVideoPlayerScreen> {
  late final VideoPlayerController _controller;
  Timer? _checkpoint;
  bool _fullscreen = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.playbackUrl),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      final resume = Duration(seconds: widget.resumeSeconds);
      if (resume > Duration.zero && resume < _controller.value.duration) {
        await _controller.seekTo(resume);
      }
      _controller.addListener(_refresh);
      _checkpoint = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _saveProgress(),
      );
      if (mounted) setState(() {});
      await _controller.play();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _saveProgress() async {
    if (!_controller.value.isInitialized) return;
    final position = _controller.value.position.inSeconds;
    final duration = _controller.value.duration.inSeconds;
    await widget.repository.updateProgress(
      widget.lessonUuid,
      status: duration > 0 && position >= duration - 3
          ? 'COMPLETED'
          : 'IN_PROGRESS',
      videoUuid: widget.videoUuid,
      positionSeconds: position,
    );
  }

  Future<void> _toggleFullscreen() async {
    _fullscreen = !_fullscreen;
    if (_fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await _restoreSystemUi();
    }
    if (mounted) setState(() {});
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _checkpoint?.cancel();
    _controller.removeListener(_refresh);
    _saveProgress();
    _controller.dispose();
    if (_fullscreen) _restoreSystemUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.value.isInitialized;
    final duration = ready ? _controller.value.duration : Duration.zero;
    final position = ready ? _controller.value.position : Duration.zero;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(widget.title),
            ),
      body: SafeArea(
        child: Center(
          child: _error != null
              ? _PlayerError(onRetry: _retry)
              : !ready
              ? const CircularProgressIndicator(color: TradeXColors.goldBright)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio == 0
                              ? 16 / 9
                              : _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    _PlayerControls(
                      controller: _controller,
                      position: position,
                      duration: duration,
                      fullscreen: _fullscreen,
                      onFullscreen: _toggleFullscreen,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    await _initialize();
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.controller,
    required this.position,
    required this.duration,
    required this.fullscreen,
    required this.onFullscreen,
  });

  final VideoPlayerController controller;
  final Duration position;
  final Duration duration;
  final bool fullscreen;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    final maximum = duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();
    final value = position.inMilliseconds
        .toDouble()
        .clamp(0, maximum)
        .toDouble();
    return ColoredBox(
      color: const Color(0xEE090B0A),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: value,
              max: maximum,
              activeColor: TradeXColors.goldBright,
              onChanged: (next) =>
                  controller.seekTo(Duration(milliseconds: next.round())),
            ),
            Row(
              children: [
                IconButton(
                  color: Colors.white,
                  onPressed: () => controller.value.isPlaying
                      ? controller.pause()
                      : controller.play(),
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: () =>
                      controller.seekTo(position - const Duration(seconds: 10)),
                  icon: const Icon(Icons.replay_10_rounded),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: () =>
                      controller.seekTo(position + const Duration(seconds: 10)),
                  icon: const Icon(Icons.forward_10_rounded),
                ),
                Text(
                  '${_clock(position)} / ${_clock(duration)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  color: Colors.white,
                  tooltip: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                  onPressed: onFullscreen,
                  icon: Icon(
                    fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _clock(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 42),
        const SizedBox(height: 12),
        const Text(
          'The protected video could not be played. The playback token may have expired.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
