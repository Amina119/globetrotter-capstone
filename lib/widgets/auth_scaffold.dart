import 'package:flutter/material.dart';

import '../theme/cameroon_colors.dart';

/// Shared visual frame for the login, register and forgot/reset password
/// screens: a green gradient header with the GlobeTrotter identity (rooted
/// in Nkolmong, Yaoundé) above a floating white card that holds the form.
class AuthScaffold extends StatelessWidget {
  final IconData heroIcon;
  final Widget child;
  final double maxWidth;

  const AuthScaffold({
    super.key,
    required this.child,
    this.heroIcon = Icons.flight_takeoff,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CameroonColors.greenDark, CameroonColors.green],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: CameroonColors.gold,
                          child: Icon(heroIcon, size: 34, color: CameroonColors.greenDark),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'GlobeTrotter',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              'Nkolmong, Yaoundé · Cameroon',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Card(
                          elevation: 10,
                          shadowColor: Colors.black45,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Center(child: _FlagStripe()),
                                const SizedBox(height: 18),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (canPop)
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white24),
                  ),
                ),
            ],
          ),
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
