import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.dart';
import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  String toJson() => name;

  static OrderStatus fromJson(String json) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == json,
      orElse: () => OrderStatus.pending,
    );
  }
}

enum PaymentMethod {
  cashOnDelivery;

  String toJson() => name;

  static PaymentMethod fromJson(String json) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == json,
      orElse: () => PaymentMethod.cashOnDelivery,
    );
  }
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final String addressId;
  final Address deliveryAddress;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.addressId,
    required this.deliveryAddress,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'addressId': addressId,
      'deliveryAddress': deliveryAddress.toJson(),
      'status': status.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
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

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      addressId: json['addressId'] as String,
      deliveryAddress: Address.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>,
      ),
      status: OrderStatus.fromJson(json['status'] as String),
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      createdAt: _parseDateTime(json['createdAt']),
      deliveredAt: json['deliveredAt'] != null
          ? _parseDateTime(json['deliveredAt'])
          : null,
    );
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<OrderItem>? items,
    double? totalAmount,
    String? addressId,
    Address? deliveryAddress,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      addressId: addressId ?? this.addressId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.id == id &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.customerPhone == customerPhone &&
        _listEquals(other.items, items) &&
        other.totalAmount == totalAmount &&
        other.addressId == addressId &&
        other.deliveryAddress == deliveryAddress &&
        other.status == status &&
        other.paymentMethod == paymentMethod &&
        other.createdAt == createdAt &&
        other.deliveredAt == deliveredAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      customerName,
      customerPhone,
      Object.hashAll(items),
      totalAmount,
      addressId,
      deliveryAddress,
      status,
      paymentMethod,
      createdAt,
      deliveredAt,
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
