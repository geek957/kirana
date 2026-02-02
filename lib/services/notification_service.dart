import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'navigation_service.dart';
import 'package:flutter/material.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // FCM and local notifications
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Shared preferences key for sound setting
  static const String _soundEnabledKey = 'notification_sound_enabled';

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

  // ========== FCM and Push Notification Methods ==========

  /// Initialize Firebase Cloud Messaging
  Future<void> initializeFCM() async {
    try {
      // Request permissions
      await requestPermissions();

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      const androidChannel = AndroidNotificationChannel(
        'order_updates',
        'Order Updates',
        description: 'Notifications for order status updates',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // Setup message handlers
      setupBackgroundHandlers();

      // Get and save FCM token
      final token = await getFCMToken();
      if (token != null) {
        print('FCM Token: $token');
        // Token can be saved to user document if needed
      }
    } catch (e) {
      throw Exception('Failed to initialize FCM: $e');
    }
  }

  /// Get FCM token for this device
  Future<String?> getFCMToken() async {
    try {
      final token = await _fcm.getToken();
      return token;
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permissions');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional notification permissions');
      } else {
        print('User declined or has not accepted notification permissions');
      }
    } catch (e) {
      print('Failed to request permissions: $e');
    }
  }

  /// Send push notification to a specific user
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification in Firestore
      final notificationId = _uuid.v4();
      final notification = AppNotification(
        id: notificationId,
        customerId: userId,
        orderId: data?['orderId'] ?? '',
        type: data?['type'] ?? 'general',
        title: title,
        message: body,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toJson());

      // Note: Actual FCM push notification sending would require a backend service
      // or Cloud Functions to send the notification to the user's FCM token.
      // This is a placeholder for the client-side notification creation.

      // For now, we'll show a local notification if the app is in foreground
      await _showLocalNotification(title, body, data);

      // Play notification sound
      await playNotificationSound();
    } catch (e) {
      throw Exception('Failed to send push notification: $e');
    }
  }

  /// Send bulk notification to all customers
  Future<void> sendBulkNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all customer user IDs
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      // Create notifications for all customers
      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notificationId = _uuid.v4();
        final notification = AppNotification(
          id: notificationId,
          customerId: userDoc.id,
          orderId: data?['orderId'] ?? '',
          type: data?['type'] ?? 'announcement',
          title: title,
          message: body,
          isRead: false,
          createdAt: DateTime.now(),
        );

        batch.set(
          _firestore.collection('notifications').doc(notificationId),
          notification.toJson(),
        );
      }

      await batch.commit();

      // Note: Actual FCM bulk notification would be handled by backend
      // This creates the in-app notifications for all users

      print('Bulk notification sent to ${usersSnapshot.docs.length} customers');
    } catch (e) {
      throw Exception('Failed to send bulk notification: $e');
    }
  }

  // ========== Notification Sound Methods ==========

  /// Play notification sound
  Future<void> playNotificationSound() async {
    try {
      final soundEnabled = await isNotificationSoundEnabled();
      if (soundEnabled) {
        await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      }
    } catch (e) {
      print('Failed to play notification sound: $e');
    }
  }

  /// Set notification sound enabled/disabled
  Future<void> setNotificationSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, enabled);
    } catch (e) {
      throw Exception('Failed to set notification sound preference: $e');
    }
  }

  /// Check if notification sound is enabled
  Future<bool> isNotificationSoundEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to true if not set
      return prefs.getBool(_soundEnabledKey) ?? true;
    } catch (e) {
      print('Failed to get notification sound preference: $e');
      return true; // Default to enabled
    }
  }

  // ========== Background Handler Methods ==========

  /// Setup background and foreground message handlers
  void setupBackgroundHandlers() {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle background messages
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      print('Handling background message: ${message.messageId}');

      // Store notification in Firestore
      if (message.data.isNotEmpty) {
        final notificationId = _uuid.v4();
        final notification = AppNotification(
          id: notificationId,
          customerId: message.data['userId'] ?? '',
          orderId: message.data['orderId'] ?? '',
          type: message.data['type'] ?? 'general',
          title: message.notification?.title ?? 'Notification',
          message: message.notification?.body ?? '',
          isRead: false,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .set(notification.toJson());
      }

      // Play sound if enabled
      await playNotificationSound();
    } catch (e) {
      print('Error handling background message: $e');
    }
  }

  /// Handle foreground messages
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      print('Handling foreground message: ${message.messageId}');

      // Show local notification
      await _showLocalNotification(
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
        message.data,
      );

      // Store notification in Firestore
      if (message.data.isNotEmpty) {
        final notificationId = _uuid.v4();
        final notification = AppNotification(
          id: notificationId,
          customerId: message.data['userId'] ?? '',
          orderId: message.data['orderId'] ?? '',
          type: message.data['type'] ?? 'general',
          title: message.notification?.title ?? 'Notification',
          message: message.notification?.body ?? '',
          isRead: false,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .set(notification.toJson());
      }

      // Play sound
      await playNotificationSound();
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  // ========== Private Helper Methods ==========

  /// Show local notification
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'order_updates',
        'Order Updates',
        channelDescription: 'Notifications for order status updates',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: data?['orderId'],
      );
    } catch (e) {
      print('Failed to show local notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    
    // Navigate to order detail screen if orderId is present
    if (response.payload != null && response.payload!.isNotEmpty) {
      final orderId = response.payload!;
      _navigateToOrderDetail(orderId);
    }
  }

  /// Handle notification tap when app is in background
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification opened app: ${message.messageId}');
    
    // Navigate to order detail screen if orderId is present in data
    final orderId = message.data['orderId'];
    if (orderId != null && orderId.isNotEmpty) {
      _navigateToOrderDetail(orderId);
    }
  }

  /// Navigate to order detail screen
  void _navigateToOrderDetail(String orderId) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      // Use named route navigation
      Navigator.of(context).pushNamed('/order-detail', arguments: orderId);
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
