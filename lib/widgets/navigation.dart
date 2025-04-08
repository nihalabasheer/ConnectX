import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../screens/recentchatspage.dart';
import '../screens/wifi_page2.dart';
import '../screens/settings.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});
  @override
  _NavigationState createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const WifiPage2(),
      SavedChatsPage(key: UniqueKey()),
      const SettingsPage(),
    ];
  }

  void _reloadSavedChats() {
    // Replace the SavedChatsPage with a new one to trigger a fresh FutureBuilder call
    setState(() {
      _pages[1] = SavedChatsPage(key: UniqueKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: isDarkMode ? Colors.black : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: GNav(
                  gap: 8,
                  backgroundColor: Colors.transparent,
                  color: isDarkMode ? Colors.white70 : Colors.grey[800],
                  activeColor: isDarkMode ? Colors.deepPurpleAccent : Colors.deepPurple,
                  tabBackgroundColor: isDarkMode
                      ? Colors.blueGrey[900]!
                      : Colors.blue.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    if (index == 1) {
                      _reloadSavedChats(); // Refresh saved chats when switching to "Chats"
                    }
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  tabs: const [
                    GButton(
                      icon: Icons.home,
                      text: 'Home',
                    ),
                    GButton(
                      icon: Icons.message,
                      text: 'Chats',
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
