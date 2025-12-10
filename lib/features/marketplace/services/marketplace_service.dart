import '../models/marketplace_model.dart';
import '../models/marketplace_category.dart';
import 'package:straycare_demo/services/firestore_service.dart';
import 'package:straycare_demo/services/auth_service.dart';

/// Service layer for marketplace operations
abstract class MarketplaceService {
  /// Fetch all marketplace items
  Future<List<MarketplaceItem>> getAllItems();

  /// Fetch items by category
  Future<List<MarketplaceItem>> getItemsByCategory(
    MarketplaceCategory category,
  );

  /// Search items
  Future<List<MarketplaceItem>> searchItems(String query);

  /// Get item details
  Future<MarketplaceItem> getItemDetails(String itemId);

  /// Add item to cart
  Future<void> addToCart(String itemId, int quantity);

  /// Remove item from cart
  Future<void> removeFromCart(String itemId);

  /// Get cart
  Future<Cart> getCart();

  /// Clear cart
  Future<void> clearCart();

  /// Create order from cart
  Future<Order> createOrder(
    String shippingAddress,
    PaymentMethod paymentMethod, {
    Cart? fromCart,
  });

  /// Get order history
  Future<List<Order>> getOrderHistory();

  /// Get order details
  Future<Order> getOrderDetails(String orderId);
}

/// Firestore implementation
class FirestoreMarketplaceService implements MarketplaceService {
  final FirestoreService _firestoreService;
  final String _itemsCollection = 'marketplace_items';
  final String _ordersCollection = 'orders';
  final String _cartCollection =
      'carts'; // In a real app, usually a subcollection of user
  final AuthService _authService;

  static final FirestoreMarketplaceService _instance =
      FirestoreMarketplaceService._internal();

  factory FirestoreMarketplaceService() {
    return _instance;
  }

  FirestoreMarketplaceService._internal()
    : _firestoreService = FirestoreService.instance,
      _authService = AuthService();

  // Cache for simple demo
  List<MarketplaceItem> _itemsCache = [];

