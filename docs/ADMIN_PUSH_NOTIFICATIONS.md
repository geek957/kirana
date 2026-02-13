# Admin Push Notifications Implementation Guide

## Overview

This document describes the implementation of push notifications for administrators when new orders are placed and when orders are delivered.

## Architecture

### Clean Separation of Concerns

**Customer Notifications (In-App):**
- Customers receive in-app notifications stored in Firestore
- Uses `AppNotification` model (unchanged from original)
- Real-time updates via Firestore listeners
- Notification bell shows unread count

**Admin Notifications (Push Only):**
- Admins receive ONLY phone push notifications via FCM
- Cloud Functions send notifications directly to admin devices
- NO Firestore notification documents created for admins
- NO changes to `AppNotification` model needed

### Push Notifications (Not In-App)
- Admins receive **phone push notifications** via Firebase Cloud Messaging (FCM)
- No admin UI required - notifications appear on admin devices
- Supports multiple admins simultaneously (broadcast to all)
- Cloud Functions handle all notification delivery

### Customer Enhancement
- Clicking the notification bell automatically marks all notifications as read
- Improves UX by eliminating the need for manual "mark all as read"

## Implementation Components

### 1. Admin Model Updates (`lib/models/admin.dart`)

Added FCM token storage:
```dart
class Admin {
  final String id;
  final String username;
  final String phoneNumber;
  final String? fcmToken;  // Device token for push notifications
  final DateTime createdAt;
}
```

**Note**: The `AppNotification` model remains unchanged - it only handles customer in-app notifications. Admin notifications go directly through FCM push, not through Firestore documents.

### 2. Admin Service (`lib/services/admin_service.dart`)

New methods for FCM token management:

**Register FCM Token (Call on admin login):**
```dart
await adminService.registerAdminFCMToken(adminId);
```

**Remove FCM Token (Call on admin logout):**
```dart
await adminService.removeAdminFCMToken(adminId);
```

### 3. Cloud Functions (`functions/src/index.ts`)

Two new Cloud Functions for admin notifications:

#### `sendNewOrderNotificationToAdmins`
- **Trigger**: onCreate on `orders/{orderId}`
- **When**: New order is placed (OrderStatus.pending)
- **Notification**:
  - Title: "🛒 New Order Received!"
  - Body: "Order #[ID] from [CustomerName]. [N] items, Total: ₹[Amount]"
  - Data: orderId, customerName, totalAmount, itemCount

#### `sendDeliveredNotificationToAdmins`
- **Trigger**: onUpdate on `orders/{orderId}`
- **When**: Order status changes to "delivered"
- **Notification**:
  - Title: "✅ Order Delivered"
  - Body: "Order #[ID] has been successfully delivered to [CustomerName]. Amount: ₹[Amount]"
  - Data: orderId, customerName, totalAmount

### 4. Firestore Security Rules (`firestore.rules`)

Added admin collection rules:
```javascript
match /admins/{adminId} {
  allow read: if isAdmin();
  allow create: if false; // Admins created manually
  // Allow admins to update ONLY their own FCM token
  allow update: if isAdmin() && 
                   isOwner(adminId) && 
                   onlyUpdatingFCMToken();
  allow delete: if false;
}
```

### 5. Customer Home Screen (`lib/screens/products/home_screen.dart`)

Updated notification bell to auto-mark-all-read:
```dart
onPressed: () async {
  // Mark all notifications as read BEFORE navigating
  await notificationProvider.markAllAsRead();
  
  // Then navigate to notifications screen
  if (context.mounted) {
    Navigator.pushNamed(context, Routes.notifications);
  }
},
```

## Deployment Instructions

### Step 1: Deploy Firestore Security Rules

```bash
cd /Volumes/workplace/flutter/kirana
firebase deploy --only firestore:rules
```

### Step 2: Deploy Cloud Functions

```bash
cd functions
npm install  # If needed
cd ..
firebase deploy --only functions
```

This will deploy:
- `sendOrderNotification` (existing - customer notifications)
- `sendBulkNotification` (existing)
- `sendNewOrderNotificationToAdmins` (new)
- `sendDeliveredNotificationToAdmins` (new)

### Step 3: Update Admin App Code

Ensure admin app calls FCM token registration:

**On Admin Login:**
```dart
final adminService = AdminService();
await adminService.registerAdminFCMToken(adminId);
adminService.setCurrentAdminId(adminId);
```

**On Admin Logout:**
```dart
final adminService = AdminService();
await adminService.removeAdminFCMToken(adminId);
await authService.logout();
```

### Step 4: Configure FCM in Admin App

Ensure Firebase Cloud Messaging is properly configured:

1. **Android**: `android/app/google-services.json` must be present
2. **iOS**: `ios/Runner/GoogleService-Info.plist` must be present
3. **FCM Permissions**: Request notification permissions on app start

## Testing Checklist

### Admin FCM Token Management
- [ ] Admin logs in → FCM token saved to Firestore
- [ ] Check Firestore console: `admins/{adminId}` has `fcmToken` field
- [ ] Admin logs out → FCM token removed from Firestore

