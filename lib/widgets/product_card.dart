import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final Future<void> Function()? onAddToCart;
  final Future<void> Function()? onRemoveFromCart;
  final int cartQuantity;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.cartQuantity = 0,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAdding = false;
  bool _isRemoving = false;
  bool _showSuccess = false;

  Future<void> _handleAddToCart() async {
    if (_isAdding || widget.onAddToCart == null) return;

    setState(() {
      _isAdding = true;
    });

    try {
      await widget.onAddToCart!();
      
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _handleRemoveFromCart() async {
    if (_isRemoving || widget.onRemoveFromCart == null) return;

    setState(() {
      _isRemoving = true;
    });

    try {
      await widget.onRemoveFromCart!();
      
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = widget.product.stockQuantity <= 0;
    final isLowStock = widget.product.stockQuantity > 0 && widget.product.stockQuantity <= 10;
    final hasDiscount = widget.product.discountPrice != null;
    final discountPercentage = widget.product.getDiscountPercentage();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isOutOfStock ? null : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Out of stock overlay
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Discount badge
                  if (hasDiscount && !isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          discountPercentage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Low stock badge
                  if (isLowStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Low Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Category label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.product.category,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Price, unit, and action buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price display
                        if (hasDiscount)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  '₹${widget.product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${widget.product.discountPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹${widget.product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        
                        // Unit size and buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Unit size
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.product.unitSize,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Add/Remove buttons
                            if (widget.onAddToCart != null && !isOutOfStock)
                              _buildCartButtons(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButtons() {
    final isInCart = widget.cartQuantity > 0;

    if (!isInCart) {
      // Show only add button when not in cart
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAdding ? null : _handleAddToCart,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: _isAdding
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 14,
                  ),
          ),
        ),
      );
    }

    // Show quantity controls when in cart
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remove button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isRemoving ? null : _handleRemoveFromCart,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: _isRemoving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.remove,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
          ),
          
          // Quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${widget.cartQuantity}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Add button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isAdding ? null : _handleAddToCart,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: _isAdding
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.add,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
