import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCManager {
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  Future<void> initialize() async {
    // Configuration for the peer connection
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    // Create the peer connection
    _peerConnection = await createPeerConnection(configuration);

    // Get user media (camera and microphone)
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    // Add the local stream to the peer connection
    localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream!);
    });

    // Set up event listeners for ICE candidates and remote streams
    _peerConnection?.onIceCandidate = (candidate) {
      // Send the candidate to the remote peer via your signaling mechanism
    };

    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'video') {
        remoteStream = event.streams.first;
      }
    };
  }

  Future<void> createOffer() async {
    final offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);
    // Send the offer to the remote peer via your signaling mechanism
  }

  Future<void> createAnswer() async {
    final answer = await _peerConnection?.createAnswer();
    await _peerConnection?.setLocalDescription(answer!);
    // Send the answer to the remote peer via your signaling mechanism
  }

  void close() {
    _peerConnection?.close();
    _peerConnection = null;
  }
}
