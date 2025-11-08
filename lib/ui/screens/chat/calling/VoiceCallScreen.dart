import 'package:Tijaraa/data/cubits/chat/firebase_signaling_call.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VoiceCallScreen extends StatefulWidget {
  final String userId;
  final String userName; // Added for UI
  final String userProfilePicture; // Added for UI
  final bool isCaller;

  const VoiceCallScreen({
    Key? key,
    required this.userId,
    required this.userName, // Required
    required this.userProfilePicture, // Required
    required this.isCaller,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late FirebaseSignalingService signaling;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MediaStream? localStream;

  // UI state
  bool _isMuted = false;
  bool _isSpeakerOn = false; // For toggling speaker/earpiece
  bool _isCallActive = false; // To show connecting/active status

  @override
  void initState() {
    super.initState();
    final currentUser = HiveUtils.getUserId();
    signaling = FirebaseSignalingService(
      currentUserId: currentUser!,
      peerUserId: widget.userId,
    );
    // Listen for call state changes (e.g., connected, disconnected)
    signaling.onCallStateChanged = (isActive) {
      if (mounted) {
        setState(() {
          _isCallActive = isActive;
        });
      }
    };
    _startVoiceCall();
  }

  Future<void> _startVoiceCall() async {
    // 1. Get local audio stream
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    // 2. Initialize the call
    await signaling.initCall(isVideoCall: false, localStream: localStream!);

    // 3. Add call log message (Moved this to after a potential connection attempt)
    // For simplicity, keeping the log here for now, assuming initCall handles initial signaling.
    if (widget.isCaller) {
      _addCallLog('Voice call started.');
    }

    // Set initial state for audio
    if (localStream != null) {
      _isMuted = !localStream!.getAudioTracks().first.enabled;
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
          ? 'You voice called this user.'
          : 'This user voice called you.',
      // In a real app, you'd update this log with call duration/status (e.g., 'Missed Call', 'Call Ended')
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

  void _toggleSpeaker() {
    // WebRTC often manages audio routing via setSpeakerphoneOn, but it requires
    // access to native WebRTC API in dart. For simplicity, we just toggle a flag.
    // In a full implementation, you would use:
    // WebRTC.platformSpecificImplementation.setSpeakerphoneOn(!_isSpeakerOn);
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  void _hangUp() {
    signaling.hangUp();
    _addCallLog('Voice call ended.'); // Log end call
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    signaling.dispose();
    localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // WhatsApp style voice call UI
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          // Optional: Add a subtle dark gradient or background image
          gradient: LinearGradient(
            colors: [Colors.black, Colors.teal.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Header / User Info ---
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                child: Column(
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
                    const SizedBox(height: 15),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isCallActive ? 'Active Call' : 'Ringing...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Main Content (Waveform Placeholder) ---
              const Expanded(
                child: Center(
                  // Placeholder for a subtle audio waveform animation
                  child: Icon(
                    Icons.mic_none,
                    size: 80,
                    color: Colors.white38,
                  ),
                ),
              ),

              // --- Controls ---
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
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
                    // Speaker Button
                    _buildCallButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      color: _isSpeakerOn ? Colors.teal : Colors.white24,
                      onTap: _toggleSpeaker,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 30),
      ),
    );
  }
}