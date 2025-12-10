import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:straycare_demo/services/firestore_service.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_model.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';

class MarketplaceRepository {
  final FirestoreService _firestoreService;
  final String _itemsCollection = 'marketplace_items';
  final String _cartsCollection = 'carts';
  final String _ordersCollection = 'orders';

  MarketplaceRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService.instance;

  // --- Marketplace Items ---

  // Helper to init data if empty (for demo purposes)
  Future<void> _ensureSampleData() async {
    // Check if items exist
    final snapshot = await _firestoreService.getCollection(_itemsCollection);

    // cleanup broken seeds (missing timestamp)
    final brokenDocs = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['createdAt'] == null;
    });

    if (brokenDocs.isNotEmpty) {
      print('DEBUG: Found ${brokenDocs.length} broken items. Deleting...');
      for (final doc in brokenDocs) {
        await _firestoreService.deleteDocument(_itemsCollection, doc.id);
      }
    } else if (snapshot.docs.length > 2) {
      print('DEBUG: Found ${snapshot.docs.length} valid items, skipping seed.');
      return;
    }

    print('DEBUG: Seeding sample data...');
    final sampleItems = [
      MarketplaceItem(
        id: '',
        title: 'Premium Vet Checkup',
        description:
            'Comprehensive health checkup for your pet including vaccination review and general wellness exam.',
        price: 1500.0,
        currency: 'BDT',
        imageUrl:
            'https://images.unsplash.com/photo-1628009368231-7603358b46a4?auto=format&fit=crop&q=80&w=800',
        seller: 'City Vet Clinic',
        category: MarketplaceCategory.healthcare,
        rating: 4.8,
        reviews: 124,
        inStock: true,
        stockCount: 50,
        features: ['General Exam', 'Vaccination Review', 'Weight Check'],
        deliveryTime: 'Instant Booking',
        location: 'Gulshan 2, Dhaka',
      ),
      MarketplaceItem(
        id: '',
        title: 'Full Dog Grooming Package',
        description:
            'Complete grooming session including bath, haircut, nail trimming, and ear cleaning.',
        price: 2500.0,
        currency: 'BDT',
        imageUrl:
            'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?auto=format&fit=crop&q=80&w=800',
        seller: 'Paws & Bubbles',
        category: MarketplaceCategory.grooming,
        rating: 4.9,
        reviews: 89,
        inStock: true,
        stockCount: 20,
        features: ['Bath & Blow Dry', 'Haircut', 'Nail Trimming'],
        deliveryTime: 'Appointment Based',
        location: 'Banani, Dhaka',
      ),
      MarketplaceItem(
        id: '',
        title: 'Organic Dog Food 5kg',
        description:
            'High-quality organic dog food rich in protein and essential nutrients for active dogs.',
        price: 3200.0,
        currency: 'BDT',
        imageUrl:
            'https://images.unsplash.com/photo-1589924691195-41432c84c161?auto=format&fit=crop&q=80&w=800',
        seller: 'Healthy Paws Store',
        category: MarketplaceCategory.foodAndNutrition,
        rating: 4.7,
        reviews: 256,
        inStock: true,
        stockCount: 100,
        features: ['Organic Ingredients', 'High Protein', 'Grain Free'],
        deliveryTime: '2-3 Days',
      ),
      MarketplaceItem(
        id: '',
        title: 'Pet Walking Service (1 Hour)',
        description:
            'Professional dog walking service. We ensure your pet gets the exercise they need safely.',
        price: 500.0,
        currency: 'BDT',
        imageUrl:
            'https://images.unsplash.com/photo-1601758177266-bc599de87707?auto=format&fit=crop&q=80&w=800',
        seller: 'Walk My Dog BD',
        category: MarketplaceCategory.services,
        rating: 4.6,
        reviews: 45,
        inStock: true,
        stockCount: 999,
        features: ['1 Hour Walk', 'GPS Tracking', 'Photo Updates'],
        deliveryTime: 'On Demand',
        location: 'Dhaka City Info',
      ),
      MarketplaceItem(
        id: '',
        title: 'Basic Obedience Training Class',
        description:
            '6-week group training course covering basic commands and socialization skills.',
        price: 12000.0,
        currency: 'BDT',
        imageUrl:
            'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&q=80&w=800',
        seller: 'K9 Academy',
        category: MarketplaceCategory.training,
        rating: 4.9,
        reviews: 67,
        inStock: true,
        stockCount: 10,
        features: ['6 Weeks', 'Certified Trainer', 'Group Classes'],
        deliveryTime: 'Schedule Based',
        location: 'Uttara Sector 7',
      ),
      MarketplaceItem(
        id: '',
        title: 'Leather Dog Collar',
        description:
            'Handcrafted genuine leather collar with durable brass hardware. Stylish and long-lasting.',
        price: 1200.0,
        currency: 'BDT',
        imageUrl:
            'https://images.unsplash.com/photo-1627916177579-247d4837895e?auto=format&fit=crop&q=80&w=800',
        seller: 'Posh Pets Accessories',
        category: MarketplaceCategory.accessories,
        rating: 4.5,
        reviews: 34,
        inStock: true,
        stockCount: 15,
        features: ['Genuine Leather', 'Brass Hardware', 'Adjustable'],
        deliveryTime: '3-4 Days',
      ),
      MarketplaceItem(
        id: '',
        title: 'Orthopedic Memory Foam Pet Bed',
        description:
            'Premium memory foam bed providing joint support and comfort for dogs of all sizes.',
        price: 4500.0,
        currency: 'BDT',
        imageUrl:
            'https://images.unsplash.com/photo-1591946614720-90a587da4a36?auto=format&fit=crop&q=80&w=800',
        seller: 'ComfyPet Home',
        category: MarketplaceCategory.furniture,
        rating: 4.8,
        reviews: 112,
        inStock: true,
        stockCount: 25,
        features: ['Memory Foam', 'Washable Cover', 'Non-slip Base'],
        deliveryTime: '3-5 Days',
      ),
    ];

    print('DEBUG: Seeding sample data...');
    for (final item in sampleItems) {
      final data = item.toJson();
      data.remove('id');
      data['createdAt'] = FieldValue.serverTimestamp();

      await _firestoreService.addDocument(_itemsCollection, data);
    }
  }

  /// Add a new item to the marketplace
  Future<DocumentReference> addMarketplaceItem(MarketplaceItem item) async {
    final data = item.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    return await _firestoreService.addDocument(_itemsCollection, data);
  }

  /// Get marketplace items with pagination
  Future<QuerySnapshot> getItems({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? category,
  }) async {
    await _ensureSampleData();
    return _firestoreService.getCollection(
      _itemsCollection,
      queryBuilder: (query) {
        var q = query.orderBy('createdAt', descending: true).limit(limit);
        if (category != null && category.isNotEmpty) {
          q = q.where('category', isEqualTo: category);
        }
        if (lastDocument != null) {
          q = q.startAfterDocument(lastDocument);
        }
        return q;
      },
    );
  }

  /// Get marketplace items stream
  Stream<QuerySnapshot> getItemsStream({int limit = 10}) {
    return _firestoreService.getCollectionStream(
      _itemsCollection,
      queryBuilder: (query) =>
          query.orderBy('createdAt', descending: true).limit(limit),
    );
  }

  // --- Cart ---

  /// Get user cart
  Stream<DocumentSnapshot> getCartStream(String userId) {
    return _firestoreService.getDocumentStream(_cartsCollection, userId);
  }

  /// Add item to cart (or update quantity)
  Future<void> addToCart(String userId, CartItem item) async {
    final cartRef = _firestoreService.collection(_cartsCollection).doc(userId);

    // We need to read the current cart to check if item exists
    // This logic is a bit complex for a simple repository method without transactions
    // For MVP, let's just use arrayUnion if possible, but arrayUnion doesn't handle quantity updates easily.
    // So we'll read-modify-write.

    return _firestoreService.collection(_cartsCollection).firestore.runTransaction((
      transaction,
    ) async {
      final snapshot = await transaction.get(cartRef);

      if (!snapshot.exists) {
        // Create new cart
        final newCart = Cart(
          userId: userId,
          items: [item],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        transaction.set(cartRef, newCart.toJson());
      } else {
        // Update existing cart
        final data = snapshot.data() as Map<String, dynamic>;
        final cart = Cart.fromJson(data);

        // Check if item exists
        final existingItemIndex = cart.items.indexWhere((i) => i.id == item.id);

        if (existingItemIndex != -1) {
          // Update quantity
          cart.items[existingItemIndex].quantity += item.quantity;
        } else {
          // Add new item
          cart.items.add(item);
        }

        // Update timestamp
        // We can't easily update 'updatedAt' in the model without making it mutable or creating a new one.
        // Let's just create a map for update.

        transaction.update(cartRef, {
          'items': cart.items.map((i) => i.toJson()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Remove item from cart
  Future<void> removeFromCart(String userId, String itemId) async {
    final cartRef = _firestoreService.collection(_cartsCollection).doc(userId);

    return _firestoreService
        .collection(_cartsCollection)
        .firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(cartRef);
          if (!snapshot.exists) return;

          final data = snapshot.data() as Map<String, dynamic>;
          final cart = Cart.fromJson(data);

          cart.items.removeWhere((item) => item.id == itemId);

          transaction.update(cartRef, {
            'items': cart.items.map((i) => i.toJson()).toList(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        });
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    await _firestoreService.deleteDocument(_cartsCollection, userId);
  }

  // --- Orders ---

  /// Create an order
  Future<DocumentReference> createOrder(Order order) async {
    final data = order.toJson();
    // Ensure timestamps are correct server-side if needed, but we'll trust client for now or use FieldValue
    // data['createdAt'] = FieldValue.serverTimestamp(); // Order model has DateTime, let's keep it consistent
    return await _firestoreService.addDocument(_ordersCollection, data);
  }

  /// Get user orders
  Stream<QuerySnapshot> getUserOrdersStream(String userId) {
    return _firestoreService.getCollectionStream(
      _ordersCollection,
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    );
  }
}
