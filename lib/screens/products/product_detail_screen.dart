import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _quantity;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    // Initialize quantity to minimum order quantity
    _quantity = widget.product.minimumOrderQuantity;
  }

  void _incrementQuantity() {
    final maxAllowed = widget.product.getMaxAllowedQuantity();
    if (_quantity < maxAllowed) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    // Don't allow quantity to go below minimum order quantity
    if (_quantity > widget.product.minimumOrderQuantity) {
      setState(() {
        _quantity--;
      });
    }
  }

  bool get _isQuantityValid {
    return widget.product.isQuantityValid(_quantity);
  }

  void _addToCart() async {
    // Prevent multiple rapid clicks
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.firebaseUser == null) {
      if (mounted) {
        // Silent - no SnackBar for not logged in
        setState(() => _isAddingToCart = false);
      }
      return;
    }

    try {
      await cartProvider.addToCart(
        authProvider.firebaseUser!.uid,
        widget.product.id,
        _quantity,
      );
      // Silent success - no SnackBar
    } catch (e) {
      // Silent error - no SnackBar
      print('Error adding to cart: $e');
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = widget.product.stockQuantity <= 0;
    final isLowStock =
        widget.product.stockQuantity > 0 && widget.product.stockQuantity <= 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final itemCount = cartProvider.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (itemCount > 0)
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.product.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Out of stock overlay
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price and unit with discount display
                  Row(
                    children: [
                      // Show discount price if available
                      if (widget.product.discountPrice != null) ...[
                        // Original price with strikethrough
                        Text(
                          '₹${widget.product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Discount price
                        Text(
                          '₹${widget.product.discountPrice!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ] else ...[
                        // Regular price (no discount)
                        Text(
                          '₹${widget.product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        'per ${widget.product.unitSize}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  // Discount badge and savings
                  if (widget.product.discountPrice != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Discount percentage badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.product.getDiscountPercentage(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'You save ₹${(widget.product.price - widget.product.discountPrice!).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Stock status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red[50]
                          : isLowStock
                          ? Colors.orange[50]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOutOfStock
                              ? Icons.cancel
                              : isLowStock
                              ? Icons.warning
                              : Icons.check_circle,
                          size: 20,
                          color: isOutOfStock
                              ? Colors.red
                              : isLowStock
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOutOfStock
                              ? 'Out of Stock'
                              : isLowStock
                              ? 'Only ${widget.product.stockQuantity} left'
                              : '${widget.product.stockQuantity} available',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? Colors.red
                                : isLowStock
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Order quantity limits display
                  if (widget.product.minimumOrderQuantity > 1 ||
                      widget.product.maximumOrderQuantity != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.product.maximumOrderQuantity != null
                                  ? 'Order between ${widget.product.minimumOrderQuantity}-${widget.product.maximumOrderQuantity} ${widget.product.unitSize}'
                                  : 'Minimum order: ${widget.product.minimumOrderQuantity} ${widget.product.unitSize}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Description section
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Product details
                  const Text(
                    'Product Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Category', widget.product.category),
                  _buildDetailRow('Unit Size', widget.product.unitSize),
                  _buildDetailRow(
                    'Stock',
                    '${widget.product.stockQuantity} ${widget.product.unitSize}',
                  ),
                  if (widget.product.minimumOrderQuantity > 1)
                    _buildDetailRow(
                      'Min. Order',
                      '${widget.product.minimumOrderQuantity} ${widget.product.unitSize}',
                    ),
                  if (widget.product.maximumOrderQuantity != null)
                    _buildDetailRow(
                      'Max. Order',
                      '${widget.product.maximumOrderQuantity} ${widget.product.unitSize}',
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      // Fixed bottom panel with quantity selector and add to cart
      bottomNavigationBar: isOutOfStock
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Validation error message
                      if (!_isQuantityValid) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _quantity < widget.product.minimumOrderQuantity
                                      ? 'Min: ${widget.product.minimumOrderQuantity} ${widget.product.unitSize}'
                                      : 'Max: ${widget.product.maximumOrderQuantity} ${widget.product.unitSize}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Quantity selector and total price
                      Row(
                        children: [
                          // Quantity label and controls
                          const Text(
                            'Quantity:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Decrement button
                          IconButton(
                            onPressed:
                                _quantity > widget.product.minimumOrderQuantity
                                ? _decrementQuantity
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 28,
                            color: _quantity > widget.product.minimumOrderQuantity
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),

                          const SizedBox(width: 8),

                          // Quantity display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isQuantityValid
                                    ? Colors.grey[300]!
                                    : Colors.red,
                                width: _isQuantityValid ? 1 : 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: _isQuantityValid ? null : Colors.red[50],
                            ),
                            child: Text(
                              _quantity.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isQuantityValid ? null : Colors.red,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Increment button
                          IconButton(
                            onPressed: _quantity < widget.product.getMaxAllowedQuantity()
                                ? _incrementQuantity
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 28,
                            color: _quantity < widget.product.getMaxAllowedQuantity()
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),

                          const Spacer(),

                          // Total price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${(widget.product.getEffectivePrice() * _quantity).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: widget.product.discountPrice != null
                                      ? Colors.green[700]
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              // Show savings if discount
                              if (widget.product.discountPrice != null)
                                Text(
                                  'Save ₹${widget.product.calculateSavings(_quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Add to Cart button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isQuantityValid && !_isAddingToCart ? _addToCart : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isQuantityValid && !_isAddingToCart
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isAddingToCart
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isQuantityValid
                                      ? 'Add to Cart'
                                      : _quantity < widget.product.minimumOrderQuantity
                                          ? 'Min ${widget.product.minimumOrderQuantity} required'
                                          : 'Max ${widget.product.maximumOrderQuantity} allowed',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
