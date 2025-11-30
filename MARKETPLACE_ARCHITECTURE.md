# Marketplace Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    StrayCare App                         │
│                  (main.dart - Navigation)                │
└───────────────┬─────────────────────────────────────────┘
                │
                ├──── Home Tab
                ├──── Marketplace Tab  ◄─── YOU ARE HERE
                ├──── Messages Tab
                └──── Profile Tab

┌─────────────────────────────────────────────────────────┐
│          Marketplace Module Architecture                 │
└─────────────────────────────────────────────────────────┘

┌────────────────────────────────────┐
│  UI Layer (Presentation)            │
├────────────────────────────────────┤
│                                     │
│  ┌─ MarketplaceScreen              │
│  │   (Product Grid View)            │
│  │                                  │
│  ├─ ProductDetailScreen            │
│  │   (Full Product Info)            │
│  │                                  │
│  ├─ CartScreen                      │
│  │   (Shopping Cart)                │
│  │                                  │
│  └─ PaymentScreen                  │
│      (Payment Checkout)             │
│                                     │
└────────────────────────────────────┘
           ↓ (calls methods)
┌────────────────────────────────────┐
│  Service Layer (Business Logic)     │
├────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ MarketplaceService          │   │
│  │ (Abstract Interface)        │   │
│  │                             │   │
│  │ + getAllItems()             │   │
│  │ + getItemsByCategory()      │   │
│  │ + searchItems()             │   │
│  │ + getItemDetails()          │   │
│  │ + addToCart()               │   │
│  │ + removeFromCart()          │   │
│  │ + getCart()                 │   │
│  │ + createOrder()             │   │
│  │ + getOrderHistory()         │   │
│  └─────────────────────────────┘   │
│           △ implements              │
│           │                         │
│    ┌──────┴──────┐                  │
│    │             │                  │
│    ▼             ▼                  │
│ LocalService  Backend               │
│ (Demo)        (Future)              │
│                                     │
└────────────────────────────────────┘
           ↓ (returns)
┌────────────────────────────────────┐
│  Data Models (Entities)             │
├────────────────────────────────────┤
│                                     │
│  • MarketplaceItem                  │
│    - id, title, description         │
│    - price, currency, imageUrl      │
│    - seller, category, rating       │
│    - reviews, inStock, stockCount   │
│    - features, deliveryTime         │
│                                     │
│  • CartItem                         │
│    - id, item (MarketplaceItem)    │
│    - quantity, addedAt              │
│                                     │
│  • Cart                             │
│    - userId, items, timestamps      │
│    - Calculations: subtotal, tax    │
│                                     │
│  • Order                            │
│    - id, userId, items, amounts     │
│    - paymentMethod, status, address │
│                                     │
│  • Enums                            │
│    - PaymentMethod (5 types)        │
│    - OrderStatus (6 states)         │
│                                     │
└────────────────────────────────────┘
```

## Data Flow Sequence

### 1. Browsing Products
```
User opens Marketplace
        │
        ▼
MarketplaceScreen.initState()
        │
        ▼
_service.getAllItems()
        │
        ▼
LocalMarketplaceService
  (returns 8 demo products)
        │
        ▼
FutureBuilder rebuilds
        │
        ▼
GridView displays 8 items
```

### 2. Viewing Product Details
```
User taps product card
        │
        ▼
Navigator.push(ProductDetailScreen)
        │
        ▼
ProductDetailScreen loads
  with MarketplaceItem data
        │
        ▼
Displays all product information
  (images, description, features, etc.)
```

### 3. Adding to Cart
```
User adjusts quantity
       │
       ├─ Quantity: [1] → [2] → [3]
       │
       ▼
User taps "Add to Cart"
       │
       ▼
_service.addToCart(itemId, quantity)
       │
       ▼
LocalMarketplaceService
  (creates CartItem, adds to _cart)
       │
       ▼
SnackBar shows success
       │
       ▼
Navigator.pop() back to grid
```

### 4. Shopping Cart Review
```
User taps cart icon
       │
       ▼
Navigator.push(CartScreen)
       │
       ▼
CartScreen calls _service.getCart()
       │
       ▼
FutureBuilder receives Cart object
       │
       ▼
Displays:
  ├─ List of CartItems
  ├─ Price for each
  ├─ Remove buttons
  └─ Summary (subtotal + tax)
```

### 5. Payment Process
```
User taps "Proceed to Payment"
       │
       ▼
