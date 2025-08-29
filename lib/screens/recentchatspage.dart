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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF357ABD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ConnectX',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Chats',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chats Section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Section Header
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                      ),

                      // Chats List
                      Expanded(
                        child: FutureBuilder<List<Device>>(
                          future: deviceStorage.loadSavedDevices(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A90E2),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Error loading saved devices',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No recent chats available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Start chatting with devices to see them here',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  Device device = snapshot.data![index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SavedChat(
                                                deviceName: device.deviceName,
                                                deviceAddress:
                                                    device.deviceAddress,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF90CAF9),
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  device.deviceName.isNotEmpty
                                                      ? device.deviceName[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    device.deviceName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    device.deviceAddress,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              color: Color(0xFF4A90E2),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
