import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class Cart {
  final String customerId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime updatedAt;

  Cart({
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.updatedAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double calculateTotal() {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
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

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      customerId: json['customerId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Cart copyWith({
    String? customerId,
    List<CartItem>? items,
    double? totalAmount,
    DateTime? updatedAt,
  }) {
    return Cart(
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart &&
        other.customerId == customerId &&
        _listEquals(other.items, items) &&
        other.totalAmount == totalAmount &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      customerId,
      Object.hashAll(items),
      totalAmount,
      updatedAt,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
