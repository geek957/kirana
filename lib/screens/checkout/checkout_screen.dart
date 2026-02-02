import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/address.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/product_service.dart';
import '../address/address_form_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  bool _isPlacingOrder = false;
  bool _acceptNoReturnPolicy = false;
  bool _needsPolicyAcceptance = false;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _checkPolicyAcceptance();
    // Start watching pending order count for capacity checks
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.startWatchingPendingCount();
  }

  Future<void> _checkPolicyAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool('has_accepted_no_return_policy') ?? false;

    if (mounted) {
      setState(() {
        _needsPolicyAcceptance = !hasAccepted;
        _acceptNoReturnPolicy = hasAccepted;
      });
    }
  }

  Future<void> _savePolicyAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_accepted_no_return_policy', true);
  }

  /// Calculate total savings from discounts across all cart items
  Future<double> _calculateTotalSavings() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return 0.0;
    }

    double totalSavings = 0.0;
    for (final item in cartProvider.cart!.items) {
      try {
        final product = await _productService.getProductById(item.productId);
        if (product != null) {
          totalSavings += product.calculateSavings(item.quantity);
        }
      } catch (e) {
        // Skip if product not found
        continue;
      }
    }
    return totalSavings;
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No-Return Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Important Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '• All orders are verified at the time of delivery',
                style: TextStyle(height: 1.5),
              ),
              Text(
                '• You must check all products before accepting delivery',
                style: TextStyle(height: 1.5),
              ),
              Text(
                '• Delivery person will take a photo as proof of delivery',
                style: TextStyle(height: 1.5),
              ),
              Text(
                '• Returns are not accepted after delivery completion',
                style: TextStyle(height: 1.5),
              ),
              Text(
                '• Please report any issues immediately during delivery',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 12),
              Text(
                'By accepting this policy, you agree to verify all products at the time of delivery.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentCustomer != null) {
      await addressProvider.loadAddresses(authProvider.currentCustomer!.id);

      // Auto-select default address if available
      final defaultAddress = addressProvider.addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => addressProvider.addresses.isNotEmpty
            ? addressProvider.addresses.first
            : throw Exception('No address'),
      );

      if (mounted) {
        setState(() {
          _selectedAddress = defaultAddress;
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate minimum quantities
    final validationErrors = await cartProvider.getCartValidationErrors();
    if (validationErrors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationErrors.join('\n')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Validate cart value
    if (!cartProvider.isCartValueValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.cartValueError ?? 'Cart value is invalid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check order capacity
    if (!orderProvider.canPlaceOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderProvider.capacityWarning ??
                'Order capacity is full. Please try again later.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Check no-return policy acceptance
    if (_needsPolicyAcceptance && !_acceptNoReturnPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the no-return policy to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    // Save policy acceptance if this is first order
    if (_needsPolicyAcceptance && _acceptNoReturnPolicy) {
      await _savePolicyAcceptance();
    }

    final order = await orderProvider.createOrder(
      customerId: authProvider.currentCustomer!.id,
      customerName: authProvider.currentCustomer!.name,
      customerPhone: authProvider.currentCustomer!.phoneNumber,
      cart: cartProvider.cart!,
      deliveryAddress: _selectedAddress!,
    );

    setState(() {
      _isPlacingOrder = false;
    });

    if (order != null && mounted) {
      // Navigate to order confirmation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(order: order),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to place order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer4<AddressProvider, CartProvider, AuthProvider, OrderProvider>(
        builder: (context, addressProvider, cartProvider, authProvider, orderProvider, child) {
          if (addressProvider.isLoading || cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Capacity Warning Banner
                if (orderProvider.capacityWarning != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: orderProvider.canPlaceOrder
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: orderProvider.canPlaceOrder
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          orderProvider.canPlaceOrder
                              ? Icons.warning_amber
                              : Icons.block,
                          color: orderProvider.canPlaceOrder
                              ? Colors.orange
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            orderProvider.capacityWarning!,
                            style: TextStyle(
                              color: orderProvider.canPlaceOrder
                                  ? Colors.orange.shade900
                                  : Colors.red.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Delivery Address Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddressFormScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadAddresses();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (addressProvider.addresses.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('No saved addresses'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddressFormScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadAddresses();
                              }
                            },
                            child: const Text('Add Address'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...addressProvider.addresses.map((address) {
                    final isSelected = _selectedAddress?.id == address.id;
                    return Card(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1)
                          : null,
                      child: RadioListTile<String>(
                        value: address.id,
                        groupValue: _selectedAddress?.id,
                        onChanged: (value) {
                          setState(() {
                            _selectedAddress = address;
                          });
                        },
                        title: Row(
                          children: [
                            Text(
                              address.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(address.fullAddress),
                            if (address.landmark != null &&
                                address.landmark!.isNotEmpty)
                              Text('Landmark: ${address.landmark}'),
                            Text('Contact: ${address.contactNumber}'),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Order Summary Section
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...cartProvider.cart!.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} (${item.quantity})',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '₹${item.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(),

                        // Subtotal
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '₹${cartProvider.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        // Delivery Charge
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Delivery Charge',
                                style: TextStyle(fontSize: 14),
                              ),
                              cartProvider.isFreeDeliveryEligible
                                  ? Row(
                                      children: [
                                        Text(
                                          '₹${cartProvider.deliveryCharge.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'FREE',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '₹${cartProvider.deliveryCharge.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                            ],
                          ),
                        ),

                        // Savings from discounts
                        FutureBuilder<double>(
                          future: _calculateTotalSavings(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data! > 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Discount Savings',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '- ₹${snapshot.data!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        const Divider(),

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${cartProvider.totalWithDelivery.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method Section
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.money, color: Colors.green),
                    title: const Text('Cash on Delivery'),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // No-Return Policy Section
                if (_needsPolicyAcceptance)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Important Policy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All products will be verified at delivery. Returns are not accepted after delivery completion.',
                            style: TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _acceptNoReturnPolicy,
                            onChanged: (value) {
                              setState(() {
                                _acceptNoReturnPolicy = value ?? false;
                              });
                            },
                            title: const Text(
                              'I accept the no-return policy',
                              style: TextStyle(fontSize: 14),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          TextButton(
                            onPressed: _showTermsAndConditions,
                            child: const Text('Read full terms and conditions'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
