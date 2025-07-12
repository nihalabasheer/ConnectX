import 'dart:convert';

class Device {
  final String deviceName;
  final String deviceAddress;

  Device({
    required this.deviceName,
    required this.deviceAddress,
  });

  String toJsonString() {
    final Map<String, dynamic> data = {
      'deviceName': deviceName,
      'deviceAddress': deviceAddress,
    };
    return jsonEncode(data);
  }

  factory Device.fromJsonString(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return Device(
      deviceName: data['deviceName'],
      deviceAddress: data['deviceAddress'],
    );
  }
}
