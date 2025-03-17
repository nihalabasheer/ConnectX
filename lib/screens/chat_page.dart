import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_message.dart';
import '../services/chat_storage.dart';
import '../services/wifi_p2p_manager.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import 'videocall.dart';

class ChatPage extends StatefulWidget {
  final String deviceName;
  final String deviceAddress;
  final WifiP2PInfo? wifiP2PInfo;

  const ChatPage({
    super.key,
    required this.deviceName,
    required this.deviceAddress,
    this.wifiP2PInfo,
  });

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  final ChatStorage _chatStorage = ChatStorage();
  String socketStatus = 'Socket inactive';
  bool isVideoCallActive = false; // Controls visibility of video call UI

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkConnectionAndSocket();
    WifiP2PManager.instance.setMessageHandler(_handleIncomingMessage);
  }

  Future<void> _checkConnectionAndSocket() async {
    bool isConnected = widget.wifiP2PInfo?.isConnected ?? false;
    bool isGroupOwner = widget.wifiP2PInfo?.isGroupOwner ?? false;

    try {
      if (isConnected) {
        if (isGroupOwner) {
          await startSocket();
          snack('Socket created!');
        } else {
          await connectToSocket();
          snack('Connected to socket!');
        }
      } else {
        snack('Not connected to any Wi-Fi P2P network.');
      }
    } catch (e) {
      snack('Error: ${e.toString()}');
    }
  }

  Future<void> _loadMessages() async {
    List<ChatMessage> messages = await _chatStorage.loadChat(widget.deviceAddress);
    setState(() {
      _messages = messages;
    });
  }

  void _sendMessage(String message) async {
    if (message.isEmpty) return;
    ChatMessage chatMessage = ChatMessage(sender: 'Me', message: message);
    setState(() {
      _messages.add(chatMessage);
    });
    await _chatStorage.saveChat(widget.deviceAddress, _messages);
    _controller.clear();
    WifiP2PManager.instance.sendStringToSocket(message);
  }

  Future<void> startSocket() async {
    if (widget.wifiP2PInfo != null) {
      bool started = await WifiP2PManager.instance.startSocket(
        groupOwnerAddress: widget.wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/ConnectX/",
        maxConcurrentDownloads: 2,
        deleteOnError: true,
        onConnect: (name, address) {
          snack("$name connected to socket with address: $address");
          setState(() {
            socketStatus = 'Socket active';
          });
          WifiP2PManager.instance.sendStringToSocket('Socket active');
        },
        transferUpdate: (transfer) {
          if (transfer.completed) {
            snack(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
        },
        receiveString: (req) async {
          _handleIncomingMessage(req);
        },
      );
      snack("open socket: $started");
    }
  }

  Future<void> connectToSocket() async {
    if (widget.wifiP2PInfo != null) {
      await WifiP2PManager.instance.connectToSocket(
        groupOwnerAddress: widget.wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/ConnectX/",
        maxConcurrentDownloads: 3,
        deleteOnError: true,
        onConnect: (address) {
          snack("connected to socket: $address");
        },
        transferUpdate: (transfer) {
          if (transfer.completed) {
            snack(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
        },
        receiveString: (req) async {
          _handleIncomingMessage(req);
        },
      );
    }
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
    List<TransferUpdate>? updates =
    await WifiP2PManager.instance.sendFiletoSocket(
      [
        filePath,
      ],
    );
    print(updates);
  }

  void _handleIncomingMessage(dynamic message) {
    if (message is String) {
      if (message.startsWith('{')) {
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'offer' || data['type'] == 'answer' || data['type'] == 'iceCandidate') {
            // Forward signaling data to the VideoCallWidget
            if (isVideoCallActive) {
              _videoCallKey.currentState?._handleSignalingData(data);
            }
          } else {
            _handleJsonMessage(message);
          }
        } catch (e) {
          debugPrint("Error decoding JSON message: $e");
        }
      } else {
        _handleTextMessage(message);
      }
    }
  }

  void _handleTextMessage(String message) {
    ChatMessage receivedMessage = ChatMessage(sender: 'Other', message: message);
    setState(() {
      _messages.add(receivedMessage);
    });
    _chatStorage.saveChat(widget.deviceAddress, _messages);
  }

  void _handleJsonMessage(String message) {
    try {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'call_initiation':
          setState(() {
            isVideoCallActive = true; // Show video call UI
          });
          break;
        case 'call_end':
          setState(() {
            isVideoCallActive = false; // Hide video call UI
          });
          break;
        default:
          debugPrint("Unknown message type: ${data['type']}");
          break;
      }
    } catch (e) {
      debugPrint("Error decoding JSON message: $e");
    }
  }

  void _endVideoCall() {
    setState(() {
      isVideoCallActive = false;
    });
    WifiP2PManager.instance.sendStringToSocket(jsonEncode({
      'type': 'call_end',
      'peerId': widget.deviceAddress,
    }));
  }

  Future<void> requestManageAllFilesPermissionAndSendFile() async {
    // Request permission to manage all files (MANAGE_EXTERNAL_STORAGE)
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      await sendFile(true);
    } else {
      print('Permission denied to manage all files.');
    }
  }

  void snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 11.0),
          child: Text(widget.deviceName),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Start Video Call',
            onPressed: () {
              setState(() {
                isVideoCallActive = true; // Show video call UI
              });
              WifiP2PManager.instance.sendStringToSocket(jsonEncode({
                'type': 'call_initiation',
                'peerId': widget.deviceAddress,
              }));
            },
          ),
        ],
        flexibleSpace: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 72.0, bottom: 3.0),
            child: Text(
              socketStatus,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    bool isSender = message.sender == 'Me';
                    return Align(
                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isSender ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () async {
                        await requestManageAllFilesPermissionAndSendFile();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _sendMessage(_controller.text);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Video Call Overlay
          if (isVideoCallActive)
            Positioned(
              bottom: 80,
              right: 10,
              child: VideoCallWidget(
                peerId: widget.deviceName,
                onEndCall: _endVideoCall,
              ),
            ),
        ],
      ),
    );
  }
}

