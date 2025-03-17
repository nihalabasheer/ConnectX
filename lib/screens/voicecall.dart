import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VoiceCallPage extends StatefulWidget {
  final String peerId;

  const VoiceCallPage({Key? key, required this.peerId}) : super(key: key);

  @override
  _VoiceCallPageState createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    // Configuration for the peer connection
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    // Create the peer connection
    _peerConnection = await createPeerConnection(configuration);

    // Get user media (microphone only)
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    // Add the local stream to the peer connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // Set up event listeners for ICE candidates and remote streams
    _peerConnection?.onIceCandidate = (candidate) {
      // Send the candidate to the remote peer via your signaling mechanism
    };

    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'audio') {
        setState(() {
          _remoteStream = event.streams.first;
        });
      }
    };

    // Create an offer to initiate the call
    final offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);
    // Send the offer to the remote peer via your signaling mechanism
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Call with ${widget.peerId}'),
      ),
      body: Center(
        child: Icon(
          Icons.mic,
          size: 100,
          color: Colors.blue,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // End the call
          _peerConnection?.close();
          Navigator.pop(context);
        },
        child: Icon(Icons.call_end),
        backgroundColor: Colors.red,
      ),
    );
  }
}