  // Helper to init data if empty (for demo purposes)
  Future<void> _ensureSampleData() async {
    // Check if items exist
    final snapshot = await _firestoreService.getCollection(_itemsCollection);
    if (snapshot.docs.isNotEmpty) {
      _itemsCache = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return MarketplaceItem.fromJson(data);
      }).toList();
      return;
    }

    // Seed data
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
      final docRef = await _firestoreService.addDocument(
        _itemsCollection,
        item.toJson()..remove('id'), // Let Firestore generate ID
      );
      print('Seeded item: ${item.title} with ID: ${docRef.id}');
    }

    // Refresh cache
    final refreshedSnapshot = await _firestoreService.getCollection(
      _itemsCollection,
    );
    _itemsCache = refreshedSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return MarketplaceItem.fromJson(data);
    }).toList();
  }

  @override
  Future<List<MarketplaceItem>> getAllItems() async {
    await _ensureSampleData();
    return _itemsCache;
  }

  @override
  Future<List<MarketplaceItem>> getItemsByCategory(
    MarketplaceCategory category,
  ) async {
    await _ensureSampleData();
    return _itemsCache.where((item) => item.category == category).toList();
  }

  @override
  Future<List<MarketplaceItem>> searchItems(String query) async {
    await _ensureSampleData();
    final lowerQuery = query.toLowerCase();
    return _itemsCache
        .where(
          (item) =>
              item.title.toLowerCase().contains(lowerQuery) ||
              item.description.toLowerCase().contains(lowerQuery) ||
              item.seller.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  @override
  Future<MarketplaceItem> getItemDetails(String itemId) async {
    final doc = await _firestoreService.getDocument(_itemsCollection, itemId);
    if (!doc.exists) {
      // Fallback to cache or throw
      return _itemsCache.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item not found'),
      );
    }
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return MarketplaceItem.fromJson(data);
  }

  // --- Cart Management (Simplified: Using local storage/mock for cart in this step
  // to avoid refactoring everything, but focusing on Real Order Creation) ---

  Cart _cart = Cart(
    userId: 'user_current',
    items: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Future<void> addToCart(String itemId, int quantity) async {
    // Ideally fetch item from Firestore
    // For donation items (dynamic), we might not find them in _itemsCache
    // so we construct them on the fly if needed or expect them passed.

    // NOTE: This relies on memory for now as per original mock,
    // but we will implement CreateOrder to be real.

    MarketplaceItem? item;
    try {
      item = await getItemDetails(itemId);
    } catch (e) {
      // It might be a dynamic donation item not in DB
      // In a real app, donation items might not need to be in 'marketplace_items'
      // but handled differently.
      // For this demo, let's assume if it starts with 'donation_', we can't fetch it easily
      // unless we passed the object.
      // The UI passes the object to addToCart usually? No, the UI calls addToCart(itemId).
      // The original mock created the item inside addToCart using getItemDetails.

      // Major issue: PostCard creates a Cart with the item directly and passes it to PaymentScreen.
      // It doesn't use addToCart for donations.
      // So this method is only for regular items.
    }

    if (item != null) {
      final cartItem = CartItem(
        id: '${itemId}_${DateTime.now().millisecondsSinceEpoch}',
        item: item,
        quantity: quantity,
        addedAt: DateTime.now(),
      );
      _cart.items.add(cartItem);
    }
  }

  @override
  Future<void> removeFromCart(String itemId) async {
    _cart.items.removeWhere((item) => item.item.id == itemId);
  }

  @override
  Future<Cart> getCart() async {
    return _cart;
  }

  @override
  Future<void> clearCart() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _firestoreService.deleteDocument(_cartCollection, user.uid);
    }
    _cart.items.clear();
  }

  @override
  Future<Order> createOrder(
    String shippingAddress,
    PaymentMethod paymentMethod, {
    Cart? fromCart,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("User must be logged in");

    final cartToUse = fromCart ?? _cart;
    print(
      'DEBUG: createOrder called. User: ${user.uid}, Items: ${cartToUse.items.length}',
    );
    final orderData = Order(
      id: '', // Will be set by Firestore ID
      userId: user.uid,
      items: cartToUse.items,
      subtotal: cartToUse.subtotal,
      tax: cartToUse.tax,
      total: cartToUse.total,
      status:
          cartToUse.items.any(
            (i) => i.item.category == MarketplaceCategory.donation,
          )
          ? OrderStatus
                .confirmed // Or completed/delivered depending on enum
          : OrderStatus.pending,
      paymentMethod: paymentMethod,
      shippingAddress: shippingAddress,
      createdAt: DateTime.now(),
      completedAt:
          cartToUse.items.any(
            (i) => i.item.category == MarketplaceCategory.donation,
          )
          ? DateTime.now()
          : null,
    ).toJson();
    print('DEBUG: Order data prepared: $orderData');

    // Remove ID so Firestore generates it
    orderData.remove('id');

    final docRef = await _firestoreService.addDocument(
      _ordersCollection,
      orderData,
    );

    // Return order with new ID
    orderData['id'] = docRef.id;

    // Clear the cart after successful order
    await clearCart();

    return Order.fromJson(orderData);
  }

  @override
  Future<List<Order>> getOrderHistory() async {
    final user = _authService.currentUser;
    print('DEBUG: getOrderHistory called. User: ${user?.uid}');
    if (user == null) {
      print('DEBUG: User is null, returning empty list');
      return [];
    }

    try {
      final snapshot = await _firestoreService.getCollection(
        _ordersCollection,
        queryBuilder: (query) => query
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true),
      );

      print('DEBUG: Found ${snapshot.docs.length} orders for user ${user.uid}');
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Order.fromJson(data);
      }).toList();
    } catch (e) {
      print('DEBUG: Error in getOrderHistory: $e');
      return [];
    }
  }

  @override
  Future<Order> getOrderDetails(String orderId) async {
    final doc = await _firestoreService.getDocument(_ordersCollection, orderId);
    if (!doc.exists) throw Exception('Order not found');

    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Order.fromJson(data);
  }
}
