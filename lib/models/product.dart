import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;
  final String categoryId;
  final String unitSize;
  final int stockQuantity;
  final String imageUrl;
  final bool isActive;
  final int minimumOrderQuantity;
  final int? maximumOrderQuantity;
  final List<String> searchKeywords;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.categoryId,
    required this.unitSize,
    required this.stockQuantity,
    required this.imageUrl,
    this.isActive = true,
    this.minimumOrderQuantity = 1,
    this.maximumOrderQuantity,
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
      'discountPrice': discountPrice,
      'category': category,
      'categoryId': categoryId,
      'unitSize': unitSize,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'minimumOrderQuantity': minimumOrderQuantity,
      'maximumOrderQuantity': maximumOrderQuantity,
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
      discountPrice: json['discountPrice'] != null
          ? (json['discountPrice'] as num).toDouble()
          : null,
      category: json['category'] as String,
      categoryId: json['categoryId'] as String,
      unitSize: json['unitSize'] as String,
      stockQuantity: json['stockQuantity'] as int,
      imageUrl: json['imageUrl'] as String,
      isActive: json['isActive'] as bool? ?? true,
      minimumOrderQuantity: json['minimumOrderQuantity'] as int? ?? 1,
      maximumOrderQuantity: json['maximumOrderQuantity'] as int?,
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
    double? discountPrice,
    String? category,
    String? categoryId,
    String? unitSize,
    int? stockQuantity,
    String? imageUrl,
    bool? isActive,
    int? minimumOrderQuantity,
    int? maximumOrderQuantity,
    List<String>? searchKeywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      unitSize: unitSize ?? this.unitSize,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      maximumOrderQuantity: maximumOrderQuantity ?? this.maximumOrderQuantity,
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
        other.discountPrice == discountPrice &&
        other.category == category &&
        other.categoryId == categoryId &&
        other.unitSize == unitSize &&
        other.stockQuantity == stockQuantity &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive &&
        other.minimumOrderQuantity == minimumOrderQuantity &&
        other.maximumOrderQuantity == maximumOrderQuantity &&
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
      discountPrice,
      category,
      categoryId,
      unitSize,
      stockQuantity,
      imageUrl,
      isActive,
      minimumOrderQuantity,
      maximumOrderQuantity,
      Object.hashAll(searchKeywords),
      createdAt,
      updatedAt,
    );
  }

  /// Returns the effective price (discount price if available, otherwise regular price)
  double getEffectivePrice() {
    return discountPrice ?? price;
  }

  /// Calculates the total savings when buying a given quantity
  /// Returns 0.0 if no discount is applied
  double calculateSavings(int quantity) {
    if (discountPrice == null) return 0.0;
    return (price - discountPrice!) * quantity;
  }

  /// Returns the discount percentage as a formatted string
  /// Returns empty string if no discount is applied
  String getDiscountPercentage() {
    if (discountPrice == null) return '';
    double percentage = ((price - discountPrice!) / price) * 100;
    return '${percentage.toStringAsFixed(0)}% OFF';
  }

  /// Checks if a quantity is within the allowed order limits
  /// Returns true if quantity is valid (between min and max)
  bool isQuantityValid(int quantity) {
    if (quantity < minimumOrderQuantity) return false;
    if (maximumOrderQuantity != null && quantity > maximumOrderQuantity!) {
      return false;
    }
    return true;
  }

  /// Returns the maximum allowed quantity considering stock and max order limit
  /// Returns the lesser of stock quantity and maximum order quantity
  int getMaxAllowedQuantity() {
    if (maximumOrderQuantity == null) return stockQuantity;
    return maximumOrderQuantity! < stockQuantity
        ? maximumOrderQuantity!
        : stockQuantity;
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
