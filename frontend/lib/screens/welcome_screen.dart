import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Shown right after a successful login or registration. Displays a welcome
/// message for a few seconds, then automatically continues to [HomeScreen].
class WelcomeScreen extends StatefulWidget {
  final String? name;

  const WelcomeScreen({super.key, this.name});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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
  Widget build(BuildContext context) {
    final name = widget.name;
    final greeting = (name == null || name.isEmpty) ? 'Welcome!' : 'Welcome, $name!';
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flight_takeoff, size: 72),
            const SizedBox(height: 16),
            Text(greeting, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Getting your trip ready...',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
