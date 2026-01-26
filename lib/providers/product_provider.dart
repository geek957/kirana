import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  // Getters
  List<Product> get products => _products;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Initialize provider by loading categories and initial products
  Future<void> initialize() async {
    await loadCategories();
    await loadProducts(refresh: true);
  }

  /// Load all available categories
  Future<void> loadCategories() async {
    try {
      _categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load categories: $e';
      notifyListeners();
    }
  }

  /// Load products with current filters
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading) return;

    // If refreshing, reset pagination
    if (refresh) {
      _products = [];
      _lastDocument = null;
      _hasMore = true;
    }

    // Don't load more if we've reached the end
    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _getProductsQuery().get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        final newProducts = snapshot.docs
            .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }

        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == 20; // Assuming limit of 20
      }
    } catch (e) {
      // Check if it's an index error
      if (e.toString().contains('index')) {
        _error =
            'Database index required. Please check console for index creation link.';
      } else {
        _error = 'Failed to load products: $e';
      }
      print('Error loading products: $e'); // Log full error for debugging
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set up real-time listener for products
  void listenToProducts() {
    _productService
        .getProductsStream(
          category: _selectedCategory,
          searchQuery: _searchQuery,
        )
        .listen(
          (products) {
            _products = products;
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to listen to products: $error';
            notifyListeners();
          },
        );
  }

  /// Update search query and reload products
  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;

    _searchQuery = query;
    notifyListeners();

    // Debounce search by adding a small delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Only search if query hasn't changed during delay
    if (_searchQuery == query) {
      await loadProducts(refresh: true);
    }
  }

  /// Update selected category and reload products
  Future<void> setCategory(String? category) async {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    await loadProducts(refresh: true);
  }

  /// Clear all filters and reload products
  Future<void> clearFilters() async {
    _selectedCategory = null;
    _searchQuery = '';
    await loadProducts(refresh: true);
  }

  /// Get a single product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      return await _productService.getProductById(productId);
    } catch (e) {
      _error = 'Failed to fetch product: $e';
      notifyListeners();
      return null;
    }
  }

  /// Check if sufficient stock is available
  Future<bool> checkStockAvailability(
    String productId,
    int requestedQuantity,
  ) async {
    try {
      return await _productService.checkStockAvailability(
        productId,
        requestedQuantity,
      );
    } catch (e) {
      _error = 'Failed to check stock: $e';
      notifyListeners();
      return false;
    }
  }

  /// Load more products (for pagination)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await loadProducts(refresh: false);
  }

  /// Helper method to build query with current filters
  Query _getProductsQuery() {
    Query query = FirebaseFirestore.instance.collection('products');

    // Start with the most selective filter to optimize query
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      query = query.where('category', isEqualTo: _selectedCategory);
      // Can add isActive filter with category
      query = query.where('isActive', isEqualTo: true);
    } else if (_searchQuery.isNotEmpty) {
      query = query.where(
        'searchKeywords',
        arrayContains: _searchQuery.toLowerCase(),
      );
      // Can add isActive filter with searchKeywords
      query = query.where('isActive', isEqualTo: true);
    } else {
      // For "All" products, just filter by isActive and order by name
      // This requires a simple index: isActive + name
      query = query.where('isActive', isEqualTo: true).orderBy('name');
    }

    query = query.limit(20);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    return query;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
