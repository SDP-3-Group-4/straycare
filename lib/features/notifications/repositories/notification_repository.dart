import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:straycare_demo/services/firestore_service.dart';

class NotificationRepository {
  final FirestoreService _firestoreService;
  final String _collectionPath = 'notifications';

  NotificationRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService.instance;

  /// Send a notification
  Future<void> sendNotification({
    required String toUserId,
    required String fromUserId,
    required String
    type, // 'connection_request', 'connection_accepted', 'like', 'comment'
    required String message,
    String? relatedId, // postId, commentId, etc.
  }) async {
    await _firestoreService.addDocument(_collectionPath, {
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'type': type,
      'message': message,
      'relatedId': relatedId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get notifications stream for a user
  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestoreService.getCollectionStream(
      _collectionPath,
      queryBuilder: (query) => query
          .where('toUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true),
    );
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestoreService.updateDocument(_collectionPath, notificationId, {
      'isRead': true,
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false),
    );

    for (var doc in snapshot.docs) {
      await _firestoreService.updateDocument(_collectionPath, doc.id, {
        'isRead': true,
      });
    }
  }

  /// Delete a notification (e.g. when request is accepted/declined)
  Future<void> deleteNotification(String notificationId) async {
    await _firestoreService.deleteDocument(_collectionPath, notificationId);
  }

  /// Delete notifications related to a specific event (e.g. connection request from X)
  Future<void> deleteConnectionRequestNotification(
    String toUserId,
    String fromUserId,
  ) async {
    final snapshot = await _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) => query
          .where('toUserId', isEqualTo: toUserId)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('type', isEqualTo: 'connection_request'),
    );

    for (var doc in snapshot.docs) {
      await _firestoreService.deleteDocument(_collectionPath, doc.id);
    }
  }
}
