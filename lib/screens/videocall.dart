import 'package:flutter/material.dart';

class VideoCallWidget extends StatelessWidget {
  final String peerId;
  final VoidCallback onEndCall;

  const VideoCallWidget({
    super.key,
    required this.peerId,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Video Call with $peerId",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Placeholder for local video stream
          Container(
            width: 150,
            height: 100,
            color: Colors.grey,
            child: const Center(child: Text("Local Video")),
          ),
          const SizedBox(height: 10),
          // Placeholder for remote video stream
          Container(
            width: 150,
            height: 100,
            color: Colors.grey,
            child: const Center(child: Text("Remote Video")),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.videocam_off, color: Colors.white),
                onPressed: () {
                  // Handle video toggle
                },
              ),
              IconButton(
                icon: const Icon(Icons.mic_off, color: Colors.white),
                onPressed: () {
                  // Handle audio toggle
                },
              ),
              IconButton(
                icon: const Icon(Icons.call_end, color: Colors.red),
                onPressed: onEndCall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}