import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../screens/wifi_page2.dart';
import '../screens/settings.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    WifiPage2(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(18.0), // Prevents sticking to edges
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30), // ✅ Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // ✅ Soft shadow
                blurRadius: 10, // ✅ Spread of shadow
                offset: const Offset(2,2), // ✅ Shadow height
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30), // ✅ Ensures inner rounding
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white, // Background color
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: GNav(
                  gap: 8,
                  backgroundColor: Colors.transparent, // ✅ Keeps shadow visible
                  color: isDarkMode ? Colors.white70 : Colors.grey[800],
                  activeColor: isDarkMode ? Colors.blueAccent : Colors.blue,
                  tabBackgroundColor: isDarkMode ? Colors.blueGrey[900]! : Colors.blue.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    Future.microtask(() {
                      if (mounted) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      }
                    });
                  },
                  tabs: const [
                    GButton(
                      icon: Icons.home,
                      text: 'Home',
                    ),
                    GButton(
                      icon: Icons.settings,
                      text: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
