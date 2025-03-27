import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_storage.dart';

class SavedChat extends StatefulWidget {
  final String deviceName;
  final String deviceAddress;

  const SavedChat({
    super.key,
    required this.deviceName,
    required this.deviceAddress,
  });

  @override
  SavedChatState createState() => SavedChatState();
}

class SavedChatState extends State<SavedChat> {
  List<ChatMessage> _messages = [];
  final ChatStorage _chatStorage = ChatStorage();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    List<ChatMessage> messages = await _chatStorage.loadChat(widget.deviceAddress);
    setState(() {
      _messages = messages;
    });
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
        title: Text(widget.deviceName),
      ),
      body: _messages.isEmpty
          ? const Center(
        child: Text(
          'No messages available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isSender = message.sender == 'Me';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSender
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                        color: isSender ? Colors.white : Colors.black,
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
    );
  }
}