import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // To get system default name
import '../provider/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late TextEditingController _deviceNameController;
  late SharedPreferences _prefs;
  bool _isEditingDeviceName = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Fetch stored device name from SharedPreferences (set in first-time login)
    String? storedDeviceName = _prefs.getString('userName');

    // Get the system default device name if nothing was stored
    String systemDeviceName = Platform.localHostname;

    // Use stored name if available, otherwise use the default system name
    _deviceNameController = TextEditingController(
      text: storedDeviceName ?? systemDeviceName,
    );

    setState(() {});
  }

  _saveDeviceName() async {
    await _prefs.setString('userName', _deviceNameController.text); // Use 'userName' key
    setState(() {
      _isEditingDeviceName = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device name saved successfully!')),
    );
  }

  _toggleEditDeviceName() {
    setState(() {
      if (_isEditingDeviceName) {
        _saveDeviceName();
      } else {
        _isEditingDeviceName = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Device Name",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.device_hub, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _deviceNameController,
                        decoration: const InputDecoration(border: InputBorder.none),
                        readOnly: !_isEditingDeviceName,
                        autofocus: _isEditingDeviceName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditingDeviceName ? Icons.check : Icons.edit,
                        color: _isEditingDeviceName ? Colors.green : Colors.blueAccent,
                      ),
                      onPressed: _toggleEditDeviceName,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            const Text(
              "Download Path",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "/storage/emulated/0/Download/ConnectX/",
                        style: const TextStyle(fontSize: 14),
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            const Text(
              "Appearance",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: isDarkMode ? Colors.orangeAccent : Colors.blueAccent,
                ),
                title: const Text('Dark Mode', style: TextStyle(fontSize: 14)),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
