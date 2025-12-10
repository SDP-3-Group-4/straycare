import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:straycare_demo/features/create_post/repositories/post_repository.dart';
import 'package:straycare_demo/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late PostRepository postRepository;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
    postRepository = PostRepository(firestoreService: firestoreService);
  });

  test('createPost adds a post to Firestore', () async {
    try {
      final Map<String, dynamic> postData = {
        'title': 'Test Post',
        'description': 'This is a test post',
        'userId': 'user123',
      };

      final docRef = await postRepository.createPost(postData);

      final snapshot = await fakeFirestore
          .collection('posts')
          .doc(docRef.id)
          .get();
      expect(snapshot.exists, true);
      expect(snapshot.data()!['title'], 'Test Post');
      expect(snapshot.data()!['userId'], 'user123');
      expect(snapshot.data()!['createdAt'], isNotNull);
    } catch (e, s) {
      print('Error in test: $e');
      print('Stack trace: $s');
      rethrow;
    }
  });

  test('getPostsStream returns a stream of posts', () async {
    await fakeFirestore.collection('posts').add({
      'title': 'Post 1',
      'createdAt': DateTime.now(),
    });
    await fakeFirestore.collection('posts').add({
      'title': 'Post 2',
      'createdAt': DateTime.now().add(const Duration(hours: 1)),
    });

    final stream = postRepository.getPostsStream();
    final snapshot = await stream.first;

    expect(snapshot.docs.length, 2);
  });
}
