import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _customerId;
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Initialize the provider with customer ID and set up real-time listeners
  void initialize(String customerId) {
    if (_customerId == customerId) {
      return; // Already initialized for this customer
    }

    _customerId = customerId;
    _setupListeners();
  }

  /// Set up real-time Firestore listeners
  void _setupListeners() {
    if (_customerId == null) return;

    // Cancel existing subscriptions
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();

    // Listen to notifications
    _notificationsSubscription = _notificationService
        .getCustomerNotificationsStream(_customerId!)
        .listen(
          (notifications) {
            _notifications = notifications;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error listening to notifications: $error');
          },
        );

    // Listen to unread count
    _unreadCountSubscription = _notificationService
        .getUnreadCountStream(_customerId!)
        .listen(
          (count) {
            _unreadCount = count;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error listening to unread count: $error');
          },
        );
  }

  /// Load notifications manually (for pull-to-refresh)
  Future<void> loadNotifications() async {
    if (_customerId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getCustomerNotifications(
        _customerId!,
      );
      _unreadCount = await _notificationService.getUnreadCount(_customerId!);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      // The real-time listener will update the state automatically
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_customerId == null) return;

    try {
      await _notificationService.markAllAsRead(_customerId!);
      // The real-time listener will update the state automatically
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete old notifications (>30 days)
  Future<void> deleteOldNotifications() async {
    try {
      await _notificationService.deleteOldNotifications();
      // The real-time listener will update the state automatically
    } catch (e) {
      debugPrint('Error deleting old notifications: $e');
      rethrow;
    }
  }

  /// Clear the provider state and cancel subscriptions
  void clear() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _notifications = [];
    _unreadCount = 0;
    _customerId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
