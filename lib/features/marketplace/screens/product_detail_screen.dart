import 'package:flutter/material.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';
import '../models/marketplace_model.dart';
import '../services/marketplace_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/appointment_booking_sheet.dart';

class ProductDetailScreen extends StatefulWidget {
  final MarketplaceItem product;
  final MarketplaceService service;
  final Function(int)? onAddToCart;

  const ProductDetailScreen({
    Key? key,
    required this.product,
    required this.service,
    this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _quantity;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  String _getCategoryDisplayName(MarketplaceCategory category) {
    switch (category) {
      case MarketplaceCategory.healthcare:
        return AppLocalizations.of(context).translate('healthcare');
      case MarketplaceCategory.grooming:
        return AppLocalizations.of(context).translate('grooming');
      case MarketplaceCategory.foodAndNutrition:
        return AppLocalizations.of(context).translate('food_nutrition');
      case MarketplaceCategory.services:
        return AppLocalizations.of(context).translate('services');
      case MarketplaceCategory.training:
        return AppLocalizations.of(context).translate('training');
      case MarketplaceCategory.accessories:
        return AppLocalizations.of(context).translate('accessories');
      case MarketplaceCategory.furniture:
        return AppLocalizations.of(context).translate('furniture');
      case MarketplaceCategory.donation:
        return AppLocalizations.of(context).translate('donations');
    }
  }

  bool _isServiceCategory(MarketplaceCategory category) {
    return category == MarketplaceCategory.healthcare ||
        category == MarketplaceCategory.grooming ||
        category == MarketplaceCategory.services ||
        category == MarketplaceCategory.training ||
        category == MarketplaceCategory.donation;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isService = _isServiceCategory(widget.product.category);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Text(
          isService
              ? AppLocalizations.of(context).translate('service_details')
              : AppLocalizations.of(context).translate('product_details'),
          style: theme.appBarTheme.titleTextStyle,
        ),
        iconTheme: theme.appBarTheme.iconTheme,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(color: Colors.grey),
              child: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Icon(
                        Icons.pets,
                        size: 100,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < widget.product.rating.toInt()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.product.rating} (${widget.product.reviews} reviews)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getCategoryDisplayName(widget.product.category),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('price'),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${widget.product.currency} ${widget.product.price.toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('seller'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.product.seller,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.product.location != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('location'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.product.location!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (widget.product.inStock)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isService
                                ? AppLocalizations.of(
                                    context,
                                  ).translate('available')
                                : '${AppLocalizations.of(context).translate('in_stock')} (${widget.product.stockCount} ${AppLocalizations.of(context).translate('available')})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isService
                                ? AppLocalizations.of(
                                    context,
                                  ).translate('unavailable')
                                : AppLocalizations.of(
                                    context,
                                  ).translate('out_of_stock'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('description'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('features'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.product.features
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isService
                              ? Icons.calendar_today
                              : Icons.local_shipping,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isService
                                  ? AppLocalizations.of(
                                      context,
                                    ).translate('appointment')
                                  : AppLocalizations.of(
                                      context,
                                    ).translate('delivery_time'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              widget.product.deliveryTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isService && widget.product.inStock)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('quantity'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () {
                                        setState(() => _quantity--);
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                                iconSize: 24,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _quantity.toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _quantity < widget.product.stockCount
                                    ? () {
                                        setState(() => _quantity++);
                                      }
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                                iconSize: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (widget.product.inStock)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isAddingToCart
                            ? null
                            : () async {
                                if (isService) {
                                  // Handle booking appointment logic
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => AppointmentBookingSheet(
                                      category: widget.product.category,
                                      onBook: (data) {
                                        // Create a cart item with appointment metadata
                                        final appointmentItem = CartItem(
                                          id: 'appt_${DateTime.now().millisecondsSinceEpoch}',
                                          item: widget.product,
                                          quantity: 1,
                                          addedAt: DateTime.now(),
                                          metadata: data,
                                        );

                                        final cart = Cart(
                                          userId: 'user_current',
                                          items: [appointmentItem],
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        );

                                        Navigator.of(context).pushNamed(
                                          '/payment',
                                          arguments: cart,
                                        );
                                      },
                                    ),
                                  );
                                } else {
                                  setState(() => _isAddingToCart = true);
                                  try {
                                    await widget.service.addToCart(
                                      widget.product.id,
                                      _quantity,
                                    );
                                    if (mounted) {
                                      widget.onAddToCart?.call(_quantity);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$_quantity ${AppLocalizations.of(context).translate('items_added_to_cart')}',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      Navigator.pop(context, true);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${AppLocalizations.of(context).translate('error')}: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isAddingToCart = false);
                                    }
                                  }
                                }
                              },
                        icon: _isAddingToCart
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isService
                                    ? Icons.calendar_today
                                    : Icons.shopping_cart,
                              ),
                        label: Text(
                          isService
                              ? AppLocalizations.of(
                                  context,
                                ).translate('book_appointment')
                              : (_isAddingToCart
                                    ? AppLocalizations.of(
                                        context,
                                      ).translate('adding_to_cart')
                                    : AppLocalizations.of(
                                        context,
                                      ).translate('add_to_cart')),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primaryColor.withOpacity(
                            0.5,
                          ),
                          disabledForegroundColor: Colors.white.withOpacity(
                            0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
