import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  Cart? _cart;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Cart>? _cartSubscription;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;

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

  /// Add item to cart
  Future<void> addToCart(
    String customerId,
    String productId,
    int quantity,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
