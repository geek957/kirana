import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/cart.dart';
import '../models/address.dart';
import 'notification_service.dart';
import 'authorization_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();
  final AuthorizationService _authService = AuthorizationService();

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
}
