import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:straycare_demo/services/firestore_service.dart';

class UserRepository {
  final FirestoreService _firestoreService;
  final String _collectionPath = 'users';

  UserRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService.instance;

  /// Create or update a user profile
  Future<void> saveUser(String uid, Map<String, dynamic> userData) async {
    // Generic verification logic (seed)
    if (userData['email'] == 'shopnilmax@gmail.com') {
      userData['verifiedStatus'] = true;
    }

    // Generate search key for case-insensitive search
    if (userData.containsKey('displayName') &&
        userData['displayName'] != null) {
      userData['searchKey'] = userData['displayName'].toString().toLowerCase();
    }

    final doc = await _firestoreService.getDocument(_collectionPath, uid);
    if (doc.exists) {
      final currentData = doc.data() as Map<String, dynamic>?;
      // If verifiedStatus is missing in DB and not provided in update, set default false
      if (currentData != null &&
          !currentData.containsKey('verifiedStatus') &&
          !userData.containsKey('verifiedStatus')) {
        userData['verifiedStatus'] = false;
      }
      await _firestoreService.updateDocument(_collectionPath, uid, userData);
    } else {
      // New User: Default to false if not provided
      if (!userData.containsKey('verifiedStatus')) {
        userData['verifiedStatus'] = false;
      }
      await _firestoreService.setDocument(_collectionPath, uid, userData);
    }
  }

