import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Create a new notification for a customer
  Future<void> createNotification({
    required String customerId,
    required String orderId,
    required String type,
    required String title,
    required String message,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = AppNotification(
        id: notificationId,
        customerId: customerId,
        orderId: orderId,
        type: type,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get all notifications for a customer, ordered by creation date (newest first)
  Future<List<AppNotification>> getCustomerNotifications(
    String customerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  /// Get a stream of notifications for real-time updates
  Stream<List<AppNotification>> getCustomerNotificationsStream(
    String customerId,
  ) {
    return _firestore
        .collection('notifications')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a customer
  Future<void> markAllAsRead(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('customerId', isEqualTo: customerId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notifications older than 30 days
  Future<void> deleteOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }

  /// Get unread notification count for a customer
  Future<int> getUnreadCount(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('customerId', isEqualTo: customerId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Get a stream of unread notification count for real-time updates
  Stream<int> getUnreadCountStream(String customerId) {
    return _firestore
        .collection('notifications')
        .where('customerId', isEqualTo: customerId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
