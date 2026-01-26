import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String customerId;
  final String label;
  final String fullAddress;
  final String? landmark;
  final String contactNumber;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.customerId,
    required this.label,
    required this.fullAddress,
    this.landmark,
    required this.contactNumber,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'label': label,
      'fullAddress': fullAddress,
      'landmark': landmark,
      'contactNumber': contactNumber,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate(); // Firestore Timestamp
    } else if (value is String) {
      return DateTime.parse(value); // ISO string
    } else {
      throw Exception('Invalid datetime value: $value');
    }
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      label: json['label'] as String,
      fullAddress: json['fullAddress'] as String,
      landmark: json['landmark'] as String?,
      contactNumber: json['contactNumber'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Address copyWith({
    String? id,
    String? customerId,
    String? label,
    String? fullAddress,
    String? landmark,
    String? contactNumber,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      landmark: landmark ?? this.landmark,
      contactNumber: contactNumber ?? this.contactNumber,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.id == id &&
        other.customerId == customerId &&
        other.label == label &&
        other.fullAddress == fullAddress &&
        other.landmark == landmark &&
        other.contactNumber == contactNumber &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      label,
      fullAddress,
      landmark,
      contactNumber,
      isDefault,
      createdAt,
      updatedAt,
    );
  }
}
