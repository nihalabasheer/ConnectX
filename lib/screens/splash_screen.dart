import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:open_settings_plus/open_settings_plus.dart';
import 'homepage.dart';
import 'first_time_login.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstTime;

  const SplashScreen({super.key, required this.isFirstTime});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), checkWifiStatus);
  }

  Future<void> checkWifiStatus() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.wifi) {
      navigateToNextScreen();
    } else {
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
              child: const Text('Open Settings'),
              onPressed: () {
                // ✅ Opens Wi-Fi settings (Android Only)
                (OpenSettingsPlus.shared as OpenSettingsPlusAndroid).wifi();
              },
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                checkWifiStatus();
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
        widget.isFirstTime ? FirstTimeLoginPage() : HomePage(),
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
