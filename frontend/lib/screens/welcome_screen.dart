import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/cameroon_colors.dart';
import 'home_screen.dart';

/// Shown right after a successful login or registration. Displays a welcome
/// message for a few seconds, then automatically continues to [HomeScreen].
class WelcomeScreen extends StatefulWidget {
  final String? name;

  const WelcomeScreen({super.key, this.name});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final l10n = AppLocalizations.of(context)!;
    final greeting = (name == null || name.isEmpty) ? l10n.welcomeDefault : l10n.welcomeNamed(name);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: CameroonColors.heroGradient),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: CameroonColors.goldGradient,
                      boxShadow: [
                        BoxShadow(color: CameroonColors.gold.withValues(alpha: 0.45), blurRadius: 30, spreadRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.flight_takeoff_rounded, size: 56, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    greeting,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.gettingTripReady,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
