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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    super.build(context);
    return Scaffold(
        appBar: AppBar(
          title: const Text('ConnectX',
              style:
                  TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.menu, color: theme.colorScheme.onPrimary),
              onPressed: showWifiOptionsBottomSheet,
              tooltip: 'Menu',
            ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Network Status',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        icon: Icons.network_check,
                        label: 'IP Address',
                        valueWidget: FutureBuilder<String?>(
                          future: getSmoothIPAddress(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                'Fetching...',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return Text(
                                snapshot.data ?? 'Not available',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              );
                            }
                          },
                        ),
                      ),
                      if (wifiP2PInfo != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildStatusChip(
                              'Connected',
                              wifiP2PInfo?.isConnected ?? false,
                              theme,
                            ),
                            _buildStatusChip(
                              'Group Owner',
                              wifiP2PInfo?.isGroupOwner ?? false,
                              theme,
                            ),
                            _buildStatusChip(
                              'Group Formed',
                              wifiP2PInfo?.groupFormed ?? false,
                              theme,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Available Devices',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      await await WifiP2PManager.instance.discover(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: peers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final peer = peers[index];
                      return _buildPeerCard(context, peer, theme, isDark);
                    },
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildStatusChip(String label, bool isActive, ThemeData theme) {
    return Chip(
      label: Text(label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          )),
      backgroundColor: isActive
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        valueWidget ??
            Text(
              value ?? 'Not available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
      ],
    );
  }

  Widget _buildPeerCard(BuildContext context, DiscoveredPeers peer,
      ThemeData theme, bool isDark) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async => _handlePeerConnection(context, peer),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(peer.deviceName[0].toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(peer.deviceName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Text(peer.deviceAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant),
                onPressed: () => showPeerDetailsDialog(context, peer),
                tooltip: 'Device details',
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
