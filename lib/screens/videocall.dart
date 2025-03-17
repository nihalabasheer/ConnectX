import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallWidget extends StatefulWidget {
  final String peerId;
  final VoidCallback onEndCall;

  const VideoCallWidget({
    super.key,
    required this.peerId,
    required this.onEndCall,
  });

  @override
  VideoCallWidgetState createState() => VideoCallWidgetState();
}

class VideoCallWidgetState extends State<VideoCallWidget> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _initWebRTC();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _localStream?.dispose();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _initWebRTC() async {
    // Create a peer connection
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}, // Google's public STUN server
      ],
    });

    // Set up event listeners for the peer connection
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // Send the ICE candidate to the remote peer via your signaling mechanism
      _sendSignalingData({
        'type': 'iceCandidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      // Set the remote stream to the remote renderer
      _remoteRenderer.srcObject = stream;
    };

    // Get local media (camera and microphone)
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    // Add local stream to the peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Set the local stream to the local renderer
    _localRenderer.srcObject = _localStream;

    // Create an SDP offer and send it to the remote peer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _sendSignalingData({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  void _sendSignalingData(Map<String, dynamic> data) {
    // Send signaling data to the remote peer via your Wi-Fi P2P socket
    // Example: WifiP2PManager.instance.sendStringToSocket(jsonEncode(data));
  }

  void handleSignalingData(Map<String, dynamic> data) async {
    switch (data['type']) {
      case 'offer':
      // Handle incoming offer
        final offer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(offer);

        // Create an SDP answer and send it to the remote peer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _sendSignalingData({
          'type': 'answer',
          'sdp': answer.sdp,
        });
        break;

      case 'answer':
      // Handle incoming answer
        final answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
        break;

      case 'iceCandidate':
      // Handle incoming ICE candidate
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
        break;
    }
  }

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
            "Video Call with ${widget.peerId}",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Local video stream
          SizedBox(
            width: 150,
            height: 100,
            child: RTCVideoView(_localRenderer),
          ),
          const SizedBox(height: 10),
          // Remote video stream
          SizedBox(
            width: 150,
            height: 100,
            child: RTCVideoView(_remoteRenderer),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.videocam_off, color: Colors.white),
                onPressed: () {
                  // Toggle video
                  final videoTrack = _localStream!.getVideoTracks().first;
                  videoTrack.enabled = !videoTrack.enabled;
                },
              ),
              IconButton(
                icon: const Icon(Icons.mic_off, color: Colors.white),
                onPressed: () {
                  // Toggle audio
                  final audioTrack = _localStream!.getAudioTracks().first;
                  audioTrack.enabled = !audioTrack.enabled;
                },
              ),
              IconButton(
                icon: const Icon(Icons.call_end, color: Colors.red),
                onPressed: () {
                  // End the call
                  _peerConnection?.close();
                  widget.onEndCall();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}