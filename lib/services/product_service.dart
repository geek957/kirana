import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'category_service.dart';

/// Custom exceptions for product operations
class ProductException implements Exception {
  final String message;
  ProductException(this.message);

  @override
  String toString() => message;
}

class InvalidDiscountPriceException extends ProductException {
  InvalidDiscountPriceException(super.message);
}

class InvalidMinimumQuantityException extends ProductException {
  InvalidMinimumQuantityException(super.message);
}

class InvalidMaximumQuantityException extends ProductException {
  InvalidMaximumQuantityException(super.message);
}

class ProductNotFoundException extends ProductException {
  ProductNotFoundException() : super('Product not found');
}

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'products';
  final CategoryService _categoryService = CategoryService();

  /// Get products with optional category and search filters
  /// Returns list of active products matching the criteria
  Future<List<Product>> getProducts({
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);

      // Build query based on filters to minimize index requirements
      if (category != null && category.isNotEmpty) {
        query = query
            .where('category', isEqualTo: category)
            .where('isActive', isEqualTo: true);
      } else if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerm = searchQuery.toLowerCase();
        query = query
            .where('searchKeywords', arrayContains: searchTerm)
            .where('isActive', isEqualTo: true);
      } else {
        // For all products, filter by isActive and order by name
        query = query.where('isActive', isEqualTo: true).orderBy('name');
      }

      query = query.limit(limit);

      // Apply pagination if startAfter document is provided
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get a single product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(productId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Product.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Check if sufficient stock is available for a product
  Future<bool> checkStockAvailability(
    String productId,
    int requestedQuantity,
  ) async {
    try {
      final product = await getProductById(productId);

      if (product == null) {
        return false;
      }

      return product.isActive && product.stockQuantity >= requestedQuantity;
    } catch (e) {
      throw Exception('Failed to check stock availability: $e');
    }
  }

  /// Get all unique categories from active products
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Stream of products for real-time updates
  Stream<List<Product>> getProductsStream({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) {
    Query query = _firestore.collection(_collectionName);

    // Build query based on filters to minimize index requirements
    if (category != null && category.isNotEmpty) {
      query = query
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true);
    } else if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchTerm = searchQuery.toLowerCase();
      query = query
          .where('searchKeywords', arrayContains: searchTerm)
          .where('isActive', isEqualTo: true);
    } else {
      query = query.where('isActive', isEqualTo: true).orderBy('name');
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Generate search keywords for a product
  /// This is a utility method that can be used when creating/updating products
  static List<String> generateSearchKeywords(String name, String category) {
    final keywords = <String>{};
    keywords.add(name.toLowerCase());
    keywords.add(category.toLowerCase());
    keywords.addAll(name.toLowerCase().split(' '));
    return keywords.toList();
  }

  // ========== Discount Management Methods ==========

  /// Set or update discount price for a product
  /// Validates that discountPrice < price
  /// Pass null to remove discount
  Future<void> setDiscount({
    required String productId,
    required double? discountPrice,
  }) async {
    try {
      // Get the product to validate against its price
      final product = await getProductById(productId);
      if (product == null) {
        throw ProductNotFoundException();
      }

      // Validate discount price if provided
      if (discountPrice != null) {
        if (!validateDiscountPrice(product.price, discountPrice)) {
          throw InvalidDiscountPriceException(
            'Discount price must be greater than 0 and less than regular price (${product.price})',
          );
        }
      }

      // Update the product
      await _firestore.collection(_collectionName).doc(productId).update({
        'discountPrice': discountPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is ProductException) {
        rethrow;
      }
      throw ProductException('Failed to set discount: $e');
    }
  }

  /// Remove discount from a product
  /// Convenience method that sets discountPrice to null
  Future<void> removeDiscount(String productId) async {
    await setDiscount(productId: productId, discountPrice: null);
  }

  /// Validate discount price
  /// Returns true if discount price is valid (> 0 and < regular price)
  bool validateDiscountPrice(double price, double? discountPrice) {
    if (discountPrice == null) return true;
    return discountPrice > 0 && discountPrice < price;
  }

  // ========== Category Management Methods ==========

  /// Update the category of a product
  /// Updates both categoryId and category name fields
  /// Updates product counts for both old and new categories
  Future<void> updateProductCategory({
    required String productId,
    required String categoryId,
  }) async {
    try {
      // Get the product to get old category
      final product = await getProductById(productId);
      if (product == null) {
        throw ProductNotFoundException();
      }

      // Get the new category to get its name
      final newCategory = await _categoryService.getCategoryById(categoryId);
      if (newCategory == null) {
        throw ProductException('Category not found');
      }

      final oldCategoryId = product.categoryId;

      // Use batch write to update product and category counts atomically
      final batch = _firestore.batch();

      // Update product
      batch.update(_firestore.collection(_collectionName).doc(productId), {
        'categoryId': categoryId,
        'category': newCategory.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update old category count (decrement)
      if (oldCategoryId != categoryId) {
        batch.update(_firestore.collection('categories').doc(oldCategoryId), {
          'productCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update new category count (increment)
        batch.update(_firestore.collection('categories').doc(categoryId), {
          'productCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      if (e is ProductException) {
        rethrow;
      }
      throw ProductException('Failed to update product category: $e');
    }
  }

  /// Batch update categories for multiple products
  /// Useful for reassigning products when deleting a category
  Future<void> batchUpdateProductCategories({
    required List<String> productIds,
    required String categoryId,
  }) async {
    try {
      // Get the new category
      final newCategory = await _categoryService.getCategoryById(categoryId);
      if (newCategory == null) {
        throw ProductException('Category not found');
      }

      // Process in batches of 500 (Firestore batch limit)
      const batchSize = 500;
      for (var i = 0; i < productIds.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < productIds.length)
            ? i + batchSize
            : productIds.length;
        final batchProductIds = productIds.sublist(i, end);

        for (final productId in batchProductIds) {
          batch.update(_firestore.collection(_collectionName).doc(productId), {
            'categoryId': categoryId,
            'category': newCategory.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }
    } catch (e) {
      throw ProductException('Failed to batch update product categories: $e');
    }
  }

  /// Get products by category with pagination
  /// Returns list of products in the specified category
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool activeOnly = true,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('categoryId', isEqualTo: categoryId);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      query = query.orderBy('name').limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ProductException('Failed to fetch products by category: $e');
    }
  }

  // ========== Minimum Quantity Management Methods ==========

  /// Set minimum order quantity for a product
  /// Validates that quantity >= 1
  Future<void> setMinimumQuantity({
    required String productId,
    required int quantity,
  }) async {
    try {
      // Validate minimum quantity
      if (!validateMinimumQuantity(quantity)) {
        throw InvalidMinimumQuantityException(
          'Minimum order quantity must be at least 1',
        );
      }

      // Update the product
      await _firestore.collection(_collectionName).doc(productId).update({
        'minimumOrderQuantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is ProductException) {
        rethrow;
      }
      throw ProductException('Failed to set minimum quantity: $e');
    }
  }

  /// Validate minimum quantity
  /// Returns true if quantity >= 1
  bool validateMinimumQuantity(int quantity) {
    return quantity >= 1;
  }

  // ========== Product CRUD Methods ==========

  /// Create a new product with all fields including discount, category, and minimum quantity
  /// Validates discount price and minimum quantity
  /// Updates category product count
  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    double? discountPrice,
    required String categoryId,
    required String unitSize,
    required int stockQuantity,
    required String imageUrl,
    bool isActive = true,
    int minimumOrderQuantity = 1,
    int? maximumOrderQuantity,
  }) async {
    try {
      // Validate discount price
      if (!validateDiscountPrice(price, discountPrice)) {
        throw InvalidDiscountPriceException(
          'Discount price must be greater than 0 and less than regular price ($price)',
        );
      }

      // Validate minimum quantity
      if (!validateMinimumQuantity(minimumOrderQuantity)) {
        throw InvalidMinimumQuantityException(
          'Minimum order quantity must be at least 1',
        );
      }

      // Validate maximum quantity if provided
      if (maximumOrderQuantity != null) {
        if (maximumOrderQuantity < 1) {
          throw InvalidMaximumQuantityException(
            'Maximum order quantity must be at least 1',
          );
        }
        if (maximumOrderQuantity < minimumOrderQuantity) {
          throw InvalidMaximumQuantityException(
            'Maximum order quantity must be greater than or equal to minimum order quantity',
          );
        }
      }

      // Get category to get its name
      final category = await _categoryService.getCategoryById(categoryId);
      if (category == null) {
        throw ProductException('Category not found');
      }

      // Create new product document
      final docRef = _firestore.collection(_collectionName).doc();
      final now = DateTime.now();

      final product = Product(
        id: docRef.id,
        name: name.trim(),
        description: description.trim(),
        price: price,
        discountPrice: discountPrice,
        category: category.name,
        categoryId: categoryId,
        unitSize: unitSize.trim(),
        stockQuantity: stockQuantity,
        imageUrl: imageUrl,
        isActive: isActive,
        minimumOrderQuantity: minimumOrderQuantity,
        maximumOrderQuantity: maximumOrderQuantity,
        searchKeywords: generateSearchKeywords(name, category.name),
        createdAt: now,
        updatedAt: now,
      );

      // Use batch to create product and update category count
      final batch = _firestore.batch();

      // Create product
      batch.set(docRef, {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'discountPrice': product.discountPrice,
        'category': product.category,
        'categoryId': product.categoryId,
        'unitSize': product.unitSize,
        'stockQuantity': product.stockQuantity,
        'imageUrl': product.imageUrl,
        'isActive': product.isActive,
        'minimumOrderQuantity': product.minimumOrderQuantity,
        'maximumOrderQuantity': product.maximumOrderQuantity,
        'searchKeywords': product.searchKeywords,
        'createdAt': Timestamp.fromDate(product.createdAt),
        'updatedAt': Timestamp.fromDate(product.updatedAt),
      });

      // Increment category product count
      batch.update(_firestore.collection('categories').doc(categoryId), {
        'productCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return product;
    } catch (e) {
      if (e is ProductException) {
        rethrow;
      }
      throw ProductException('Failed to create product: $e');
    }
  }

  /// Update an existing product with all fields
  /// Validates discount price and minimum quantity
  /// Updates category product count if category changed
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? categoryId,
    String? unitSize,
    int? stockQuantity,
    String? imageUrl,
    bool? isActive,
    int? minimumOrderQuantity,
    int? maximumOrderQuantity,
  }) async {
    try {
      // Get existing product
      final existingProduct = await getProductById(productId);
      if (existingProduct == null) {
        throw ProductNotFoundException();
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {};

      // Validate and add price fields
      final newPrice = price ?? existingProduct.price;
      final newDiscountPrice = discountPrice ?? existingProduct.discountPrice;

      if (!validateDiscountPrice(newPrice, newDiscountPrice)) {
        throw InvalidDiscountPriceException(
          'Discount price must be greater than 0 and less than regular price ($newPrice)',
        );
      }

      if (price != null) updateData['price'] = price;
      if (discountPrice != null) {
        updateData['discountPrice'] = discountPrice;
      }

      // Validate and add minimum quantity
      if (minimumOrderQuantity != null) {
        if (!validateMinimumQuantity(minimumOrderQuantity)) {
          throw InvalidMinimumQuantityException(
            'Minimum order quantity must be at least 1',
          );
        }
        updateData['minimumOrderQuantity'] = minimumOrderQuantity;
      }

      // Validate and add maximum quantity
      if (maximumOrderQuantity != null) {
        final newMin = minimumOrderQuantity ?? existingProduct.minimumOrderQuantity;
        if (maximumOrderQuantity < 1) {
          throw InvalidMaximumQuantityException(
            'Maximum order quantity must be at least 1',
          );
        }
        if (maximumOrderQuantity < newMin) {
          throw InvalidMaximumQuantityException(
            'Maximum order quantity must be greater than or equal to minimum order quantity',
          );
        }
        updateData['maximumOrderQuantity'] = maximumOrderQuantity;
      }

      // Add other fields
      if (name != null) updateData['name'] = name.trim();
      if (description != null) updateData['description'] = description.trim();
      if (unitSize != null) updateData['unitSize'] = unitSize.trim();
      if (stockQuantity != null) updateData['stockQuantity'] = stockQuantity;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isActive != null) updateData['isActive'] = isActive;

      // Handle category change
      if (categoryId != null && categoryId != existingProduct.categoryId) {
        final newCategory = await _categoryService.getCategoryById(categoryId);
        if (newCategory == null) {
          throw ProductException('Category not found');
        }

        updateData['categoryId'] = categoryId;
        updateData['category'] = newCategory.name;

        // Update search keywords if name or category changed
        final newName = name ?? existingProduct.name;
        updateData['searchKeywords'] = generateSearchKeywords(
          newName,
          newCategory.name,
        );

        // Use batch to update product and category counts
        final batch = _firestore.batch();

        // Update product
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        batch.update(
          _firestore.collection(_collectionName).doc(productId),
          updateData,
        );

        // Update old category count (decrement)
        batch.update(
          _firestore.collection('categories').doc(existingProduct.categoryId),
          {
            'productCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Update new category count (increment)
        batch.update(_firestore.collection('categories').doc(categoryId), {
          'productCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      } else {
        // No category change, simple update
        if (name != null) {
          updateData['searchKeywords'] = generateSearchKeywords(
            name,
            existingProduct.category,
          );
        }

        updateData['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection(_collectionName)
            .doc(productId)
            .update(updateData);
      }
    } catch (e) {
      if (e is ProductException) {
        rethrow;
      }
      throw ProductException('Failed to update product: $e');
    }
  }
}
