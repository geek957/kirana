# Firebase Setup for Enhanced Features

## Overview

This document outlines the Firebase configuration requirements for the enhanced features in Kirana v2.0, including categories, discounts, delivery proof, app configuration, push notifications, and more.

## Table of Contents

1. [Firebase Services Required](#firebase-services-required)
2. [Firestore Database Setup](#firestore-database-setup)
3. [Firebase Storage Setup](#firebase-storage-setup)
4. [Firebase Cloud Messaging Setup](#firebase-cloud-messaging-setup)
5. [Security Rules](#security-rules)
6. [Indexes](#indexes)
7. [Initial Data Setup](#initial-data-setup)
8. [Platform-Specific Configuration](#platform-specific-configuration)

---

## Firebase Services Required

### Core Services (Existing)
- ✅ Firebase Authentication (Phone)
- ✅ Cloud Firestore
- ✅ Firebase Storage
- ✅ Firebase Analytics
- ✅ Firebase Crashlytics
- ✅ Firebase Performance Monitoring

### New Services (Enhanced Features)
- 🆕 **Firebase Cloud Messaging (FCM)** - Push notifications
- 🆕 **Firebase Storage** (expanded usage) - Delivery photos

### Service Activation

1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Select Your Project**
3. **Enable Required Services**:
   - Navigate to "Build" section
   - Enable Cloud Messaging
   - Verify Storage is enabled
   - Check Firestore is active

---

## Firestore Database Setup

### New Collections

#### 1. Categories Collection

**Path**: `/categories/{categoryId}`

**Document Structure**:
```json
{
  "id": "string",
  "name": "string",
  "description": "string | null",
  "productCount": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Initial Setup**:
Create at least one default category:
```javascript
{
  id: "groceries",
  name: "Groceries",
  description: "General grocery items",
  productCount: 0,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now()
}
```

#### 2. Config Collection

**Path**: `/config/app_settings`

**Document Structure**:
```json
{
  "deliveryCharge": 20.0,
  "freeDeliveryThreshold": 200.0,
  "maxCartValue": 3000.0,
  "orderCapacityWarningThreshold": 2,
  "orderCapacityBlockThreshold": 10,
  "updatedAt": "timestamp",
  "updatedBy": "string (admin user ID)"
}
```

**Initial Setup**:
Create the config document with default values:
```javascript
{
  deliveryCharge: 20.0,
  freeDeliveryThreshold: 200.0,
  maxCartValue: 3000.0,
  orderCapacityWarningThreshold: 2,
  orderCapacityBlockThreshold: 10,
  updatedAt: Timestamp.now(),
  updatedBy: "[your-admin-user-id]"
}
```

### Extended Collections

#### 3. Products Collection (Extended)

**New Fields Added**:
```json
{
  "discountPrice": "number | null",
  "categoryId": "string (required)",
  "minimumOrderQuantity": "number (default: 1)"
}
```

**Migration Required**:
- Add `categoryId` to all existing products
- Add `minimumOrderQuantity: 1` to all existing products
- `discountPrice` can remain null

#### 4. Orders Collection (Extended)

**New Fields Added**:
```json
{
  "deliveryPhotoUrl": "string | null",
  "deliveryLocation": {
    "latitude": "number",
    "longitude": "number"
  } | null,
  "customerRemarks": "string | null",
  "remarksTimestamp": "timestamp | null",
  "deliveryCharge": "number"
}
```

**Migration Required**:
- Add `deliveryCharge: 0` to all existing orders
- Other fields can remain null

---

## Firebase Storage Setup

### Storage Buckets

**Default Bucket**: `[your-project-id].appspot.com`

### Directory Structure

Create the following directory structure:

```
/
├── product_images/          (existing)
│   └── {productId}.jpg
│
└── delivery_photos/         (new)
    └── {orderId}_{timestamp}.jpg
```

### Storage Configuration

**Delivery Photos Directory**:
- **Path**: `/delivery_photos/`
- **File Format**: JPEG
- **Naming**: `{orderId}_{timestamp}.jpg`
- **Max Size**: 5MB (enforced by rules)
- **Compression**: Automatic in app

### Storage Quotas

**Check Current Usage**:
1. Go to Firebase Console
2. Navigate to Storage
3. Check usage metrics

**Recommended Plan**:
- **Spark (Free)**: 5GB storage, 1GB/day downloads
- **Blaze (Pay-as-you-go)**: Unlimited, $0.026/GB storage, $0.12/GB downloads

**Estimate for Delivery Photos**:
- Average photo size: 500KB-1MB (after compression)
- 100 orders/day = 50-100MB/day
- 30 days = 1.5-3GB/month

---

## Firebase Cloud Messaging Setup

### FCM Configuration

#### 1. Enable Cloud Messaging

1. Go to Firebase Console
2. Navigate to "Project Settings"
3. Select "Cloud Messaging" tab
4. Note your **Server Key** and **Sender ID**

#### 2. Android Setup

**Add to `android/app/build.gradle`**:
```gradle
dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

**Add to `android/app/src/main/AndroidManifest.xml`**:
```xml
<application>
    <!-- FCM Default Notification Channel -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="order_updates" />
    
    <!-- FCM Default Notification Icon -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />
</application>
```

**Add Permissions**:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### 3. iOS Setup

**Enable Push Notifications**:
1. Open Xcode
2. Select your project
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes"
7. Check "Remote notifications"

**Add to `ios/Runner/Info.plist`**:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**Upload APNs Certificate**:
1. Generate APNs certificate in Apple Developer Portal
2. Go to Firebase Console → Project Settings → Cloud Messaging
3. Upload APNs certificate under "iOS app configuration"

#### 4. Notification Channels (Android)

Create notification channel in app:
```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'order_updates',
  'Order Updates',
  description: 'Notifications for order status updates',
  importance: Importance.high,
);
```

---

## Security Rules

### Firestore Security Rules

**Deploy the following rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    // Categories Collection
    match /categories/{categoryId} {
      allow read: if request.auth != null;
      allow create, update: if isAdmin();
      allow delete: if isAdmin() && resource.data.productCount == 0;
    }
    
    // Config Collection
    match /config/app_settings {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
    
    // Products Collection (Extended)
    match /products/{productId} {
      allow read: if request.auth != null;
      allow create, update, delete: if isAdmin();
      
      // Validation for new fields
      allow write: if request.resource.data.discountPrice == null 
        || request.resource.data.discountPrice < request.resource.data.price;
      allow write: if request.resource.data.minimumOrderQuantity >= 1;
      allow write: if exists(/databases/$(database)/documents/categories/$(request.resource.data.categoryId));
    }
    
    // Orders Collection (Extended)
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (isAdmin() || resource.data.customerId == request.auth.uid);
      
      // Customer can add/update remarks
      allow update: if request.auth.uid == resource.data.customerId &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['customerRemarks', 'remarksTimestamp']) &&
        (resource.data.remarksTimestamp == null || 
         request.time < resource.data.remarksTimestamp + duration.value(24, 'h'));
      
      // Admin can update delivery proof
      allow update: if isAdmin() &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['deliveryPhotoUrl', 'deliveryLocation', 'status', 'updatedAt']);
    }
  }
}
```

**Deploy Rules**:
```bash
firebase deploy --only firestore:rules
```

### Firebase Storage Rules

**Deploy the following rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
        firestore.exists(/databases/(default)/documents/admins/$(request.auth.uid));
    }
    
    // Product Images (existing)
    match /product_images/{imageId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
    
    // Delivery Photos (new)
    match /delivery_photos/{orderId}_{timestamp}.jpg {
      // Only admins can upload
      allow write: if isAdmin();
      
      // Authenticated users can read
      allow read: if request.auth != null;
      
      // Never allow delete (permanent record)
      allow delete: if false;
      
      // Validate file size (max 5MB)
      allow write: if request.resource.size < 5 * 1024 * 1024;
      
      // Validate file type (images only)
      allow write: if request.resource.contentType.matches('image/.*');
    }
  }
}
```

**Deploy Rules**:
```bash
firebase deploy --only storage
```

---

## Indexes

### Required Composite Indexes

#### 1. Products by Category

**Collection**: `products`
**Fields**:
- `categoryId` (Ascending)
- `isAvailable` (Ascending)
- `name` (Ascending)

**Create in Firebase Console**:
1. Go to Firestore → Indexes
2. Click "Create Index"
3. Collection: `products`
4. Add fields as above
5. Click "Create"

#### 2. Categories by Name

**Collection**: `categories`
**Fields**:
- `name` (Ascending)

**Create in Firebase Console**:
1. Go to Firestore → Indexes
2. Click "Create Index"
3. Collection: `categories`
4. Field: `name` (Ascending)
5. Click "Create"

#### 3. Orders by Status (for capacity count)

**Collection**: `orders`
**Fields**:
- `status` (Ascending)
- `createdAt` (Descending)

**Note**: This index may already exist. Verify in Firebase Console.

### Index Creation via Firebase CLI

Alternatively, create `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryId", "order": "ASCENDING" },
        { "fieldPath": "isAvailable", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "categories",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Deploy Indexes**:
```bash
firebase deploy --only firestore:indexes
```

---

## Initial Data Setup

### 1. Create Default Configuration

**Using Firebase Console**:
1. Go to Firestore
2. Create collection: `config`
3. Create document: `app_settings`
4. Add fields:
   ```
   deliveryCharge: 20
   freeDeliveryThreshold: 200
   maxCartValue: 3000
   orderCapacityWarningThreshold: 2
   orderCapacityBlockThreshold: 10
   updatedAt: [current timestamp]
   updatedBy: [your admin user ID]
   ```

**Using Script** (see `scripts/initialize_default_data.js`):
```bash
node scripts/initialize_default_data.js
```

### 2. Create Default Categories

**Recommended Categories**:
1. Fresh Fruits
2. Fresh Vegetables
3. Dairy Products
4. Snacks & Beverages
5. Grains & Cereals
6. Spices & Condiments
7. Personal Care
8. Household Items

**Using Firebase Console**:
1. Go to Firestore
2. Create collection: `categories`
3. For each category, create document with:
   ```
   id: [auto-generated or custom]
   name: [category name]
   description: [optional description]
   productCount: 0
   createdAt: [current timestamp]
   updatedAt: [current timestamp]
   ```

**Using Script**:
```bash
node scripts/initialize_default_data.js --categories
```

### 3. Migrate Existing Products

**Add Required Fields**:
For each existing product, add:
- `categoryId`: Assign to appropriate category
- `minimumOrderQuantity`: Set to 1 (default)
- `discountPrice`: Leave as null (no discount)

**Bulk Update Script**:
```javascript
// scripts/migrate_products.js
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function migrateProducts() {
  const productsRef = db.collection('products');
  const snapshot = await productsRef.get();
  
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      categoryId: 'groceries', // or assign based on product
      minimumOrderQuantity: 1,
      discountPrice: null
    });
  });
  
  await batch.commit();
  console.log('Products migrated successfully');
}

