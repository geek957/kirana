import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Service for logging admin actions for audit purposes
class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  static const String _collectionName = 'auditLogs';

  /// Log an admin action
  Future<void> logAction({
    required String adminId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final logId = _uuid.v4();
      final now = DateTime.now();

      final logEntry = {
        'id': logId,
        'adminId': adminId,
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'timestamp': now.toIso8601String(),
        'details': details ?? {},
      };

      await _firestore.collection(_collectionName).doc(logId).set(logEntry);
    } catch (e) {
      // Log to console but don't throw - audit logging failure shouldn't block operations
      print('Failed to log audit action: $e');
    }
  }

  /// Log admin data access
  Future<void> logDataAccess({
    required String adminId,
    required String resourceType,
    required String resourceId,
    String? customerId,
  }) async {
    await logAction(
      adminId: adminId,
      action: 'DATA_ACCESS',
      resourceType: resourceType,
      resourceId: resourceId,
      details: {
        'accessType': 'read',
        if (customerId != null) 'customerId': customerId,
      },
    );
  }

  /// Log admin data modification
  Future<void> logDataModification({
    required String adminId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    await logAction(
      adminId: adminId,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: {
        'modificationType': action,
        if (oldValues != null) 'oldValues': oldValues,
        if (newValues != null) 'newValues': newValues,
      },
    );
  }

  /// Log product creation
  Future<void> logProductCreation({
    required String adminId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    await logAction(
      adminId: adminId,
      action: 'CREATE_PRODUCT',
      resourceType: 'product',
      resourceId: productId,
      details: {
        'productName': productData['name'],
        'category': productData['category'],
        'price': productData['price'],
        'stockQuantity': productData['stockQuantity'],
      },
    );
  }

  /// Log product update
  Future<void> logProductUpdate({
    required String adminId,
    required String productId,
    required Map<String, dynamic> changes,
  }) async {
    await logAction(
      adminId: adminId,
      action: 'UPDATE_PRODUCT',
      resourceType: 'product',
      resourceId: productId,
      details: {'changes': changes},
    );
  }

  /// Log product deletion
  Future<void> logProductDeletion({
    required String adminId,
    required String productId,
    required String productName,
  }) async {
    await logAction(
      adminId: adminId,
      action: 'DELETE_PRODUCT',
      resourceType: 'product',
      resourceId: productId,
      details: {'productName': productName},
    );
  }

  /// Log stock update
  Future<void> logStockUpdate({
    required String adminId,
    required String productId,
    required String productName,
    required int oldQuantity,
    required int newQuantity,
  }) async {
    await logAction(
      adminId: adminId,
      action: 'UPDATE_STOCK',
      resourceType: 'product',
      resourceId: productId,
      details: {
        'productName': productName,
        'oldQuantity': oldQuantity,
        'newQuantity': newQuantity,
        'difference': newQuantity - oldQuantity,
      },
    );
  }

  /// Log order status update
  Future<void> logOrderStatusUpdate({
    required String adminId,
    required String orderId,
    required String oldStatus,
    required String newStatus,
    required String customerId,
  }) async {
    await logAction(
      adminId: adminId,
      action: 'UPDATE_ORDER_STATUS',
      resourceType: 'order',
      resourceId: orderId,
      details: {
        'customerId': customerId,
        'oldStatus': oldStatus,
        'newStatus': newStatus,
      },
    );
  }

  /// Log customer data access
  Future<void> logCustomerDataAccess({
    required String adminId,
    required String customerId,
    required String dataType,
  }) async {
    await logAction(
      adminId: adminId,
      action: 'ACCESS_CUSTOMER_DATA',
      resourceType: 'customer',
      resourceId: customerId,
      details: {'dataType': dataType},
    );
  }

  /// Get audit logs for a specific admin
  Future<List<Map<String, dynamic>>> getAdminLogs({
    required String adminId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('adminId', isEqualTo: adminId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch admin logs: $e');
    }
  }

  /// Get audit logs for a specific resource
  Future<List<Map<String, dynamic>>> getResourceLogs({
    required String resourceType,
    required String resourceId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('resourceType', isEqualTo: resourceType)
          .where('resourceId', isEqualTo: resourceId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch resource logs: $e');
    }
  }

  /// Get all audit logs (admin only, with pagination)
  Future<List<Map<String, dynamic>>> getAllLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? action,
    String? resourceType,
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      if (resourceType != null) {
        query = query.where('resourceType', isEqualTo: resourceType);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch audit logs: $e');
    }
  }

  /// Clean up old audit logs (older than specified days)
  Future<void> cleanupOldLogs({int daysToKeep = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      int deleteCount = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      if (deleteCount > 0) {
        await batch.commit();
        print('Cleaned up $deleteCount old audit logs');
      }
    } catch (e) {
      print('Failed to cleanup old audit logs: $e');
    }
  }
}
