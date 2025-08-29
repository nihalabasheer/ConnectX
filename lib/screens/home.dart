import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wifi_p2p_manager.dart';
import 'dart:async';
import 'chat_page.dart';
import '../services/device_info_storage.dart';
import '../models/device_model.dart';
import 'package:audioplayers/audioplayers.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _WifiPage2State();
}

class _WifiPage2State extends State<Home>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final TextEditingController msgText = TextEditingController();
  final DeviceStorage _deviceStorage = DeviceStorage();
  late Future<List<Device>> savedDevices;
  WifiP2PInfo? wifiP2PInfo;
  List<DiscoveredPeers> peers = [];
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    savedDevices = _deviceStorage.loadSavedDevices();
    _init();
  }

  void _init() async {
    _streamWifiInfo =
        WifiP2PManager.instance.streamWifiP2PInfo().listen((event) {
      setState(() {
        wifiP2PInfo = event;
      });
    });

    _streamPeers = WifiP2PManager.instance.streamPeers().listen((event) {
      setState(() {
        peers = event;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      WifiP2PManager.instance.unregister();
    } else if (state == AppLifecycleState.resumed) {
      WifiP2PManager.instance.register();
    }
  }

  Future<void> saveOrCheckDevice(
      String deviceName, String deviceAddress) async {
    await _deviceStorage.saveOrCheckDevice(deviceName, deviceAddress);
    setState(() {
      savedDevices = _deviceStorage.loadSavedDevices();
    });
  }

  Future<void> playConnectSound() async {
    await _audioPlayer.play(AssetSource('sounds/connected.mp3'));
  }

  Future closeSocketConnection() async {
    bool closed = WifiP2PManager.instance.closeSocket();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("closed: $closed"),
      ),
    );
  }

  Future<void> showWifiOptionsBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.90,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(10),
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            _buildOption("Start Discovery", Icons.search, () async {
              Navigator.pop(context);
              bool? discovering = await WifiP2PManager.instance.discover();
              snack(discovering == true
                  ? "Discovery started"
                  : "Discovery failed");
            }),
            _buildOption("Stop Discovery", Icons.stop, () async {
              Navigator.pop(context);
              bool? stopped = await WifiP2PManager.instance.stopDiscovery();
              snack(stopped == true
                  ? "Stopped discovery"
                  : "Failed to stop discovery");
            }),
            _buildOption("Create Group", Icons.group_add, () async {
              Navigator.pop(context);
              bool? created = await WifiP2PManager.instance.createGroup();
              snack(
                  created == true ? "Group created" : "Failed to create group");
            }),
            _buildOption("Remove Group / Disconnect", Icons.group_off,
                () async {
              Navigator.pop(context);
              bool? removed = await WifiP2PManager.instance.removeGroup();
              snack(removed == true
                  ? "Group removed/disconnected"
                  : "Failed to remove group");
            }),
            _buildOption("Get Group Info", Icons.info_outline, () async {
              Navigator.pop(context);
              var info = await WifiP2PManager.instance.groupInfo();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Group Info"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Group Name: ${info?.groupNetworkName}"),
                      Text("Passphrase: ${info?.passPhrase}"),
                      Text("Is Group Owner: ${info?.isGroupOwner}"),
                      Text("Clients: ${info?.clients}"),
                    ],
                  ),
                ),
              );
            }),
            _buildOption("Get IP Address", Icons.dns, () async {
              Navigator.pop(context);
              String? ip = await WifiP2PManager.instance.getIPAddress();
              snack(ip != null ? "IP: $ip" : "Failed to get IP");
            }),
            _buildOption("Ask Location Permission", Icons.pin_drop, () async {
              Navigator.pop(context);
              bool granted =
                  await WifiP2PManager.instance.askLocationPermission();
              snack(granted
                  ? "Location permission granted"
                  : "Location permission denied");
            }),
            _buildOption("Ask Storage Permission", Icons.sd_storage, () async {
              Navigator.pop(context);
              bool granted =
                  await WifiP2PManager.instance.askStoragePermission();
              snack(granted
                  ? "Storage permission granted"
                  : "Storage permission denied");
            }),
            _buildOption("Enable Location", Icons.gps_fixed, () async {
              Navigator.pop(context);
              bool enabled =
                  await WifiP2PManager.instance.enableLocationServices();
              snack(enabled ? "Location enabled" : "Failed to enable location");
            }),
            _buildOption("Enable Wi-Fi", Icons.wifi_tethering, () async {
              Navigator.pop(context);
              bool enabled = await WifiP2PManager.instance.enableWifiServices();
              snack(enabled ? "Wi-Fi enabled" : "Failed to enable Wi-Fi");
            }),
            _buildOption("Check Location Enabled", Icons.location_on, () async {
              Navigator.pop(context);
              bool? enabled =
                  await WifiP2PManager.instance.checkLocationEnabled();
              snack(enabled == true
                  ? "Location is enabled"
                  : "Location is disabled");
            }),
            _buildOption("Check Wi-Fi Enabled", Icons.wifi, () async {
              Navigator.pop(context);
              bool? enabled = await WifiP2PManager.instance.checkWifiEnabled();
              snack(enabled == true ? "Wi-Fi is enabled" : "Wi-Fi is disabled");
            }),
            _buildOption("Close Socket", Icons.cancel, () async {
              Navigator.pop(context);
              await closeSocketConnection();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  void snack(String msg) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(msg),
      ),
    );
  }

  void showPeerDetailsDialog(BuildContext context, DiscoveredPeers peer) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: AlertDialog(
          content: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("name: ${peer.deviceName}"),
                Text("address: ${peer.deviceAddress}"),
                Text("isGroupOwner: ${peer.isGroupOwner}"),
                Text(
                    "isServiceDiscoveryCapable: ${peer.isServiceDiscoveryCapable}"),
                Text("primaryDeviceType: ${peer.primaryDeviceType}"),
                Text("secondaryDeviceType: ${peer.secondaryDeviceType}"),
                Text("status: ${peer.status}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                bool? connected =
                    await WifiP2PManager.instance.connect(peer.deviceAddress);
                if (connected == true) {
                  playConnectSound();
                }
                snack("Connected: $connected");
              },
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Device>> loadSavedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getStringList('savedDevices') ?? [];
    return devicesJson.map((deviceString) {
      final deviceData = deviceString.split(',');
      return Device(deviceName: deviceData[0], deviceAddress: deviceData[1]);
    }).toList();
  }

  void _handlePeerConnection(BuildContext context, DiscoveredPeers peer) async {
    bool? connected = await WifiP2PManager.instance.connect(peer.deviceAddress);
    if (wifiP2PInfo?.isConnected == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            deviceName: peer.deviceName,
            deviceAddress: peer.deviceAddress,
            wifiP2PInfo: wifiP2PInfo,
          ),
        ),
      );
      saveOrCheckDevice(peer.deviceName, peer.deviceAddress);
    } else {
      snack("Connecting to ${peer.deviceName}");
    }
  }

  Future<String?> getSmoothIPAddress() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return await WifiP2PManager.instance.getIPAddress();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ConnectX',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: showWifiOptionsBottomSheet,
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.wifi,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Network Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: getSmoothIPAddress(),
                      builder: (context, snapshot) {
                        return Text(
                          'IP Address: ${snapshot.data ?? "Not Available"}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatusIndicator(
                          Icons.wifi,
                          'Connected',
                          wifiP2PInfo?.isConnected ?? false,
                        ),
                        _buildStatusIndicator(
                          Icons.person,
                          'Group Owner',
                          wifiP2PInfo?.isGroupOwner ?? false,
                        ),
                        _buildStatusIndicator(
                          Icons.group,
                          'Group Formed',
                          wifiP2PInfo?.groupFormed ?? false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Available Devices',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                WifiP2PManager.instance.discover();
                              },
                              child: const Text(
                                'Refresh',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: peers.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No devices found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Pull down to refresh or tap Refresh',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                itemCount: peers.length,
                                itemBuilder: (context, index) {
                                  final peer = peers[index];
                                  return _buildDeviceItem(
                                    peer.deviceName.isNotEmpty
                                        ? peer.deviceName[0].toUpperCase()
                                        : '?',
                                    peer.deviceName,
                                    peer.deviceAddress,
                                    peer,
                                  );
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

  Widget _buildStatusIndicator(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF4A90E2) : Colors.white70,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF4A90E2) : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceItem(String initial, String deviceName, String macAddress,
      DiscoveredPeers peer) {
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
          onTap: () => _handlePeerConnection(context, peer),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF90CAF9),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    initial,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      macAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showPeerDetailsDialog(context, peer),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4A90E2),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
