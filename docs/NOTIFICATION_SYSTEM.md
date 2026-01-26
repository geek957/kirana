# Notification System Implementation

## Overview

The notification system provides in-app notifications to customers about their order status changes. Notifications are stored in Firestore and displayed in real-time using Firestore listeners.

## Architecture

### Data Model

**Firestore Collection:** `/notifications/{notificationId}`

```dart
{
  id: string,
  customerId: string,
  orderId: string,
  type: string,
  title: string,
  message: string,
  isRead: boolean,
  createdAt: timestamp
}
```

### Components

1. **NotificationService** (`lib/services/notification_service.dart`)
   - Creates notifications
   - Retrieves customer notifications
   - Marks notifications as read
   - Deletes old notifications (>30 days)
   - Provides real-time streams for notifications and unread count

2. **NotificationProvider** (`lib/providers/notification_provider.dart`)
   - Manages notification state
   - Sets up real-time Firestore listeners
   - Handles notification operations (mark as read, mark all as read)
   - Provides unread count for badge display

3. **NotificationsScreen** (`lib/screens/notifications/notifications_screen.dart`)
   - Displays list of notifications
   - Shows unread indicators
   - Allows marking notifications as read
   - Navigates to order details on tap

4. **Home Screen Integration**
   - Notification bell icon in app bar
   - Badge showing unread count
   - Real-time updates

## Notification Triggers

Notifications are automatically created when an admin updates an order status to:

- **Confirmed** - "Your order has been confirmed and will be prepared soon."
- **Preparing** - "Your order is being prepared for delivery."
- **Out for Delivery** - "Your order is out for delivery and will arrive soon."
- **Delivered** - "Your order has been delivered. Thank you for shopping with us!"

## Integration with Order Service

The `OrderService.updateOrderStatus()` method automatically creates notifications when order status changes. This is done in a transaction to ensure atomicity.

```dart
await orderService.updateOrderStatus(orderId, OrderStatus.confirmed);
// Notification is automatically created for the customer
```

## Security Rules

```javascript
match /notifications/{notificationId} {
  allow read: if isOwner(resource.data.customerId) || isAdmin();
  allow create: if isAdmin(); // Only admins can create notifications
  allow update: if isOwner(resource.data.customerId); // Customers can mark as read
  allow delete: if isOwner(resource.data.customerId);
}
```

## Firestore Indexes

Two composite indexes are required:

1. **Customer notifications ordered by date:**
   - customerId (ASCENDING)
   - createdAt (DESCENDING)

2. **Unread notifications by customer:**
   - customerId (ASCENDING)
   - isRead (ASCENDING)

## Features

### Real-time Updates
- Notifications appear instantly when created
- Unread count updates automatically
- No manual refresh needed

### Mark as Read
- Individual notifications can be marked as read by tapping
- "Mark all read" button marks all notifications as read at once
- Read status is persisted in Firestore

### Navigation
- Tapping a notification navigates to the order detail screen
- Order ID is passed for direct navigation

### Empty State
- Friendly empty state when no notifications exist
- Icon and helpful message displayed

### Pull to Refresh
- Swipe down to manually refresh notifications
- Useful for ensuring latest data

### Automatic Cleanup
- Notifications older than 30 days can be deleted
- `deleteOldNotifications()` method available for scheduled cleanup

## Usage

### Initialize in Home Screen

```dart
// In HomeScreen initState
final authProvider = context.read<AuthProvider>();
if (authProvider.firebaseUser != null) {
  context.read<NotificationProvider>().initialize(
    authProvider.firebaseUser!.uid,
  );
}
```

### Display Notification Bell

```dart
Consumer<NotificationProvider>(
  builder: (context, notificationProvider, child) {
    final unreadCount = notificationProvider.unreadCount;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Badge(count: unreadCount),
          ),
      ],
    );
  },
)
```

### Create Notification (Admin Only)

```dart
await notificationService.createNotification(
  customerId: order.customerId,
  orderId: orderId,
  type: 'order_status_change',
  title: 'Order Confirmed',
  message: 'Your order #$orderId has been confirmed.',
);
```

## Future Enhancements

1. **Push Notifications**
   - Integrate Firebase Cloud Messaging (FCM)
   - Send push notifications for important updates
   - Allow users to configure notification preferences

2. **Notification Categories**
   - Order updates
   - Promotional offers
   - Low stock alerts (for admins)
   - System announcements

3. **Notification Preferences**
   - Allow users to enable/disable notification types
   - Configure quiet hours
   - Email notifications option

4. **Rich Notifications**
   - Include product images
   - Action buttons (e.g., "Track Order", "Reorder")
   - Expandable content

## Testing

### Manual Testing Checklist

- [ ] Create an order and verify notification appears
- [ ] Update order status and verify notification is created
- [ ] Verify unread count badge updates in real-time
- [ ] Tap notification and verify navigation to order details
- [ ] Mark notification as read and verify visual change
- [ ] Mark all as read and verify all notifications update
- [ ] Pull to refresh and verify notifications reload
- [ ] Verify empty state when no notifications exist
- [ ] Verify notifications persist across app restarts

### Property-Based Test

Property 32 (Task 11.3) validates that order status updates create notifications with correct details.

## Troubleshooting

### Notifications not appearing
- Verify Firestore indexes are deployed
- Check security rules allow notification creation
- Ensure NotificationProvider is initialized with correct customer ID
- Check Firestore console for notification documents

### Unread count not updating
- Verify real-time listener is active
- Check for errors in console logs
- Ensure isRead field is boolean type in Firestore

### Navigation not working
- Verify order ID is correctly stored in notification
- Check OrderDetailScreen route is properly configured
- Ensure order exists in Firestore

## Performance Considerations

- Notifications are loaded with real-time listeners (efficient)
- Unread count uses a separate optimized query
- Old notifications (>30 days) should be periodically deleted
- Consider pagination for users with many notifications (>100)

## Maintenance

### Regular Tasks
1. Monitor notification creation rate
2. Clean up old notifications (>30 days) monthly
3. Review notification messages for clarity
4. Check for failed notification creations in logs

### Monitoring Metrics
- Notification creation rate
- Average time to mark as read
- Unread notification count per user
- Failed notification creation attempts
