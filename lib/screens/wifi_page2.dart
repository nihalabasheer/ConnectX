import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wifi_p2p_manager.dart';
import 'dart:async';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_page.dart';
import '../services/device_info_storage.dart';
import '../models/device_model.dart';
import 'package:audioplayers/audioplayers.dart';


class WifiPage2 extends StatefulWidget {
  const WifiPage2({super.key});

  @override
  State<WifiPage2> createState() => _WifiPage2State();
}

class _WifiPage2State extends State<WifiPage2> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
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
    _streamWifiInfo = WifiP2PManager.instance.streamWifiP2PInfo().listen((event) {
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

  Future<void> saveOrCheckDevice(String deviceName, String deviceAddress) async {
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

  Future sendMessage() async {
    WifiP2PManager.instance.sendStringToSocket(msgText.text);
  }

  Future sendFile(bool phone) async {
    String? filePath = await FilesystemPicker.open(
      context: context,
      rootDirectory: Directory(phone ? "/storage/emulated/0/" : "/storage/"),
      fsType: FilesystemType.file,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
      showGoUp: true,
      folderIconColor: Colors.blue,
    );
    if (filePath == null) return;
    List<TransferUpdate>? updates = await WifiP2PManager.instance.sendFiletoSocket([filePath]);
    print(updates);
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
              snack(discovering == true ? "Discovery started" : "Discovery failed");
            }),
            _buildOption("Stop Discovery", Icons.stop, () async {
              Navigator.pop(context);
              bool? stopped = await WifiP2PManager.instance.stopDiscovery();
              snack(stopped == true ? "Stopped discovery" : "Failed to stop discovery");
            }),
            _buildOption("Create Group", Icons.group_add, () async {
              Navigator.pop(context);
              bool? created = await WifiP2PManager.instance.createGroup();
              snack(created == true ? "Group created" : "Failed to create group");
            }),
            _buildOption("Remove Group / Disconnect", Icons.group_off, () async {
              Navigator.pop(context);
              bool? removed = await WifiP2PManager.instance.removeGroup();
              snack(removed == true ? "Group removed/disconnected" : "Failed to remove group");
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
              bool granted = await WifiP2PManager.instance.askLocationPermission();
              snack(granted ? "Location permission granted" : "Location permission denied");
            }),
            _buildOption("Ask Storage Permission", Icons.sd_storage, () async {
              Navigator.pop(context);
              bool granted = await WifiP2PManager.instance.askStoragePermission();
              snack(granted ? "Storage permission granted" : "Storage permission denied");
            }),
            _buildOption("Enable Location", Icons.gps_fixed, () async {
              Navigator.pop(context);
              bool enabled = await WifiP2PManager.instance.enableLocationServices();
              snack(enabled ? "Location enabled" : "Failed to enable location");
            }),
            _buildOption("Enable Wi-Fi", Icons.wifi_tethering, () async {
              Navigator.pop(context);
              bool enabled = await WifiP2PManager.instance.enableWifiServices();
              snack(enabled ? "Wi-Fi enabled" : "Failed to enable Wi-Fi");
            }),
            _buildOption("Check Location Enabled", Icons.location_on, () async {
              Navigator.pop(context);
              bool? enabled = await WifiP2PManager.instance.checkLocationEnabled();
              snack(enabled == true ? "Location is enabled" : "Location is disabled");
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
                Text("isServiceDiscoveryCapable: ${peer.isServiceDiscoveryCapable}"),
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
                bool? connected = await WifiP2PManager.instance.connect(peer.deviceAddress);
                if(connected==true){
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

  Future<void> requestManageAllFilesPermissionAndSendFile() async {
    PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      await sendFile(true);
    } else {
      print('Permission denied to manage all files.');
    }
  }

  Future<List<Device>> loadSavedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getStringList('savedDevices') ?? [];
    return devicesJson.map((deviceString) {
      final deviceData = deviceString.split(',');
      return Device(deviceName: deviceData[0], deviceAddress: deviceData[1]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConnectX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: showWifiOptionsBottomSheet,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("IP: ${wifiP2PInfo == null ? "null" : wifiP2PInfo?.groupOwnerAddress}"),
              wifiP2PInfo != null
                  ? Text("connected: ${wifiP2PInfo?.isConnected}, isGroupOwner: ${wifiP2PInfo?.isGroupOwner}, groupFormed: ${wifiP2PInfo?.groupFormed}, groupOwnerAddress: ${wifiP2PInfo?.groupOwnerAddress}, clients: ${wifiP2PInfo?.clients}")
                  : const SizedBox.shrink(),
              const SizedBox(height: 10),
              const Text("PEERS:"),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: peers.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Text(
                          peers[index].deviceName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(peers[index].deviceName),
                      subtitle: Text("Address: ${peers[index].deviceAddress}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showPeerDetailsDialog(context, peers[index]);
                        },
                      ),
                      onTap: () async {
                        bool? connected = await WifiP2PManager.instance.connect(peers[index].deviceAddress);
                        if (connected == true) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                deviceName: peers[index].deviceName,
                                deviceAddress: peers[index].deviceAddress,
                                wifiP2PInfo: wifiP2PInfo,
                              ),
                            ),
                          );
                          saveOrCheckDevice(peers[index].deviceName, peers[index].deviceAddress);
                        } else {
                          snack("Failed to connect to ${peers[index].deviceName}");
                        }
                      },
                    ),
                  );
                },
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