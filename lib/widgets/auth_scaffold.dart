import 'package:flutter/material.dart';

import '../theme/cameroon_colors.dart';

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

  static const _wideBreakpoint = 900.0;

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
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          return Stack(
            children: [
              if (isWide)
                Row(
                  children: [
                    SizedBox(width: 440, child: _BrandPanel(heroIcon: heroIcon)),
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

  const _BrandPanel({required this.heroIcon});

  static const _features = [
    ('Personalized recommendations', Icons.auto_awesome),
    ('Plan & manage your itineraries', Icons.map_outlined),
    ('Share trips with friends & family', Icons.people_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CameroonColors.greenDark, CameroonColors.green],
        ),
      ),
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
