import 'package:flutter/material.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';
import 'models/marketplace_model.dart';
import 'services/marketplace_service.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import '../../l10n/app_localizations.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _service = LocalMarketplaceService();
  late Future<List<MarketplaceItem>> _itemsFuture;
  MarketplaceCategory? _selectedCategory;
  String _searchQuery = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _itemsFuture = _service.getAllItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _filterItems() {
    setState(() {
      if (_searchQuery.isNotEmpty) {
        _itemsFuture = _service.searchItems(_searchQuery);
      } else if (_selectedCategory != null) {
        _itemsFuture = _service.getItemsByCategory(_selectedCategory!);
      } else {
        _itemsFuture = _service.getAllItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverPersistentHeader(
              pinned: true,
              delegate: _MarketplaceHeaderDelegate(
                topPadding: MediaQuery.of(context).padding.top,
                service: _service,
                selectedCategory: _selectedCategory,
                onSearchChanged: (value) {
                  _searchQuery = value;
                  _filterItems();
                },
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _filterItems();
                  });
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ];
        },
        body: FutureBuilder<List<MarketplaceItem>>(
          future: _itemsFuture,
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

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context).translate('no_items_found'),
                ),
              );
            }

            return GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(8.0),
              childAspectRatio: 0.8,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              children: items
                  .map(
                    (item) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: item,
                              service: _service,
                            ),
                          ),
                        );
                      },
                      child: MarketItemCard(
                        title: item.title,
                        price: 'BDT ${item.price.toStringAsFixed(0)}',
                        imageUrl: item.imageUrl,
                        seller: item.seller,
                        rating: item.rating,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class MarketItemCard extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;
  final String seller;
  final double rating;

  const MarketItemCard({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.seller,
    this.rating = 4.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.pets, color: Colors.grey.shade600),
                    );
                  },
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seller,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final MarketplaceService service;
  final MarketplaceCategory? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<MarketplaceCategory?> onCategorySelected;

  _MarketplaceHeaderDelegate({
    required this.topPadding,
    required this.service,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  @override
  double get minExtent => 110 + topPadding;

  @override
  double get maxExtent => 110 + topPadding + kToolbarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final double maxScroll = maxExtent - minExtent;
    final double effectiveOffset = shrinkOffset.clamp(0.0, maxScroll);
    final double titleOpacity = (1 - effectiveOffset / maxScroll).clamp(
      0.0,
      1.0,
    );

    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: effectiveOffset >= maxScroll ? 2.0 : 0.0,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Title and Actions (Manual Row instead of AppBar)
          Positioned(
            top: topPadding - effectiveOffset,
            left: 0,
            right: 0,
            height: kToolbarHeight,
            child: Opacity(
              opacity: titleOpacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          AppLocalizations.of(context).translate('marketplace'),
                          style:
                              theme.appBarTheme.titleTextStyle ??
                              theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CartScreen(service: service),
                              ),
                            );
                            // Refresh cart count when returning
                            if (context.mounted) {
                              (context as Element).markNeedsBuild();
                            }
                          },
                          icon: Icon(
                            Icons.shopping_cart,
                            size: 28, // Increased size
                            color:
                                theme.appBarTheme.iconTheme?.color ??
                                theme.iconTheme.color,
                          ),
                        ),
                        FutureBuilder<Cart>(
                          future: service.getCart(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.items.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final itemCount = snapshot.data!.items.fold<int>(
                              0,
                              (sum, item) => sum + item.quantity,
                            );

                            return Positioned(
                              right: 4, // Adjusted position
                              top: 4, // Adjusted position
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18, // Slightly larger badge
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$itemCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11, // Slightly larger text
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Search Bar and Chips
          Positioned(
            top: topPadding + kToolbarHeight - effectiveOffset,
            left: 0,
            right: 0,
            height: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      onChanged: onSearchChanged,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        ).translate('search_services'),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FilterChip(
                          label: Text(
                            AppLocalizations.of(context).translate('all'),
                          ),
                          labelStyle: const TextStyle(fontSize: 12),
                          selected: selectedCategory == null,
                          onSelected: (selected) {
                            onCategorySelected(null);
                          },
                          shape: const StadiumBorder(),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                        ),
                      ),
                      ...MarketplaceCategory.values.map(
                        (category) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                            label: Text(
                              _getCategoryDisplayName(context, category),
                            ),
                            labelStyle: const TextStyle(fontSize: 12),
                            selected: selectedCategory == category,
                            onSelected: (selected) {
                              onCategorySelected(selected ? category : null);
                            },
                            shape: const StadiumBorder(),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_MarketplaceHeaderDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding ||
        selectedCategory != oldDelegate.selectedCategory ||
        service != oldDelegate.service;
  }

  String _getCategoryDisplayName(
    BuildContext context,
    MarketplaceCategory category,
  ) {
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
}
