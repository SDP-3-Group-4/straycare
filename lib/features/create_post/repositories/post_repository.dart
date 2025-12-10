import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:straycare_demo/services/firestore_service.dart';
import '../../notifications/repositories/notification_repository.dart';

class PostRepository {
  final FirestoreService _firestoreService;
  final String _collectionPath = 'posts';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  PostRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService.instance;

  /// Create a new post
  Future<DocumentReference> createPost(Map<String, dynamic> postData) async {
    // Add server timestamp
    postData['createdAt'] = FieldValue.serverTimestamp();
    return await _firestoreService.addDocument(_collectionPath, postData);
  }

  /// Like a post
  Future<void> likePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestoreService.getDocumentReference(
      _collectionPath,
      postId,
    );

    await _firestoreService.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? []);

      if (!likes.contains(user.uid)) {
        transaction.update(postRef, {
          'likes': FieldValue.arrayUnion([user.uid]),
          'likesCount': FieldValue.increment(1),
        });
      }
    });

    // Send notification (fire and forget, outside transaction)
    _sendLikeNotification(postId, user.uid);
  }

  /// Unlike a post
  Future<void> unlikePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestoreService.getDocumentReference(
      _collectionPath,
      postId,
    );

    await _firestoreService.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? []);

      if (likes.contains(user.uid)) {
        transaction.update(postRef, {
          'likes': FieldValue.arrayRemove([user.uid]),
          'likesCount': FieldValue.increment(-1),
        });
      }
    });
  }

  Future<void> _sendLikeNotification(String postId, String userId) async {
    try {
      final postDoc = await _firestoreService.getDocument(
        _collectionPath,
        postId,
      );
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final authorId = data['authorId'];
        if (authorId != null && authorId != userId) {
          await _notificationRepository.sendNotification(
            toUserId: authorId,
            fromUserId: userId,
            type: 'like',
            message: 'liked your post',
            relatedId: postId,
          );
        }
      }
    } catch (e) {
      print('Error sending like notification: $e');
    }
  }

  /// Get posts with pagination and optional category filter
  Future<QuerySnapshot> getPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? category,
  }) {
    return _firestoreService.getCollection(
      _collectionPath,
      queryBuilder: (query) {
        var q = query.orderBy('createdAt', descending: true);

        if (category != null && category.isNotEmpty) {
          q = q.where('category', isEqualTo: category);
        }

        q = q.limit(limit);

        if (lastDocument != null) {
          q = q.startAfterDocument(lastDocument);
        }
        return q;
      },
    );
  }

  /// Get real-time stream of posts (for initial load or updates if needed)
  Stream<QuerySnapshot> getPostsStream({int limit = 10}) {
    return _firestoreService.getCollectionStream(
      _collectionPath,
      queryBuilder: (query) =>
          query.orderBy('createdAt', descending: true).limit(limit),
    );
  }

  /// Get posts by category
  Stream<QuerySnapshot> getPostsByCategoryStream(String category) {
    return _firestoreService.getCollectionStream(
      _collectionPath,
      queryBuilder: (query) => query
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true),
    );
  }

  /// Get posts by user
  Stream<QuerySnapshot> getPostsByUserStream(String userId) {
    return _firestoreService.getCollectionStream(
      _collectionPath,
      queryBuilder: (query) => query
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    );
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    await _firestoreService.deleteDocument(_collectionPath, postId);
  }

  /// Get comments for a post
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestoreService.getCollectionStream(
      '$_collectionPath/$postId/comments',
      queryBuilder: (query) => query.orderBy('timestamp', descending: true),
    );
  }

  /// Get posts by IDs
  Future<List<DocumentSnapshot>> getPostsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore whereIn is limited to 10. For more, we need to batch or fetch individually.
    // For simplicity in this demo, we'll fetch individually or in chunks of 10.
    // Let's fetch individually for now to ensure order or just use whereIn if < 10.

    if (ids.length <= 10) {
      final snapshot = await _firestoreService.getCollection(
        _collectionPath,
        queryBuilder: (query) =>
            query.where(FieldPath.documentId, whereIn: ids),
      );
      return snapshot.docs;
    } else {
      // Chunk it
      List<DocumentSnapshot> allDocs = [];
      for (var i = 0; i < ids.length; i += 10) {
        final end = (i + 10 < ids.length) ? i + 10 : ids.length;
        final chunk = ids.sublist(i, end);
        final snapshot = await _firestoreService.getCollection(
          _collectionPath,
          queryBuilder: (query) =>
              query.where(FieldPath.documentId, whereIn: chunk),
        );
        allDocs.addAll(snapshot.docs);
      }
      return allDocs;
    }
  }

  /// Add a comment to a post
  Future<void> addComment(
    String postId,
    Map<String, dynamic> commentData,
  ) async {
    // Add timestamp
    commentData['timestamp'] = FieldValue.serverTimestamp();

    await _firestoreService.addDocument(
      '$_collectionPath/$postId/comments',
      commentData,
    );

    // Update comment count on post
    await _firestoreService.updateDocument(_collectionPath, postId, {
      'commentsCount': FieldValue.increment(1),
    });

    // Send notification
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final postDoc = await _firestoreService.getDocument(
          _collectionPath,
          postId,
        );
        if (postDoc.exists) {
          final data = postDoc.data() as Map<String, dynamic>;
          final authorId = data['authorId'];
          if (authorId != null && authorId != user.uid) {
            await _notificationRepository.sendNotification(
              toUserId: authorId,
              fromUserId: user.uid,
              type: 'comment',
              message: 'commented on your post',
              relatedId: postId,
            );
          }
        }
      }
    } catch (e) {
      print('Error sending comment notification: $e');
    }
  }

  /// Toggle like on a post
  Future<bool> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final postRef = _firestoreService.getDocumentReference(
      _collectionPath,
      postId,
    );
    bool isLiked = false;

    await _firestoreService.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? []);

      if (likes.contains(user.uid)) {
        // Unlike
        transaction.update(postRef, {
          'likes': FieldValue.arrayRemove([user.uid]),
          'likesCount': FieldValue.increment(-1),
        });
        isLiked = false;
      } else {
        // Like
        transaction.update(postRef, {
          'likes': FieldValue.arrayUnion([user.uid]),
          'likesCount': FieldValue.increment(1),
        });
        isLiked = true;
      }
    });

    if (isLiked) {
      _sendLikeNotification(postId, user.uid);
    }
    return isLiked;
  }

  /// Add a reply to a comment
  Future<void> addReply(
    String postId,
    String commentId,
    Map<String, dynamic> replyData,
  ) async {
    // Add timestamp
    replyData['timestamp'] = FieldValue.serverTimestamp();

    await _firestoreService.addDocument(
      '$_collectionPath/$postId/comments/$commentId/replies',
      replyData,
    );
  }

  /// Get replies for a comment
  Stream<QuerySnapshot> getRepliesStream(String postId, String commentId) {
    return _firestoreService.getCollectionStream(
      '$_collectionPath/$postId/comments/$commentId/replies',
      queryBuilder: (query) => query.orderBy(
        'timestamp',
        descending: false,
      ), // Oldest first for replies usually
    );
  }

  /// Update a comment
  Future<void> updateComment(
    String postId,
    String commentId,
    String newContent,
  ) async {
    await _firestoreService.updateDocument(
      '$_collectionPath/$postId/comments',
      commentId,
      {'content': newContent, 'isEdited': true},
    );
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    await _firestoreService.deleteDocument(
      '$_collectionPath/$postId/comments',
      commentId,
    );
    // Update comment count
    await _firestoreService.updateDocument(_collectionPath, postId, {
      'commentsCount': FieldValue.increment(-1),
    });
  }

  /// Update a reply
  Future<void> updateReply(
    String postId,
    String commentId,
    String replyId,
    String newContent,
  ) async {
    await _firestoreService.updateDocument(
      '$_collectionPath/$postId/comments/$commentId/replies',
      replyId,
      {'content': newContent, 'isEdited': true},
    );
  }

  /// Delete a reply
  Future<void> deleteReply(
    String postId,
    String commentId,
    String replyId,
  ) async {
    await _firestoreService.deleteDocument(
      '$_collectionPath/$postId/comments/$commentId/replies',
      replyId,
    );
  }

  /// Process a donation
  Future<void> donate(
    String postId,
    double amount,
    String donorId,
    String postOwnerId,
    String postTitle,
  ) async {
    // Run as a transaction to ensure atomic updates
    await _firestoreService.runTransaction((transaction) async {
      final postRef = _firestoreService.getDocumentReference(
        _collectionPath,
        postId,
      );
      final postSnapshot = await transaction.get(postRef);

      if (!postSnapshot.exists) {
        throw Exception("Post does not exist!");
      }

      // Add to donations subcollection
      final donationRef = postRef.collection('donations').doc();
      transaction.set(donationRef, {
        'donorId': donorId,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update post stats including donor count
      transaction.update(postRef, {
        'raisedAmount': FieldValue.increment(amount),
        'donorCount': FieldValue.increment(1),
      });
    });

    // Send notification
    try {
      if (donorId != postOwnerId) {
        await NotificationRepository().sendNotification(
          toUserId: postOwnerId,
          fromUserId: donorId,
          type: 'donation',
          message:
              'donated ৳${amount.toStringAsFixed(0)} to your fundraiser "$postTitle"',
          relatedId: postId,
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Get post count for a user
  Future<int> getPostCount(String userId) async {
    return await _firestoreService.getCount(
      _collectionPath,
      queryBuilder: (query) => query.where('authorId', isEqualTo: userId),
    );
  }
}
