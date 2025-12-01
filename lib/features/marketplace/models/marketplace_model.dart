/// Marketplace data models
/// These are structured for easy backend integration
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';

class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String imageUrl;
  final String seller;
  final MarketplaceCategory category;
  final double rating;
  final int reviews;
  final bool inStock;
  final int stockCount;
  final List<String> features;
  final String deliveryTime;
  final String? location;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.seller,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.inStock,
    required this.stockCount,
    required this.features,
    required this.deliveryTime,
    this.location,
  });

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'seller': seller,
      'category': category.toString().split('.').last,
      'rating': rating,
      'reviews': reviews,
      'inStock': inStock,
      'stockCount': stockCount,
      'features': features,
      'deliveryTime': deliveryTime,
      'location': location,
    };
  }

  /// Create from JSON (backend response)
  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'BDT',
      imageUrl: json['imageUrl'] as String,
      seller: json['seller'] as String,
      category: MarketplaceCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => MarketplaceCategory.accessories,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: json['reviews'] as int? ?? 0,
      inStock: json['inStock'] as bool? ?? true,
      stockCount: json['stockCount'] as int? ?? 0,
      features: List<String>.from(json['features'] as List? ?? []),
      deliveryTime: json['deliveryTime'] as String? ?? '2-3 days',
      location: json['location'] as String?,
    );
  }
}

class CartItem {
  final String id;
  final MarketplaceItem item;
  int quantity;
  final DateTime addedAt;
  final Map<String, dynamic>? metadata;

  CartItem({
    required this.id,
    required this.item,
    required this.quantity,
    required this.addedAt,
    this.metadata,
  });

  double get totalPrice => item.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      item: MarketplaceItem.fromJson(json['item'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      addedAt: DateTime.parse(json['addedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class Cart {
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Tax is calculated only on non-donation items.
  double get tax =>
      items
          .where((item) => item.item.category != MarketplaceCategory.donation)
          .fold(0.0, (sum, item) => sum + item.totalPrice) *
      0.05;

  double get total => subtotal + tax;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      userId: json['userId'] as String,
      items:
          (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

enum PaymentMethod {
  creditCard,
  debitCard,
  mobileMoney,
  bankTransfer,
  cashOnDelivery,
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String shippingAddress;
  final DateTime createdAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items:
          (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentMethod'],
        orElse: () => PaymentMethod.creditCard,
      ),
      shippingAddress: json['shippingAddress'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}
