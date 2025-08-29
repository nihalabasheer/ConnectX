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
    List<ChatMessage> messages =
        await _chatStorage.loadChat(widget.deviceAddress);
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
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          widget.deviceName.isNotEmpty
                              ? widget.deviceName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            'Chat History',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Messages Section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _messages.isEmpty
                      ? const Center(
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
                                'No messages available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start a conversation to see messages here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isSender = message.sender == 'Me';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: isSender
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSender
                                            ? const Color(0xFF4A90E2)
                                            : const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isSender
                                              ? const Radius.circular(16)
                                              : const Radius.circular(4),
                                          bottomRight: isSender
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
