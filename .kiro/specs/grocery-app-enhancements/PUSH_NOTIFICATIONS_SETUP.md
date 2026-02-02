# Push Notifications Setup Guide

Complete guide to enable push notifications on user devices for the Kirana app.

## Overview

This implementation adds complete push notification support:
- ✅ Notifications appear on phone home screen
- ✅ Works when app is open, background, or closed
- ✅ Automatic notifications when order status changes
- ✅ Tap notification to open order details
- ✅ In-app notification list
- ✅ Cloud Functions for server-side delivery

## What Was Implemented

### Client-Side (Flutter App)

1. **FCM Initialization** (`lib/main.dart`)
   - Requests notification permissions
   - Sets up notification channels
   - Configures message handlers

2. **Token Management** (`lib/providers/auth_provider.dart`, `lib/services/auth_service.dart`)
   - Gets FCM token on login
   - Saves token to user document in Firestore
   - Updates token on app launch

3. **Notification Navigation** (`lib/services/notification_service.dart`)
   - Handles notification taps
   - Routes to order detail screen

4. **Security Rules** (`firestore.rules`)
   - Updated to allow Cloud Functions to create notifications

### Server-Side (Cloud Functions)

1. **sendOrderNotification** (`functions/src/index.ts`)
   - Triggers on order status change
   - Sends push notification to customer's device
   - Creates in-app notification document

2. **sendBulkNotification** (`functions/src/index.ts`)
   - Allows admins to send announcements
   - HTTP callable function

## Deployment Steps

### Step 1: Install Cloud Function Dependencies

```bash
cd functions
npm install
```

### Step 2: Build TypeScript

```bash
npm run build
```

### Step 3: Verify Firebase Project

```bash
# Check which project you're using
firebase projects:list

# Switch project if needed
firebase use <project-id>
```

### Step 4: Deploy Firestore Rules

```bash
cd ..
firebase deploy --only firestore:rules
```

### Step 5: Deploy Cloud Functions

**IMPORTANT**: Requires Firebase Blaze (pay-as-you-go) plan

```bash
firebase deploy --only functions
```

If you're on the free Spark plan, you'll see an error. Upgrade at:
https://console.firebase.google.com/project/YOUR_PROJECT_ID/usage/details

### Step 6: Build and Test the App

```bash
# Clean build
flutter clean
flutter pub get

# Build for Android
flutter build apk

# Or build for iOS
flutter build ios

# Run on physical device (required for push notifications)
flutter run --release
```

## Testing Push Notifications

### Test 1: App in Foreground

1. Open the app
2. Log in as a customer
3. Place an order
4. Log in as admin (different device or browser)
5. Update order status to "Confirmed"
6. **Expected**: Local notification appears on customer's device

### Test 2: App in Background

1. Open the app and log in
2. Place an order
3. Press home button (app goes to background)
4. Admin updates order status
5. **Expected**: System notification appears in notification tray

### Test 3: App Completely Closed

1. Log in and place an order
2. Force close the app completely
3. Admin updates order status
4. **Expected**: System notification appears in notification tray

### Test 4: Notification Tap

1. Receive a notification
2. Tap on it
3. **Expected**: App opens to order detail screen

## Verification Checklist

- [ ] Notification permission requested on first launch
- [ ] FCM token saved to user document in Firestore
- [ ] Cloud Functions deployed successfully
- [ ] Order status change triggers notification
- [ ] Notification appears on device
- [ ] Tapping notification opens order details
- [ ] In-app notification list shows notifications
- [ ] Notifications work in foreground, background, and closed states

## Troubleshooting

### Notifications Not Appearing

**Issue**: No notifications on device

**Solutions**:
1. Check notification permissions in device settings
2. Verify FCM token is saved: Check Firestore customer document for `fcmToken` field
3. Check Cloud Function logs: `firebase functions:log`
4. Ensure app is built in release mode for testing
5. Test on physical device (simulator may not show push notifications)

### Cloud Function Not Triggering

**Issue**: Function doesn't run when order status changes

**Solutions**:
1. Verify function is deployed: Check Firebase Console > Functions
2. Check function logs for errors
3. Ensure order document path is `orders/{orderId}`
4. Verify Firestore rules allow function to write notifications

### Permission Denied Errors

**Issue**: Firestore permission errors

**Solution**:
```bash
firebase deploy --only firestore:rules
```

### FCM Token Not Saved

**Issue**: Token field missing in user document

**Solutions**:
1. Log out and log back in
2. Check console logs for FCM initialization errors
3. Verify `NotificationService().initializeFCM()` is called in main.dart

## Cost Estimate

### Cloud Functions (Free Tier)
- 2M invocations/month FREE
- 400K GB-seconds FREE
- 200K CPU-seconds FREE

### Typical Usage
- 100 orders/day = 3,000 invocations/month
- **Well within free tier**

### When You'll Pay
- Only if you exceed free tier limits
- Roughly $0.40 per million invocations after free tier

## Firebase Console Monitoring

### View Function Logs
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click "Functions" in left menu
4. Click on function name to see logs

### View Notifications in Firestore
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Firestore Database"
3. Navigate to `notifications` collection
4. Verify notifications are being created

## Advanced Features

### Send Custom Notifications (Admin)

You can call the bulk notification function from your admin panel:

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> sendAnnouncement() async {
  try {
    final result = await FirebaseFunctions.instance
      .httpsCallable('sendBulkNotification')
      .call({
        'title': 'Special Offer!',
        'body': 'Get 20% off on all products today.',
        'type': 'announcement',
      });
    
    print('Sent to ${result.data['totalCustomers']} customers');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Notification Sounds

Sound files are included in `assets/sounds/notification.mp3`. To customize:
1. Replace the MP3 file
2. Update reference in `NotificationService` if needed

### Notification Channels (Android)

Channel is configured as `order_updates` with:
- High importance
- Sound enabled
- Badge enabled

Modify in `NotificationService.initializeFCM()` if needed.

## Security Considerations

1. **FCM Tokens**: Stored securely in Firestore, only accessible by owner and admins
2. **Cloud Functions**: Run with admin privileges, validated by Firebase
3. **Bulk Notifications**: Require authentication, only admins can send
4. **User Data**: Protected by Firestore security rules

## Next Steps

### Phase 1: Basic Testing ✅
- Deploy functions
- Test on physical device
- Verify all notification states work

### Phase 2: Production
- Monitor function invocations
- Collect user feedback
- Adjust notification messages if needed

### Phase 3: Enhancements
- Add notification preferences (user settings)
- Rich notifications with images
- Notification categories
- Schedule notifications
- Analytics tracking

## Support Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

## Quick Reference Commands

```bash
# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only rules
firebase deploy --only firestore:rules

# View function logs
firebase functions:log

# Test functions locally
cd functions && npm run serve
```

## Summary

You now have a complete push notification system:
- Customers receive notifications on their home screen
- Notifications work in all app states
- Cloud Functions handle server-side delivery
- In-app notification list for history
- Cost-effective (free tier covers typical usage)

The next step is to deploy and test on a physical device!
