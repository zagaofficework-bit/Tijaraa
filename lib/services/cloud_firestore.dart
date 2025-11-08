import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CloudFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of unread notifications count for a specific user
  Stream<int> unreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get notifications for a specific user
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
    String userId,
  ) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Add notification
  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
