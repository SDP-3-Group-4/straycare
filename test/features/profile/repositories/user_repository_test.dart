import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import 'package:straycare_demo/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserRepository userRepository;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
    userRepository = UserRepository(firestoreService: firestoreService);
  });

  test('saveUser saves user data to Firestore', () async {
    final userData = {
      'uid': 'user1',
      'email': 'test@example.com',
      'displayName': 'Test User',
    };

    await userRepository.saveUser('user1', userData);

    final snapshot = await fakeFirestore.collection('users').doc('user1').get();
    expect(snapshot.exists, true);
    final data = snapshot.data() as Map<String, dynamic>;
    expect(data['email'], 'test@example.com');
    expect(data['displayName'], 'Test User');
  });

  test('getUser returns user data', () async {
    await fakeFirestore.collection('users').doc('user1').set({
      'uid': 'user1',
      'email': 'test@example.com',
      'displayName': 'Test User',
    });

    final snapshot = await userRepository.getUser('user1');
    expect(snapshot.exists, true);
    final data = snapshot.data() as Map<String, dynamic>;
    expect(data['email'], 'test@example.com');
  });
}
