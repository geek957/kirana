import 'package:firebase_analytics/firebase_analytics.dart';

/// Service for tracking analytics events and user properties
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // User Properties

  /// Set user property for admin status
  Future<void> setUserIsAdmin(bool isAdmin) async {
    await _analytics.setUserProperty(
      name: 'is_admin',
      value: isAdmin.toString(),
    );
  }

  /// Set user property for customer since date
  Future<void> setUserCustomerSince(DateTime customerSince) async {
    await _analytics.setUserProperty(
      name: 'customer_since',
      value: customerSince.toIso8601String(),
    );
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Clear user ID on logout
  Future<void> clearUserId() async {
    await _analytics.setUserId(id: null);
  }

  // Product Events

  /// Log product view event
  Future<void> logProductView({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) async {
    await _analytics.logEvent(
      name: 'product_view',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'category': category,
        'price': price,
      },
    );
  }

  /// Log product search event
  Future<void> logProductSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  /// Log category filter event
  Future<void> logCategoryFilter(String category) async {
    await _analytics.logEvent(
      name: 'category_filter',
      parameters: {'category': category},
    );
  }

  // Cart Events

  /// Log add to cart event
  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
  }) async {
    await _analytics.logAddToCart(
      currency: 'INR',
      value: price * quantity,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          itemCategory: category,
          price: price,
          quantity: quantity,
        ),
      ],
    );
  }

  /// Log remove from cart event
  Future<void> logRemoveFromCart({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
  }) async {
    await _analytics.logRemoveFromCart(
      currency: 'INR',
      value: price * quantity,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          itemCategory: category,
          price: price,
          quantity: quantity,
        ),
      ],
    );
  }

  /// Log view cart event
  Future<void> logViewCart({
    required double totalAmount,
    required int itemCount,
  }) async {
    await _analytics.logViewCart(
      currency: 'INR',
      value: totalAmount,
      items: [],
    );
    await _analytics.logEvent(
      name: 'view_cart_details',
      parameters: {'item_count': itemCount, 'total_amount': totalAmount},
    );
  }

  // Checkout Events

  /// Log begin checkout event
  Future<void> logBeginCheckout({
    required double totalAmount,
    required int itemCount,
  }) async {
    await _analytics.logBeginCheckout(
      currency: 'INR',
      value: totalAmount,
      items: [],
    );
    await _analytics.logEvent(
      name: 'begin_checkout_details',
      parameters: {'item_count': itemCount, 'total_amount': totalAmount},
    );
  }

  /// Log address selection event
  Future<void> logAddressSelected(String addressLabel) async {
    await _analytics.logEvent(
      name: 'address_selected',
      parameters: {'address_label': addressLabel},
    );
  }

  // Order Events

  /// Log order placed event
  Future<void> logOrderPlaced({
    required String orderId,
    required double totalAmount,
    required int itemCount,
    required String paymentMethod,
  }) async {
    await _analytics.logPurchase(
      currency: 'INR',
      value: totalAmount,
      transactionId: orderId,
      items: [],
    );
    await _analytics.logEvent(
      name: 'order_placed_details',
      parameters: {
        'order_id': orderId,
        'item_count': itemCount,
        'payment_method': paymentMethod,
        'total_amount': totalAmount,
      },
    );
  }

  /// Log order cancelled event
  Future<void> logOrderCancelled({
    required String orderId,
    required double totalAmount,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'order_cancelled',
      parameters: {
        'order_id': orderId,
        'total_amount': totalAmount,
        'reason': reason,
      },
    );
  }

  /// Log order status view event
  Future<void> logOrderStatusView(String orderId, String status) async {
    await _analytics.logEvent(
      name: 'order_status_view',
      parameters: {'order_id': orderId, 'status': status},
    );
  }

  // Authentication Events

  /// Log login event
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Log sign up event
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // Admin Events

  /// Log product added by admin
  Future<void> logAdminProductAdded({
    required String productId,
    required String productName,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'admin_product_added',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'category': category,
      },
    );
  }

  /// Log product updated by admin
  Future<void> logAdminProductUpdated({
    required String productId,
    required String productName,
  }) async {
    await _analytics.logEvent(
      name: 'admin_product_updated',
      parameters: {'product_id': productId, 'product_name': productName},
    );
  }

  /// Log stock updated by admin
  Future<void> logAdminStockUpdated({
    required String productId,
    required String productName,
    required int newStock,
  }) async {
    await _analytics.logEvent(
      name: 'admin_stock_updated',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'new_stock': newStock,
      },
    );
  }

  /// Log order status updated by admin
  Future<void> logAdminOrderStatusUpdated({
    required String orderId,
    required String oldStatus,
    required String newStatus,
  }) async {
    await _analytics.logEvent(
      name: 'admin_order_status_updated',
      parameters: {
        'order_id': orderId,
        'old_status': oldStatus,
        'new_status': newStatus,
      },
    );
  }

  // Screen View Events

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Error Events

  /// Log error event
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }
}
