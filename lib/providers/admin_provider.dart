import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/admin_service.dart';
import '../services/product_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  final ProductService _productService = ProductService();

  // Dashboard stats
  int _totalProducts = 0;
  int _todaysOrders = 0;
  int _lowStockCount = 0;
  List<Order> _recentOrders = [];

  // Order management
  List<Order> _allOrders = [];

  // Inventory management
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = [];

  // Loading state
  bool _isLoading = false;

  // Getters
  int get totalProducts => _totalProducts;
  int get todaysOrders => _todaysOrders;
  int get lowStockCount => _lowStockCount;
  List<Order> get recentOrders => _recentOrders;
  List<Order> get allOrders => _allOrders;
  List<Product> get allProducts => _allProducts;
  List<Product> get filteredProducts => _filteredProducts;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;

  /// Loads dashboard data including stats and recent orders
  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all products to calculate total
      final products = await _adminService.getAllProducts(isActive: true);
      _totalProducts = products.length;

      // Load low stock products
      final lowStockProducts = await _adminService.getLowStockProducts();
      _lowStockCount = lowStockProducts.length;

      // Load recent orders
      final allOrders = await _adminService.getAllOrders();
      _recentOrders = allOrders.take(10).toList();

      // Calculate today's orders
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      _todaysOrders = allOrders
          .where((order) => order.createdAt.isAfter(todayStart))
          .length;
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads all products for inventory management
  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProducts = await _adminService.getAllProducts();
      _filteredProducts = _allProducts;

      // Extract unique categories
      final categorySet = <String>{};
      for (var product in _allProducts) {
        categorySet.add(product.category);
      }
      _categories = categorySet.toList()..sort();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Searches and filters products
  void searchProducts({
    String? searchQuery,
    String? category,
    bool lowStockOnly = false,
  }) {
    _filteredProducts = _allProducts.where((product) {
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = product.name.toLowerCase().contains(query);
        final matchesCategory = product.category.toLowerCase().contains(query);
        if (!matchesName && !matchesCategory) {
          return false;
        }
      }

      // Category filter
      if (category != null && product.category != category) {
        return false;
      }

      // Low stock filter
      if (lowStockOnly && product.stockQuantity > 10) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  /// Adds a new product
  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String unitSize,
    required int stockQuantity,
    String? imageUrl,
  }) async {
    try {
      await _adminService.addProduct(
        name: name,
        description: description,
        price: price,
        category: category,
        unitSize: unitSize,
        stockQuantity: stockQuantity,
        imageUrl: imageUrl,
      );

      // Reload products after adding
      await loadAllProducts();
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  /// Updates an existing product
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? unitSize,
    int? stockQuantity,
    String? imageUrl,
  }) async {
    try {
      await _adminService.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        category: category,
        unitSize: unitSize,
        stockQuantity: stockQuantity,
        imageUrl: imageUrl,
      );

      // Reload products after updating
      await loadAllProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  /// Soft deletes a product (sets isActive to false)
  Future<void> deleteProduct(String productId) async {
    try {
      await _adminService.deleteProduct(productId);

      // Reload products after deleting
      await loadAllProducts();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  /// Restores a deleted product (sets isActive to true)
  Future<void> restoreProduct(String productId) async {
    try {
      await _adminService.updateProduct(productId: productId, isActive: true);

      // Reload products after restoring
      await loadAllProducts();
    } catch (e) {
      debugPrint('Error restoring product: $e');
      rethrow;
    }
  }

  /// Updates stock quantity for a product
  Future<void> updateStock(String productId, int newQuantity) async {
    try {
      await _adminService.updateStock(productId, newQuantity);

      // Reload products after updating stock
      await loadAllProducts();
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
    }
  }

  /// Gets a product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      return await _productService.getProductById(productId);
    } catch (e) {
      debugPrint('Error getting product: $e');
      rethrow;
    }
  }

  /// Gets low stock products
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      return await _adminService.getLowStockProducts(threshold: threshold);
    } catch (e) {
      debugPrint('Error getting low stock products: $e');
      rethrow;
    }
  }

  /// Gets all orders with optional status filter
  Future<List<Order>> getAllOrders({OrderStatus? status}) async {
    try {
      return await _adminService.getAllOrders(status: status);
    } catch (e) {
      debugPrint('Error getting orders: $e');
      rethrow;
    }
  }

  /// Loads all orders for order management screen
  Future<void> loadAllOrders({OrderStatus? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allOrders = await _adminService.getAllOrders(status: status);
    } catch (e) {
      debugPrint('Error loading all orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _adminService.updateOrderStatus(orderId, newStatus);
      // Reload orders after updating
      await loadAllOrders();
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  /// Stream of all products for real-time updates
  Stream<List<Product>> streamAllProducts({String? category, bool? isActive}) {
    return _adminService.streamAllProducts(
      category: category,
      isActive: isActive,
    );
  }

  /// Stream of all orders for real-time updates
  Stream<List<Order>> streamAllOrders({OrderStatus? status}) {
    return _adminService.streamAllOrders(status: status);
  }

  /// Stream of low stock products for real-time monitoring
  Stream<List<Product>> streamLowStockProducts({int threshold = 10}) {
    return _adminService.streamLowStockProducts(threshold: threshold);
  }

  /// Clears all data (useful for logout)
  void clear() {
    _totalProducts = 0;
    _todaysOrders = 0;
    _lowStockCount = 0;
    _recentOrders = [];
    _allOrders = [];
    _allProducts = [];
    _filteredProducts = [];
    _categories = [];
    _isLoading = false;
    notifyListeners();
  }
}
