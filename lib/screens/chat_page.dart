import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_message.dart';
import '../services/aes.dart';
import '../services/chat_storage.dart';
import '../services/wifi_p2p_manager.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import '../services/settings_storage.dart';

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
  bool _isGroupOwner = false;

  @override
  void initState() {
    super.initState();
    _isGroupOwner = widget.wifiP2PInfo?.isGroupOwner ?? false;
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
    List<ChatMessage> messages =
        await _chatStorage.loadChat(widget.deviceAddress);
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
    WifiP2PManager.instance
        .sendStringToSocket(AESHelper.encryptMessage(message));
  }

  Future<String> _getDownloadPath() async {
    return await SettingsStorage.getDownloadLocation();
  }

  Future<void> startSocket() async {
    if (widget.wifiP2PInfo != null) {
      String downloadPath = await _getDownloadPath();

      bool started = await WifiP2PManager.instance.startSocket(
        groupOwnerAddress: widget.wifiP2PInfo!.groupOwnerAddress,
        downloadPath: downloadPath,
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
      String downloadPath = await _getDownloadPath();

      await WifiP2PManager.instance.connectToSocket(
        groupOwnerAddress: widget.wifiP2PInfo!.groupOwnerAddress,
        downloadPath: downloadPath,
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
      if (message == "Socket active") {
        setState(() {
          socketStatus = "Socket active";
        });
      } else {
        _handleTextMessage(message);
      }
    }
  }

  void _handleTextMessage(String message) {
    String decrypted = AESHelper.decryptMessage(message);
    ChatMessage receivedMessage =
        ChatMessage(sender: 'Other', message: decrypted);
    setState(() {
      _messages.add(receivedMessage);
    });
    _chatStorage.saveChat(widget.deviceAddress, _messages);
  }

  Future<void> requestManageAllFilesPermissionAndSendFile() async {
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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(left: 8, right: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF90CAF9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.deviceName.isNotEmpty
                              ? widget.deviceName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.deviceName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            socketStatus == 'Socket active'
                                ? 'Active'
                                : 'Inactive',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (socketStatus != 'Socket active' && !_isGroupOwner)
                Container(
                  margin: const EdgeInsets.fromLTRB(22, 5, 22, 0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Not connected',
                          style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: const Text('CONNECT',
                            style: TextStyle(fontSize: 14)),
                        onPressed: () async {
                          await connectToSocket();
                          setState(() => socketStatus = 'Connecting...');
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
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
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isSender = message.sender == 'Me';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: isSender
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isSender) ...[
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF90CAF9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.deviceName.isNotEmpty
                                              ? widget.deviceName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isSender
                                            ? const Color(0xFF4A90E2)
                                            : const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft: isSender
                                              ? const Radius.circular(18)
                                              : const Radius.circular(4),
                                          bottomRight: isSender
                                              ? const Radius.circular(4)
                                              : const Radius.circular(18),
                                        ),
                                      ),
                                      child: Text(
                                        message.message,
                                        style: TextStyle(
                                          color: isSender
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.attach_file,
                                  color: Color(0xFF4A90E2)),
                              onPressed:
                                  requestManageAllFilesPermissionAndSendFile,
                            ),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    hintText: 'Message',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onSubmitted: (text) => _sendMessage(text),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon:
                                    const Icon(Icons.send, color: Colors.white),
                                onPressed: () => _sendMessage(_controller.text),
                              ),
                            ),
                          ],
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
