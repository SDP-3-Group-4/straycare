import '../models/marketplace_model.dart';
import '../models/marketplace_category.dart';

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

/// Local implementation (demo)
class LocalMarketplaceService implements MarketplaceService {
  static final LocalMarketplaceService _instance =
      LocalMarketplaceService._internal();

  factory LocalMarketplaceService() {
    return _instance;
  }

  LocalMarketplaceService._internal() {
    _initializeSampleData();
    _cart = Cart(
      userId: 'user_current',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  final List<MarketplaceItem> _items = [];
  late Cart _cart;

  void _initializeSampleData() {
    _items.addAll([
      MarketplaceItem(
        id: 'item_001',
        title: 'Vet Consultation',
        description:
            'Professional veterinary consultation for your pet. Includes physical examination, diagnosis, and treatment recommendations.',
        price: 500,
        currency: 'BDT',
        imageUrl: 'https://picsum.photos/seed/vetvisit/300/300',
        seller: 'Dr. Arpita Biswas (Verified)',
        category: MarketplaceCategory.healthcare,
        rating: 4.8,
        reviews: 156,
        inStock: true,
        stockCount: 50,
        features: [
          'Online consultation available',
          'Experienced veterinarian',
          '30 minutes session',
          'Prescription included',
        ],
        deliveryTime: 'Same day',
        location: 'Dr. Arpita\'s Clinic, Dhanmondi 27, Dhaka',
      ),
      MarketplaceItem(
        id: 'item_003',
        title: 'Premium Cat Food (1kg)',
        description:
            'High-quality cat food with balanced nutrition. Rich in proteins and essential vitamins for your cat\'s health.',
        price: 750,
        currency: 'BDT',
        imageUrl: 'https://picsum.photos/seed/catfood/300/300',
        seller: 'PetShop BD',
        category: MarketplaceCategory.foodAndNutrition,
        rating: 4.5,
        reviews: 234,
        inStock: true,
        stockCount: 100,
        features: [
          'Premium ingredients',
          'No artificial colors',
          'Balanced nutrition',
          'Long shelf life',
        ],
        deliveryTime: '1-2 days',
      ),
      MarketplaceItem(
        id: 'item_006',
        title: 'Premium Dog Collar & Leash Set',
        description:
            'Durable, comfortable dog collar and leash set. Made from high-quality materials with reflective strips.',
        price: 650,
        currency: 'BDT',
        imageUrl: 'https://picsum.photos/seed/dogcollar/300/300',
        seller: 'Pet Accessories Store',
        category: MarketplaceCategory.accessories,
        rating: 4.4,
        reviews: 89,
        inStock: true,
        stockCount: 50,
        features: [
          'Adjustable fit',
          'Reflective strips',
          'Comfortable padding',
          'Multiple colors',
        ],
        deliveryTime: '2-3 days',
      ),
      MarketplaceItem(
        id: 'item_007',
        title: 'Pet Bed (Large)',
        description:
            'Comfortable orthopedic pet bed. Great for senior pets and large breeds. Machine washable cover.',
        price: 2500,
        currency: 'BDT',
        imageUrl: 'https://picsum.photos/seed/petbed/300/300',
        seller: 'ComfortPets',
        category: MarketplaceCategory.furniture,
        rating: 4.6,
        reviews: 125,
        inStock: true,
        stockCount: 25,
        features: [
          'Orthopedic support',
          'Machine washable',
          'Non-slip bottom',
          'Multiple sizes',
        ],
        deliveryTime: '3-5 days',
      ),
      MarketplaceItem(
        id: 'item_008',
        title: 'Pet First Aid Kit',
        description:
            'Complete first aid kit for pets. Includes bandages, antiseptic, tweezers, scissors, and emergency guide.',
        price: 1500,
        currency: 'BDT',
        imageUrl: 'https://picsum.photos/seed/firstaid/300/300',
        seller: 'MediPets',
        category: MarketplaceCategory.healthcare,
        rating: 4.7,
        reviews: 98,
        inStock: true,
        stockCount: 40,
        features: [
          'Complete supplies',
          'Emergency guide included',
          'Portable case',
          'Easy to use',
        ],
        deliveryTime: '2-3 days',
      ),
    ]);
  }

  @override
  Future<List<MarketplaceItem>> getAllItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _items;
  }

  @override
  Future<List<MarketplaceItem>> getItemsByCategory(
    MarketplaceCategory category,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _items.where((item) => item.category == category).toList();
  }

  @override
  Future<List<MarketplaceItem>> searchItems(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return _items
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
    await Future.delayed(const Duration(milliseconds: 200));
    return _items.firstWhere((item) => item.id == itemId);
  }

  @override
  Future<void> addToCart(String itemId, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final item = await getItemDetails(itemId);
    final cartItem = CartItem(
      id: '${itemId}_${DateTime.now().millisecondsSinceEpoch}',
      item: item,
      quantity: quantity,
      addedAt: DateTime.now(),
    );
    _cart.items.add(cartItem);
    _cart = Cart(
      userId: _cart.userId,
      items: _cart.items,
      createdAt: _cart.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> removeFromCart(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _cart.items.removeWhere((item) => item.item.id == itemId);
    _cart = Cart(
      userId: _cart.userId,
      items: _cart.items,
      createdAt: _cart.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Cart> getCart() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _cart;
  }

  @override
  Future<void> clearCart() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _cart = Cart(
      userId: _cart.userId,
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Order> createOrder(
    String shippingAddress,
    PaymentMethod paymentMethod, {
    Cart? fromCart,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final cartToUse = fromCart ?? _cart;
    final order = Order(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      userId: cartToUse.userId,
      items: cartToUse.items,
      subtotal: cartToUse.subtotal,
      tax: cartToUse.tax,
      total: cartToUse.total,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      shippingAddress: shippingAddress,
      createdAt: DateTime.now(),
    );
    if (fromCart == null) {
      await clearCart();
    }
    return order;
  }

  @override
  Future<List<Order>> getOrderHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  @override
  Future<Order> getOrderDetails(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    throw Exception('Order not found');
  }
}
