import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/location_tracking_service.dart';
import 'map_page.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    MapPage(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Live map' : 'Settings'),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () => _centerOnUser(context),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Future<void> _centerOnUser(BuildContext context) async {
    final tracker = context.read<LocationTrackingService>();
    await tracker.refreshCurrentLocation();
  }
}
