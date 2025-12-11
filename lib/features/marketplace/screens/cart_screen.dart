import 'package:flutter/material.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';
import '../models/marketplace_model.dart';
import '../repositories/marketplace_repository.dart';
import '../../../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatefulWidget {
  final MarketplaceRepository repository;
  final VoidCallback? onCheckout;

  const CartScreen({Key? key, required this.repository, this.onCheckout})
    : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final AuthService _authService = AuthService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _authService.getUserUid();
  }

  bool _isServiceCategory(MarketplaceCategory category) {
    return category == MarketplaceCategory.healthcare ||
        category == MarketplaceCategory.grooming ||
        category == MarketplaceCategory.services ||
        category == MarketplaceCategory.training;
  }

  String _getAppBarTitle(Cart cart) {
    final bool hasService = cart.items.any(
      (item) => _isServiceCategory(item.item.category),
    );
    final bool hasProduct = cart.items.any(
      (item) => !_isServiceCategory(item.item.category),
    );

    if (hasService && hasProduct) {
      return AppLocalizations.of(context).translate('your_cart_and_bookings');
    } else if (hasService) {
      return AppLocalizations.of(context).translate('your_bookings');
    } else {
      return AppLocalizations.of(context).translate('your_cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userId != null
            ? widget.repository.getCartStream(_userId!)
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${AppLocalizations.of(context).translate('error')}: ${snapshot.error}',
              ),
            );
          }

          Cart cart;
          if (!snapshot.hasData || !snapshot.data!.exists) {
            cart = Cart(
              userId: _userId ?? '',
              items: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          } else {
            cart = Cart.fromJson(snapshot.data!.data() as Map<String, dynamic>);
          }

          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('cart_empty'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.shopping_bag),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('continue_shopping'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: theme.appBarTheme.backgroundColor,
                elevation: theme.appBarTheme.elevation,
                title: Text(
                  _getAppBarTitle(cart),
                  style: theme.appBarTheme.titleTextStyle,
                ),
                centerTitle: true,
                iconTheme: theme.appBarTheme.iconTheme,
                pinned: true,
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cartItem = cart.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: CartItemTile(
                      cartItem: cartItem,
                      isService: _isServiceCategory(cartItem.item.category),
                      onRemove: () async {
                        if (_userId != null) {
                          await widget.repository.removeFromCart(
                            _userId!,
                            cartItem.id,
                          );
                        }
                      },
                    ),
                  );
                }, childCount: cart.items.length),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
        stream: _userId != null
            ? widget.repository.getCartStream(_userId!)
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox.shrink();
          }
          final cart = Cart.fromJson(
            snapshot.data!.data() as Map<String, dynamic>,
          );
          if (cart.items.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('subtotal'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'BDT ${cart.subtotal.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).translate('tax')} (5%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'BDT ${cart.tax.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.grey.shade300),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('total'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'BDT ${cart.total.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed('/payment', arguments: cart);
                    },
                    icon: const Icon(Icons.payment),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('proceed_to_payment'),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final CartItem cartItem;
  final bool isService;
  final VoidCallback? onRemove;

  const CartItemTile({
    Key? key,
    required this.cartItem,
    required this.isService,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = cartItem.item;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) {
                  return Center(
                    child: Icon(Icons.pets, color: Colors.grey.shade600),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isService
                      ? 'BDT ${item.price.toStringAsFixed(0)}'
                      : 'BDT ${item.price.toStringAsFixed(0)} × ${cartItem.quantity}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).translate('total')}: BDT ${cartItem.totalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
