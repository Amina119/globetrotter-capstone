import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/session.dart';

void main() {
  runApp(const GlobeTrotterApp());
}

class GlobeTrotterApp extends StatelessWidget {
  const GlobeTrotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Session(),
      child: MaterialApp(
        title: 'GlobeTrotter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
        home: const _StartupGate(),
      ),
    );
  }
}

/// Restores a saved session (if any) before deciding whether to show the
/// login screen or jump straight to the authenticated home screen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    context.read<Session>().restore().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final session = context.watch<Session>();
    return session.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
