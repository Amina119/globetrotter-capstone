import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';
import '../theme/locale_controller.dart';
import 'admin_destinations_screen.dart';
import 'dashboard_screen.dart';
import 'destinations_screen.dart';
import 'chat_screen.dart';
import 'feedback_screen.dart';
import 'itineraries_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String _destinationsQuery = '';

  void _search(String query) {
    setState(() {
      _destinationsQuery = query;
      _index = 1;
    });
  }

  Future<void> _logout() async {
    await context.read<Session>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final displayName = (session.name != null && session.name!.isNotEmpty) ? session.name : session.email;
    final l10n = AppLocalizations.of(context)!;
    final localeController = context.watch<LocaleController>();
    final currentLang = localeController.locale?.languageCode ?? Localizations.localeOf(context).languageCode;

    final pages = [
      DashboardScreen(onSeeAll: (i) => setState(() => _index = i), onSearch: _search),
      DestinationsScreen(key: ValueKey(_destinationsQuery), initialQuery: _destinationsQuery),
      const FeedbackScreen(),
      const ItinerariesScreen(),
      const MapScreen(),
      const ChatScreen(),
      if (session.isAdmin) const AdminDestinationsScreen(),
    ];
    final titles = [
      l10n.navHome,
      l10n.navDestinations,
      l10n.navFeedback,
      l10n.titleMyItineraries,
      l10n.navMap,
      'Chat',
      if (session.isAdmin) l10n.titleManageDestinations,
    ];
    final navDestinations = [
      NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.navHome),
      NavigationDestination(icon: const Icon(Icons.explore), label: l10n.navDestinations),
      NavigationDestination(icon: const Icon(Icons.star_outline_rounded), selectedIcon: const Icon(Icons.star_rounded), label: l10n.navFeedback),
      NavigationDestination(icon: const Icon(Icons.card_travel), label: l10n.navItineraries),
      NavigationDestination(icon: const Icon(Icons.map), label: l10n.navMap),
      NavigationDestination(icon: const Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
      if (session.isAdmin) NavigationDestination(icon: const Icon(Icons.admin_panel_settings), label: l10n.navAdmin),
    ];

    // Guard against a stale tab index if isAdmin flips and the tab count shrinks.
    final index = _index < pages.length ? _index : 0;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: CameroonColors.heroGradient)),
        title: Text(titles[index]),
        actions: [
          if (displayName != null && index != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(displayName, style: const TextStyle(color: Colors.white))),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => localeController.setLocale(Locale(currentLang == 'fr' ? 'en' : 'fr')),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  currentLang == 'fr' ? 'FR' : 'EN',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: l10n.profileTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(l10n.profileTooltip)),
                  body: const ProfileScreen(),
                ),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: l10n.logoutTooltip, onPressed: _logout),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: navDestinations,
      ),
    );
  }
}
