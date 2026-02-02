import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/cart.dart';
import '../models/address.dart';
import 'notification_service.dart';
import 'authorization_service.dart';
import 'config_service.dart';
import 'image_upload_service.dart';

/// Custom exceptions for order operations
class OrderException implements Exception {
  final String message;
  OrderException(this.message);

  @override
  String toString() => message;
}

class DeliveryPhotoUploadException extends OrderException {
  DeliveryPhotoUploadException(String message)
    : super('Failed to upload delivery photo: $message');
}

class RemarksEditWindowExpiredException extends OrderException {
  RemarksEditWindowExpiredException()
    : super('Cannot edit remarks after 24 hours');
}

class InvalidRemarksException extends OrderException {
  InvalidRemarksException(String message) : super('Invalid remarks: $message');
}

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();
  final AuthorizationService _authService = AuthorizationService();
  final ConfigService _configService = ConfigService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  // Cache for pending order count with TTL
  int? _cachedPendingCount;
  DateTime? _pendingCountCacheTime;
  static const Duration _pendingCountCacheDuration = Duration(seconds: 30);

  /// Creates an order from the customer's cart using a Firestore transaction
  /// to ensure atomic stock deduction and order creation
  Future<Order> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required Cart cart,
    required Address deliveryAddress,
  }) async {
    // Verify user can create order for this customer
    await _authService.requireCustomerDataAccess(customerId);

    if (cart.items.isEmpty) {
      throw Exception('Cannot create order with empty cart');
    }

    final orderId = _uuid.v4();
    final now = DateTime.now();

    // Calculate delivery charge based on cart value
    final deliveryCharge = _configService.calculateDeliveryCharge(
      cart.totalAmount,
    );

    // Convert cart items to order items
    final orderItems = cart.items.map((cartItem) {
      return OrderItem(
        productId: cartItem.productId,
        productName: cartItem.productName,
        price: cartItem.price,
        quantity: cartItem.quantity,
        subtotal: cartItem.subtotal,
      );
    }).toList();

    final order = Order(
      id: orderId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: orderItems,
      totalAmount: cart.totalAmount,
      addressId: deliveryAddress.id,
      deliveryAddress: deliveryAddress,
      status: OrderStatus.pending,
      paymentMethod: PaymentMethod.cashOnDelivery,
      createdAt: now,
      deliveryCharge: deliveryCharge,
    );

    // Use Firestore transaction to ensure atomicity
    // IMPORTANT: Firestore requires all reads before all writes
    await _firestore.runTransaction((transaction) async {
      // PHASE 1: Read all product documents first
      final productSnapshots = <String, DocumentSnapshot>{};
      for (final item in cart.items) {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);
        final productSnapshot = await transaction.get(productRef);
        productSnapshots[item.productId] = productSnapshot;
      }

      // PHASE 2: Validate all products and stock levels
      for (final item in cart.items) {
        final productSnapshot = productSnapshots[item.productId]!;

        if (!productSnapshot.exists) {
          throw Exception('Product ${item.productName} not found');
        }

        final productData = productSnapshot.data() as Map<String, dynamic>;
        final currentStock = productData['stockQuantity'] as int;

        if (currentStock < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.productName}. Available: $currentStock, Requested: ${item.quantity}',
          );
        }
      }

      // PHASE 3: Perform all writes
      // 3.1: Deduct stock for all items
      for (final item in cart.items) {
        final productSnapshot = productSnapshots[item.productId]!;
        final productData = productSnapshot.data() as Map<String, dynamic>;
        final currentStock = productData['stockQuantity'] as int;

        final productRef = _firestore
            .collection('products')
            .doc(item.productId);

        transaction.update(productRef, {
          'stockQuantity': currentStock - item.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3.2: Create the order
      final orderRef = _firestore.collection('orders').doc(orderId);
      transaction.set(orderRef, order.toJson());

      // 3.3: Clear the customer's cart
      final cartRef = _firestore.collection('carts').doc(customerId);
      transaction.update(cartRef, {
        'items': [],
        'totalAmount': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return order;
  }

  /// Retrieves all orders for a specific customer, sorted by creation date (newest first)
  Future<List<Order>> getCustomerOrders(String customerId) async {
    try {
      // Verify user can access this customer's orders
      await _authService.requireCustomerDataAccess(customerId);

      final querySnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customer orders: $e');
    }
  }

  /// Retrieves a specific order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      // Verify user can access this order
      await _authService.requireOrderAccess(orderId);

      final docSnapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return Order.fromJson(docSnapshot.data()!);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Updates the status of an order and creates a notification for the customer
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      // Only admins can update order status
      await _authService.requireAdmin();

      // First, get the order to retrieve customer information
      final orderSnapshot = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderSnapshot.exists) {
        throw Exception('Order not found');
      }

      final order = Order.fromJson(orderSnapshot.data()!);

      // Update order status in a transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection('orders').doc(orderId);

        transaction.update(orderRef, {
          'status': newStatus.toJson(),
          if (newStatus == OrderStatus.delivered)
            'deliveredAt': FieldValue.serverTimestamp(),
        });
      });

      // Create notification for status changes that customers should be notified about
      if (_shouldNotifyCustomer(newStatus)) {
        final notificationData = _getNotificationData(newStatus, orderId);
        await _notificationService.createNotification(
          customerId: order.customerId,
          orderId: orderId,
          type: 'order_status_change',
          title: notificationData['title']!,
          message: notificationData['message']!,
        );
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Determines if customer should be notified for this status change
  bool _shouldNotifyCustomer(OrderStatus status) {
    return status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.outForDelivery ||
        status == OrderStatus.delivered;
  }

  /// Gets notification title and message for a given order status
  Map<String, String> _getNotificationData(OrderStatus status, String orderId) {
    switch (status) {
      case OrderStatus.confirmed:
        return {
          'title': 'Order Confirmed',
          'message':
              'Your order #$orderId has been confirmed and will be prepared soon.',
        };
      case OrderStatus.preparing:
        return {
          'title': 'Order Being Prepared',
          'message': 'Your order #$orderId is being prepared for delivery.',
        };
      case OrderStatus.outForDelivery:
        return {
          'title': 'Out for Delivery',
          'message':
              'Your order #$orderId is out for delivery and will arrive soon.',
        };
      case OrderStatus.delivered:
        return {
          'title': 'Order Delivered',
          'message':
              'Your order #$orderId has been delivered. Thank you for shopping with us!',
        };
      default:
        return {
          'title': 'Order Update',
          'message': 'Your order #$orderId status has been updated.',
        };
    }
  }

  /// Cancels an order and restores stock quantities
  /// Only allowed for orders with status Pending or Confirmed
  Future<void> cancelOrder(String orderId) async {
    // Verify user can access this order (customer or admin)
    await _authService.requireOrderAccess(orderId);

    // Use transaction to ensure atomicity
    // IMPORTANT: Firestore requires all reads before all writes
    await _firestore.runTransaction((transaction) async {
      // PHASE 1: Read order document
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnapshot = await transaction.get(orderRef);

      if (!orderSnapshot.exists) {
        throw Exception('Order not found');
      }

      final order = Order.fromJson(orderSnapshot.data()!);

      // Check if order can be cancelled
      if (order.status != OrderStatus.pending &&
          order.status != OrderStatus.confirmed) {
        throw Exception(
          'Cannot cancel order with status ${order.status.name}. '
          'Only pending or confirmed orders can be cancelled.',
        );
      }

      // PHASE 2: Read all product documents
      final productSnapshots = <String, DocumentSnapshot>{};
      for (final item in order.items) {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);
        final productSnapshot = await transaction.get(productRef);
        productSnapshots[item.productId] = productSnapshot;
      }

      // PHASE 3: Perform all writes
      // 3.1: Restore stock for all items
      for (final item in order.items) {
        final productSnapshot = productSnapshots[item.productId];

        if (productSnapshot != null && productSnapshot.exists) {
          final productData = productSnapshot.data() as Map<String, dynamic>;
          final currentStock = productData['stockQuantity'] as int;

          final productRef = _firestore
              .collection('products')
              .doc(item.productId);

          transaction.update(productRef, {
            'stockQuantity': currentStock + item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 3.2: Update order status to cancelled
      transaction.update(orderRef, {'status': OrderStatus.cancelled.toJson()});
    });
  }

  /// Stream of orders for a customer (real-time updates)
  Stream<List<Order>> streamCustomerOrders(String customerId) {
    // Note: Authorization check should be done before subscribing to stream
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromJson(doc.data()))
              .toList();
        });
  }

  /// Stream of a specific order (real-time updates)
  Stream<Order?> streamOrder(String orderId) {
    // Note: Authorization check should be done before subscribing to stream
    return _firestore.collection('orders').doc(orderId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return Order.fromJson(snapshot.data()!);
    });
  }

  /// Upload delivery photo to Firebase Storage
  /// Returns the download URL of the uploaded photo
  /// Automatically compresses image to optimize storage and upload time
  Future<String> uploadDeliveryPhoto({
    required String orderId,
    required File photoFile,
  }) async {
    try {
      // Only admins can upload delivery photos
      await _authService.requireAdmin();

      // Validate file exists
      if (!await photoFile.exists()) {
        throw DeliveryPhotoUploadException('Photo file does not exist');
      }

      // Compress image using ImageUploadService for optimal size
      // This reduces storage costs and upload time
      File compressedPhoto;
      try {
        compressedPhoto = await _imageUploadService.compressImage(photoFile);
      } catch (e) {
        // If compression fails, use original file
        compressedPhoto = photoFile;
      }

      // Validate file size after compression (max 5MB)
      final fileSize = await compressedPhoto.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw DeliveryPhotoUploadException('Photo size exceeds 5MB limit');
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${orderId}_$timestamp.jpg';
      final storageRef = _storage.ref().child('delivery_photos/$fileName');

      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'orderId': orderId,
          'uploadedAt': timestamp.toString(),
        },
      );

      final uploadTask = storageRef.putFile(compressedPhoto, metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up temporary compressed file if it was created
      if (compressedPhoto.path != photoFile.path) {
        try {
          await compressedPhoto.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      return downloadUrl;
    } catch (e) {
      if (e is DeliveryPhotoUploadException) {
        rethrow;
      }
      throw DeliveryPhotoUploadException(e.toString());
    }
  }

  /// Capture and save delivery location to order
  Future<void> captureDeliveryLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Only admins can capture delivery location
      await _authService.requireAdmin();

      // Validate coordinates
      if (latitude < -90 || latitude > 90) {
        throw OrderException('Invalid latitude: must be between -90 and 90');
      }
      if (longitude < -180 || longitude > 180) {
        throw OrderException('Invalid longitude: must be between -180 and 180');
      }

      // Create GeoPoint
      final geoPoint = GeoPoint(latitude, longitude);

      // Update order with delivery location
      await _firestore.collection('orders').doc(orderId).update({
        'deliveryLocation': geoPoint,
      });
    } catch (e) {
      if (e is OrderException) {
        rethrow;
      }
      throw OrderException('Failed to capture delivery location: $e');
    }
  }

  /// Complete delivery by uploading photo and capturing location
  /// This is a convenience method that combines both operations
  Future<void> completeDelivery({
    required String orderId,
    required File deliveryPhoto,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Only admins can complete delivery
      await _authService.requireAdmin();

      // Upload photo first
      final photoUrl = await uploadDeliveryPhoto(
        orderId: orderId,
        photoFile: deliveryPhoto,
      );

      // Capture location
      final geoPoint = GeoPoint(latitude, longitude);

      // Update order with both photo URL and location, and mark as delivered
      await _firestore.collection('orders').doc(orderId).update({
        'deliveryPhotoUrl': photoUrl,
        'deliveryLocation': geoPoint,
        'status': OrderStatus.delivered.toJson(),
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      // Get order to send notification
      final order = await getOrderById(orderId);
      if (order != null) {
        // Send notification to customer
        await _notificationService.createNotification(
          customerId: order.customerId,
          orderId: orderId,
          type: 'order_delivered',
          title: 'Order Delivered',
          message:
              'Your order #$orderId has been delivered. Thank you for shopping with us!',
        );
      }
    } catch (e) {
      if (e is OrderException || e is DeliveryPhotoUploadException) {
        rethrow;
      }
      throw OrderException('Failed to complete delivery: $e');
    }
  }

  /// Add customer remarks and rating to a delivered order
  /// Rating is required (1-5 stars), remarks are optional but limited to 500 characters
  Future<void> addCustomerRemarks({
    required String orderId,
    String? remarks,
    required int rating,
  }) async {
    try {
      // Get the order first to verify it's delivered and check ownership
      final order = await getOrderById(orderId);
      if (order == null) {
        throw OrderException('Order not found');
      }

      // Verify user can access this order
      await _authService.requireCustomerDataAccess(order.customerId);

      // Verify order is delivered
      if (order.status != OrderStatus.delivered) {
        throw OrderException('Can only add feedback to delivered orders');
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw OrderException('Rating must be between 1 and 5 stars');
      }

      // Validate remarks if provided
      String? sanitizedRemarks;
      if (remarks != null && remarks.isNotEmpty) {
        sanitizedRemarks = _sanitizeRemarks(remarks);
      }

      // Add feedback with timestamp
      await _firestore.collection('orders').doc(orderId).update({
        'rating': rating,
        'customerRemarks': sanitizedRemarks,
        'remarksTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is OrderException || e is InvalidRemarksException) {
        rethrow;
      }
      throw OrderException('Failed to add customer remarks: $e');
    }
  }

  /// Update customer remarks and rating on a delivered order
  /// Can only be updated within 24 hours of the first feedback
  Future<void> updateCustomerRemarks({
    required String orderId,
    String? remarks,
    required int rating,
  }) async {
    try {
      // Get the order first to verify it's delivered and check edit window
      final order = await getOrderById(orderId);
      if (order == null) {
        throw OrderException('Order not found');
      }

      // Verify user can access this order
      await _authService.requireCustomerDataAccess(order.customerId);

      // Verify order is delivered
      if (order.status != OrderStatus.delivered) {
        throw OrderException('Can only update feedback on delivered orders');
      }

      // Check if feedback can be edited
      if (!canEditRemarks(order)) {
        throw RemarksEditWindowExpiredException();
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw OrderException('Rating must be between 1 and 5 stars');
      }

      // Validate remarks if provided
      String? sanitizedRemarks;
      if (remarks != null && remarks.isNotEmpty) {
        sanitizedRemarks = _sanitizeRemarks(remarks);
      }

      // Update feedback (keep original timestamp)
      await _firestore.collection('orders').doc(orderId).update({
        'rating': rating,
        'customerRemarks': sanitizedRemarks,
      });
    } catch (e) {
      if (e is OrderException ||
          e is InvalidRemarksException ||
          e is RemarksEditWindowExpiredException) {
        rethrow;
      }
      throw OrderException('Failed to update customer remarks: $e');
    }
  }

  /// Check if customer remarks can be edited
  /// Returns true if no remarks exist yet or if within 24-hour edit window
  bool canEditRemarks(Order order) {
    // If no remarks timestamp, remarks haven't been added yet
    if (order.remarksTimestamp == null) {
      return true;
    }

    // Check if within 24-hour edit window
    final now = DateTime.now();
    final elapsed = now.difference(order.remarksTimestamp!);
    return elapsed.inHours < 24;
  }

  /// Get count of pending orders
  /// Used for order capacity management
  /// Implements caching with 30-second TTL to reduce Firestore reads
  Future<int> getPendingOrderCount() async {
    try {
      // Check if cached value is still valid
      if (_cachedPendingCount != null && _pendingCountCacheTime != null) {
        final cacheAge = DateTime.now().difference(_pendingCountCacheTime!);
        if (cacheAge < _pendingCountCacheDuration) {
          return _cachedPendingCount!;
        }
      }

      // Cache expired or not available, fetch from Firestore
      final querySnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: OrderStatus.pending.toJson())
          .count()
          .get();

      final count = querySnapshot.count ?? 0;

      // Update cache
      _cachedPendingCount = count;
      _pendingCountCacheTime = DateTime.now();

      return count;
    } catch (e) {
      // If query fails, return cached value if available
      if (_cachedPendingCount != null) {
        return _cachedPendingCount!;
      }
      throw OrderException('Failed to get pending order count: $e');
    }
  }

  /// Clear the pending order count cache
  /// Useful when you know the count has changed and want to force a refresh
  void clearPendingCountCache() {
    _cachedPendingCount = null;
    _pendingCountCacheTime = null;
  }

  /// Stream of pending order count for real-time updates
  /// Used for order capacity warnings and blocking
  Stream<int> watchPendingOrderCount() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.pending.toJson())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Sanitize customer remarks
  /// Removes potentially harmful characters and enforces character limit
  String _sanitizeRemarks(String input) {
    // Trim whitespace
    String sanitized = input.trim();

    // Enforce character limit (500 characters)
    if (sanitized.length > 500) {
      throw InvalidRemarksException('Remarks cannot exceed 500 characters');
    }

    // Remove potentially harmful characters (basic sanitization)
    sanitized = sanitized.replaceAll(RegExp(r'[<>]'), '');

    return sanitized;
  }
}
