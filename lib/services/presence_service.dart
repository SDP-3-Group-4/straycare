import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to track user online/offline presence
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Mark current user as online
  Future<void> goOnline() async {
    if (_currentUserId == null) return;

    await _db.collection('users').doc(_currentUserId).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Mark current user as offline with last seen timestamp
  Future<void> goOffline() async {
    if (_currentUserId == null) return;

    await _db.collection('users').doc(_currentUserId).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Stream presence data for a specific user
  Stream<Map<String, dynamic>> getUserPresence(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return {'isOnline': false, 'lastSeen': null};
      }
      final data = doc.data() as Map<String, dynamic>;
      return {
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': data['lastSeen'],
      };
    });
  }

  /// Format last seen time as human-readable string
  static String formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Offline';

    DateTime lastSeenTime;
    if (lastSeen is Timestamp) {
      lastSeenTime = lastSeen.toDate();
    } else if (lastSeen is DateTime) {
      lastSeenTime = lastSeen;
    } else {
      return 'Offline';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenTime);

    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays}d ago';
    } else {
      return 'Active a while ago';
    }
  }
}
