import 'package:Tijaraa/data/cubits/chat/firebase_signaling_call.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <<< ADDED
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
  late String _currentUserId; // <<< ADDED to store Firebase UID

  @override
  void initState() {
    super.initState();
    initRenderers();

    // CRITICAL FIX: Use the Firebase Authentication UID for security rules
    final currentUser = FirebaseAuth.instance.currentUser?.uid;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Handle unauthenticated state
        Navigator.of(context).pop();
      });
      return;
    }

    _currentUserId = currentUser; // Store the authenticated UID

    signaling = FirebaseSignalingService(
      currentUserId: _currentUserId, // <<< FIXED
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
    // 1. Get local audio/video stream (Required for both Caller and Callee)
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localRenderer.srcObject = localStream; // Attach stream to renderer

    // 2. Conditional Initialization
    if (widget.isCaller) {
      // CALLER LOGIC: Start the call and send the offer
      await signaling.initCall(isVideoCall: true, localStream: localStream!);
      _addCallLog('Video call started.');
    } else {
      // CALLEE LOGIC: Listen for the offer in our Firestore document and answer it
      _firestore.collection('calls').doc(_currentUserId).snapshots().listen((
        // <<< FIXED: Listen on current user's UID document
        doc,
      ) async {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          // CRITICAL: Only answer if an offer exists and no answer has been sent yet
          if (data.containsKey('offer') && !data.containsKey('answer')) {
            print("🎉 Callee received Offer, preparing to answer...");

            // The localStream is ready, call the signaling service's answer method
            await signaling.answerCall(data);

            // Log the call after successfully receiving the offer and answering.
            _addCallLog('Video call received.');
          }
        }
      });
    }

    // 3. Set initial states
    if (localStream != null) {
      _isMuted = !localStream!.getAudioTracks().first.enabled;
      _isCameraOn = localStream!.getVideoTracks().first.enabled;
    }
    setState(() {});
  }

  Future<void> _addCallLog(String statusText) async {
    await _firestore.collection('chats').add({
      'senderId': _currentUserId, // <<< FIXED
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
      // Assuming Helper.switchCamera is a utility function you have access to.
      // If not, replace with the correct WebRTC camera switching logic.
      // E.g., MediaStreamTrack.switchCamera() if using an updated package.
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
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white,
                          size: 30,
                        ),
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
                    _isCallActive ? 'Connected' : 'Ringing...',
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
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}
