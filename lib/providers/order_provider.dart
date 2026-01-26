import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/order.dart';
import '../models/cart.dart';
import '../models/address.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Order>>? _ordersSubscription;
  StreamSubscription<Order?>? _selectedOrderSubscription;

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize real-time listener for customer orders
  void initializeOrdersListener(String customerId) {
    _ordersSubscription?.cancel();
    _ordersSubscription = _orderService
        .streamCustomerOrders(customerId)
        .listen(
          (orders) {
            _orders = orders;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to load orders: $error';
            notifyListeners();
          },
        );
  }

  /// Initialize real-time listener for a specific order
  void initializeOrderListener(String orderId) {
    _selectedOrderSubscription?.cancel();
    _selectedOrderSubscription = _orderService
        .streamOrder(orderId)
        .listen(
          (order) {
            _selectedOrder = order;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to load order: $error';
            notifyListeners();
          },
        );
  }

  /// Create a new order from cart
  Future<Order?> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required Cart cart,
    required Address deliveryAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        cart: cart,
        deliveryAddress: deliveryAddress,
      );

      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Fetch orders for a customer (one-time fetch, not real-time)
  Future<void> fetchCustomerOrders(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getCustomerOrders(customerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a specific order by ID (one-time fetch)
  Future<void> fetchOrderById(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderService.getOrderById(orderId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.cancelOrder(orderId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    _selectedOrderSubscription?.cancel();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _selectedOrderSubscription?.cancel();
    super.dispose();
  }
}
