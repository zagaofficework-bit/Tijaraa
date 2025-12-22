import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class CloudFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> unreadCountStream(String? userId) {
    return _firestore.collection('notifications').snapshots().asyncMap((
      snapshot,
    ) async {
      try {
        // 1. Prepare the list of futures to fetch counts
        final List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [
          _firestore
              .collection('notifications')
              .where('userId', isNull: true)
              .where('isRead', isEqualTo: false)
              .get(),
          _firestore
              .collection('notifications')
              .where('userId', isEqualTo: 'global')
              .where('isRead', isEqualTo: false)
              .get(),
        ];

        // Add the user-specific query only if userId is valid
        if (userId != null && userId.isNotEmpty) {
          futures.add(
            _firestore
                .collection('notifications')
                .where('userId', isEqualTo: userId)
                .where('isRead', isEqualTo: false)
                .get(),
          );
        }

        // 2. Wait for all counts to return
        final List<QuerySnapshot<Map<String, dynamic>>> results =
            await Future.wait(futures);

        // 3. Sum the lengths. result.docs.length is an int, so '+' will work here.
        int totalUnread = 0;
        for (var res in results) {
          totalUnread += res.docs.length;
        }

        return totalUnread;
      } catch (e) {
        print("Error in unreadCountStream: $e");
        return 0;
      }
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
    String? userId,
  ) {
    // Since we can't use [null, 'global', userId] in one 'whereIn' filter,
    // we prioritize the user's specific notifications and 'global' tag.

    List<String> validIds = ['global'];
    if (userId != null && userId.isNotEmpty) validIds.add(userId);

    // This query matches Rule #2 for userId == auth.uid and userId == 'global'
    return _firestore
        .collection('notifications')
        .where('userId', whereIn: validIds)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 3. Mark all as read (Remains mostly the same, ensuring userId is valid)
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// 4. Add notification
  Future<void> addNotification({
    required String userId, // Pass 'global' for global alerts
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
