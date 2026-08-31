import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';

import '../utils/video_platform.dart';
import 'full_screen_video_player.dart';

/// Shows a place's video (preferred) or still photo when set and the asset
/// has been dropped into the project; otherwise shows a colorful icon
/// placeholder so the layout still looks finished before real media arrives.
class PlaceMedia extends StatelessWidget {
  final String? videoAsset;
  final String? imageAsset;
  final IconData icon;
  final Color color;
  final BorderRadius? borderRadius;

  /// Shown as the title of the full-screen, sound-on video player opened
  /// from the "watch video" button. Only needed when [videoAsset] is set.
  final String? placeName;

  const PlaceMedia({
    super.key,
    this.videoAsset,
    this.imageAsset,
    required this.icon,
    required this.color,
    this.borderRadius,
    this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: videoAsset == null
          ? _imageOrPlaceholder()
          : Stack(
              fit: StackFit.expand,
              children: [
                _PlaceVideo(assetPath: videoAsset!, fallback: _imageOrPlaceholder()),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _WatchVideoButton(assetPath: videoAsset!, title: placeName ?? ''),
                ),
              ],
            ),
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

/// Small overlay button on a place's (muted, looping) video thumbnail that
/// opens the same video full-screen, with sound, via [FullScreenVideoPlayer].
class _WatchVideoButton extends StatelessWidget {
  final String assetPath;
  final String title;

  const _WatchVideoButton({required this.assetPath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FullScreenVideoPlayer(assetPath: assetPath, title: title)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
