# Deployment Checklist - Enhanced Features (v2.0)

## Overview

This checklist ensures all enhanced features are properly configured and tested before deploying Kirana v2.0 to production. Complete each section in order.

## Pre-Deployment Checklist

### 1. Firebase Configuration

#### Firestore Database
- [ ] Categories collection created
- [ ] Config document (`/config/app_settings`) created with default values
- [ ] Products collection updated with new fields (`categoryId`, `minimumOrderQuantity`, `discountPrice`)
- [ ] Orders collection updated with new fields (`deliveryPhotoUrl`, `deliveryLocation`, `customerRemarks`, `deliveryCharge`)
- [ ] All existing products have `categoryId` assigned
- [ ] All existing products have `minimumOrderQuantity` set (default: 1)
- [ ] All existing orders have `deliveryCharge` set (default: 0 for historical)

#### Firebase Storage
- [ ] `delivery_photos/` directory structure created
- [ ] Storage rules deployed and tested
- [ ] Storage quota checked (sufficient for delivery photos)
- [ ] Test photo upload successful
- [ ] Test photo retrieval successful

#### Firebase Cloud Messaging
- [ ] FCM enabled in Firebase Console
- [ ] Server key and Sender ID noted
- [ ] Android FCM configuration complete
- [ ] iOS APNs certificate uploaded
- [ ] Test notification sent successfully (Android)
- [ ] Test notification sent successfully (iOS)
- [ ] Notification channels configured (Android)
- [ ] Background notification handling tested

#### Security Rules
- [ ] Firestore security rules deployed
- [ ] Storage security rules deployed
- [ ] Category access rules tested (admin write, user read)
- [ ] Config access rules tested (admin write, user read)
- [ ] Product validation rules tested (discount < price, minQty >= 1)
- [ ] Order remarks rules tested (24-hour edit window)
- [ ] Delivery photo rules tested (admin write, user read, no delete)

#### Indexes
- [ ] Products by category index created
- [ ] Categories by name index created
- [ ] Orders by status index verified
- [ ] All indexes show "Enabled" status in Firebase Console
- [ ] Test queries using indexes successful

### 2. Initial Data Setup

#### Default Configuration
- [ ] Config document created with values:
  - [ ] `deliveryCharge: 20`
  - [ ] `freeDeliveryThreshold: 200`
  - [ ] `maxCartValue: 3000`
  - [ ] `orderCapacityWarningThreshold: 2`
  - [ ] `orderCapacityBlockThreshold: 10`
  - [ ] `updatedAt: [timestamp]`
  - [ ] `updatedBy: [admin-user-id]`

#### Default Categories
- [ ] At least one category created
- [ ] Recommended categories created:
  - [ ] Fresh Fruits
  - [ ] Fresh Vegetables
  - [ ] Dairy Products
  - [ ] Snacks & Beverages
  - [ ] Grains & Cereals
  - [ ] Spices & Condiments
  - [ ] Personal Care
  - [ ] Household Items
- [ ] All categories have `productCount: 0` initially
- [ ] Category names are unique

#### Data Migration
- [ ] All existing products assigned to categories
- [ ] All existing products have minimum quantity set
- [ ] All existing orders have delivery charge field
- [ ] No orphaned products (all have valid categoryId)
- [ ] Data migration script executed successfully

### 3. App Configuration

#### Android Setup
- [ ] `minSdkVersion` set to 21 or higher
- [ ] `google-services.json` file added to `android/app/`
- [ ] FCM dependency added to `build.gradle`
- [ ] Permissions added to `AndroidManifest.xml`:
  - [ ] CAMERA
  - [ ] ACCESS_FINE_LOCATION
  - [ ] ACCESS_COARSE_LOCATION
  - [ ] POST_NOTIFICATIONS
- [ ] FCM metadata added to `AndroidManifest.xml`
- [ ] Notification icon created (`ic_notification`)
- [ ] App builds successfully for Android

#### iOS Setup
- [ ] `GoogleService-Info.plist` added to `ios/Runner/`
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes capability enabled (Remote notifications)
- [ ] Permissions added to `Info.plist`:
  - [ ] NSCameraUsageDescription
  - [ ] NSLocationWhenInUseUsageDescription
- [ ] UIBackgroundModes configured
- [ ] APNs certificate uploaded to Firebase
- [ ] App builds successfully for iOS

