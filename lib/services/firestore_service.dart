import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  final FirebaseFirestore _db;

  factory FirestoreService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirestoreService._test(firestore);
    }
    return _instance;
  }

  FirestoreService._internal() : _db = FirebaseFirestore.instance;

  FirestoreService._test(this._db);

  static FirestoreService get instance => _instance;

  /// Get a reference to a collection
  CollectionReference collection(String path) {
    return _db.collection(path);
  }

  /// Add a document to a collection
  Future<DocumentReference> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _db.collection(collectionPath).add(data);
    } catch (e) {
      throw Exception('Error adding document: $e');
    }
  }

  /// Set a document (create or overwrite)
  Future<void> setDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error setting document: $e');
    }
  }

  /// Update a document
  Future<void> updateDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      throw Exception('Error updating document: $e');
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String collectionPath, String docId) async {
    try {
      await _db.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  /// Get a single document (cache-first)
  Future<DocumentSnapshot> getDocument(
    String collectionPath,
    String docId, {
    bool cacheFirst = false,
  }) async {
    try {
      final options = cacheFirst
          ? const GetOptions(source: Source.cache)
          : const GetOptions(source: Source.serverAndCache);
      return await _db.collection(collectionPath).doc(docId).get(options);
    } catch (e) {
      // If cache fails, fallback to server
      if (cacheFirst) {
        return await _db.collection(collectionPath).doc(docId).get();
      }
      throw Exception('Error getting document: $e');
    }
  }

  /// Get a stream of a single document
  Stream<DocumentSnapshot> getDocumentStream(
    String collectionPath,
    String docId,
  ) {
    return _db.collection(collectionPath).doc(docId).snapshots();
  }

  /// Get a stream of a query
  Stream<QuerySnapshot> getCollectionStream(
    String collectionPath, {
    Query Function(Query)? queryBuilder,
  }) {
    Query query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// Get a future of a query (cache-first option)
  Future<QuerySnapshot> getCollection(
    String collectionPath, {
    Query Function(Query)? queryBuilder,
    bool cacheFirst = false,
  }) async {
    Query query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    try {
      final options = cacheFirst
          ? const GetOptions(source: Source.cache)
          : const GetOptions(source: Source.serverAndCache);
      return await query.get(options);
    } catch (e) {
      // If cache fails, fallback to server
      if (cacheFirst) {
        return await query.get();
      }
      rethrow;
    }
  }

  /// Get the count of documents in a query
  Future<int> getCount(
    String collectionPath, {
    Query Function(Query)? queryBuilder,
  }) async {
    Query query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// Run a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler,
  ) {
    return _db.runTransaction(transactionHandler);
  }

  /// Get document reference
  DocumentReference getDocumentReference(String collectionPath, String docId) {
    return _db.collection(collectionPath).doc(docId);
  }
}
