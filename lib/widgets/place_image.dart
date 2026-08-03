import 'package:flutter/material.dart';

/// Shows a place's photo when [assetPath] is set and the file has been
/// dropped into the project; otherwise shows a colorful icon placeholder so
/// the layout still looks finished before real photos arrive.
class PlaceImage extends StatelessWidget {
  final String? assetPath;
  final IconData icon;
  final Color color;
  final BorderRadius? borderRadius;

  const PlaceImage({
    super.key,
    required this.assetPath,
    required this.icon,
    required this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final path = assetPath;
    return ClipRRect(
      borderRadius: radius,
      child: path == null
          ? _placeholder()
          : Image.asset(
              path,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
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
}