#### Dependencies
- [ ] All new packages added to `pubspec.yaml`:
  - [ ] `image_picker: ^1.0.7`
  - [ ] `geolocator: ^10.1.0`
  - [ ] `firebase_messaging: ^14.7.10`
  - [ ] `flutter_local_notifications: ^16.3.0`
  - [ ] `audioplayers: ^5.2.1`
  - [ ] `flutter_image_compress: ^2.1.0`
- [ ] `flutter pub get` executed successfully
- [ ] No dependency conflicts

#### Assets
- [ ] Notification sound file added (`assets/sounds/notification.mp3`)
- [ ] Sound asset declared in `pubspec.yaml`
- [ ] Sound file accessible and plays correctly

### 4. Feature Testing - Admin

#### Category Management
- [ ] Admin can access Category Management screen
- [ ] Admin can create new category
- [ ] Category name uniqueness enforced
- [ ] Admin can edit category name and description
- [ ] Admin can delete empty category
- [ ] Cannot delete category with products (validation works)
- [ ] Categories display alphabetically
- [ ] Product count updates correctly

#### Product Management with New Fields
- [ ] Admin can add product with category selection
- [ ] Admin can set discount price (validated < regular price)
- [ ] Admin can set minimum order quantity (validated >= 1)
- [ ] Discount percentage displays correctly
- [ ] Cannot save discount >= regular price
- [ ] Cannot save minimum quantity < 1
- [ ] Product category can be changed
- [ ] Product count updates in old and new categories

#### App Configuration
- [ ] Admin can access App Configuration screen
- [ ] Admin can view current configuration
- [ ] Admin can update delivery charge
- [ ] Admin can update free delivery threshold
- [ ] Admin can update max cart value
- [ ] Admin can update order capacity thresholds
- [ ] Validation prevents invalid values
- [ ] Validation enforces relationships (threshold < max, warning < block)
- [ ] Changes save successfully
- [ ] Changes propagate to all devices within 2 seconds
- [ ] Last updated info displays correctly

#### Delivery Proof Capture
- [ ] Admin can access order details
- [ ] "Mark as Delivered" button available for "Out for Delivery" orders
- [ ] Camera opens when capturing delivery proof
- [ ] Photo can be captured
- [ ] Photo can be retaken if needed
- [ ] GPS location captured automatically
- [ ] Location accuracy acceptable
- [ ] Photo uploads successfully
- [ ] Location saves successfully
- [ ] Order status updates to "Delivered"
- [ ] Customer receives notification
- [ ] Delivery proof visible in order details

#### Order Management
- [ ] Pending order count displays on dashboard
- [ ] Order capacity status calculated correctly
- [ ] Admin can view customer remarks
- [ ] Admin can see delivery proof for delivered orders

### 5. Feature Testing - Customer

#### Category Filtering
- [ ] Category chips display on home screen
- [ ] "All" category shows all products
- [ ] Tapping category filters products correctly
- [ ] Active category highlighted
- [ ] Product count badge shows on categories
- [ ] Filtering is fast and responsive

#### Discount Pricing
- [ ] Products with discounts show strikethrough on original price
- [ ] Discount price displays prominently
- [ ] Discount percentage badge shows
- [ ] Savings calculation correct
- [ ] Cart uses discount price
- [ ] Order summary shows savings

#### Minimum Order Quantity
- [ ] Minimum quantity displays on product detail
- [ ] Quantity selector starts at minimum
- [ ] Cannot select less than minimum
- [ ] Error message shows if trying to add less than minimum
- [ ] "Add to Cart" disabled when quantity < minimum
- [ ] Cart validation checks minimum quantities

#### Delivery Charges
- [ ] Cart shows delivery charge (₹20 for < ₹200)
- [ ] Cart shows FREE delivery for >= ₹200
- [ ] "Add ₹X more for free delivery" message displays
- [ ] Progress bar shows proximity to free delivery
- [ ] Delivery charge line item in order summary
- [ ] Delivery charge calculated correctly

#### Cart Value Limits
- [ ] Warning shows when approaching ₹3000
- [ ] Error shows when exceeding ₹3000
- [ ] Checkout disabled when over limit
- [ ] Clear error message explains limit

#### Order Capacity
- [ ] Warning shows when pending orders >= 2
- [ ] "Delivery might be delayed" message displays
- [ ] Can still place order when warning shown
- [ ] Blocking message shows when pending >= 10
- [ ] Cannot place order when blocked
- [ ] Clear message explains capacity full

