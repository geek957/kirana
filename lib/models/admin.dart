import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String id;
  final String username;
  final String phoneNumber;
  final DateTime createdAt;

  Admin({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
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

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as String,
      username: json['username'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Admin copyWith({
    String? id,
    String? username,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return Admin(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Admin &&
        other.id == id &&
        other.username == username &&
        other.phoneNumber == phoneNumber &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, username, phoneNumber, createdAt);
  }
}
