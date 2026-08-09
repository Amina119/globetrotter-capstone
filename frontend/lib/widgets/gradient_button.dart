import 'package:flutter/material.dart';

import '../theme/cameroon_colors.dart';

/// A premium-feeling primary call-to-action button: a gradient pill with a
/// soft glow shadow and a subtle press-scale animation, used for every
/// primary action on the auth screens (log in, register, reset, etc.).
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color>? colors;

  const GradientButton({super.key, required this.onPressed, required this.child, this.colors});

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = widget.colors ?? const [CameroonColors.green, CameroonColors.greenDark];

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled ? colors : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colors.last.withValues(alpha: _pressed ? 0.18 : 0.35),
                      blurRadius: _pressed ? 10 : 18,
                      offset: Offset(0, _pressed ? 3 : 8),
                    ),
                  ]
                : const [],
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
