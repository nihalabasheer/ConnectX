import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wifi_p2p_manager.dart';
import 'dart:async';
import 'chat_page.dart';
import '../services/device_info_storage.dart';
import '../models/device_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui';

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
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        children: [
          _buildAppBarIcon(),
          const SizedBox(width: 16),
          _buildAppBarTitle(),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.wifi_tethering_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return const Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ConnectX',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.tune_rounded, color: Colors.white),
        onPressed: showWifiOptionsBottomSheet,
        tooltip: 'Network Options',
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: _buildGlassContainerDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNetworkStatusCard(),
                    const SizedBox(height: 24),
                    _buildDevicesHeader(),
                    const SizedBox(height: 16),
                    _buildDevicesList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGlassContainerDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNetworkStatusHeader(),
          const SizedBox(height: 16),
          _buildIPAddressRow(),
          if (wifiP2PInfo != null) ...[
            const SizedBox(height: 16),
            _buildStatusChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkStatusHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Network Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildIPAddressRow() {
    return _buildNetworkInfoRow(
      icon: Icons.public_rounded,
      label: 'IP Address',
      valueWidget: FutureBuilder<String?>(
        future: getSmoothIPAddress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildStatusBadge(
              'Fetching...',
              Colors.orange,
              0.2,
              0.3,
            );
          }
          return _buildStatusBadge(
            snapshot.data ?? 'Not available',
            snapshot.hasData ? const Color(0xFF93C5FD) : Colors.red,
            snapshot.hasData ? 0.3 : 0.2,
            snapshot.hasData ? 0.5 : 0.3,
            textColor: snapshot.hasData
                ? const Color.fromARGB(255, 251, 251, 251)
                : Colors.red,
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(
    String text,
    Color color,
    double backgroundAlpha,
    double borderAlpha, {
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: borderAlpha),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusIconButton(
          icon: Icons.wifi_rounded,
          isActive: wifiP2PInfo?.isConnected ?? false,
          tooltip: 'Connected',
        ),
        _buildStatusIconButton(
          icon: Icons.admin_panel_settings_rounded,
          isActive: wifiP2PInfo?.isGroupOwner ?? false,
          tooltip: 'Group Owner',
        ),
        _buildStatusIconButton(
          icon: Icons.group_rounded,
          isActive: wifiP2PInfo?.groupFormed ?? false,
          tooltip: 'Group Formed',
        ),
      ],
    );
  }

  Widget _buildStatusIconButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1E40AF).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF1E40AF)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.white70,
            ),
            const SizedBox(height: 4),
            Text(
              tooltip,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesHeader() {
    return Row(
      children: [
        _buildDevicesIcon(),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Available Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildDevicesIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.devices_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
        onPressed: () => WifiP2PManager.instance.discover(),
        tooltip: 'Refresh devices',
      ),
    );
  }

  Widget _buildDevicesList() {
    return Expanded(
      child: peers.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: peers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final peer = peers[index];
                return _buildEnhancedPeerCard(context, peer);
              },
            ),
    );
  }

  Widget _buildPeerAvatar(DiscoveredPeers peer) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          peer.deviceName.isNotEmpty ? peer.deviceName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPeerInfo(DiscoveredPeers peer) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            peer.deviceName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            peer.deviceAddress,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerInfoButton(DiscoveredPeers peer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
        onPressed: () => showPeerDetailsDialog(context, peer),
        tooltip: 'Device details',
      ),
    );
  }

  Widget _buildEnhancedPeerCard(BuildContext context, DiscoveredPeers peer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handlePeerConnection(context, peer),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPeerAvatar(peer),
                const SizedBox(width: 16),
                _buildPeerInfo(peer),
                _buildPeerInfoButton(peer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkInfoRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        valueWidget,
      ],
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF93C5FD).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: isActive
              ? const Color(0xFF93C5FD).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? const Color(0xFFDDD6FE) : Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No devices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull down to refresh or start discovery',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
