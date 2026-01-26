import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String unitSize;
  final int stockQuantity;
  final String imageUrl;
  final bool isActive;
  final List<String> searchKeywords;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.unitSize,
    required this.stockQuantity,
    required this.imageUrl,
    this.isActive = true,
    List<String>? searchKeywords,
    required this.createdAt,
    required this.updatedAt,
  }) : searchKeywords =
           searchKeywords ?? _generateSearchKeywords(name, category);

  static List<String> _generateSearchKeywords(String name, String category) {
    final keywords = <String>{};
    keywords.add(name.toLowerCase());
    keywords.add(category.toLowerCase());
    keywords.addAll(name.toLowerCase().split(' '));
    return keywords.toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'unitSize': unitSize,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'searchKeywords': searchKeywords,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      unitSize: json['unitSize'] as String,
      stockQuantity: json['stockQuantity'] as int,
      imageUrl: json['imageUrl'] as String,
      isActive: json['isActive'] as bool? ?? true,
      searchKeywords: (json['searchKeywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? unitSize,
    int? stockQuantity,
    String? imageUrl,
    bool? isActive,
    List<String>? searchKeywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      unitSize: unitSize ?? this.unitSize,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.category == category &&
        other.unitSize == unitSize &&
        other.stockQuantity == stockQuantity &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive &&
        _listEquals(other.searchKeywords, searchKeywords) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      price,
      category,
      unitSize,
      stockQuantity,
      imageUrl,
      isActive,
      Object.hashAll(searchKeywords),
      createdAt,
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
