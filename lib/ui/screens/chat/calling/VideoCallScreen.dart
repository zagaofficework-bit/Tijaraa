import 'package:Tijaraa/data/cubits/chat/firebase_signaling_call.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallScreen extends StatefulWidget {
  final String userId;
  final String userName; // Added for UI
  final String userProfilePicture; // Added for UI
  final bool isCaller;

  const VideoCallScreen({
    Key? key,
    required this.userId,
    required this.userName, // Required
    required this.userProfilePicture, // Required
    required this.isCaller,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late FirebaseSignalingService signaling;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // WebRTC Renderers
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? localStream;

  // UI State
  bool _isCameraOn = true;
  bool _isMuted = false;
  bool _isFrontCamera = true;
  bool _isRemoteVideoActive = false;
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();
    initRenderers();
    final currentUser = HiveUtils.getUserId();
    signaling = FirebaseSignalingService(
      currentUserId: currentUser!,
      peerUserId: widget.userId,
    );

    // Setup signaling event handlers
    signaling.onLocalStream = (stream) {
      _localRenderer.srcObject = stream;
      localStream = stream;
      setState(() {});
    };
    signaling.onRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {
        _isRemoteVideoActive = true;
      });
    };
    signaling.onCallStateChanged = (isActive) {
      if (mounted) {
        setState(() {
          _isCallActive = isActive;
        });
      }
    };

    _startVideoCall();
  }

  void initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _startVideoCall() async {
    // 1. Get local audio/video stream
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localRenderer.srcObject = localStream; // Attach stream to renderer

    // 2. Initialize the call
    await signaling.initCall(isVideoCall: true, localStream: localStream!);

    // 3. Add call log message (Similar to VoiceCallScreen, keeping it simple here)
    if (widget.isCaller) {
      _addCallLog('Video call started.');
    }

    // Set initial states
    if (localStream != null) {
      _isMuted = !localStream!.getAudioTracks().first.enabled;
      _isCameraOn = localStream!.getVideoTracks().first.enabled;
    }
    setState(() {});
  }

  Future<void> _addCallLog(String statusText) async {
    await _firestore.collection('chats').add({
      'senderId': HiveUtils.getUserId(),
      'receiverId': widget.userId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'system_call_log',
      'text': widget.isCaller
          ? 'You video called this user.'
          : 'This user video called you.',
    });
  }

  void _toggleMute() {
    final audioTrack = localStream?.getAudioTracks().first;
    if (audioTrack != null) {
      audioTrack.enabled = !_isMuted;
      setState(() {
        _isMuted = !_isMuted;
      });
    }
  }

  void _toggleCamera() {
    final videoTrack = localStream?.getVideoTracks().first;
    if (videoTrack != null) {
      videoTrack.enabled = !_isCameraOn;
      setState(() {
        _isCameraOn = !_isCameraOn;
      });
    }
  }

  void _switchCamera() async {
    if (localStream != null) {
      await Helper.switchCamera(localStream!.getVideoTracks().first);
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    }
  }

  void _hangUp() {
    signaling.hangUp();
    _addCallLog('Video call ended.'); // Log end call
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    signaling.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Remote Video (Main View)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: _isRemoteVideoActive
                ? RTCVideoView(
              _remoteRenderer,
              objectFit:
              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
                : _buildCallWaitingPlaceholder(),
          ),

          // 2. Local Video (Small View)
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: _switchCamera, // Tap to switch camera
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isCameraOn
                    ? RTCVideoView(
                  _localRenderer,
                  mirror: _isFrontCamera,
                  objectFit: RTCVideoViewObjectFit
                      .RTCVideoViewObjectFitCover,
                )
                    : const Center(
                  child: Icon(Icons.videocam_off,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
          // 3. User Info (Overlay when remote video is inactive)
          if (!_isRemoteVideoActive)
            Positioned(
              top: MediaQuery.of(context).size.height / 3,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isCallActive ? 'Connecting...' : 'Ringing...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // 4. Controls (Bottom Bar)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute Button
                _buildCallButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.white24,
                  onTap: _toggleMute,
                ),
                // End Call Button
                _buildCallButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onTap: _hangUp,
                  iconColor: Colors.white,
                ),
                // Toggle Camera On/Off
                _buildCallButton(
                  icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                  color: _isCameraOn ? Colors.white24 : Colors.red,
                  onTap: _toggleCamera,
                ),
                // Switch Camera
                _buildCallButton(
                  icon: Icons.switch_camera,
                  color: Colors.white24,
                  onTap: _switchCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallWaitingPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: widget.userProfilePicture.isNotEmpty
                  ? NetworkImage(widget.userProfilePicture)
                  : null,
              child: widget.userProfilePicture.isEmpty
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),
            const Text(
              'Waiting for partner...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}