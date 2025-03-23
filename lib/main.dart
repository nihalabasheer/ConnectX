import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/homepage.dart';
import 'screens/first_time_login.dart';
import 'provider/theme_provider.dart';
import '../services/wifi_p2p_manager.dart';
import 'screens/splash_screen.dart';
import 'screens/homepage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
  await WiFiManagerService.initializeWiFiManager();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(isFirstTime: isFirstTime), // Correct placement for 'home'
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    // Get the current theme state from ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ConnectX',
      debugShowCheckedModeBanner: false,
      /*theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.purple,
          elevation: 0,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 14, fontFamily: 'Roboto'),
        ),
      ),*/
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(), // Optionally define a dark theme
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light, // Apply theme globally
      home: SplashScreen(isFirstTime: isFirstTime), // Set the splash screen as the first screen,
    );
  }
}

class WiFiManagerService {
  static Future<void> initializeWiFiManager() async {
    WifiP2PManager.instance.initialize();
    WifiP2PManager.instance.register();
    WifiP2PManager.instance.closeSocket();
    WifiP2PManager.instance.removeGroup();
    WifiP2PManager.instance.discover();
  }
}