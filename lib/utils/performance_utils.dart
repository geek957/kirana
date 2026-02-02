/// Performance optimization utilities for the grocery app
/// Provides helper methods and best practices for optimizing app performance

import 'package:flutter/foundation.dart';

/// Performance optimization utilities
class PerformanceUtils {
  /// Check if cache is still valid based on TTL
  /// Returns true if cache is valid, false if expired or not available
  static bool isCacheValid(DateTime? cacheTime, Duration cacheDuration) {
    if (cacheTime == null) return false;
    final cacheAge = DateTime.now().difference(cacheTime);
    return cacheAge < cacheDuration;
  }

  /// Log performance metrics in debug mode
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      print('Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }

  /// Measure execution time of an async operation
  static Future<T> measureAsync<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      logPerformance(operation, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      logPerformance('$operation (failed)', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Measure execution time of a synchronous operation
  static T measureSync<T>(String operation, T Function() function) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = function();
      stopwatch.stop();
      logPerformance(operation, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      logPerformance('$operation (failed)', stopwatch.elapsed);
      rethrow;
    }
  }
}

/// Cache configuration constants
class CacheConfig {
  /// Cache duration for app configuration (5 minutes)
  static const Duration appConfigCacheDuration = Duration(minutes: 5);

  /// Cache duration for categories (5 minutes)
  static const Duration categoriesCacheDuration = Duration(minutes: 5);

  /// Cache duration for pending order count (30 seconds)
  static const Duration pendingOrderCountCacheDuration = Duration(seconds: 30);

  /// Cache duration for product lists (2 minutes)
  static const Duration productListCacheDuration = Duration(minutes: 2);
}

/// Pagination configuration constants
class PaginationConfig {
  /// Default page size for product lists
  static const int defaultProductPageSize = 20;

  /// Default page size for order lists
  static const int defaultOrderPageSize = 20;

  /// Maximum page size to prevent excessive data loading
  static const int maxPageSize = 50;
}

/// Image optimization constants
class ImageOptimizationConfig {
  /// Maximum image dimensions for delivery photos
  static const int maxDeliveryPhotoSize = 800;

  /// Maximum file size for delivery photos (500KB)
  static const int maxDeliveryPhotoBytes = 500 * 1024;

  /// JPEG quality for compressed images
  static const int compressionQuality = 85;

  /// Maximum file size for product images (500KB)
  static const int maxProductImageBytes = 500 * 1024;
}

/// Real-time listener optimization guidelines
class ListenerOptimizationGuidelines {
  /// Best practices for real-time listeners:
  ///
  /// 1. Always dispose listeners in the dispose() method
  /// 2. Use StreamSubscription to manage listener lifecycle
  /// 3. Cancel subscriptions when screen is disposed
  /// 4. Use limit() queries to reduce data transfer
  /// 5. Implement pagination for large datasets
  /// 6. Cache frequently accessed data
  /// 7. Use selective listeners (only subscribe when needed)
  /// 8. Avoid multiple listeners for the same data
  /// 9. Use where() clauses to filter data at the source
  /// 10. Consider using snapshots() only for critical real-time data

  static const String documentation = '''
Performance Optimization Guidelines:

1. Caching Strategy:
   - Cache frequently accessed data (config, categories)
   - Use TTL (Time To Live) for cache invalidation
   - Clear cache when data is modified
   - Implement fallback to cached data on network errors

2. Image Optimization:
   - Compress images before upload
   - Use appropriate image dimensions
   - Implement progressive loading
   - Cache images locally

3. Query Optimization:
   - Use indexed queries
   - Implement pagination for large datasets
   - Use count() queries for counts only
   - Avoid fetching unnecessary fields

4. Real-time Listener Optimization:
   - Dispose listeners properly
   - Use selective listening
   - Implement pagination for real-time data
   - Cache real-time data locally

5. Network Optimization:
   - Batch operations when possible
   - Use offline persistence
   - Implement retry mechanisms
   - Handle network errors gracefully
''';
}
