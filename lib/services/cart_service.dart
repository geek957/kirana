import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import 'product_service.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  // Get cart collection reference
  CollectionReference get _cartsCollection => _firestore.collection('carts');

  /// Add item to cart with stock validation
  Future<void> addToCart(
    String customerId,
    String productId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    // Validate stock availability
    final product = await _productService.getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }
    if (product.stockQuantity < quantity) {
      throw Exception(
        'Insufficient stock. Only ${product.stockQuantity} available',
      );
    }

    // Get current cart
    final cart = await getCart(customerId);
    final items = List<CartItem>.from(cart.items);

    // Check if item already exists in cart
    final existingIndex = items.indexWhere(
      (item) => item.productId == productId,
    );

    if (existingIndex != -1) {
      // Update quantity of existing item
      final existingItem = items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;

      // Validate total quantity against stock
      if (product.stockQuantity < newQuantity) {
        throw Exception(
          'Insufficient stock. Only ${product.stockQuantity} available',
        );
      }

      items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
    } else {
      // Add new item to cart
      items.add(
        CartItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: quantity,
          imageUrl: product.imageUrl,
        ),
      );
    }

    // Calculate new total
    final totalAmount = items.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    // Update cart in Firestore
    await _cartsCollection.doc(customerId).set({
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove item from cart
  Future<void> removeFromCart(String customerId, String productId) async {
    final cart = await getCart(customerId);
    final items = cart.items
        .where((item) => item.productId != productId)
        .toList();

    // Calculate new total
    final totalAmount = items.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    // Update cart in Firestore
    await _cartsCollection.doc(customerId).set({
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update quantity of item in cart with stock validation
  Future<void> updateQuantity(
    String customerId,
    String productId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    // Validate stock availability
    final product = await _productService.getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }
    if (product.stockQuantity < quantity) {
      throw Exception(
        'Insufficient stock. Only ${product.stockQuantity} available',
      );
    }

    final cart = await getCart(customerId);
    final items = List<CartItem>.from(cart.items);

    final index = items.indexWhere((item) => item.productId == productId);
    if (index == -1) {
      throw Exception('Item not found in cart');
    }

    items[index] = items[index].copyWith(quantity: quantity);

    // Calculate new total
    final totalAmount = items.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    // Update cart in Firestore
    await _cartsCollection.doc(customerId).set({
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get cart for customer
  Future<Cart> getCart(String customerId) async {
    final doc = await _cartsCollection.doc(customerId).get();

    if (!doc.exists) {
      // Return empty cart if doesn't exist
      return Cart(
        customerId: customerId,
        items: [],
        totalAmount: 0.0,
        updatedAt: DateTime.now(),
      );
    }

    final data = doc.data() as Map<String, dynamic>;

    // Handle Firestore Timestamp
    DateTime updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.parse(data['updatedAt']);
    } else {
      updatedAt = DateTime.now();
    }

    return Cart(
      customerId: data['customerId'] as String,
      items: (data['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      updatedAt: updatedAt,
    );
  }

  /// Validate cart stock availability
  Future<bool> validateCartStock(String customerId) async {
    final cart = await getCart(customerId);

    for (final item in cart.items) {
      try {
        final product = await _productService.getProductById(item.productId);
        if (product == null || product.stockQuantity < item.quantity) {
          return false;
        }
      } catch (e) {
        // Product not found or error
        return false;
      }
    }

    return true;
  }

  /// Calculate cart total
  Future<double> calculateTotal(String customerId) async {
    final cart = await getCart(customerId);
    return cart.items.fold<double>(0.0, (total, item) => total + item.subtotal);
  }

  /// Clear cart (used after order placement)
  Future<void> clearCart(String customerId) async {
    await _cartsCollection.doc(customerId).set({
      'customerId': customerId,
      'items': [],
      'totalAmount': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get cart stream for real-time updates
  Stream<Cart> getCartStream(String customerId) {
    return _cartsCollection.doc(customerId).snapshots().map((doc) {
      if (!doc.exists) {
        return Cart(
          customerId: customerId,
          items: [],
          totalAmount: 0.0,
          updatedAt: DateTime.now(),
        );
      }

      final data = doc.data() as Map<String, dynamic>;

      // Handle Firestore Timestamp
      DateTime updatedAt;
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        updatedAt = DateTime.parse(data['updatedAt']);
      } else {
        updatedAt = DateTime.now();
      }

      return Cart(
        customerId: data['customerId'] as String,
        items: (data['items'] as List<dynamic>)
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalAmount: (data['totalAmount'] as num).toDouble(),
        updatedAt: updatedAt,
      );
    });
  }
}
