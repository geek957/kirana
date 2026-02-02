import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/config_service.dart';
import '../services/product_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final ConfigService _configService;
  final ProductService _productService = ProductService();

  Cart? _cart;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Cart>? _cartSubscription;

  /// Constructor with ConfigService dependency injection
  CartProvider({ConfigService? configService})
    : _configService = configService ?? ConfigService();

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;

  /// Calculate delivery charge based on cart value
  /// Returns 0 if cart value meets free delivery threshold
  double get deliveryCharge {
    return _configService.calculateDeliveryCharge(totalAmount);
  }

  /// Calculate total amount including delivery charge
  double get totalWithDelivery {
    return totalAmount + deliveryCharge;
  }

  /// Check if cart is eligible for free delivery
  bool get isFreeDeliveryEligible {
    return deliveryCharge == 0.0;
  }

  /// Calculate amount needed to reach free delivery threshold
  /// Returns 0 if already eligible for free delivery
  double get amountForFreeDelivery {
    return max(0.0, _configService.getAmountForFreeDelivery(totalAmount));
  }

  /// Check if cart value is within valid limits
  /// Returns false if cart exceeds maximum cart value
  bool get isCartValueValid {
    return _configService.isCartValueValid(totalAmount);
  }

  /// Get error message if cart value is invalid
  /// Returns null if cart value is valid
  String? get cartValueError {
    if (!isCartValueValid) {
      return 'Cart exceeds maximum value';
    }
    return null;
  }

  /// Initialize cart listener for a customer
  void initializeCart(String customerId) {
    _cartSubscription?.cancel();
    _cartSubscription = _cartService
        .getCartStream(customerId)
        .listen(
          (cart) {
            _cart = cart;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  /// Validate minimum quantity for a product
  /// Returns true if quantity meets or exceeds minimum order quantity
  bool validateMinimumQuantity(Product product, int quantity) {
    return quantity >= product.minimumOrderQuantity;
  }

  /// Get all cart validation errors
  /// Returns list of error messages for items that don't meet minimum quantity
  Future<List<String>> getCartValidationErrors() async {
    final errors = <String>[];

    if (_cart == null || _cart!.items.isEmpty) {
      return errors;
    }

    // Check each cart item against product's minimum quantity
    for (final item in _cart!.items) {
      try {
        final product = await _productService.getProductById(item.productId);
        if (product != null) {
          if (item.quantity < product.minimumOrderQuantity) {
            errors.add(
              '${product.name} requires minimum ${product.minimumOrderQuantity} ${product.unitSize}',
            );
          }
          if (product.maximumOrderQuantity != null &&
              item.quantity > product.maximumOrderQuantity!) {
            errors.add(
              '${product.name} exceeds maximum ${product.maximumOrderQuantity} ${product.unitSize}',
            );
          }
        }
      } catch (e) {
        // If product not found, add generic error
        errors.add('Unable to validate ${item.productName}');
      }
    }

    return errors;
  }

  /// Add item to cart with minimum quantity validation
  Future<void> addToCart(
    String customerId,
    String productId,
    int quantity,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch product to validate minimum quantity
      final product = await _productService.getProductById(productId);

      if (product == null) {
        throw Exception('Product not found');
      }

      // Validate minimum quantity
      if (!validateMinimumQuantity(product, quantity)) {
        throw Exception(
          'Minimum order quantity for ${product.name} is ${product.minimumOrderQuantity} ${product.unitSize}',
        );
      }

      // Validate maximum quantity
      if (product.maximumOrderQuantity != null &&
          quantity > product.maximumOrderQuantity!) {
        throw Exception(
          'Maximum order quantity for ${product.name} is ${product.maximumOrderQuantity} ${product.unitSize}',
        );
      }

      await _cartService.addToCart(customerId, productId, quantity);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String customerId, String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.removeFromCart(customerId, productId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update quantity of item in cart
  Future<void> updateQuantity(
    String customerId,
    String productId,
    int quantity,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.updateQuantity(customerId, productId, quantity);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Validate cart stock
  Future<bool> validateCartStock(String customerId) async {
    try {
      return await _cartService.validateCartStock(customerId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear cart
  Future<void> clearCart(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartService.clearCart(customerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Dispose and cancel subscriptions
  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
