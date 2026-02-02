import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_config.dart';

/// Enum representing order capacity status based on pending order count
enum OrderCapacityStatus {
  /// Normal capacity - less than warning threshold
  normal,

  /// Warning capacity - at or above warning threshold but below block threshold
  warning,

  /// Blocked capacity - at or above block threshold
  blocked,
}

/// Custom exceptions for config operations
class ConfigException implements Exception {
  final String message;
  ConfigException(this.message);

  @override
  String toString() => message;
}

class ConfigNotFoundException extends ConfigException {
  ConfigNotFoundException() : super('Configuration not found');
}

class InvalidConfigException extends ConfigException {
  InvalidConfigException(String message)
    : super('Invalid configuration: $message');
}

/// Service for managing app configuration with singleton pattern
/// Provides caching and real-time updates for app-wide settings
class ConfigService {
  // Singleton pattern
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'config';
  final String _documentId = 'app_settings';

  // Cache for configuration
  AppConfig? _cachedConfig;
  StreamSubscription<DocumentSnapshot>? _configSubscription;
  final StreamController<AppConfig> _configStreamController =
      StreamController<AppConfig>.broadcast();

  /// Get the current configuration
  /// Returns cached config if available, otherwise fetches from Firestore
  /// Implements in-memory caching for optimal performance
  Future<AppConfig> getConfig() async {
    // Return cached config if available
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        throw ConfigNotFoundException();
      }

