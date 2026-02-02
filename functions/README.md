# Cloud Functions for Push Notifications

This directory contains Firebase Cloud Functions that handle push notifications for the Kirana app.

## Features

1. **Automatic Order Notifications**: Triggers when order status changes
2. **Bulk Notifications**: Admin can send announcements to all customers
3. **FCM Integration**: Sends push notifications to user devices
4. **In-App Notifications**: Creates notification documents in Firestore

## Prerequisites

1. Node.js 20 or higher
2. Firebase CLI installed globally: `npm install -g firebase-tools`
3. Firebase project with Blaze (pay-as-you-go) plan

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Select Your Firebase Project

```bash
firebase use --add
# Select your project from the list
```

### 4. Build TypeScript

```bash
npm run build
```

### 5. Deploy Functions

```bash
# Deploy all functions
npm run deploy

# Or deploy from project root
cd ..
firebase deploy --only functions
```

## Functions

### sendOrderNotification

**Trigger**: Firestore order document update
**Purpose**: Automatically sends push notifications when order status changes

**Statuses that trigger notifications:**
- `confirmed` - Order Confirmed! 🎉
- `preparing` - Order Being Prepared 👨‍🍳
- `out_for_delivery` - Out for Delivery 🚚
- `delivered` - Order Delivered ✅

**How it works:**
1. Detects order status change in Firestore
2. Retrieves customer's FCM token
3. Creates in-app notification document
4. Sends push notification to device

### sendBulkNotification

**Trigger**: HTTP callable function
**Purpose**: Admins can send announcement notifications to all customers

**Usage from Flutter:**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('sendBulkNotification')
  .call({
    'title': 'New Products Available!',
    'body': 'Check out our latest arrivals.',
    'type': 'announcement',
  });
```

## Testing Locally

### 1. Start Firebase Emulators

```bash
npm run serve
```

### 2. Point Your App to Emulators

In your Flutter app's main.dart:

```dart
// For testing only
if (kDebugMode) {
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

## Monitoring

### View Function Logs

```bash
npm run logs
```

### Firebase Console

View detailed logs and metrics:
- Go to [Firebase Console](https://console.firebase.google.com)
- Select your project
- Navigate to Functions

## Cost Considerations

Firebase Cloud Functions pricing (free tier):
- 2 million invocations/month
- 400,000 GB-seconds
- 200,000 CPU-seconds

For a typical small grocery app:
- ~100 orders/day = 3,000 invocations/month
- Well within free tier limits

## Troubleshooting

### Function not triggering

1. Check Firebase Console logs
2. Verify order document path matches: `orders/{orderId}`
3. Ensure customer has FCM token saved

### Push notification not appearing

1. Verify FCM token is saved in customer document
2. Check notification permissions on device
3. Test with a simple notification first
4. Check Firebase Cloud Messaging logs

### Build errors

```bash
# Clean and rebuild
rm -rf lib node_modules
npm install
npm run build
```

## Security

- Functions run with admin privileges
- Bulk notifications require authentication
- Customer data is protected by Firestore rules
- FCM tokens are stored securely in user documents

## Maintenance

### Update Dependencies

```bash
npm update
npm audit fix
```

### Deploy Updates

```bash
npm run build
npm run deploy
```

## Support

For issues or questions:
1. Check Firebase documentation: https://firebase.google.com/docs/functions
2. Review function logs in Firebase Console
3. Test locally with emulators first
