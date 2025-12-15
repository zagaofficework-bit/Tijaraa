import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class FirebaseSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(bool)? onCallStateChanged;

  MediaStream? get localStream => _localStream;

  final String currentUserId;
  final String peerUserId;

  FirebaseSignalingService({
    required this.currentUserId,
    required this.peerUserId,
  });

  void _setupPeerConnectionListeners() {
    if (_peerConnection == null) return;

    // 1. Listen for new remote tracks/streams
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        // Typically, the first stream contains all tracks (audio/video)
        onRemoteStream?.call(event.streams[0]);
        // Set call state to active once remote media is received
        onCallStateChanged?.call(true);
      }
    };

    // 2. Listen for connection state changes (useful for detecting disconnects)
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      if (kDebugMode) {
        print('ICE Connection State: $state');
      }
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onCallStateChanged?.call(true);
      } else if (state ==
              RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        onCallStateChanged?.call(false);
        // Optional: Trigger hangUp/cleanup if connection fails
      }
    };
  }

  /// 🔹 Initialize a call (voice or video) - CALLER LOGIC
  Future<void> initCall({
    required bool isVideoCall,
    required MediaStream localStream,
  }) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);
    _setupPeerConnectionListeners(); // Setup listeners

    // Set local stream from the stream passed from UI
    _localStream = localStream;
    onLocalStream?.call(_localStream!);

    // Add local tracks to peer connection
    for (var track in _localStream!.getTracks()) {
      _peerConnection?.addTrack(track, _localStream!);
    }

    await _sendCallMessage(isVideoCall, isOutgoing: true);

    // Listen for ICE candidates and send to Callee's candidate collection
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        // Only send non-null candidates
        _firestore
            .collection('calls')
            .doc(
              peerUserId, // Store candidate for the peer (callee) to pick up
            )
            .collection('candidates')
            .add(candidate.toMap());
      }
    };

    // Create and set offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Send offer to Callee's main call document
    await _firestore.collection('calls').doc(peerUserId).set({
      'offer': offer.toMap(),
      'callerId': currentUserId,
      'isVideo': isVideoCall,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Listen for Answer from the Callee
    _firestore.collection('calls').doc(currentUserId).snapshots().listen((
      doc,
    ) async {
      // <-- ADDED async
      if (doc.exists && doc.data()!.containsKey('answer')) {
        final peer = _peerConnection;
        if (peer != null) {
          // FIX: Use getRemoteDescription() instead of the undefined currentRemoteDescription
          final remoteDesc = await peer.getRemoteDescription();
          if (remoteDesc == null) {
            // <-- Check if Remote Description is already set
            var answer = RTCSessionDescription(
              doc['answer']['sdp'],
              doc['answer']['type'],
            );
            await peer.setRemoteDescription(answer); // <-- ADDED await
            onCallStateChanged?.call(true);
          }
        }
      }
    });

    // Listen for ICE candidates from peer (Callee)
    _firestore
        .collection('calls')
        .doc(currentUserId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var data = change.doc.data()!;
              _peerConnection?.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
              // Clean up candidate from collection after adding
              change.doc.reference.delete();
            }
          }
        });
  }

  /// 🔹 Answer incoming call - CALLEE LOGIC
  Future<void> answerCall(Map<String, dynamic> offerData) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);
    _setupPeerConnectionListeners(); // Setup listeners

    // Fixed: Fetch local media stream for the answerer
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': offerData['isVideo'],
    });

    onLocalStream?.call(_localStream!); // Expose local stream

    // Add local tracks to peer connection
    for (var track in _localStream!.getTracks()) {
      _peerConnection?.addTrack(track, _localStream!);
    }

    // Listen for ICE candidates and send to Caller's candidate collection
    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _firestore
            .collection('calls')
            .doc(peerUserId) // Write candidate to the Caller's document
            .collection('candidates')
            .add(candidate.toMap());
      }
    };

    // Set remote description from offer
    RTCSessionDescription offer = RTCSessionDescription(
      offerData['offer']['sdp'],
      offerData['offer']['type'],
    );
    await _peerConnection!.setRemoteDescription(offer);

    // CRITICAL FIX RESTORED: Add a slight delay to allow the candidate handlers to attach
    await Future.delayed(const Duration(milliseconds: 500));

    // Create and send answer
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Send answer to Caller's main call document
    await _firestore.collection('calls').doc(peerUserId).update({
      'answer': answer.toMap(),
    });

    // Listen for ICE candidates from the caller
    _firestore
        .collection('calls')
        .doc(currentUserId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var data = change.doc.data()!;
              _peerConnection?.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
              change.doc.reference.delete();
            }
          }
        });

    await _sendCallMessage(offerData['isVideo'], isOutgoing: false);
  }

  /// 🔹 Handle call termination and cleanup Firestore data
  Future<void> hangUp() async {
    // 💡 NEW: Clean up Firestore signaling data
    try {
      // 1. Delete the main call document for both users
      await _firestore.collection('calls').doc(currentUserId).delete();
      await _firestore.collection('calls').doc(peerUserId).delete();

      // 2. Clear candidate collections for both users (Note: the rule handles this after read)
      // We still try to delete in case of failure or if the rule wasn't strictly enforced before.
      var callerCandidates = await _firestore
          .collection('calls')
          .doc(currentUserId)
          .collection('candidates')
          .get();
      for (var doc in callerCandidates.docs) {
        await doc.reference.delete();
      }
      var peerCandidates = await _firestore
          .collection('calls')
          .doc(peerUserId)
          .collection('candidates')
          .get();
      for (var doc in peerCandidates.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during hangUp Firestore cleanup: $e');
      }
    }

    dispose();
    onCallStateChanged?.call(false); // Notify UI of disconnect
  }

  /// 🔹 Send a system message to chat (like WhatsApp call logs)
  Future<void> _sendCallMessage(
    bool isVideo, {
    required bool isOutgoing,
  }) async {
    final type = isVideo ? 'video' : 'voice';
    final emoji = isVideo ? '📹' : '📞';

    try {
      await _firestore.collection('chats').add({
        'senderId': currentUserId,
        'receiverId': peerUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system_call_log', // Using the type from your original UI files
        'text': isOutgoing
            ? 'You ${type} called this user.'
            : 'This user ${type} called you.',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending call message: $e');
      }
    }
  }

  /// 🔹 Generate unique chat ID between two users
  String _getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  /// 🔹 Clean up when done
  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    _peerConnection = null;
  }
}
