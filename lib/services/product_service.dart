import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'products';

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
}
