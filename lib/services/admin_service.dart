import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/notification.dart';
import 'product_service.dart';
import 'audit_service.dart';
import 'authorization_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final AuditService _auditService = AuditService();
  final AuthorizationService _authService = AuthorizationService();
  final String _productsCollection = 'products';

  // Current admin ID (should be set when admin logs in)
  String? _currentAdminId;

  /// Set the current admin ID for audit logging
  void setCurrentAdminId(String adminId) {
    _currentAdminId = adminId;
  }

  /// Adds a new product to the inventory
  Future<Product> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required String unitSize,
    required int stockQuantity,
    String? imageUrl,
  }) async {
    // Verify user is admin
    await _authService.requireAdmin();

    try {
      final productId = _uuid.v4();
      final now = DateTime.now();

      // Generate search keywords for the product
      final searchKeywords = ProductService.generateSearchKeywords(
        name,
        category,
      );

      final product = Product(
        id: productId,
        name: name,
        description: description,
        price: price,
        category: category,
        unitSize: unitSize,
        stockQuantity: stockQuantity,
        imageUrl: imageUrl ?? '',
        isActive: true,
        searchKeywords: searchKeywords,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .set(product.toJson());

      // Log product creation
      if (_currentAdminId != null) {
        await _auditService.logProductCreation(
          adminId: _currentAdminId!,
          productId: productId,
          productData: product.toJson(),
        );
      }

      return product;
    } catch (e) {
      throw Exception('Failed to add product: $e');
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
    bool? isActive,
  }) async {
    // Verify user is admin
    await _authService.requireAdmin();

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (unitSize != null) updateData['unitSize'] = unitSize;
      if (stockQuantity != null) updateData['stockQuantity'] = stockQuantity;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isActive != null) updateData['isActive'] = isActive;

      // Regenerate search keywords if name or category changed
      if (name != null || category != null) {
        final productDoc = await _firestore
            .collection(_productsCollection)
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final currentData = productDoc.data()!;
          final finalName = name ?? currentData['name'] as String;
          final finalCategory = category ?? currentData['category'] as String;

          updateData['searchKeywords'] = ProductService.generateSearchKeywords(
            finalName,
            finalCategory,
          );
        }
      }

      await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .update(updateData);

      // Log product update
      if (_currentAdminId != null) {
        await _auditService.logProductUpdate(
          adminId: _currentAdminId!,
          productId: productId,
          changes: updateData,
        );
      }
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Soft deletes a product by setting isActive to false
  Future<void> deleteProduct(String productId) async {
    // Verify user is admin
    await _authService.requireAdmin();

    try {
      // Get product name for audit log
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .get();

      String productName = 'Unknown';
      if (productDoc.exists) {
        productName = productDoc.data()?['name'] as String? ?? 'Unknown';
      }

      await _firestore.collection(_productsCollection).doc(productId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log product deletion
      if (_currentAdminId != null) {
        await _auditService.logProductDeletion(
          adminId: _currentAdminId!,
          productId: productId,
          productName: productName,
        );
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Updates the stock quantity for a product
  Future<void> updateStock(String productId, int newQuantity) async {
    // Verify user is admin
    await _authService.requireAdmin();

    try {
      if (newQuantity < 0) {
        throw Exception('Stock quantity cannot be negative');
      }

      // Get current product data for audit log
      final productDoc = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .get();

      int oldQuantity = 0;
      String productName = 'Unknown';
      if (productDoc.exists) {
        oldQuantity = productDoc.data()?['stockQuantity'] as int? ?? 0;
        productName = productDoc.data()?['name'] as String? ?? 'Unknown';
      }

      await _firestore.collection(_productsCollection).doc(productId).update({
        'stockQuantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log stock update
      if (_currentAdminId != null) {
        await _auditService.logStockUpdate(
          adminId: _currentAdminId!,
          productId: productId,
          productName: productName,
          oldQuantity: oldQuantity,
          newQuantity: newQuantity,
        );
      }
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Gets products with stock below the specified threshold
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_productsCollection)
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isLessThanOrEqualTo: threshold)
          .orderBy('stockQuantity')
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock products: $e');
    }
  }

  /// Gets all orders with optional status filter
  Future<List<Order>> getAllOrders({OrderStatus? status}) async {
    // Verify user is admin
    await _authService.requireAdmin();

    try {
      Query query = _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toJson());
      }

      final querySnapshot = await query.get();

      final orders = querySnapshot.docs
          .map((doc) => Order.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Log data access for each order
      if (_currentAdminId != null) {
        for (final order in orders) {
          await _auditService.logCustomerDataAccess(
            adminId: _currentAdminId!,
            customerId: order.customerId,
            dataType: 'order',
          );
        }
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Stream of all orders for real-time updates
  Stream<List<Order>> streamAllOrders({OrderStatus? status}) {
    Query query = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toJson());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return Order.fromJson(data);
        }
        throw Exception('Invalid order data format');
      }).toList();
    });
  }

  /// Stream of low stock products for real-time monitoring
  Stream<List<Product>> streamLowStockProducts({int threshold = 10}) {
    return _firestore
        .collection(_productsCollection)
        .where('isActive', isEqualTo: true)
        .where('stockQuantity', isLessThanOrEqualTo: threshold)
        .orderBy('stockQuantity')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromJson(doc.data()))
              .toList();
        });
  }

  /// Gets all products (including inactive) for admin inventory management
  Future<List<Product>> getAllProducts({
    String? category,
    String? searchQuery,
    bool? isActive,
  }) async {
    // Verify user is admin
    await _authService.requireAdmin();

    try {
      Query query = _firestore.collection(_productsCollection);

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerm = searchQuery.toLowerCase();
        query = query.where('searchKeywords', arrayContains: searchTerm);
      }

      query = query.orderBy('name');

      final querySnapshot = await query.get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return Product.fromJson(data);
        }
        throw Exception('Invalid product data format');
      }).toList();

      // Log data access
      if (_currentAdminId != null && products.isNotEmpty) {
        await _auditService.logDataAccess(
          adminId: _currentAdminId!,
          resourceType: 'product',
          resourceId: 'inventory_list',
        );
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch all products: $e');
    }
  }

  /// Stream of all products for real-time inventory management
  Stream<List<Product>> streamAllProducts({String? category, bool? isActive}) {
    Query query = _firestore.collection(_productsCollection);

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('name');

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          return Product.fromJson(data);
        }
        throw Exception('Invalid product data format');
      }).toList();
    });
  }

  /// Updates order status and creates a notification for the customer
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    // Verify user is admin
    await _authService.requireAdmin();

    try {
      // Get the order first to retrieve customer information
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = Order.fromJson(orderDoc.data()!);
      final oldStatus = order.status;

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.toJson(),
        if (newStatus == OrderStatus.delivered)
          'deliveredAt': FieldValue.serverTimestamp(),
      });

      // Create notification for customer
      await _createNotification(
        customerId: order.customerId,
        orderId: orderId,
        status: newStatus,
      );

      // Log order status update
      if (_currentAdminId != null) {
        await _auditService.logOrderStatusUpdate(
          adminId: _currentAdminId!,
          orderId: orderId,
          oldStatus: oldStatus.toJson(),
          newStatus: newStatus.toJson(),
          customerId: order.customerId,
        );
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Creates a notification for order status changes
  Future<void> _createNotification({
    required String customerId,
    required String orderId,
    required OrderStatus status,
  }) async {
    final notificationId = _uuid.v4();
    final now = DateTime.now();

    // Generate notification title, message, and type based on status
    String title;
    String message;
    String type;

    switch (status) {
      case OrderStatus.confirmed:
        title = 'Order Confirmed';
        message =
            'Your order #$orderId has been confirmed and is being prepared.';
        type = 'order_confirmed';
        break;
      case OrderStatus.preparing:
        title = 'Order Being Prepared';
        message = 'Your order #$orderId is being prepared for delivery.';
        type = 'order_preparing';
        break;
      case OrderStatus.outForDelivery:
        title = 'Out for Delivery';
        message =
            'Your order #$orderId is out for delivery and will arrive soon.';
        type = 'order_out_for_delivery';
        break;
      case OrderStatus.delivered:
        title = 'Order Delivered';
        message =
            'Your order #$orderId has been delivered. Thank you for shopping with us!';
        type = 'order_delivered';
        break;
      case OrderStatus.cancelled:
        title = 'Order Cancelled';
        message = 'Your order #$orderId has been cancelled.';
        type = 'order_cancelled';
        break;
      default:
        // Don't create notification for pending status
        return;
    }

    final notification = AppNotification(
      id: notificationId,
      customerId: customerId,
      orderId: orderId,
      type: type,
      title: title,
      message: message,
      isRead: false,
      createdAt: now,
    );

    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .set(notification.toJson());
  }
}