migrateProducts();
```

### 4. Migrate Existing Orders

**Add Delivery Charge Field**:
For each existing order, add:
- `deliveryCharge`: Set to 0 (historical orders were free)

**Bulk Update Script**:
```javascript
// scripts/migrate_orders.js
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function migrateOrders() {
  const ordersRef = db.collection('orders');
  const snapshot = await ordersRef.get();
  
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      deliveryCharge: 0
    });
  });
  
  await batch.commit();
  console.log('Orders migrated successfully');
}

migrateOrders();
```

---

## Platform-Specific Configuration

### Android Configuration

**1. Update `android/app/build.gradle`**:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for FCM
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

**2. Update `android/app/src/main/AndroidManifest.xml`**:
```xml
<manifest>
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- FCM Configuration -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="order_updates" />
        
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
    </application>
</manifest>
```

**3. Add Notification Icon**:
- Create `android/app/src/main/res/drawable/ic_notification.xml`
- Or add PNG icons in various densities

### iOS Configuration

**1. Update `ios/Runner/Info.plist`**:
```xml
<dict>
    <!-- Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to capture delivery photos</string>
    
    <!-- Location Permission -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need your location to record delivery location</string>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>
</dict>
```

**2. Enable Capabilities in Xcode**:
- Push Notifications
- Background Modes → Remote notifications

**3. Upload APNs Certificate**:
- Generate in Apple Developer Portal
- Upload to Firebase Console

---

## Verification Checklist

### Firebase Services
- [ ] Cloud Firestore enabled
- [ ] Firebase Storage enabled
- [ ] Firebase Cloud Messaging enabled
- [ ] Firebase Authentication (Phone) configured
- [ ] Firebase Analytics enabled
- [ ] Firebase Crashlytics enabled

### Firestore Setup
- [ ] Categories collection created
- [ ] Config document created with default values
- [ ] Products collection has new fields
- [ ] Orders collection has new fields
- [ ] Security rules deployed
- [ ] Indexes created

### Firebase Storage
- [ ] delivery_photos directory exists
- [ ] Storage rules deployed
- [ ] Storage quota sufficient

### FCM Setup
- [ ] FCM enabled in Firebase Console
- [ ] Android configuration complete
- [ ] iOS configuration complete
- [ ] APNs certificate uploaded (iOS)
- [ ] Test notification sent successfully

### Initial Data
- [ ] Default config document created
- [ ] At least one category created
- [ ] Existing products migrated
- [ ] Existing orders migrated

### Testing
- [ ] Create category successfully
- [ ] Add product with discount
- [ ] Place order with delivery charge
- [ ] Receive push notification
- [ ] Upload delivery photo
- [ ] Capture delivery location
- [ ] Add customer remarks

---

## Troubleshooting

### Common Issues

**Issue: Firestore permission denied**
- Solution: Deploy security rules, verify admin user exists

**Issue: Storage upload fails**
- Solution: Deploy storage rules, check file size and type

**Issue: Push notifications not received**
- Solution: Verify FCM setup, check device permissions, test with Firebase Console

**Issue: Indexes not working**
- Solution: Wait for index creation (can take minutes), verify in Firebase Console

**Issue: Config document not found**
- Solution: Create manually in Firebase Console or run initialization script

---

## Need Help?

For additional support:
- **Firebase Documentation**: https://firebase.google.com/docs
- **Firebase Console**: https://console.firebase.google.com
- **Technical Support**: Contact system administrator
- **General Setup**: See main Firebase Setup Guide

---

**Last Updated**: January 2025
**Version**: 2.0 (Enhanced Features)
