import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/floating_cart_preview.dart';
import '../../utils/routes.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize category provider
      context.read<CategoryProvider>().loadCategories();
      context.read<CategoryProvider>().startListening();

      // Initialize product provider
      context.read<ProductProvider>().initialize();

      // Initialize cart provider if user is logged in
      final authProvider = context.read<AuthProvider>();
      if (authProvider.firebaseUser != null) {
        context.read<CartProvider>().initializeCart(
          authProvider.firebaseUser!.uid,
        );
        // Initialize notification provider
        context.read<NotificationProvider>().initialize(
          authProvider.firebaseUser!.uid,
        );
      }
    });

    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _focusSearch() {
    // Scroll to top to show search bar
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    // Focus search field
    _searchFocusNode.requestFocus();
  }

  Future<void> _handleAddToCart(String productId) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.firebaseUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add items to cart'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Add 1 quantity to cart (addToCart handles increment automatically)
      await cartProvider.addToCart(
        authProvider.firebaseUser!.uid,
        productId,
        1, // Always add 1, the service handles existing quantity
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveFromCart(String productId) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.firebaseUser == null) {
      return;
    }

    try {
      final currentQuantity = _getCartQuantity(productId);
      
      if (currentQuantity > 1) {
        // Reduce quantity by 1
        await cartProvider.updateQuantity(
          authProvider.firebaseUser!.uid,
          productId,
          currentQuantity - 1,
        );
      } else {
        // Remove from cart
        await cartProvider.removeFromCart(
          authProvider.firebaseUser!.uid,
          productId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getCartQuantity(String productId) {
    final cartProvider = context.read<CartProvider>();
    final cart = cartProvider.cart;
    
    if (cart == null) return 0;
    
    try {
      final item = cart.items.firstWhere(
        (item) => item.productId == productId,
      );
      return item.quantity;
    } catch (e) {
      // Item not found in cart
      return 0;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when user scrolls to 80% of the list
      context.read<ProductProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kirana'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Notification bell icon
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () async {
                      // Mark all notifications as read BEFORE navigating
                      await notificationProvider.markAllAsRead();
                      
                      // Then navigate to notifications screen
                      if (context.mounted) {
                        Navigator.pushNamed(context, Routes.notifications);
                      }
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
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
                          unreadCount > 99 ? '99+' : '$unreadCount',
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
          // Cart icon
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final itemCount = cartProvider.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.cart);
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : '$itemCount',
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
          // Profile icon
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, Routes.profile);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductProvider>().setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                context.read<ProductProvider>().setSearchQuery(value);
              },
            ),
          ),

          // Category chips
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              if (categoryProvider.categories.isEmpty) {
                return const SizedBox.shrink();
              }

              return SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // "All" chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: categoryProvider.selectedCategory == null,
                        onSelected: (selected) {
                          if (selected) {
                            categoryProvider.selectCategory(null);
                            context.read<ProductProvider>().setCategory(null);
                          }
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    // Category chips
                    ...categoryProvider.categories.map((category) {
                      final isSelected =
                          categoryProvider.selectedCategory?.id == category.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.name),
                              if (category.productCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[400],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${category.productCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              categoryProvider.selectCategory(category);
                              context.read<ProductProvider>().setCategory(
                                category.name,
                              );
                            } else {
                              categoryProvider.selectCategory(null);
                              context.read<ProductProvider>().setCategory(null);
                            }
                          },
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Product grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                // Show error if any
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadProducts(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Show loading indicator on initial load
                if (provider.isLoading && provider.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show empty state
                if (provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show product grid
                return RefreshIndicator(
                  onRefresh: () => provider.loadProducts(refresh: true),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount:
                        provider.products.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at the end if loading more
                      if (index == provider.products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final product = provider.products[index];
                      return Consumer<CartProvider>(
                        builder: (context, cartProvider, _) {
                          final cartQuantity = _getCartQuantity(product.id);
                          
                          return ProductCard(
                            product: product,
                            cartQuantity: cartQuantity,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.productDetail,
                                arguments: product,
                              );
                            },
                            onAddToCart: () => _handleAddToCart(product.id),
                            onRemoveFromCart: () => _handleRemoveFromCart(product.id),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating cart preview
          const FloatingCartPreview(),
          // Bottom navigation
          CustomerBottomNav(
            currentIndex: 0,
            onSearchTap: _focusSearch,
          ),
        ],
      ),
    );
  }
}
