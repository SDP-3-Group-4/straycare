# Marketplace System Documentation

## Overview

This document provides a comprehensive guide to the StrayCare Marketplace system, which includes product browsing, detailed product views, shopping cart, and payment processing.

## Architecture

The marketplace system follows a **service-oriented architecture** pattern similar to the chat system, ensuring scalability and easy backend integration.

### Key Components

1. **Models** (`models/marketplace_model.dart`)
   - `MarketplaceItem`: Product data model
   - `CartItem`: Individual cart item
   - `Cart`: Shopping cart container
   - `Order`: Order confirmation model
   - Enums: `PaymentMethod`, `OrderStatus`

2. **Services** (`services/marketplace_service.dart`)
   - `MarketplaceService`: Abstract interface
   - `LocalMarketplaceService`: Local implementation with demo data

3. **Screens** (`screens/`)
   - `MarketplaceScreen`: Main marketplace with product grid
   - `ProductDetailScreen`: Detailed product view
   - `CartScreen`: Shopping cart display
   - `PaymentScreen`: Payment flow

4. **UI Components**
   - `MarketItemCard`: Reusable product card component

## Data Models

### MarketplaceItem

```dart
class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String imageUrl;
  final String seller;
  final String category;
  final double rating;
  final int reviews;
  final bool inStock;
  final int stockCount;
  final List<String> features;
  final String deliveryTime;
}
```

**JSON Serialization**: Full `toJson()` and `fromJson()` methods for backend API integration.

### Cart & CartItem

- **CartItem**: Represents one product in the cart with quantity
- **Cart**: Container for multiple items with automatic calculations
  - `subtotal`: Sum of all items
  - `tax`: 5% tax calculation
  - `total`: Subtotal + tax

### Order

Records completed transactions with:
- Order ID (timestamp-based)
- Items purchased
- Total amount
- Payment method
- Shipping address
- Order status (Pending, Confirmed, Processing, Shipped, Delivered, Cancelled)

## Service Layer

### MarketplaceService Interface

```dart
abstract class MarketplaceService {
  Future<List<MarketplaceItem>> getAllItems();
  Future<List<MarketplaceItem>> getItemsByCategory(String category);
  Future<List<MarketplaceItem>> searchItems(String query);
  Future<MarketplaceItem> getItemDetails(String itemId);
  Future<void> addToCart(String itemId, int quantity);
  Future<void> removeFromCart(String itemId);
  Future<Cart> getCart();
  Future<void> clearCart();
  Future<Order> createOrder(String shippingAddress, PaymentMethod paymentMethod);
  Future<List<Order>> getOrderHistory();
  Future<Order> getOrderDetails(String orderId);
}
```

### LocalMarketplaceService

**Current Implementation**:
- In-memory storage
- 8 demo products (Vet Consultation, Grooming, Pet Food, Dog Walking, Training, Collar, Bed, First Aid Kit)
- Simulated delays (200-500ms) for realistic UX
- Full cart management

**To Swap with Backend**:
1. Create `BackendMarketplaceService implements MarketplaceService`
2. Replace API calls with actual HTTP requests
3. Update `main.dart` to use new service
4. No changes needed to UI layer

## Features

### Product Browsing

- Grid view of 2 columns
- Product cards showing:
  - Image
  - Title
  - Seller name
  - Price
  - Star rating badge
  - Tap to open details

### Product Details

- Full product image
- Star rating with review count
- Complete description
- Category badge
- Price display
- Seller information
- Stock status (in-stock with count or out-of-stock)
- Feature list with checkmarks
- Delivery time estimate
- Quantity selector
- Add to cart button

### Shopping Cart

- List of cart items
- Remove item functionality
- Quantity display
- Individual totals
- Empty state UI
- Summary section showing:
  - Subtotal
  - Tax (5%)
  - Total amount
- Proceed to Payment button

### Payment Processing

- Order summary with itemized breakdown
- Shipping address input field
- Payment method selection:
  - Credit Card
  - Debit Card
  - Mobile Money
  - Bank Transfer
  - Cash on Delivery
- Security notice
- Order confirmation dialog with:
  - Order ID
  - Total amount
  - Order status (Pending)

## Integration Guide

### Using the Marketplace

1. **Access from Main App**
   - Marketplace is a tab in bottom navigation
   - Routes to `MarketplaceScreen`

