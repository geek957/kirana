/// Route names for the application
class Routes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';

  // Customer routes
  static const String home = '/home';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderHistory = '/order-history';
  static const String orderDetail = '/order-detail';
  static const String profile = '/profile';
  static const String addressList = '/address-list';
  static const String addressForm = '/address-form';
  static const String notifications = '/notifications';

  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminInventory = '/admin/inventory';
  static const String adminProductAdd = '/admin/product/add';
  static const String adminProductEdit = '/admin/product/edit';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/order/detail';
}
