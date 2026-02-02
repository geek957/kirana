import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

/// Custom exceptions for category operations
class CategoryException implements Exception {
  final String message;
  CategoryException(this.message);

  @override
  String toString() => message;
}

class CategoryNameNotUniqueException extends CategoryException {
  CategoryNameNotUniqueException() : super('Category name already exists');
}

class CategoryHasProductsException extends CategoryException {
  CategoryHasProductsException()
    : super(
        'Cannot delete category with products. Please reassign products first.',
      );
}

class CategoryNotFoundException extends CategoryException {
  CategoryNotFoundException() : super('Category not found');
}

/// Service for managing product categories with Firestore integration
/// Implements caching for improved performance
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'categories';

  // Cache for categories with timestamp
  List<Category>? _cachedCategories;
  DateTime? _categoriesCacheTime;
  static const Duration _categoriesCacheDuration = Duration(minutes: 5);

  /// Get all categories sorted alphabetically by name
  /// Returns list of all categories in the system
  /// Implements caching with 5-minute TTL to reduce Firestore reads
  Future<List<Category>> getCategories() async {
    try {
      // Check if cached value is still valid
      if (_cachedCategories != null && _categoriesCacheTime != null) {
        final cacheAge = DateTime.now().difference(_categoriesCacheTime!);
        if (cacheAge < _categoriesCacheDuration) {
          return _cachedCategories!;
        }
      }

      // Cache expired or not available, fetch from Firestore
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('name')
          .get();

      final categories = snapshot.docs
          .map((doc) => Category.fromJson(doc.data()))
          .toList();

      // Update cache
      _cachedCategories = categories;
      _categoriesCacheTime = DateTime.now();

      return categories;
    } catch (e) {
      // If query fails, return cached value if available
      if (_cachedCategories != null) {
        return _cachedCategories!;
      }
      throw CategoryException('Failed to fetch categories: $e');
    }
  }

  /// Clear the categories cache
  /// Useful when you know categories have changed and want to force a refresh
  void clearCache() {
    _cachedCategories = null;
    _categoriesCacheTime = null;
  }

  /// Preload categories into cache
  /// Call this during app initialization for better performance
  Future<void> preloadCategories() async {
    if (_cachedCategories == null) {
      await getCategories();
    }
  }

  /// Stream of categories for real-time updates
  /// Returns a stream that emits updated category list whenever data changes
  Stream<List<Category>> watchCategories() {
    try {
      return _firestore
          .collection(_collectionName)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Category.fromJson(doc.data()))
                .toList();
          });
    } catch (e) {
      throw CategoryException('Failed to watch categories: $e');
    }
  }

  /// Get a single category by ID
  /// Returns null if category doesn't exist
  Future<Category?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return Category.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw CategoryException('Failed to fetch category: $e');
    }
  }

  /// Create a new category with unique name validation
  /// Throws CategoryNameNotUniqueException if name already exists
  /// Returns the created category with generated ID
  /// Clears cache to ensure fresh data on next fetch
  Future<Category> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      // Validate name is not empty
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        throw CategoryException('Category name cannot be empty');
      }

      // Check for unique name
      final isUnique = await isCategoryNameUnique(trimmedName);
      if (!isUnique) {
        throw CategoryNameNotUniqueException();
      }

      // Create new category document
      final docRef = _firestore.collection(_collectionName).doc();
      final now = DateTime.now();

      final category = Category(
        id: docRef.id,
        name: trimmedName,
        description: description?.trim(),
        productCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await docRef.set({
        'id': category.id,
        'name': category.name,
        'description': category.description,
        'productCount': category.productCount,
        'createdAt': Timestamp.fromDate(category.createdAt),
        'updatedAt': Timestamp.fromDate(category.updatedAt),
      });

      // Clear cache to ensure fresh data
      clearCache();

      return category;
    } catch (e) {
      if (e is CategoryException) {
        rethrow;
      }
      throw CategoryException('Failed to create category: $e');
    }
  }

  /// Update an existing category
  /// Validates unique name if name is being changed
  /// Throws CategoryNotFoundException if category doesn't exist
  /// Throws CategoryNameNotUniqueException if new name already exists
  /// Clears cache to ensure fresh data on next fetch
  Future<void> updateCategory({
    required String id,
    required String name,
    String? description,
  }) async {
    try {
      // Validate name is not empty
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        throw CategoryException('Category name cannot be empty');
      }

      // Check if category exists
      final existingCategory = await getCategoryById(id);
      if (existingCategory == null) {
        throw CategoryNotFoundException();
      }

      // Check for unique name if name is being changed
      if (existingCategory.name != trimmedName) {
        final isUnique = await isCategoryNameUnique(trimmedName, excludeId: id);
        if (!isUnique) {
          throw CategoryNameNotUniqueException();
        }
      }

      // Update category
      await _firestore.collection(_collectionName).doc(id).update({
        'name': trimmedName,
        'description': description?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache to ensure fresh data
      clearCache();
    } catch (e) {
      if (e is CategoryException) {
        rethrow;
      }
      throw CategoryException('Failed to update category: $e');
    }
  }

  /// Delete a category
  /// Validates that category has no products assigned
  /// Throws CategoryNotFoundException if category doesn't exist
  /// Throws CategoryHasProductsException if category has products
  /// Clears cache to ensure fresh data on next fetch
  Future<void> deleteCategory(String id) async {
    try {
      // Check if category exists
      final category = await getCategoryById(id);
      if (category == null) {
        throw CategoryNotFoundException();
      }

      // Validate no products are assigned
      final productCount = await getProductCount(id);
      if (productCount > 0) {
        throw CategoryHasProductsException();
      }

      // Delete category
      await _firestore.collection(_collectionName).doc(id).delete();

      // Clear cache to ensure fresh data
      clearCache();
    } catch (e) {
      if (e is CategoryException) {
        rethrow;
      }
      throw CategoryException('Failed to delete category: $e');
    }
  }

  /// Check if a category name is unique
  /// Optionally exclude a specific category ID (for updates)
  /// Returns true if name is unique, false otherwise
  Future<bool> isCategoryNameUnique(String name, {String? excludeId}) async {
    try {
      final trimmedName = name.trim();

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: trimmedName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return true;
      }

      // If excludeId is provided, check if the found category is the one being excluded
      if (excludeId != null && snapshot.docs.first.id == excludeId) {
        return true;
      }

      return false;
    } catch (e) {
      throw CategoryException('Failed to check category name uniqueness: $e');
    }
  }

  /// Get the number of products assigned to a category
  /// Returns the count of products with this categoryId
  Future<int> getProductCount(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw CategoryException('Failed to get product count: $e');
    }
  }

  /// Increment the product count for a category
  /// Should be called when a product is assigned to this category
  Future<void> incrementProductCount(String categoryId) async {
    try {
      await _firestore.collection(_collectionName).doc(categoryId).update({
        'productCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CategoryException('Failed to increment product count: $e');
    }
  }

  /// Decrement the product count for a category
  /// Should be called when a product is removed from this category
  /// Ensures count doesn't go below 0
  Future<void> decrementProductCount(String categoryId) async {
    try {
      // Get current count to ensure it doesn't go below 0
      final category = await getCategoryById(categoryId);
      if (category != null && category.productCount > 0) {
        await _firestore.collection(_collectionName).doc(categoryId).update({
          'productCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw CategoryException('Failed to decrement product count: $e');
    }
  }

  /// Recalculate and update the product count for a category
  /// Useful for fixing inconsistencies in denormalized data
  Future<void> recalculateProductCount(String categoryId) async {
    try {
      final actualCount = await getProductCount(categoryId);

      await _firestore.collection(_collectionName).doc(categoryId).update({
        'productCount': actualCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CategoryException('Failed to recalculate product count: $e');
    }
  }
}