Navigator.pushNamed('/payment', args: cart)
       │
       ▼
PaymentScreen receives Cart object
       │
       ▼
Displays:
  ├─ Order summary
  ├─ Address input field
  └─ Payment method selection
       │
       ▼
User enters address & selects method
       │
       ▼
User taps "Complete Payment"
       │
       ▼
_service.createOrder(address, method)
       │
       ▼
LocalMarketplaceService
  (creates Order, clears cart)
       │
       ▼
Shows Order Confirmation Dialog
       │
       ▼
User taps "Back to Home"
       │
       ▼
Navigator.popUntil() returns home
```

## Service Implementation Strategy

### Current (Demo)
```
LocalMarketplaceService
├── In-memory List<MarketplaceItem>
├── In-memory Cart object
└── Simulated delays (200-500ms)

Uses: Perfect for demo, testing, development
```

### Future (Production)
```
BackendMarketplaceService
├── HTTP requests to API
├── Server-side cart storage
└── Real-time sync

Swap: Just change instantiation in marketplace_screen.dart!
```

## Component Dependency Graph

```
marketplace_screen.dart
    ├── imports: MarketplaceService, ProductDetailScreen, CartScreen
    ├── uses: LocalMarketplaceService()
    └── instantiates: MarketItemCard

product_detail_screen.dart
    ├── imports: MarketplaceService, models
    ├── requires: MarketplaceItem, MarketplaceService
    └── calls: service.addToCart()

cart_screen.dart
    ├── imports: MarketplaceService, models
    ├── requires: MarketplaceService
    ├── calls: service.getCart(), service.removeFromCart()
    └── navigates: /payment route

payment_screen.dart
    ├── imports: MarketplaceService, models
    ├── requires: Cart, MarketplaceService
    ├── calls: service.createOrder()
    └── displays: OrderSuccessDialog

main.dart
    ├── imports: PaymentScreen, MarketplaceScreen
    └── routes: /payment → PaymentScreen
```

## State Management Flow

```
App Level
├── MainAppShell (currentIndex state)
│   └── Manages bottom nav selection
│
Marketplace Level
├── MarketplaceScreen (StatefulWidget)
│   ├── _itemsFuture (Future<List<MarketplaceItem>>)
│   └── _service (MarketplaceService instance)
│
├── ProductDetailScreen (StatefulWidget)
│   ├── _quantity (int)
│   └── _isAddingToCart (bool)
│
└── CartScreen (StatefulWidget)
    ├── _cartFuture (Future<Cart>)
    └── _refreshCart() method
```

## Technology Stack

```
┌─────────────────────────────┐
│     Flutter/Dart            │
├─────────────────────────────┤
│  Material Design 3          │
│  BuildContext & Navigator   │
│  Async/Await & Futures      │
│  FutureBuilder              │
│  JSON Serialization         │
└─────────────────────────────┘
```

## API Contract (for Backend)

When backend is ready, it must provide:

```
GET /api/products
  ↓ returns List<MarketplaceItem> JSON

GET /api/products/{id}
  ↓ returns MarketplaceItem JSON

GET /api/products?category=Healthcare
  ↓ returns filtered List<MarketplaceItem>

POST /api/cart/add
  ├─ body: {itemId, quantity}
  └─ returns: {success: true}

POST /api/cart
  └─ returns: Cart JSON

POST /api/orders
  ├─ body: {items, address, paymentMethod}
  └─ returns: Order JSON with ID
```

## Error Handling Flow

```
Operation (e.g., addToCart)
    │
    ├─ Success ──→ Show SnackBar
    │
    └─ Error ──→ Catch exception
         │
         ├─ Network error ──→ User message
         ├─ Validation error ──→ Validation message
         └─ Server error ──→ Retry option
```

## Performance Considerations

```
✅ Async operations (no UI freeze)
✅ FutureBuilder for efficient rebuilds
✅ Network simulation (realistic timing)
✅ Lazy image loading (network)
✅ Modular widgets (reusable)
✅ Efficient list rendering (GridView)
```

## Security Ready

```
✅ Address input validation (required)
✅ Quantity validation (1-stockCount)
✅ Price calculations (server-side ready)
✅ JSON serialization (no data leakage)
✅ Async/await (prevents race conditions)
```

---

**This architecture ensures**:
- Easy backend integration
- Clean separation of concerns
- Testable components
- Scalable design
- No rollback needed when backend connects
