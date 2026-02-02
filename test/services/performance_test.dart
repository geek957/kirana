import 'package:flutter_test/flutter_test.dart';
import 'package:kirana/utils/performance_utils.dart';

void main() {
  group('Performance Utils Tests', () {
    test('isCacheValid returns false for null cache time', () {
      expect(
        PerformanceUtils.isCacheValid(null, const Duration(minutes: 5)),
        false,
      );
    });

    test('isCacheValid returns true for fresh cache', () {
      final cacheTime = DateTime.now().subtract(const Duration(minutes: 2));
      expect(
        PerformanceUtils.isCacheValid(cacheTime, const Duration(minutes: 5)),
        true,
      );
    });

    test('isCacheValid returns false for expired cache', () {
      final cacheTime = DateTime.now().subtract(const Duration(minutes: 10));
      expect(
        PerformanceUtils.isCacheValid(cacheTime, const Duration(minutes: 5)),
        false,
      );
    });

    test('measureSync executes function and returns result', () {
      final result = PerformanceUtils.measureSync('test operation', () => 42);
      expect(result, 42);
    });

    test('measureAsync executes function and returns result', () async {
      final result = await PerformanceUtils.measureAsync(
        'test operation',
        () async => 42,
      );
      expect(result, 42);
    });

    test('measureSync handles exceptions', () {
      expect(
        () => PerformanceUtils.measureSync(
          'test operation',
          () => throw Exception('test error'),
        ),
        throwsException,
      );
    });

    test('measureAsync handles exceptions', () async {
      expect(
        () => PerformanceUtils.measureAsync(
          'test operation',
          () async => throw Exception('test error'),
        ),
        throwsException,
      );
    });
  });

  group('Cache Configuration Tests', () {
    test('cache durations are properly configured', () {
      expect(CacheConfig.appConfigCacheDuration, const Duration(minutes: 5));
      expect(CacheConfig.categoriesCacheDuration, const Duration(minutes: 5));
      expect(
        CacheConfig.pendingOrderCountCacheDuration,
        const Duration(seconds: 30),
      );
      expect(CacheConfig.productListCacheDuration, const Duration(minutes: 2));
    });
  });

  group('Pagination Configuration Tests', () {
    test('pagination sizes are properly configured', () {
      expect(PaginationConfig.defaultProductPageSize, 20);
      expect(PaginationConfig.defaultOrderPageSize, 20);
      expect(PaginationConfig.maxPageSize, 50);
    });
  });

  group('Image Optimization Configuration Tests', () {
    test('image optimization settings are properly configured', () {
      expect(ImageOptimizationConfig.maxDeliveryPhotoSize, 800);
      expect(ImageOptimizationConfig.maxDeliveryPhotoBytes, 500 * 1024);
      expect(ImageOptimizationConfig.compressionQuality, 85);
      expect(ImageOptimizationConfig.maxProductImageBytes, 500 * 1024);
    });
  });

  group('Performance Benchmarks', () {
    test('cache lookup should be fast', () {
      final stopwatch = Stopwatch()..start();
      final cacheTime = DateTime.now().subtract(const Duration(minutes: 2));
      final isValid = PerformanceUtils.isCacheValid(
        cacheTime,
        const Duration(minutes: 5),
      );
      stopwatch.stop();

      expect(isValid, true);
      expect(stopwatch.elapsedMicroseconds, lessThan(1000)); // < 1ms
    });

    test('sync measurement overhead should be minimal', () {
      final stopwatch = Stopwatch()..start();
      PerformanceUtils.measureSync('test', () => 42);
      stopwatch.stop();

      expect(stopwatch.elapsedMicroseconds, lessThan(10000)); // < 10ms
    });

    test('async measurement overhead should be minimal', () async {
      final stopwatch = Stopwatch()..start();
      await PerformanceUtils.measureAsync('test', () async => 42);
      stopwatch.stop();

      expect(stopwatch.elapsedMicroseconds, lessThan(10000)); // < 10ms
    });
  });
}
