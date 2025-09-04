import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsStorage {
  static const String _downloadLocationKey = 'download_location';

  static Future<String> getDownloadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString(_downloadLocationKey);

    if (savedPath != null && await Directory(savedPath).exists()) {
      return savedPath;
    }
    return await getDefaultDownloadLocation();
  }

  static Future<void> setDownloadLocation(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadLocationKey, path);
  }

  static Future<String> getDefaultDownloadLocation() async {
    if (Platform.isAndroid) {
      return "/storage/emulated/0/Download/ConnectX/";
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return "${directory.path}/ConnectX/Downloads";
    }
  }
}
