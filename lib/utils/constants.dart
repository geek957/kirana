/// App-wide constants for the Kirana Grocery Application
class AppConstants {
  // App Information
  static const String appName = 'Kirana';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String customersCollection = 'customers';
  static const String addressesCollection = 'addresses';
  static const String productsCollection = 'products';
  static const String cartsCollection = 'carts';
  static const String ordersCollection = 'orders';
  static const String verificationCodesCollection = 'verificationCodes';
  static const String auditLogsCollection = 'auditLogs';
  static const String notificationsCollection = 'notifications';

  // Order Status
  static const String orderStatusPending = 'Pending';
  static const String orderStatusConfirmed = 'Confirmed';
  static const String orderStatusPreparing = 'Preparing';
  static const String orderStatusOutForDelivery = 'Out for Delivery';
  static const String orderStatusDelivered = 'Delivered';
  static const String orderStatusCancelled = 'Cancelled';

  // Payment Methods
  static const String paymentMethodCOD = 'Cash on Delivery';

  // Pagination
  static const int productsPerPage = 20;
  static const int ordersPerPage = 20;

  // Image Upload
  static const int maxImageSizeKB = 500;
  static const int maxImageWidth = 800;
  static const int maxImageHeight = 800;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];

  // OTP Configuration
  static const int otpLength = 4;
  static const int otpExpiryMinutes = 5;
  static const int otpMaxAttemptsPerHour = 3;
  static const int otpResendDelaySeconds = 45;

  // Stock Thresholds
  static const int lowStockThreshold = 10;

  // Notification Settings
  static const int notificationRetentionDays = 30;

  // Encryption
  static const int bcryptCostFactor = 12;

  // Error Messages
  static const String errorNetworkUnavailable =
      'Network connection unavailable. Please check your internet connection.';
  static const String errorUnknown =
      'An unexpected error occurred. Please try again.';
  static const String errorInsufficientStock =
      'Insufficient stock available for this item.';
  static const String errorOrderCancellationNotAllowed =
      'This order cannot be cancelled at its current status.';
  static const String errorOTPRateLimit =
      'Too many OTP requests. Please try again after 1 hour.';
  static const String errorInvalidOTP = 'Invalid or expired verification code.';
  static const String errorUnauthorized =
      'You are not authorized to perform this action.';

  // Success Messages
  static const String successOrderPlaced = 'Order placed successfully!';
  static const String successOrderCancelled = 'Order cancelled successfully.';
  static const String successProductAdded = 'Product added successfully.';
  static const String successProductUpdated = 'Product updated successfully.';
  static const String successAddedToCart = 'Item added to cart.';
  static const String successRemovedFromCart = 'Item removed from cart.';

  // Validation
  static const int minPhoneNumberLength = 10;
  static const int maxPhoneNumberLength = 15;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minAddressLength = 10;
  static const int maxAddressLength = 500;
  static const int minProductNameLength = 2;
  static const int maxProductNameLength = 100;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 1000;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}
