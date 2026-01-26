import 'package:firebase_performance/firebase_performance.dart';

/// Service for performance monitoring and tracing
class PerformanceService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  // Singleton pattern
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  /// Enable/disable performance monitoring
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
  }

  /// Create a custom trace
  Trace createTrace(String name) {
    return _performance.newTrace(name);
  }

  /// Start and return a trace for manual control
  Future<Trace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Stop a trace
  Future<void> stopTrace(Trace trace) async {
    await trace.stop();
  }

  /// Create an HTTP metric
  HttpMetric createHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // Predefined traces for common operations

  /// Trace product loading
  Future<T> traceProductLoad<T>(Future<T> Function() operation) async {
    final trace = _performance.newTrace('product_load');
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace product search
  Future<T> traceProductSearch<T>(
    Future<T> Function() operation,
    String searchTerm,
  ) async {
    final trace = _performance.newTrace('product_search');
    trace.putAttribute('search_term', searchTerm);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace cart operations
  Future<T> traceCartOperation<T>(
    Future<T> Function() operation,
    String operationType,
  ) async {
    final trace = _performance.newTrace('cart_operation');
    trace.putAttribute('operation_type', operationType);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace order placement
  Future<T> traceOrderPlacement<T>(Future<T> Function() operation) async {
    final trace = _performance.newTrace('order_placement');
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace checkout process
  Future<T> traceCheckout<T>(Future<T> Function() operation) async {
    final trace = _performance.newTrace('checkout_process');
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace image upload
  Future<T> traceImageUpload<T>(
    Future<T> Function() operation,
    int fileSizeBytes,
  ) async {
    final trace = _performance.newTrace('image_upload');
    trace.putAttribute('file_size_bytes', fileSizeBytes.toString());
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace authentication
  Future<T> traceAuthentication<T>(
    Future<T> Function() operation,
    String authMethod,
  ) async {
    final trace = _performance.newTrace('authentication');
    trace.putAttribute('auth_method', authMethod);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace admin operations
  Future<T> traceAdminOperation<T>(
    Future<T> Function() operation,
    String operationType,
  ) async {
    final trace = _performance.newTrace('admin_operation');
    trace.putAttribute('operation_type', operationType);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace database query
  Future<T> traceDatabaseQuery<T>(
    Future<T> Function() operation,
    String queryType,
  ) async {
    final trace = _performance.newTrace('database_query');
    trace.putAttribute('query_type', queryType);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace screen load
  Future<T> traceScreenLoad<T>(
    Future<T> Function() operation,
    String screenName,
  ) async {
    final trace = _performance.newTrace('screen_load');
    trace.putAttribute('screen_name', screenName);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  // HTTP Metrics helpers

  /// Trace HTTP request
  Future<T> traceHttpRequest<T>(
    Future<T> Function() operation,
    String url,
    HttpMethod method, {
    int? requestPayloadSize,
    int? responsePayloadSize,
    String? responseContentType,
  }) async {
    final metric = _performance.newHttpMetric(url, method);

    if (requestPayloadSize != null) {
      metric.requestPayloadSize = requestPayloadSize;
    }

    await metric.start();

    try {
      final result = await operation();

      if (responsePayloadSize != null) {
        metric.responsePayloadSize = responsePayloadSize;
      }
      if (responseContentType != null) {
        metric.responseContentType = responseContentType;
      }
      metric.httpResponseCode = 200;

      await metric.stop();
      return result;
    } catch (e) {
      metric.httpResponseCode = 500;
      await metric.stop();
      rethrow;
    }
  }

  /// Trace Firestore read
  Future<T> traceFirestoreRead<T>(
    Future<T> Function() operation,
    String collection,
  ) async {
    final trace = _performance.newTrace('firestore_read');
    trace.putAttribute('collection', collection);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace Firestore write
  Future<T> traceFirestoreWrite<T>(
    Future<T> Function() operation,
    String collection,
  ) async {
    final trace = _performance.newTrace('firestore_write');
    trace.putAttribute('collection', collection);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace Firebase Storage upload
  Future<T> traceStorageUpload<T>(
    Future<T> Function() operation,
    String path,
  ) async {
    final trace = _performance.newTrace('storage_upload');
    trace.putAttribute('path', path);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// Trace Firebase Storage download
  Future<T> traceStorageDownload<T>(
    Future<T> Function() operation,
    String path,
  ) async {
    final trace = _performance.newTrace('storage_download');
    trace.putAttribute('path', path);
    await trace.start();
    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }
}
