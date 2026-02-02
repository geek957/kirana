import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/category_service.dart';

/// Provider for managing product categories with real-time updates
/// Extends ChangeNotifier for state management integration
/// Validates: Requirements 2.2.1-2.2.9
class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  // State fields
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Category>>? _categoriesSubscription;

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all categories sorted alphabetically
  /// Sets loading state and handles errors
  /// Uses cached data when available for better performance
  Future<void> loadCategories() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories();
    } catch (e) {
      _error = 'Failed to load categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Preload categories into cache during app initialization
  /// This improves performance by loading data before it's needed
  Future<void> preloadCategories() async {
    try {
      await _categoryService.preloadCategories();
      _categories = await _categoryService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to preload categories: $e';
    }
  }

  /// Create a new category with validation
  /// Validates: Requirements 2.2.1, 2.2.8
  /// Throws CategoryNameNotUniqueException if name already exists
  /// Throws CategoryException if name is empty
  Future<void> createCategory(String name, String? description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _categoryService.createCategory(
        name: name,
        description: description,
      );
      // Real-time listener will update the list automatically
    } catch (e) {
      _error = 'Failed to create category: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing category with validation
  /// Validates: Requirements 2.2.2, 2.2.8
  /// Throws CategoryNotFoundException if category doesn't exist
  /// Throws CategoryNameNotUniqueException if new name already exists
  Future<void> updateCategory(
    String id,
    String name,
    String? description,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _categoryService.updateCategory(
        id: id,
        name: name,
        description: description,
      );
      // Real-time listener will update the list automatically
      
      // Update selected category if it was the one being updated
      if (_selectedCategory?.id == id) {
        _selectedCategory = _categories.firstWhere(
          (cat) => cat.id == id,
          orElse: () => _selectedCategory!,
        );
      }
    } catch (e) {
      _error = 'Failed to update category: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a category with validation
  /// Validates: Requirements 2.2.3, 2.2.7
  /// Throws CategoryHasProductsException if category has products
  /// Throws CategoryNotFoundException if category doesn't exist
  Future<void> deleteCategory(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _categoryService.deleteCategory(id);
      // Real-time listener will update the list automatically

      // Clear selection if deleted category was selected
      if (_selectedCategory?.id == id) {
        _selectedCategory = null;
      }
    } catch (e) {
      _error = 'Failed to delete category: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a category for filtering products
  /// Validates: Requirement 2.2.5
  /// Pass null to clear selection and show all products
  void selectCategory(Category? category) {
    if (_selectedCategory?.id == category?.id) return;

    _selectedCategory = category;
    notifyListeners();
  }

  /// Set up real-time listener for category updates
  /// Automatically updates the category list when data changes in Firestore
  /// Ensures categories are always sorted alphabetically
  void startListening() {
    _categoriesSubscription?.cancel();

    _categoriesSubscription = _categoryService.watchCategories().listen(
      (categories) {
        _categories = categories;
        // Categories are already sorted by the service
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to listen to categories: $error';
        notifyListeners();
      },
    );
  }

  /// Stop listening to real-time updates
  void stopListening() {
    _categoriesSubscription?.cancel();
    _categoriesSubscription = null;
  }

  /// Get a category by ID from the local list
  /// Returns null if not found
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Dispose of resources
  /// Cancels stream subscriptions to prevent memory leaks
  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