#### Push Notifications
- [ ] Customer receives notification when order confirmed
- [ ] Customer receives notification when order preparing
- [ ] Customer receives notification when out for delivery
- [ ] Customer receives notification when delivered
- [ ] Notification sound plays
- [ ] Notification appears in device tray
- [ ] Tapping notification opens relevant order
- [ ] In-app notification center shows all notifications

#### Delivery Proof Viewing
- [ ] Customer can view delivery photo for their orders
- [ ] Photo displays clearly and can be zoomed
- [ ] Delivery location shows (coordinates or map)
- [ ] Delivery timestamp displays

#### Customer Remarks
- [ ] Remarks section appears for delivered orders
- [ ] Customer can add remarks (up to 500 characters)
- [ ] Character counter displays
- [ ] Remarks save successfully
- [ ] Customer can edit remarks within 24 hours
- [ ] Cannot edit remarks after 24 hours
- [ ] Remarks timestamp displays

### 6. Integration Testing

#### End-to-End Flows
- [ ] **Complete Order Flow**:
  1. [ ] Customer browses products by category
  2. [ ] Customer adds discounted product to cart
  3. [ ] Cart shows delivery charge and free delivery progress
  4. [ ] Customer proceeds to checkout
  5. [ ] Order placed successfully
  6. [ ] Admin receives notification
  7. [ ] Admin confirms order
  8. [ ] Customer receives confirmation notification
  9. [ ] Admin marks as preparing
  10. [ ] Admin marks as out for delivery
  11. [ ] Admin captures delivery proof (photo + location)
  12. [ ] Order marked as delivered
  13. [ ] Customer receives delivery notification
  14. [ ] Customer views delivery proof
  15. [ ] Customer adds delivery remarks

- [ ] **Category Management Flow**:
  1. [ ] Admin creates new category
  2. [ ] Admin adds products to category
  3. [ ] Product count updates
  4. [ ] Customer filters by category
  5. [ ] Products display correctly

- [ ] **Configuration Change Flow**:
  1. [ ] Admin updates delivery charge
  2. [ ] Changes save successfully
  3. [ ] Customer app updates within 2 seconds
  4. [ ] New delivery charge applies to new orders

- [ ] **Capacity Management Flow**:
  1. [ ] Multiple orders placed (pending count increases)
  2. [ ] Warning appears at threshold
  3. [ ] Blocking occurs at limit
  4. [ ] Admin processes orders (count decreases)
  5. [ ] Blocking removed, orders can be placed again

#### Cross-Platform Testing
- [ ] All features work on Android
- [ ] All features work on iOS
- [ ] Push notifications work on both platforms
- [ ] Camera works on both platforms
- [ ] Location works on both platforms
- [ ] UI displays correctly on both platforms

#### Performance Testing
- [ ] Photo upload completes within 10 seconds
- [ ] Location capture completes within 5 seconds
- [ ] Config updates propagate within 2 seconds
- [ ] Category filtering is instant
- [ ] Cart calculations are instant
- [ ] App remains responsive during uploads

### 7. Error Handling

#### Network Errors
- [ ] Graceful handling of no internet connection
- [ ] Retry mechanism for failed uploads
- [ ] Clear error messages for network issues
- [ ] Offline cart persistence still works

#### Permission Errors
- [ ] Clear message when camera permission denied
- [ ] Directions to enable camera permission
- [ ] Clear message when location permission denied
- [ ] Directions to enable location permission
- [ ] Clear message when notification permission denied

#### Validation Errors
- [ ] Clear error for duplicate category name
- [ ] Clear error for invalid discount price
- [ ] Clear error for invalid minimum quantity
- [ ] Clear error for invalid config values
- [ ] Clear error for cart over limit
- [ ] Clear error for order capacity full

#### Upload Errors
- [ ] Retry mechanism for failed photo uploads
- [ ] Clear error message for upload failures
- [ ] Progress indicator during upload
- [ ] Ability to retry manually

### 8. Security Testing

#### Access Control
- [ ] Non-admin cannot access admin features
- [ ] Customer can only view their own orders
- [ ] Customer can only add remarks to their own orders
- [ ] Customer cannot modify delivery proof
- [ ] Customer cannot modify configuration

#### Data Validation
- [ ] Discount price validation enforced server-side
- [ ] Minimum quantity validation enforced server-side
- [ ] Config value validation enforced server-side
- [ ] Remarks edit window enforced server-side
- [ ] File size validation enforced for uploads
- [ ] File type validation enforced for uploads

#### Audit Logging
- [ ] All admin actions logged
- [ ] Config changes logged with admin ID
- [ ] Category changes logged
- [ ] Product changes logged

### 9. Documentation

