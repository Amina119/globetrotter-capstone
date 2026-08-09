import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';

import '../utils/video_platform.dart';

/// Shows a place's video (preferred) or still photo when set and the asset
/// has been dropped into the project; otherwise shows a colorful icon
/// placeholder so the layout still looks finished before real media arrives.
class PlaceMedia extends StatelessWidget {
  final String? videoAsset;
  final String? imageAsset;
  final IconData icon;
  final Color color;
  final BorderRadius? borderRadius;

  const PlaceMedia({
    super.key,
    this.videoAsset,
    this.imageAsset,
    required this.icon,
    required this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: videoAsset != null
          ? _PlaceVideo(assetPath: videoAsset!, fallback: _imageOrPlaceholder())
          : _imageOrPlaceholder(),
    );
  }

  Widget _imageOrPlaceholder() {
    final path = imageAsset;
    if (path == null) return _placeholder(icon, color);
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder(icon, color),
    );
  }
}

Widget _placeholder(IconData icon, Color color) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.55)],
      ),
    ),
    child: Center(child: Icon(icon, color: Colors.white, size: 36)),
  );
}

/// Looping, muted video for a place thumbnail/hero. Falls back to [fallback]
/// (still photo or icon placeholder) if the asset is missing or fails to load.
class _PlaceVideo extends StatefulWidget {
  final String assetPath;
  final Widget fallback;

  const _PlaceVideo({required this.assetPath, required this.fallback});

  @override
  State<_PlaceVideo> createState() => _PlaceVideoState();
}

class _PlaceVideoState extends State<_PlaceVideo> {
  VideoPlayerController? _videoPlayerController;
  mk.Player? _player;
  mkv.VideoController? _mediaKitController;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (useMediaKitVideo) {
      final player = mk.Player();
      _player = player;
      _mediaKitController = mkv.VideoController(player);
      player.setPlaylistMode(mk.PlaylistMode.loop);
      player.setVolume(0);
      player.open(mk.Media('asset:///${widget.assetPath}')).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
    } else {
      final controller = VideoPlayerController.asset(widget.assetPath);
      _videoPlayerController = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() {});
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
    if (_failed) return widget.fallback;

    if (useMediaKitVideo) {
      final controller = _mediaKitController;
      if (controller == null) return widget.fallback;
      return mkv.Video(controller: controller, controls: mkv.NoVideoControls, fit: BoxFit.cover);
    }
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return widget.fallback;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