### New Order Notifications
- [ ] Customer places order
- [ ] All admin phones receive push notification immediately
- [ ] Notification shows: customer name, item count, total amount
- [ ] Tapping notification can navigate to order details (optional)

### Delivered Order Notifications
- [ ] Admin marks order as delivered
- [ ] All admin phones receive push notification
- [ ] Notification shows: customer name, order amount

### Multi-Admin Support
- [ ] Multiple admins log in on different devices
- [ ] All admins receive notifications simultaneously
- [ ] Each admin can independently manage their FCM token

### Customer Experience
- [ ] Customer clicks notification bell
- [ ] All notifications automatically marked as read
- [ ] Unread count badge updates immediately
- [ ] Notifications screen shows all as read

## Notification Content

### New Order Notification
```
Title: 🛒 New Order Received!
Body: Order #abc-123 from John Doe. 5 items, Total: ₹450.00
```

### Delivered Order Notification
```
Title: ✅ Order Delivered
Body: Order #abc-123 has been successfully delivered to John Doe. Amount: ₹450.00
```

## Multi-Admin Architecture

### How It Works
1. Each admin device has a unique FCM token
2. Cloud Functions query ALL admin documents
3. Collect ALL FCM tokens from all admins
4. Use `sendEachForMulticast()` to broadcast to all devices
5. Each admin receives the notification on their phone

### Scalability
- Supports unlimited number of admins
- No performance impact with more admins
- Firebase handles message delivery and retries
- Failed deliveries logged but don't block others

## Troubleshooting

### Admin Not Receiving Notifications

**Check 1: FCM Token Registered**
```bash
# Check Firestore console
# Navigate to: admins/{adminId}
# Verify fcmToken field exists and is not null
```

**Check 2: Cloud Function Logs**
```bash
firebase functions:log --only sendNewOrderNotificationToAdmins
firebase functions:log --only sendDeliveredNotificationToAdmins
```

**Check 3: FCM Permissions**
```dart
// In admin app, verify permissions granted
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Authorization status: ${settings.authorizationStatus}');
// Should be: AuthorizationStatus.authorized
```

### Notifications Not Triggering

**Check 1: Cloud Functions Deployed**
```bash
firebase functions:list
# Should show:
# - sendNewOrderNotificationToAdmins
# - sendDeliveredNotificationToAdmins
```

**Check 2: Function Execution**
```bash
# Check Cloud Function logs in Firebase Console
# Functions > Logs
# Look for: "New order created" or "Order delivered"
```

### Customer Auto-Mark-All-Read Not Working

**Check 1: NotificationProvider Initialized**
```dart
// In home_screen.dart initState
context.read<NotificationProvider>().initialize(userId);
```

**Check 2: Firestore Rules**
```bash
# Verify customers can update their own notifications
# Check: match /notifications/{notificationId}
# Should allow: update: if isOwner(resource.data.customerId)
```

## Security Considerations

### Admin FCM Token Security
- Admins can only update their OWN FCM token
- Token updates validated by Firestore security rules
- Tokens automatically expire/refresh by Firebase

### Cloud Function Authorization
- Functions run with admin privileges
- No client-side code can trigger admin notifications
- Only Firestore triggers invoke notification functions

### Notification Data
- Push notifications contain order summary only
- Sensitive data (payment info, addresses) not included
- Full order details available in admin app

## Performance

### Cloud Function Cold Starts
- First invocation may take 1-2 seconds
- Subsequent calls are faster (warm state)
- No impact on order creation speed (async)

### FCM Message Delivery
- Typically delivered in < 1 second
- Firebase handles retries for offline devices
- Messages persist for up to 4 weeks

### Multi-Admin Broadcasting
- No additional latency for multiple admins
- `sendEachForMulticast` is optimized by Firebase
- Maximum 500 tokens per batch (plenty for most cases)

## Future Enhancements

### Potential Improvements
1. **Admin Notification Preferences**: Allow admins to customize notification types
2. **Rich Notifications**: Include product images and action buttons
3. **Notification Categories**: Different sounds for urgent vs normal orders
4. **Admin Notification History**: Store admin notification read status
5. **Custom Notification Channels**: Separate channels for different notification types

### Monitoring
- Track notification delivery success rate
- Monitor Cloud Function execution times
- Alert on failed FCM token registrations
- Dashboard for admin notification metrics

## Related Documentation
- [NOTIFICATION_SYSTEM.md](./NOTIFICATION_SYSTEM.md) - Customer notification system
- [FIREBASE_SETUP_GUIDE.md](./FIREBASE_SETUP_GUIDE.md) - Firebase configuration
- [ADMIN_USER_GUIDE.md](./ADMIN_USER_GUIDE.md) - Admin app usage

## Support

For issues or questions:
1. Check Cloud Function logs in Firebase Console
2. Verify Firestore security rules deployed correctly
3. Test FCM token registration/removal
4. Review admin app FCM configuration

---

**Implementation Date**: February 8, 2026  
**Version**: 1.0  
**Status**: ✅ Ready for Deployment
