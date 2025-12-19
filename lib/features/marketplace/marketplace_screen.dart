import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_model.dart';
import 'package:straycare_demo/features/marketplace/providers/marketplace_provider.dart';
import 'package:straycare_demo/features/marketplace/repositories/marketplace_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MarketplaceProvider(),
      child: const _MarketplaceScreenContent(),
    );
  }
}

class _MarketplaceScreenContent extends StatefulWidget {
  const _MarketplaceScreenContent();

  @override
  State<_MarketplaceScreenContent> createState() =>
      _MarketplaceScreenContentState();
}

class _MarketplaceScreenContentState extends State<_MarketplaceScreenContent> {
  final ScrollController _scrollController = ScrollController();
  final MarketplaceRepository _repository =
      MarketplaceRepository(); // Keep for navigation
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MarketplaceProvider>().loadMoreItems();
    }
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
                repository: _repository,
                selectedCategory: context
                    .watch<MarketplaceProvider>()
                    .selectedCategory,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onCategorySelected: (category) {
                  context.read<MarketplaceProvider>().setCategory(
                    category ?? 'All',
                  );
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
        body: Consumer<MarketplaceProvider>(
          builder: (context, provider, child) {
            if (provider.items.isEmpty && provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            var items = provider.items.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return MarketplaceItem.fromJson(data);
            }).toList();

            // Client-side filtering for search (Category is handled by provider somewhat, but let's enforce)
            if (provider.selectedCategory != 'All') {
              // Provider fetches all for now, so we filter here if needed,
              // OR provider handles it. My provider implementation fetches all.
              // So I should filter here.
              // Actually, provider logic was "fetch all".
              // To be consistent with "Industry Standard", filtering should be server-side.
              // But for now, let's filter client side as per previous implementation to keep it working.
              // Wait, previous implementation filtered client side.
              items = items
                  .where(
                    (item) =>
                        item.category.name == provider.selectedCategory ||
                        provider.selectedCategory == 'All',
                  )
                  .toList();
            }

            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              items = items.where((item) {
                return item.title.toLowerCase().contains(query) ||
                    item.description.toLowerCase().contains(query) ||
                    item.seller.toLowerCase().contains(query);
              }).toList();
            }

            if (items.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context).translate('no_items_found'),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: items.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: item,
                          repository: _repository,
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
                );
              },
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
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 100,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.pets, color: Colors.grey.shade600),
                  ),
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
  final MarketplaceRepository repository;
  final String? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategorySelected;

  _MarketplaceHeaderDelegate({
    required this.topPadding,
    required this.repository,
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
                        StreamBuilder<DocumentSnapshot>(
                          stream: repository.getCartStream(
                            AuthService().currentUser?.uid ?? '',
                          ),
                          builder: (context, snapshot) {
                            int itemCount = 0;
                            if (snapshot.hasData &&
                                snapshot.data!.exists &&
                                snapshot.data!.data() != null) {
                              try {
                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                // Simple parsing to avoid importing Cart model if not needed,
                                // but we imported MarketplaceModel so we can use Cart.fromJson
                                final cart = Cart.fromJson(data);
                                itemCount = cart.itemCount;
                              } catch (e) {
                                print('Error parsing cart count: $e');
                              }
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CartScreen(repository: repository),
                                      ),
                                    );
                                    // Refresh cart count when returning
                                    if (context.mounted) {
                                      (context as Element).markNeedsBuild();
                                    }
                                  },
                                  icon: Icon(
                                    Icons.shopping_cart,
                                    size: 28,
                                    color:
                                        theme.appBarTheme.iconTheme?.color ??
                                        theme.iconTheme.color,
                                  ),
                                ),
                                if (itemCount > 0)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        itemCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
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
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      onChanged: onSearchChanged,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        ).translate('search_services'),
                        hintStyle: TextStyle(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
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
                          selected: selectedCategory == 'All',
                          onSelected: (selected) {
                            onCategorySelected('All');
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
                            selected:
                                selectedCategory ==
                                category.name, // Simple comparison
                            onSelected: (selected) {
                              onCategorySelected(
                                selected ? category.name : null,
                              );
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
        repository != oldDelegate.repository;
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
