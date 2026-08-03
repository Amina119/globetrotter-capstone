import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:video_player/video_player.dart';

import '../theme/cameroon_colors.dart';

// The video_player package has no Windows/Linux desktop implementation, so
// those platforms use media_kit_video instead.
bool get _useMediaKit =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

/// Shared visual frame for the login, register and forgot/reset password
/// screens.
///
/// On wide viewports (web/desktop) it renders a two-pane layout: a branded
/// panel introducing GlobeTrotter on the left, and the form on a clean
/// white pane on the right — the layout modern SaaS products use for
/// auth pages. On narrow viewports (phones) it falls back to a single
/// column with a compact brand header above the form.
class AuthScaffold extends StatelessWidget {
  final IconData heroIcon;
  final Widget child;
  final double maxWidth;

  /// Optional asset path (e.g. `assets/videos/login_hero.mp4`) for a looping,
  /// muted video shown behind the branded panel. Falls back to the plain
  /// gradient if omitted or if the asset fails to load.
  final String? heroVideoAsset;

  static const _wideBreakpoint = 900.0;

  const AuthScaffold({
    super.key,
    required this.child,
    this.heroIcon = Icons.flight_takeoff,
    this.maxWidth = 420,
    this.heroVideoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          return Stack(
            children: [
              if (isWide)
                Row(
                  children: [
                    SizedBox(
                      width: 440,
                      child: _BrandPanel(heroIcon: heroIcon, heroVideoAsset: heroVideoAsset),
                    ),
                    Expanded(
                      child: _FormPane(maxWidth: maxWidth, child: child),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _CompactBrandHeader(heroIcon: heroIcon),
                    Expanded(child: _FormPane(maxWidth: maxWidth, child: child)),
                  ],
                ),
              if (canPop)
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: isWide ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Branded left panel shown on wide (web/desktop) screens.
class _BrandPanel extends StatelessWidget {
  final IconData heroIcon;
  final String? heroVideoAsset;

  const _BrandPanel({required this.heroIcon, this.heroVideoAsset});

  static const _features = [
    ('Personalized recommendations', Icons.auto_awesome),
    ('Plan & manage your itineraries', Icons.map_outlined),
    ('Share trips with friends & family', Icons.people_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final hasVideo = heroVideoAsset != null;
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CameroonColors.greenDark, CameroonColors.green],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo) _BrandVideoBackground(assetPath: heroVideoAsset!),
          // Gradient scrim so text stays readable over the video (or acts
          // as the plain background when there is no video).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CameroonColors.greenDark.withValues(alpha: hasVideo ? 0.72 : 1),
                  CameroonColors.green.withValues(alpha: hasVideo ? 0.72 : 1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: CameroonColors.gold,
                      child: Icon(heroIcon, size: 24, color: CameroonColors.greenDark),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'GlobeTrotter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Your journey starts in\nNkolmbong, Yaoundé.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, height: 1.25),
                ),
                if (hasVideo) ...[
                  const SizedBox(height: 18),
                  _WatchWithSoundButton(onTap: () => _openVideoWithSound(context, heroVideoAsset!)),
                ],
                const SizedBox(height: 28),
                for (final f in _features) ...[
                  _FeatureRow(text: f.$1, icon: f.$2),
                  const SizedBox(height: 14),
                ],
                const Spacer(),
                const _FlagStripe(),
                const SizedBox(height: 10),
                Text(
                  'Nkolmbong, Yaoundé · Cameroon',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Looping, muted video shown behind the brand panel's content. Silently
/// falls back to nothing (leaving the gradient visible) if the asset is
/// missing or fails to load.
class _BrandVideoBackground extends StatefulWidget {
  final String assetPath;

  const _BrandVideoBackground({required this.assetPath});

  @override
  State<_BrandVideoBackground> createState() => _BrandVideoBackgroundState();
}

class _BrandVideoBackgroundState extends State<_BrandVideoBackground> {
  VideoPlayerController? _videoPlayerController;
  mk.Player? _player;
  mkv.VideoController? _mediaKitController;

  @override
  void initState() {
    super.initState();
    if (_useMediaKit) {
      final player = mk.Player();
      _player = player;
      _mediaKitController = mkv.VideoController(player);
      player.setPlaylistMode(mk.PlaylistMode.loop);
      player.setVolume(0);
      player.open(mk.Media('asset:///${widget.assetPath}'));
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
        // Asset missing or unsupported — the gradient background remains.
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
    if (_useMediaKit) {
      final controller = _mediaKitController;
      if (controller == null) return const SizedBox.shrink();
      return mkv.Video(controller: controller, controls: mkv.NoVideoControls, fit: BoxFit.cover);
    }
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
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

/// Pill button overlaid on the brand video inviting the user to watch it
/// full-size with its original audio.
class _WatchWithSoundButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WatchWithSoundButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 13,
                backgroundColor: CameroonColors.gold,
                child: Icon(Icons.play_arrow_rounded, size: 18, color: CameroonColors.greenDark),
              ),
              const SizedBox(width: 10),
              Text(
                'Watch with sound',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openVideoWithSound(BuildContext context, String assetPath) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => _VideoSoundDialog(assetPath: assetPath),
  );
}

/// Full-size video player with its original (unmuted) audio, opened from
/// the "Watch with sound" button. Separate controller/player from the
/// muted looping background so the two never interfere.
class _VideoSoundDialog extends StatefulWidget {
  final String assetPath;

  const _VideoSoundDialog({required this.assetPath});

  @override
  State<_VideoSoundDialog> createState() => _VideoSoundDialogState();
}

class _VideoSoundDialogState extends State<_VideoSoundDialog> {
  VideoPlayerController? _videoPlayerController;
  mk.Player? _player;
  mkv.VideoController? _mediaKitController;

  @override
  void initState() {
    super.initState();
    if (_useMediaKit) {
      final player = mk.Player();
      _player = player;
      _mediaKitController = mkv.VideoController(player);
      player.setVolume(100);
      player.open(mk.Media('asset:///${widget.assetPath}'));
    } else {
      final controller = VideoPlayerController.asset(widget.assetPath);
      _videoPlayerController = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        controller
          ..setVolume(1)
          ..play();
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _player?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: _buildPlayer()),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_useMediaKit) {
      final controller = _mediaKitController;
      if (controller == null) return const Center(child: CircularProgressIndicator(color: Colors.white));
      return mkv.Video(controller: controller);
    }
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          VideoPlayer(controller),
          if (!controller.value.isPlaying) const Icon(Icons.play_arrow, color: Colors.white, size: 64),
          Align(
            alignment: Alignment.bottomCenter,
            child: VideoProgressIndicator(controller, allowScrubbing: true, padding: const EdgeInsets.all(8)),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final IconData icon;

  const _FeatureRow({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: CameroonColors.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92))),
        ),
      ],
    );
  }
}

/// Compact brand header shown above the form on narrow (mobile) screens.
class _CompactBrandHeader extends StatelessWidget {
  final IconData heroIcon;

  const _CompactBrandHeader({required this.heroIcon});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CameroonColors.green,
                  child: Icon(heroIcon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  'GlobeTrotter',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: CameroonColors.greenDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _FlagStripe(),
          ],
        ),
      ),
    );
  }
}

/// White pane holding the actual form content, centered with a max width.
class _FormPane extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const _FormPane({required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// A small three-segment stripe echoing the Cameroonian flag.
class _FlagStripe extends StatelessWidget {
  const _FlagStripe();

  @override
  Widget build(BuildContext context) {
    Widget bar(Color color) => Container(
          width: 26,
          height: 4,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(CameroonColors.green),
        const SizedBox(width: 4),
        bar(CameroonColors.red),
        const SizedBox(width: 4),
        bar(CameroonColors.gold),
      ],
    );
  }
}
