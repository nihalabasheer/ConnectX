import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart'; // ✅ Import flutter_p2p_connection
import 'package:open_settings_plus/open_settings_plus.dart';
import 'homepageold.dart';
import 'first_time_login.dart';
import '../widgets/navigation.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstTime;

  const SplashScreen({super.key, required this.isFirstTime});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterP2pConnection _flutterP2p = FlutterP2pConnection();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), checkWifiStatus);
  }

  Future<void> checkWifiStatus() async {
    try {
      // ✅ Try to start peer discovery. This only works if Wi-Fi is ON
      bool discoveryStarted = await _flutterP2p.discover();

      if (discoveryStarted) {
        // ✅ If discovery started successfully (Wi-Fi is ON), proceed to next screen
        navigateToNextScreen();
      } else {
        // ❌ If discovery did not start, show dialog asking user to enable Wi-Fi
        showWifiDialog();
      }
    } catch (e) {
      // ❌ If error occurs, assume Wi-Fi is OFF and show dialog
      showWifiDialog();
    }
  }

  void showWifiDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wi-Fi Required'),
          content: const Text('This app requires Wi-Fi to function. Please enable Wi-Fi.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Wi-Fi Settings'),
              onPressed: () {
                (OpenSettingsPlus.shared as OpenSettingsPlusAndroid).wifi(); // ✅ Opens Wi-Fi settings
              },
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                checkWifiStatus(); // ✅ Check again if Wi-Fi is ON
              },
            ),
          ],
        );
      },
    );
  }

  void navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
        widget.isFirstTime ? FirstTimeLoginPage() : Navigation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D62),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/connectx_logo.png',
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'ConnectX',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Fast. Secure. Offline',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFE0E6ED),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}