import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String phoneNumber;
  final String name;
  final String? defaultAddressId;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime lastLogin;

  Customer({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.defaultAddressId,
    this.isAdmin = false,
    required this.createdAt,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'defaultAddressId': defaultAddressId,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
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

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String,
      defaultAddressId: json['defaultAddressId'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      lastLogin: _parseDateTime(json['lastLogin']),
    );
  }

  Customer copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? defaultAddressId,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return Customer(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.phoneNumber == phoneNumber &&
        other.name == name &&
        other.defaultAddressId == defaultAddressId &&
        other.isAdmin == isAdmin &&
        other.createdAt == createdAt &&
        other.lastLogin == lastLogin;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      phoneNumber,
      name,
      defaultAddressId,
      isAdmin,
      createdAt,
      lastLogin,
    );
  }
}
