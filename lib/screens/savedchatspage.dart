import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/device_info_storage.dart';
import 'saved_chat.dart';

class SavedChatsPage extends StatelessWidget {
  const SavedChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceStorage deviceStorage = DeviceStorage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: FutureBuilder<List<Device>>(
        future: deviceStorage.loadSavedDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading saved devices'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No saved chats available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Device device = snapshot.data![index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Text(
                        device.deviceName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(device.deviceName),
                    subtitle: Text(device.deviceAddress),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedChat(
                            deviceName: device.deviceName,
                            deviceAddress: device.deviceAddress,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}