  /// Update specific fields of a user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (data.containsKey('displayName') && data['displayName'] != null) {
      data['searchKey'] = data['displayName'].toString().toLowerCase();
    }
    await _firestoreService.updateDocument(_collectionPath, uid, data);
  }

  /// Get user profile stream
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestoreService.getDocumentStream(_collectionPath, uid);
  }

  /// Get user profile once
  Future<DocumentSnapshot> getUser(String uid) async {
    return await _firestoreService.getDocument(_collectionPath, uid);
  }

  /// Check if user profile exists
  Future<bool> userExists(String uid) async {
    final doc = await _firestoreService.getDocument(_collectionPath, uid);
    return doc.exists;
  }

  /// Save a post
  Future<void> savePost(String uid, String postId) async {
    await _firestoreService.updateDocument(_collectionPath, uid, {
      'savedPostIds': FieldValue.arrayUnion([postId]),
    });
  }

  /// Unsave a post
  Future<void> unsavePost(String uid, String postId) async {
    await _firestoreService.updateDocument(_collectionPath, uid, {
      'savedPostIds': FieldValue.arrayRemove([postId]),
    });
  }

  /// Get saved post IDs stream
  Stream<DocumentSnapshot> getSavedPostIdsStream(String uid) {
    return _firestoreService.getDocumentStream(_collectionPath, uid);
  }

  // --- Connection Management ---

  /// Send a connection request
  Future<void> sendConnectionRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    // Add to current user's sent requests
    await _firestoreService.setDocument(_collectionPath, currentUserId, {
      'sentRequests': FieldValue.arrayUnion([targetUserId]),
    });

    // Add to target user's received requests
    await _firestoreService.setDocument(_collectionPath, targetUserId, {
      'receivedRequests': FieldValue.arrayUnion([currentUserId]),
    });
  }

  /// Accept a connection request
  Future<void> acceptConnectionRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    // Add to both users' connections list
    await _firestoreService.setDocument(_collectionPath, currentUserId, {
      'connections': FieldValue.arrayUnion([targetUserId]),
      'receivedRequests': FieldValue.arrayRemove([targetUserId]),
    });

    await _firestoreService.setDocument(_collectionPath, targetUserId, {
      'connections': FieldValue.arrayUnion([currentUserId]),
      'sentRequests': FieldValue.arrayRemove([currentUserId]),
    });
  }

  /// Decline a connection request
  Future<void> declineConnectionRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    // Remove from current user's received requests
    await _firestoreService.updateDocument(_collectionPath, currentUserId, {
      'receivedRequests': FieldValue.arrayRemove([targetUserId]),
    });

    // Remove from target user's sent requests
    await _firestoreService.updateDocument(_collectionPath, targetUserId, {
      'sentRequests': FieldValue.arrayRemove([currentUserId]),
    });
  }

  /// Cancel a sent connection request
  Future<void> cancelConnectionRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    // Remove from current user's sent requests
    await _firestoreService.updateDocument(_collectionPath, currentUserId, {
      'sentRequests': FieldValue.arrayRemove([targetUserId]),
    });

    // Remove from target user's received requests
    await _firestoreService.updateDocument(_collectionPath, targetUserId, {
      'receivedRequests': FieldValue.arrayRemove([currentUserId]),
    });
  }

  /// Remove a connection
  Future<void> removeConnection(
    String currentUserId,
    String targetUserId,
  ) async {
    await _firestoreService.updateDocument(_collectionPath, currentUserId, {
      'connections': FieldValue.arrayRemove([targetUserId]),
    });

    await _firestoreService.updateDocument(_collectionPath, targetUserId, {
      'connections': FieldValue.arrayRemove([currentUserId]),
    });
  }
  // --- User Search ---

  /// Get multiple users by ID
  Future<List<DocumentSnapshot>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];

    // Firestore 'in' queries are limited to 10. Split into chunks.
    final List<DocumentSnapshot> allDocs = [];
    final chunkSize = 10;

    for (var i = 0; i < uids.length; i += chunkSize) {
      final end = (i + chunkSize < uids.length) ? i + chunkSize : uids.length;
      final chunk = uids.sublist(i, end);

      final snapshot = await _firestoreService
          .getCollectionStream(
            _collectionPath,
            queryBuilder: (query) =>
                query.where(FieldPath.documentId, whereIn: chunk),
          )
          .first;
      allDocs.addAll(snapshot.docs);
    }
    return allDocs;
  }

  /// Search users by display name (simple prefix match)
  Future<List<DocumentSnapshot>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final normalizedQuery = query;

    // 1. Search by 'searchKey' (Case-Insensitive for updated users)
    final searchKeyQuery = normalizedQuery.toLowerCase();
    final searchKeySnapshot = await _firestoreService
        .getCollectionStream(
          _collectionPath,
          queryBuilder: (query) => query
              .where('searchKey', isGreaterThanOrEqualTo: searchKeyQuery)
              .where('searchKey', isLessThan: searchKeyQuery + '\uf8ff')
              .limit(20),
        )
        .first;

    // 2. Search by 'displayName' (Raw input - Case-Sensitive fallback)
    final displayNameSnapshot = await _firestoreService
        .getCollectionStream(
          _collectionPath,
          queryBuilder: (query) => query
              .where('displayName', isGreaterThanOrEqualTo: normalizedQuery)
              .where('displayName', isLessThan: normalizedQuery + '\uf8ff')
              .limit(20),
        )
        .first;

    // 3. Search by 'displayName' (Capitalized - Common Case Fallback)
    // Useful for finding "Shopnil" when searching "shopnil" if searchKey is missing.
    List<DocumentSnapshot> capitalizedSnapshotDocs = [];
    if (normalizedQuery.isNotEmpty) {
      // Only if the query starts with a lowercase letter, we try capitalizing it.
      // e.g. "shopnil" -> "Shopnil". "Shopnil" -> "Shopnil" (same, so no need re-query if step 2 covered it)
      final capitalizedQuery =
          normalizedQuery[0].toUpperCase() +
          normalizedQuery.substring(1).toLowerCase();

      if (capitalizedQuery != normalizedQuery) {
        final snapshot = await _firestoreService
            .getCollectionStream(
              _collectionPath,
              queryBuilder: (query) => query
                  .where(
                    'displayName',
                    isGreaterThanOrEqualTo: capitalizedQuery,
                  )
                  .where('displayName', isLessThan: capitalizedQuery + '\uf8ff')
                  .limit(20),
            )
            .first;
        capitalizedSnapshotDocs = snapshot.docs;
      }
    }

    // Merge results to avoid duplicates
    final Map<String, DocumentSnapshot> mergedDocs = {};

    for (var doc in searchKeySnapshot.docs) mergedDocs[doc.id] = doc;
    for (var doc in displayNameSnapshot.docs) {
      if (!mergedDocs.containsKey(doc.id)) mergedDocs[doc.id] = doc;
    }
    for (var doc in capitalizedSnapshotDocs) {
      if (!mergedDocs.containsKey(doc.id)) mergedDocs[doc.id] = doc;
    }

    return mergedDocs.values.toList();
  }
}
