import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for crash reporting and error tracking
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Singleton pattern
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  /// Initialize Crashlytics
  Future<void> initialize() async {
    // Enable crash collection in release mode
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Pass all uncaught errors from the framework to Crashlytics
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Set user identifier
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Clear user identifier
  Future<void> clearUserId() async {
    await _crashlytics.setUserIdentifier('');
  }

  /// Set custom key for debugging
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Set multiple custom keys
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (final entry in keys.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }
  }

  /// Log a message
  void log(String message) {
    _crashlytics.log(message);
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Record a Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterError(details);
  }

  /// Force a crash (for testing only)
  void forceCrash() {
    _crashlytics.crash();
  }

  // Custom keys for common scenarios

  /// Set screen name key
  Future<void> setScreenName(String screenName) async {
    await setCustomKey('screen_name', screenName);
  }

  /// Set user role key
  Future<void> setUserRole(String role) async {
    await setCustomKey('user_role', role);
  }

  /// Set order context
  Future<void> setOrderContext({
    required String orderId,
    required String status,
    required double amount,
  }) async {
    await setCustomKeys({
      'order_id': orderId,
      'order_status': status,
      'order_amount': amount,
    });
  }

  /// Set product context
  Future<void> setProductContext({
    required String productId,
    required String productName,
    required String category,
  }) async {
    await setCustomKeys({
      'product_id': productId,
      'product_name': productName,
      'product_category': category,
    });
  }

  /// Set cart context
  Future<void> setCartContext({
    required int itemCount,
    required double totalAmount,
  }) async {
    await setCustomKeys({
      'cart_item_count': itemCount,
      'cart_total_amount': totalAmount,
    });
  }

  /// Clear all custom keys
  Future<void> clearCustomKeys() async {
    // Note: Firebase Crashlytics doesn't have a direct clear method
    // We set empty values for common keys
    await setCustomKeys({
      'screen_name': '',
      'user_role': '',
      'order_id': '',
      'order_status': '',
      'order_amount': 0,
      'product_id': '',
      'product_name': '',
      'product_category': '',
      'cart_item_count': 0,
      'cart_total_amount': 0,
    });
  }
}