      final config = AppConfig.fromJson(doc.data() as Map<String, dynamic>);
      _cachedConfig = config;
      return config;
    } catch (e) {
      if (e is ConfigException) {
        rethrow;
      }
      throw ConfigException('Failed to fetch configuration: $e');
    }
  }

  /// Preload configuration into cache
  /// Call this during app initialization for better performance
  Future<void> preloadConfig() async {
    if (_cachedConfig == null) {
      await getConfig();
    }
  }

  /// Stream of configuration for real-time updates
  /// Automatically updates cache when configuration changes
  Stream<AppConfig> watchConfig() {
    // Start listening if not already listening
    if (_configSubscription == null) {
      _configSubscription = _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                final config = AppConfig.fromJson(
                  snapshot.data() as Map<String, dynamic>,
                );
                _cachedConfig = config;
                _configStreamController.add(config);
              }
            },
            onError: (error) {
              _configStreamController.addError(
                ConfigException('Failed to watch configuration: $error'),
              );
            },
          );
    }

    return _configStreamController.stream;
  }

  /// Update configuration (admin only)
  /// Validates configuration values before saving
  /// Updates cache after successful save
  Future<void> updateConfig(AppConfig config) async {
    try {
      // Validate configuration
      _validateConfig(config);

      // Prepare data for Firestore
      final data = {
        'deliveryCharge': config.deliveryCharge,
        'freeDeliveryThreshold': config.freeDeliveryThreshold,
        'maxCartValue': config.maxCartValue,
        'orderCapacityWarningThreshold': config.orderCapacityWarningThreshold,
        'orderCapacityBlockThreshold': config.orderCapacityBlockThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': config.updatedBy,
      };

      // Update in Firestore
      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(data, SetOptions(merge: true));

      // Update cache with new config (using current time since serverTimestamp is pending)
      _cachedConfig = config.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      if (e is ConfigException) {
        rethrow;
      }
      throw ConfigException('Failed to update configuration: $e');
    }
  }

  /// Calculate delivery charge based on cart value
  /// Returns 0 if cart value meets free delivery threshold
  double calculateDeliveryCharge(double cartValue) {
    if (_cachedConfig == null) {
      // Use default values if config not loaded
      return cartValue >= 200.0 ? 0.0 : 20.0;
    }

    if (cartValue >= _cachedConfig!.freeDeliveryThreshold) {
      return 0.0;
    }

    return _cachedConfig!.deliveryCharge;
  }

  /// Check if cart value is within valid limits
  /// Returns true if cart value is less than or equal to max cart value
  bool isCartValueValid(double cartValue) {
    if (_cachedConfig == null) {
      // Use default value if config not loaded
      return cartValue <= 3000.0;
    }

    return cartValue <= _cachedConfig!.maxCartValue;
  }

  /// Get order capacity status based on pending order count
  /// Returns normal, warning, or blocked status
  OrderCapacityStatus getOrderCapacityStatus(int pendingCount) {
    if (_cachedConfig == null) {
      // Use default values if config not loaded
      if (pendingCount >= 10) {
        return OrderCapacityStatus.blocked;
      } else if (pendingCount >= 2) {
        return OrderCapacityStatus.warning;
      }
      return OrderCapacityStatus.normal;
    }

    if (pendingCount >= _cachedConfig!.orderCapacityBlockThreshold) {
      return OrderCapacityStatus.blocked;
    } else if (pendingCount >= _cachedConfig!.orderCapacityWarningThreshold) {
      return OrderCapacityStatus.warning;
    }

    return OrderCapacityStatus.normal;
  }

  /// Calculate amount needed to reach free delivery threshold
  /// Returns 0 if already eligible for free delivery
  double getAmountForFreeDelivery(double cartValue) {
    if (_cachedConfig == null) {
      // Use default value if config not loaded
      final remaining = 200.0 - cartValue;
      return remaining > 0 ? remaining : 0.0;
    }

    final remaining = _cachedConfig!.freeDeliveryThreshold - cartValue;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Initialize default configuration if it doesn't exist
  /// Should be called on app first launch or if config is missing
  Future<void> initializeDefaultConfig({String? adminId}) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        final defaultConfig = AppConfig.defaultConfig(adminId: adminId);

        final data = {
          'deliveryCharge': defaultConfig.deliveryCharge,
          'freeDeliveryThreshold': defaultConfig.freeDeliveryThreshold,
          'maxCartValue': defaultConfig.maxCartValue,
          'orderCapacityWarningThreshold':
              defaultConfig.orderCapacityWarningThreshold,
          'orderCapacityBlockThreshold':
              defaultConfig.orderCapacityBlockThreshold,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': defaultConfig.updatedBy,
        };

        await _firestore.collection(_collectionName).doc(_documentId).set(data);

        _cachedConfig = defaultConfig;
      }
    } catch (e) {
      throw ConfigException('Failed to initialize default configuration: $e');
    }
  }

  /// Validate configuration values
  /// Throws InvalidConfigException if validation fails
  void _validateConfig(AppConfig config) {
    // Validate delivery charge
    if (config.deliveryCharge < 0) {
      throw InvalidConfigException('Delivery charge cannot be negative');
    }

    if (config.deliveryCharge > 1000) {
      throw InvalidConfigException('Delivery charge cannot exceed ₹1000');
    }

    // Validate free delivery threshold
    if (config.freeDeliveryThreshold <= 0) {
      throw InvalidConfigException(
        'Free delivery threshold must be greater than 0',
      );
    }

    if (config.freeDeliveryThreshold > 10000) {
      throw InvalidConfigException(
        'Free delivery threshold cannot exceed ₹10000',
      );
    }

    // Validate max cart value
    if (config.maxCartValue <= config.freeDeliveryThreshold) {
      throw InvalidConfigException(
        'Max cart value must be greater than free delivery threshold',
      );
    }

    if (config.maxCartValue > 100000) {
      throw InvalidConfigException('Max cart value cannot exceed ₹100000');
    }

    // Validate order capacity thresholds
    if (config.orderCapacityWarningThreshold <= 0) {
      throw InvalidConfigException(
        'Order capacity warning threshold must be greater than 0',
      );
    }

    if (config.orderCapacityBlockThreshold <=
        config.orderCapacityWarningThreshold) {
      throw InvalidConfigException(
        'Order capacity block threshold must be greater than warning threshold',
      );
    }

    if (config.orderCapacityBlockThreshold > 1000) {
      throw InvalidConfigException(
        'Order capacity block threshold cannot exceed 1000',
      );
    }
  }

  /// Dispose of resources
  /// Cancels stream subscriptions and closes stream controllers
  void dispose() {
    _configSubscription?.cancel();
    _configSubscription = null;
    _configStreamController.close();
    _cachedConfig = null;
  }

  /// Reset the singleton instance (useful for testing)
  /// Disposes current instance and clears cache
  void reset() {
    dispose();
  }
}
