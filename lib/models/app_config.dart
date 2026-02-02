import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfig {
  final double deliveryCharge;
  final double freeDeliveryThreshold;
  final double maxCartValue;
  final int orderCapacityWarningThreshold;
  final int orderCapacityBlockThreshold;
  final DateTime updatedAt;
  final String updatedBy;

  AppConfig({
    required this.deliveryCharge,
    required this.freeDeliveryThreshold,
    required this.maxCartValue,
    required this.orderCapacityWarningThreshold,
    required this.orderCapacityBlockThreshold,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Factory constructor with default values
  factory AppConfig.defaultConfig({String? adminId}) {
    return AppConfig(
      deliveryCharge: 20.0,
      freeDeliveryThreshold: 200.0,
      maxCartValue: 3000.0,
      orderCapacityWarningThreshold: 2,
      orderCapacityBlockThreshold: 10,
      updatedAt: DateTime.now(),
      updatedBy: adminId ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryCharge': deliveryCharge,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'maxCartValue': maxCartValue,
      'orderCapacityWarningThreshold': orderCapacityWarningThreshold,
      'orderCapacityBlockThreshold': orderCapacityBlockThreshold,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      // Firestore Timestamp object
      return value.toDate();
    } else if (value is String) {
      // ISO 8601 string
      return DateTime.parse(value);
    } else {
      throw Exception('Invalid datetime value: $value');
    }
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      deliveryCharge: (json['deliveryCharge'] as num).toDouble(),
      freeDeliveryThreshold: (json['freeDeliveryThreshold'] as num).toDouble(),
      maxCartValue: (json['maxCartValue'] as num).toDouble(),
      orderCapacityWarningThreshold:
          json['orderCapacityWarningThreshold'] as int,
      orderCapacityBlockThreshold: json['orderCapacityBlockThreshold'] as int,
      updatedAt: _parseDateTime(json['updatedAt']),
      updatedBy: json['updatedBy'] as String,
    );
  }

  AppConfig copyWith({
    double? deliveryCharge,
    double? freeDeliveryThreshold,
    double? maxCartValue,
    int? orderCapacityWarningThreshold,
    int? orderCapacityBlockThreshold,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AppConfig(
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      freeDeliveryThreshold:
          freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      maxCartValue: maxCartValue ?? this.maxCartValue,
      orderCapacityWarningThreshold:
          orderCapacityWarningThreshold ?? this.orderCapacityWarningThreshold,
      orderCapacityBlockThreshold:
          orderCapacityBlockThreshold ?? this.orderCapacityBlockThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfig &&
        other.deliveryCharge == deliveryCharge &&
        other.freeDeliveryThreshold == freeDeliveryThreshold &&
        other.maxCartValue == maxCartValue &&
        other.orderCapacityWarningThreshold == orderCapacityWarningThreshold &&
        other.orderCapacityBlockThreshold == orderCapacityBlockThreshold &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      deliveryCharge,
      freeDeliveryThreshold,
      maxCartValue,
      orderCapacityWarningThreshold,
      orderCapacityBlockThreshold,
      updatedAt,
      updatedBy,
    );
  }
}
