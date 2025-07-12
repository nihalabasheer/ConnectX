import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/settings.dart';
import 'namechange.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  CustomDrawerState createState() => CustomDrawerState();
}

class CustomDrawerState extends State<CustomDrawer> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _changeUserName() async {
    showDialog(
      context: context,
      builder: (context) {
        return NameChangeDialog(
          currentUserName: userName,
          onNameChanged: (newUserName) {
            setState(() {
              userName = newUserName;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(userName),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _changeUserName,
                ),
              ],
            ),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text(userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SettingsPage())
              );
            },
          ),
          // Theme toggle button
          ListTile(
            leading: Icon(themeProvider.isDarkMode
                ? Icons.dark_mode
                : Icons.light_mode),
            title: Text(themeProvider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode'),
            onTap: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
