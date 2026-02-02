import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import '../models/order.dart';
import '../models/cart.dart';
import '../models/address.dart';
import '../services/order_service.dart';
import '../services/config_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final ConfigService _configService = ConfigService();

  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Order>>? _ordersSubscription;
  StreamSubscription<Order?>? _selectedOrderSubscription;
  StreamSubscription<int>? _pendingCountSubscription;

  // New state field for pending order count
  int _pendingOrderCount = 0;

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingOrderCount => _pendingOrderCount;

  /// Get order capacity status based on pending order count
  OrderCapacityStatus get capacityStatus {
    return _configService.getOrderCapacityStatus(_pendingOrderCount);
  }

  /// Check if new orders can be placed
  /// Returns false if pending orders >= block threshold
  bool get canPlaceOrder {
    // Use the capacity status to determine if orders can be placed
    return capacityStatus != OrderCapacityStatus.blocked;
  }

  /// Get capacity warning message if applicable
  /// Returns null if no warning needed
  String? get capacityWarning {
    final status = capacityStatus;

    switch (status) {
      case OrderCapacityStatus.blocked:
        return 'Order capacity is full. Please try again later.';
      case OrderCapacityStatus.warning:
        return 'Delivery might be delayed due to high order volume.';
      case OrderCapacityStatus.normal:
        return null;
    }
  }

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

  /// Upload delivery proof (photo and location) for an order
  /// Combines photo upload and location capture in a single operation
  Future<bool> uploadDeliveryProof({
    required String orderId,
    required File photo,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.completeDelivery(
        orderId: orderId,
        deliveryPhoto: photo,
        latitude: latitude,
        longitude: longitude,
      );

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

  /// Add customer remarks and rating to a delivered order
  /// Rating is required (1-5 stars), remarks are optional but limited to 500 characters
  Future<bool> addRemarks({
    required String orderId,
    String? remarks,
    required int rating,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if this is an update or new remarks
      final order = _selectedOrder ?? await _orderService.getOrderById(orderId);

      if (order != null && order.rating != null) {
        // Update existing feedback
        await _orderService.updateCustomerRemarks(
          orderId: orderId,
          remarks: remarks,
          rating: rating,
        );
      } else {
        // Add new feedback
        await _orderService.addCustomerRemarks(
          orderId: orderId,
          remarks: remarks,
          rating: rating,
        );
      }

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

  /// Start watching pending order count for real-time updates
  /// Should be called when the app starts or when order capacity needs to be monitored
  void startWatchingPendingCount() {
    // Cancel existing subscription if any
    _pendingCountSubscription?.cancel();

    // Subscribe to pending order count stream
    _pendingCountSubscription = _orderService.watchPendingOrderCount().listen(
      (count) {
        _pendingOrderCount = count;
        notifyListeners();
      },
      onError: (error) {
        // Log error but don't update UI state
        debugPrint('Error watching pending order count: $error');
      },
    );
  }

  /// Stop watching pending order count
  /// Useful when order capacity monitoring is no longer needed
  void stopWatchingPendingCount() {
    _pendingCountSubscription?.cancel();
    _pendingCountSubscription = null;
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _selectedOrderSubscription?.cancel();
    _pendingCountSubscription?.cancel();
    super.dispose();
  }
}
