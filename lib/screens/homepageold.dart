import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import '../screens/wifi_page2.dart';
import '../widgets/drawer.dart';
import 'chat_page.dart';
import '../services/wifi_p2p_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WifiP2PInfo? wifiP2PInfo;
  List<DiscoveredPeers> peers = [];
  List<DiscoveredPeers> connectedDevices = [];
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _streamPeers?.cancel();
    super.dispose();
  }

  void _initialize() async {
    await WifiP2PManager.instance.discover();
    _streamPeers = WifiP2PManager.instance.streamPeers().listen((event) {
      setState(() {
        peers = event;
      });
    });
    _streamWifiInfo = WifiP2PManager.instance.streamWifiP2PInfo().listen((event) {
      setState(() {
        wifiP2PInfo = event;
      });
    });
  }

  void _connectToPeer(DiscoveredPeers peer) async {
    bool? connected = await WifiP2PManager.instance.connect(peer.deviceAddress);
    if (connected == true) {
      setState(() {
        connectedDevices.add(peer);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(connected == true
            ? 'Connected to ${peer.deviceName}'
            : 'Failed to connect to ${peer.deviceName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConnectX'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              WifiP2PManager.instance.discover();
            },
          ),
          IconButton(
            icon: const Icon(Icons.wifi),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WifiPage2()),
              );
            },
          ),
        ],

      ),
      body: Column(
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey,),
            Column(
              children: [Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0)),
                peers.isEmpty
                    ? const Center(
                  child: Text('No devices found. Searching...'),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: peers.length,
                  itemBuilder: (context, index) {
                    final peer = peers[index];
                    return ListTile(
                      title: Text(peer.deviceName),
                      subtitle: Text(peer.deviceAddress),
                      trailing: ElevatedButton(
                        onPressed: () => _connectToPeer(peer),
                        child: const Text('Connect'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                connectedDevices.isEmpty
                    ? const Center(
                  child: Text('No connected devices.'),
                )
                    : SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  child: ListView.builder(
                    itemCount: connectedDevices.length,
                    itemBuilder: (context, index) {
                      final device = connectedDevices[index];
                      return ListTile(
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
                              builder: (context) => ChatPage(
                                deviceName: connectedDevices[index].deviceName,
                                deviceAddress: connectedDevices[index].deviceAddress,
                                wifiP2PInfo: wifiP2PInfo,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ]),
      drawer: const CustomDrawer(),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.5,
    );
  }
}