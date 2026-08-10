import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session.dart';
import 'admin_destinations_screen.dart';
import 'dashboard_screen.dart';
import 'destinations_screen.dart';
import 'itineraries_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'recommendations_screen.dart';

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

    final pages = [
      DashboardScreen(onSeeAll: (i) => setState(() => _index = i), onSearch: _search),
      DestinationsScreen(key: ValueKey(_destinationsQuery), initialQuery: _destinationsQuery),
      const RecommendationsScreen(),
      const ItinerariesScreen(),
      const MapScreen(),
      if (session.isAdmin) const AdminDestinationsScreen(),
    ];
    final titles = [
      'Home',
      'Destinations',
      'Recommendations',
      'My Itineraries',
      'Map',
      if (session.isAdmin) 'Manage Destinations',
    ];
    final navDestinations = [
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.explore), label: 'Destinations'),
      const NavigationDestination(icon: Icon(Icons.recommend), label: 'For You'),
      const NavigationDestination(icon: Icon(Icons.card_travel), label: 'Itineraries'),
      const NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
      if (session.isAdmin) const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];

    // Guard against a stale tab index if isAdmin flips and the tab count shrinks.
    final index = _index < pages.length ? _index : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          if (displayName != null && index != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(displayName, style: const TextStyle(color: Colors.white))),
            ),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Log out', onPressed: _logout),
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