2. **Navigation Flow**
   ```
   MarketplaceScreen (grid)
         ↓ (tap product)
   ProductDetailScreen (details)
         ↓ (add to cart)
   CartScreen (review)
         ↓ (checkout)
   PaymentScreen (payment)
         ↓ (confirm)
   Order Confirmation
   ```

3. **Cart Icon**
   - Located in AppBar of `MarketplaceScreen`
   - Navigate to cart from any screen

### Backend Integration Checklist

When connecting to real backend:

- [ ] Create `BackendMarketplaceService` class
- [ ] Implement all methods with API calls
- [ ] Update `marketplace_screen.dart` to use new service
- [ ] Update URL configuration for API endpoints
- [ ] Add authentication headers if needed
- [ ] Implement error handling for network failures
- [ ] Add retry logic for failed requests
- [ ] Update payment flow to use real payment gateway
- [ ] Test all workflows end-to-end
- [ ] Update `main.dart` to use `BackendMarketplaceService`

## Demo Products

Current sample data includes:

1. **Vet Consultation** - BDT 500
2. **Pet Grooming (Full)** - BDT 1200
3. **Premium Cat Food (1kg)** - BDT 750
4. **Dog Walking Service** - BDT 300
5. **Dog Training Package (4 weeks)** - BDT 4000
6. **Premium Dog Collar & Leash Set** - BDT 650
7. **Pet Bed (Large)** - BDT 2500
8. **Pet First Aid Kit** - BDT 1500

All demo data has:
- Realistic pricing
- Complete descriptions
- Multiple features
- Star ratings (4.4 - 4.9)
- Delivery time estimates
- Stock information

## Payment Methods

Supported payment methods (demo):
- Credit Card
- Debit Card
- Mobile Money
- Bank Transfer
- Cash on Delivery

> **Note**: These are UI placeholders. Real payment gateway integration required for production.

## Scalability

### Design Principles

1. **Service Abstraction**: UI never directly references implementation
2. **JSON Serialization**: All models support backend API conversion
3. **Async/Await**: All operations are async-ready
4. **Error Handling**: Null safety and error boundaries throughout
5. **Modular Structure**: Each feature in separate files

### Performance Considerations

- `LocalMarketplaceService` uses in-memory List (suitable for demo)
- For backend: implement pagination in `getAllItems()`
- Add caching layer for frequently accessed products
- Lazy-load product images
- Implement search debouncing

## File Structure

```
lib/features/marketplace/
├── models/
│   └── marketplace_model.dart (154 lines)
├── services/
│   └── marketplace_service.dart (240 lines)
├── screens/
│   ├── product_detail_screen.dart (424 lines)
│   ├── cart_screen.dart (230 lines)
│   └── payment_screen.dart (500+ lines)
└── marketplace_screen.dart (239 lines)
```

## Theme Integration

- Primary color: `0xFF6B46C1` (Purple)
- Secondary color: `0xFFA78BFA` (Light Purple)
- Uses Material Design 3
- Consistent with app theme throughout

## Testing Notes

### Manual Testing Checklist

- [ ] Browse products in grid view
- [ ] Tap product → opens detail screen
- [ ] Adjust quantity → works correctly
- [ ] Add to cart → success message
- [ ] Open cart → shows all items
- [ ] Remove item → updates cart
- [ ] Checkout → shows payment screen
- [ ] Enter address → validation works
- [ ] Select payment method → highlights correctly
- [ ] Complete payment → shows confirmation
- [ ] Confirm → returns to home

### Example Test Scenarios

1. **Add Multiple Items**: Add 2-3 different products, verify cart totals
2. **Empty Cart**: Remove all items, verify empty state
3. **Quantity Changes**: Adjust quantities before checkout
4. **Address Validation**: Try to checkout without address

## Known Limitations (Demo)

- Payment processing is simulated (no real transactions)
- Order history returns empty (not persisted)
- Cart data is not persisted between app restarts
- Search functionality is UI-only (placeholder)
- All data is in-memory

## Future Enhancements

- Real payment gateway integration (Stripe, SSLCommerz, etc.)
- Order history persistence
- User account integration
- Wishlist feature
- Product reviews and ratings
- Advanced filtering
- Recommendation engine
- Inventory management
- Order tracking
- Notification system

## Support

For integration questions or backend API specifications, refer to the service interface documentation or contact the development team.
