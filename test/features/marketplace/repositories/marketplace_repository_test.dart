import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:straycare_demo/features/marketplace/repositories/marketplace_repository.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_model.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';
import 'package:straycare_demo/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MarketplaceRepository marketplaceRepository;
  late FirestoreService firestoreService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
    marketplaceRepository = MarketplaceRepository(
      firestoreService: firestoreService,
    );
  });

  test('getItemsStream returns stream of items', () async {
    await fakeFirestore.collection('marketplace_items').add({
      'title': 'Item 1',
      'price': 100,
      'category': 'healthcare',
      'seller': 'Seller 1',
      'description': 'Desc 1',
      'imageUrl': 'url1',
      'currency': 'BDT',
      'rating': 4.5,
      'reviews': 10,
      'inStock': true,
      'stockCount': 5,
      'features': [],
      'deliveryTime': '1 day',
    });

    final stream = marketplaceRepository.getItemsStream();
    final snapshot = await stream.first;
    expect(snapshot.docs.length, 1);
  });

  test('addToCart adds item to cart', () async {
    final item = MarketplaceItem(
      id: 'item1',
      title: 'Item 1',
      price: 100,
      category: MarketplaceCategory.healthcare,
      seller: 'Seller 1',
      description: 'Desc 1',
      imageUrl: 'url1',
      currency: 'BDT',
      rating: 4.5,
      reviews: 10,
      inStock: true,
      stockCount: 5,
      features: [],
      deliveryTime: '1 day',
    );

    final cartItem = CartItem(
      id: 'cartItem1',
      item: item,
      quantity: 1,
      addedAt: DateTime.now(),
    );

    await marketplaceRepository.addToCart('user1', cartItem);

    final cartSnapshot = await fakeFirestore
        .collection('carts')
        .doc('user1')
        .get();
    expect(cartSnapshot.exists, true);
    final data = cartSnapshot.data()!;
    expect(data['userId'], 'user1');
    expect((data['items'] as List).length, 1);
    expect(data['items'][0]['id'], 'cartItem1');
  });
}
