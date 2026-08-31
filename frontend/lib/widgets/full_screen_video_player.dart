import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';

import '../utils/video_platform.dart';

/// Full-screen video playback WITH sound, opened from a place's "Watch
/// video" button. Everywhere else in the app (place cards, tiles, the
/// detail screen header) the same video plays muted and looping as a
/// thumbnail — this is the one place it plays with real audio and
/// standard playback controls.
class FullScreenVideoPlayer extends StatefulWidget {
  final String assetPath;
  final String title;

  const FullScreenVideoPlayer({super.key, required this.assetPath, required this.title});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  mk.Player? _player;
  mkv.VideoController? _mediaKitController;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (useMediaKitVideo) {
      final player = mk.Player();
      _player = player;
      _mediaKitController = mkv.VideoController(player);
      player.setVolume(100);
      player.open(mk.Media('asset:///${widget.assetPath}')).then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
    } else {
      final controller = VideoPlayerController.asset(widget.assetPath);
      _videoPlayerController = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        controller
          ..setVolume(1.0)
          ..play();
        setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: _failed
              ? const Text('Could not play this video.', style: TextStyle(color: Colors.white70))
              : !_ready
                  ? const CircularProgressIndicator(color: Colors.white)
                  : useMediaKitVideo
                      ? mkv.Video(controller: _mediaKitController!, controls: mkv.AdaptiveVideoControls)
                      : _VideoPlayerWithControls(controller: _videoPlayerController!),
        ),
      ),
    );
  }
}

/// Minimal play/pause + scrub-bar controls for the `video_player` backend
/// (used on mobile and web) — that package ships the raw video surface only,
/// no chrome, so this wraps it with just enough UI to actually use it.
class _VideoPlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoPlayerWithControls({required this.controller});

  @override
  State<_VideoPlayerWithControls> createState() => _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<_VideoPlayerWithControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    setState(() {
      widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GestureDetector(
      onTap: _togglePlayPause,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.all(8),
                colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