#### User Documentation
- [ ] README.md updated with new features
- [ ] Customer User Guide updated
- [ ] Admin User Guide updated
- [ ] Admin Category Management guide created
- [ ] Admin App Configuration guide created
- [ ] Admin Delivery Proof guide created

#### Technical Documentation
- [ ] Firebase Setup Enhancements guide created
- [ ] Deployment Checklist created
- [ ] Security rules documented
- [ ] Indexes documented
- [ ] Migration scripts documented

### 10. Monitoring & Analytics

#### Firebase Analytics
- [ ] Analytics events configured for new features
- [ ] Category filter usage tracked
- [ ] Discount product views tracked
- [ ] Delivery proof capture tracked
- [ ] Config changes tracked

#### Firebase Crashlytics
- [ ] Crashlytics enabled
- [ ] Test crash reported successfully
- [ ] Error logging configured for new features

#### Firebase Performance
- [ ] Performance monitoring enabled
- [ ] Photo upload performance tracked
- [ ] Location capture performance tracked
- [ ] Config load performance tracked

### 11. Final Checks

#### Code Quality
- [ ] All code reviewed
- [ ] No debug code or console logs in production
- [ ] No hardcoded values (use config)
- [ ] Error handling comprehensive
- [ ] Code follows project conventions

#### Build Configuration
- [ ] App version number updated
- [ ] Build number incremented
- [ ] Release build configuration correct
- [ ] ProGuard rules configured (Android)
- [ ] App signing configured

#### Store Preparation
- [ ] App screenshots updated with new features
- [ ] App description updated
- [ ] What's New section prepared
- [ ] Privacy policy updated (if needed)
- [ ] Terms of service updated (if needed)

---

## Deployment Steps

### 1. Pre-Deployment
- [ ] Complete all checklist items above
- [ ] Create backup of current production data
- [ ] Notify users of upcoming update (if needed)
- [ ] Schedule deployment during low-traffic period

### 2. Firebase Deployment
- [ ] Deploy Firestore security rules
- [ ] Deploy Storage security rules
- [ ] Deploy Firestore indexes
- [ ] Create default config document
- [ ] Create default categories
- [ ] Run data migration scripts
- [ ] Verify all Firebase changes

### 3. App Deployment
- [ ] Build release APK (Android)
- [ ] Build release IPA (iOS)
- [ ] Test release builds on real devices
- [ ] Upload to Google Play Console
- [ ] Upload to App Store Connect
- [ ] Submit for review

### 4. Post-Deployment
- [ ] Monitor Firebase Console for errors
- [ ] Monitor Crashlytics for crashes
- [ ] Monitor Analytics for usage
- [ ] Check user feedback
- [ ] Verify all features working in production
- [ ] Monitor performance metrics

### 5. Rollback Plan (If Needed)
- [ ] Revert Firestore security rules
- [ ] Revert Storage security rules
- [ ] Restore previous app version
- [ ] Restore database backup
- [ ] Notify users of rollback

---

## Sign-Off

### Technical Lead
- [ ] All technical requirements met
- [ ] Code quality approved
- [ ] Security reviewed
- [ ] Performance acceptable

**Name**: ________________  
**Date**: ________________  
**Signature**: ________________

### Product Manager
- [ ] All features implemented
- [ ] User experience approved
- [ ] Documentation complete
- [ ] Ready for deployment

**Name**: ________________  
**Date**: ________________  
**Signature**: ________________

### QA Lead
- [ ] All tests passed
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] Ready for production

**Name**: ________________  
**Date**: ________________  
**Signature**: ________________

---

## Post-Deployment Monitoring

### First 24 Hours
- [ ] Monitor crash rate (target: < 0.5%)
- [ ] Monitor error rate (target: < 2%)
- [ ] Monitor photo upload success rate (target: > 95%)
- [ ] Monitor notification delivery rate (target: > 95%)
- [ ] Monitor user feedback
- [ ] Check for critical issues

### First Week
- [ ] Review analytics data
- [ ] Analyze feature adoption rates
- [ ] Gather user feedback
- [ ] Identify improvement areas
- [ ] Plan hotfixes if needed

### First Month
- [ ] Comprehensive feature usage analysis
- [ ] Performance optimization review
- [ ] User satisfaction assessment
- [ ] Plan next iteration

---

**Deployment Date**: ________________  
**Version**: 2.0 (Enhanced Features)  
**Last Updated**: January 2025

---

**Remember**: Do not deploy until ALL checklist items are complete and signed off!
