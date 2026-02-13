import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/cart_item.dart';
import '../../utils/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<String> _validationErrors = [];
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    // Start watching pending order count for capacity warnings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.startWatchingPendingCount();
      _validateCart();
    });
  }

  /// Validate cart items against minimum quantity requirements
  Future<void> _validateCart() async {
    setState(() {
      _isValidating = true;
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final errors = await cartProvider.getCartValidationErrors();

    setState(() {
      _validationErrors = errors;
      _isValidating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerId = authProvider.firebaseUser?.uid;

    if (customerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: const Center(child: Text('Please log in to view your cart')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), elevation: 0),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cart = cartProvider.cart;

          if (cartProvider.isLoading && cart == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cart == null || cart.items.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              // Order capacity warning banner
              _buildCapacityWarningBanner(context),
              // Cart value validation banner
              _buildCartValueBanner(context, cartProvider),
              // Minimum quantity validation errors
              if (_validationErrors.isNotEmpty)
                _buildValidationErrorsBanner(context),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(
                      context,
                      item,
                      customerId,
                      cartProvider,
                    );
                  },
                ),
              ),
              _buildCartSummary(context, cart, customerId, cartProvider),
            ],
          );
        },
      ),
    );
  }

  /// Build order capacity warning banner
  /// Shows warning when pending orders >= warning threshold
  Widget _buildCapacityWarningBanner(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final warning = orderProvider.capacityWarning;

        if (warning == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: orderProvider.canPlaceOrder
              ? Colors.orange.shade100
              : Colors.red.shade100,
          child: Row(
            children: [
              Icon(
                orderProvider.canPlaceOrder
                    ? Icons.warning_amber
                    : Icons.error_outline,
                color: orderProvider.canPlaceOrder
                    ? Colors.orange.shade900
                    : Colors.red.shade900,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderProvider.canPlaceOrder
                          ? 'High Order Volume'
                          : 'Order Capacity Full',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: orderProvider.canPlaceOrder
                            ? Colors.orange.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warning,
                      style: TextStyle(
                        fontSize: 13,
                        color: orderProvider.canPlaceOrder
                            ? Colors.orange.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pending orders: ${orderProvider.pendingOrderCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: orderProvider.canPlaceOrder
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build cart value validation banner
  /// Shows warning when approaching max cart value or error when exceeded
  Widget _buildCartValueBanner(
    BuildContext context,
    CartProvider cartProvider,
  ) {
    final isValid = cartProvider.isCartValueValid;
    final error = cartProvider.cartValueError;

    if (isValid && error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cart Value Limit Exceeded',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error ?? 'Please reduce items to proceed with checkout',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build minimum quantity validation errors banner
  /// Shows errors for items that don't meet minimum quantity requirements
  Widget _buildValidationErrorsBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.amber.shade100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimum Quantity Requirements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                ..._validationErrors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    String customerId,
    CartProvider cartProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () async {
                                if (item.quantity > 1) {
                                  try {
                                    await cartProvider.updateQuantity(
                                      customerId,
                                      item.productId,
                                      item.quantity - 1,
                                    );
                                    // Re-validate cart after quantity change
                                    _validateCart();
                                  } catch (e) {
                                    // Silent error - no SnackBar
                                    print('Error updating quantity: $e');
                                  }
                                } else {
                                  // When quantity is 1, show delete confirmation
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Remove Item'),
                                      content: const Text(
                                        'Remove this item from your cart?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await cartProvider.removeFromCart(
                                        customerId,
                                        item.productId,
                                      );
                                      // Re-validate cart after item removal
                                      if (context.mounted) {
                                        _validateCart();
                                      }
                                    } catch (e) {
                                      // Silent error - no SnackBar
                                      print('Error removing from cart: $e');
                                    }
                                  }
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () async {
                                try {
                                  await cartProvider.updateQuantity(
                                    customerId,
                                    item.productId,
                                    item.quantity + 1,
                                  );
                                  // Re-validate cart after quantity change
                                  _validateCart();
                                } catch (e) {
                                  // Silent error - no SnackBar
                                  print('Error updating quantity: $e');
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Subtotal
                      Text(
                        '₹${item.subtotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove Item'),
                    content: const Text(
                      'Are you sure you want to remove this item from your cart?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Remove',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await cartProvider.removeFromCart(
                      customerId,
                      item.productId,
                    );
                    // Re-validate cart after item removal
                    if (context.mounted) {
                      _validateCart();
                      // Silent removal - no SnackBar
                    }
                  } catch (e) {
                    // Silent error - no SnackBar
                    print('Error removing from cart: $e');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    dynamic cart,
    String customerId,
    CartProvider cartProvider,
  ) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final deliveryCharge = cartProvider.deliveryCharge;
        final isFreeDelivery = cartProvider.isFreeDeliveryEligible;
        final amountForFreeDelivery = cartProvider.amountForFreeDelivery;
        final isCartValid = cartProvider.isCartValueValid;
        final canPlaceOrder = orderProvider.canPlaceOrder;
        final hasValidationErrors = _validationErrors.isNotEmpty;

        // Determine if checkout should be disabled
        final isCheckoutDisabled =
            !isCartValid ||
            !canPlaceOrder ||
            hasValidationErrors ||
            _isValidating;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '₹${cart.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Delivery charge with free delivery indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Row(
                      children: [
                        if (!isFreeDelivery && deliveryCharge > 0)
                          Text(
                            '₹${deliveryCharge.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        if (isFreeDelivery)
                          Row(
                            children: [
                              Text(
                                '₹${deliveryCharge.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Free',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),

                // Free delivery progress indicator
                if (!isFreeDelivery && amountForFreeDelivery > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add ₹${amountForFreeDelivery.toStringAsFixed(2)} more for free delivery',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 24),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${cartProvider.totalWithDelivery.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Proceed to Checkout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCheckoutDisabled
                        ? null
                        : () {
                            Navigator.pushNamed(context, Routes.checkout);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isCheckoutDisabled
                          ? Colors.grey.shade300
                          : null,
                    ),
                    child: Text(
                      isCheckoutDisabled
                          ? 'Cannot Proceed to Checkout'
                          : 'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCheckoutDisabled ? Colors.grey.shade600 : null,
                      ),
                    ),
                  ),
                ),

                // Explanation text when checkout is disabled
                if (isCheckoutDisabled) ...[
                  const SizedBox(height: 8),
                  Text(
                    !isCartValid
                        ? 'Cart value exceeds maximum limit'
                        : !canPlaceOrder
                        ? 'Order capacity is full'
                        : hasValidationErrors
                        ? 'Please fix minimum quantity requirements'
                        : 'Validating cart...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
