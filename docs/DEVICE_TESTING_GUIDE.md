# Device Testing Guide - Pre-Deployment

## Overview

This guide provides step-by-step instructions for testing all enhanced features on real Android and iOS devices before deployment. Complete all tests to ensure production readiness.

## Prerequisites

### Required Devices
- [ ] At least one Android device (Android 5.0 / API 21 or higher)
- [ ] At least one iOS device (iOS 12.0 or higher)
- [ ] Both devices should have:
  - Active internet connection
  - Camera
  - GPS/Location services
  - Notification permissions available

### Required Accounts
- [ ] Admin account credentials
- [ ] Customer account credentials (at least 2 for testing)
- [ ] Firebase Console access
- [ ] Google Play Console access (for Android)
- [ ] App Store Connect access (for iOS)

### Test Data
- [ ] At least 3 categories created
- [ ] At least 10 products with various configurations:
  - Products with discounts
  - Products without discounts
  - Products with different minimum quantities
  - Products in different categories
- [ ] Default configuration document created

---

## Test Plan

### Phase 1: Installation & Permissions

#### Android Device Testing

**1.1 Install Application**
- [ ] Install APK on Android device
- [ ] App launches successfully
- [ ] No crash on startup
- [ ] Firebase connection established

**1.2 Camera Permission**
- [ ] Navigate to admin order management
- [ ] Attempt to capture delivery photo
- [ ] Camera permission dialog appears
- [ ] Grant permission
- [ ] Camera opens successfully
- [ ] Can capture photo
- [ ] Photo preview displays correctly

**1.3 Location Permission**
- [ ] Delivery photo capture triggers location request
- [ ] Location permission dialog appears
- [ ] Grant permission
- [ ] Location captured successfully
- [ ] Coordinates display correctly

**1.4 Notification Permission**
- [ ] Notification permission dialog appears (Android 13+)
- [ ] Grant permission
- [ ] Test notification received
- [ ] Notification appears in system tray
- [ ] Notification sound plays

**Test Results:**
```
Device Model: _______________
Android Version: _______________
Camera Permission: [ ] Pass [ ] Fail
Location Permission: [ ] Pass [ ] Fail
Notification Permission: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### iOS Device Testing

**1.5 Install Application**
- [ ] Install IPA on iOS device (via TestFlight or direct)
- [ ] App launches successfully
- [ ] No crash on startup
- [ ] Firebase connection established

**1.6 Camera Permission**
- [ ] Navigate to admin order management
- [ ] Attempt to capture delivery photo
- [ ] Camera permission dialog appears with description
- [ ] Grant permission
- [ ] Camera opens successfully
- [ ] Can capture photo
- [ ] Photo preview displays correctly

**1.7 Location Permission**
- [ ] Delivery photo capture triggers location request
- [ ] Location permission dialog appears with description
- [ ] Grant "While Using App" permission
- [ ] Location captured successfully
- [ ] Coordinates display correctly

**1.8 Notification Permission**
- [ ] Notification permission dialog appears
- [ ] Grant permission
- [ ] Test notification received
- [ ] Notification appears in Notification Center
- [ ] Notification sound plays
- [ ] Badge count updates

**Test Results:**
```
Device Model: _______________
iOS Version: _______________
Camera Permission: [ ] Pass [ ] Fail
Location Permission: [ ] Pass [ ] Fail
Notification Permission: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

---

### Phase 2: Firebase Cloud Messaging (FCM)

#### Android FCM Testing

**2.1 Foreground Notifications**
- [ ] App is open and in foreground
- [ ] Send test notification from Firebase Console
- [ ] Notification received within 5 seconds
- [ ] Notification sound plays
- [ ] Notification displays in-app
- [ ] Tapping notification navigates correctly

**2.2 Background Notifications**
- [ ] App is in background (home screen)
- [ ] Send test notification from Firebase Console
- [ ] Notification appears in system tray
- [ ] Notification sound plays
- [ ] Tapping notification opens app
- [ ] Navigates to correct screen

**2.3 App Closed Notifications**
- [ ] Force close app
- [ ] Send test notification from Firebase Console
- [ ] Notification appears in system tray
- [ ] Notification sound plays
- [ ] Tapping notification launches app
- [ ] Navigates to correct screen

**2.4 Order Status Notifications**
- [ ] Place order as customer
- [ ] Admin confirms order
- [ ] Customer receives "Order Confirmed" notification
- [ ] Admin marks as preparing
- [ ] Customer receives "Preparing" notification
- [ ] Admin marks as out for delivery
- [ ] Customer receives "Out for Delivery" notification
- [ ] Admin completes delivery
- [ ] Customer receives "Delivered" notification with photo

**Test Results:**
```
Foreground: [ ] Pass [ ] Fail
Background: [ ] Pass [ ] Fail
App Closed: [ ] Pass [ ] Fail
Order Notifications: [ ] Pass [ ] Fail
Average Delivery Time: _____ seconds
Notes: _______________________________________________
```

#### iOS FCM Testing

**2.5 Foreground Notifications**
- [ ] App is open and in foreground
- [ ] Send test notification from Firebase Console
- [ ] Notification received within 5 seconds
- [ ] Notification sound plays
- [ ] Notification banner displays
- [ ] Tapping notification navigates correctly

**2.6 Background Notifications**
- [ ] App is in background (home screen)
- [ ] Send test notification from Firebase Console
- [ ] Notification appears in Notification Center
- [ ] Notification sound plays
- [ ] Badge count updates
- [ ] Tapping notification opens app
- [ ] Navigates to correct screen

**2.7 App Closed Notifications**
- [ ] Force close app (swipe up from app switcher)
- [ ] Send test notification from Firebase Console
- [ ] Notification appears in Notification Center
- [ ] Notification sound plays
- [ ] Badge count updates
- [ ] Tapping notification launches app
- [ ] Navigates to correct screen

**2.8 Order Status Notifications**
- [ ] Place order as customer
- [ ] Admin confirms order
- [ ] Customer receives "Order Confirmed" notification
- [ ] Admin marks as preparing
- [ ] Customer receives "Preparing" notification
- [ ] Admin marks as out for delivery
- [ ] Customer receives "Out for Delivery" notification
- [ ] Admin completes delivery
- [ ] Customer receives "Delivered" notification with photo

**Test Results:**
```
Foreground: [ ] Pass [ ] Fail
Background: [ ] Pass [ ] Fail
App Closed: [ ] Pass [ ] Fail
Order Notifications: [ ] Pass [ ] Fail
Average Delivery Time: _____ seconds
Notes: _______________________________________________
```

---

### Phase 3: Camera & Photo Upload

#### Android Camera Testing

**3.1 Camera Access**
- [ ] Open admin order management
- [ ] Select order "Out for Delivery"
- [ ] Tap "Mark as Delivered"
- [ ] Camera opens immediately
- [ ] Camera preview displays correctly
- [ ] Can switch between front/back camera (if available)

**3.2 Photo Capture**
- [ ] Capture photo
- [ ] Photo preview displays
- [ ] Photo is clear and properly oriented
- [ ] Can retake photo if needed
- [ ] Confirm photo selection

**3.3 Photo Upload**
- [ ] Upload progress indicator displays
- [ ] Upload completes within 10 seconds (on good connection)
- [ ] Success message displays
- [ ] Photo URL saved to order
- [ ] Photo visible in order details

**3.4 Photo Quality**
- [ ] Photo file size < 1MB (check Firebase Storage)
- [ ] Photo resolution appropriate (not too large)
- [ ] Photo quality acceptable for delivery proof
- [ ] Photo loads quickly when viewing

**3.5 Error Handling**
- [ ] Test with airplane mode (no internet)
- [ ] Appropriate error message displays
- [ ] Retry option available
- [ ] Photo queued for upload when connection restored

**Test Results:**
```
Camera Access: [ ] Pass [ ] Fail
Photo Capture: [ ] Pass [ ] Fail
Photo Upload: [ ] Pass [ ] Fail
Upload Time: _____ seconds
Photo Size: _____ KB
Photo Quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
Error Handling: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### iOS Camera Testing

**3.6 Camera Access**
- [ ] Open admin order management
- [ ] Select order "Out for Delivery"
- [ ] Tap "Mark as Delivered"
- [ ] Camera opens immediately
- [ ] Camera preview displays correctly
- [ ] Can switch between front/back camera

**3.7 Photo Capture**
- [ ] Capture photo
- [ ] Photo preview displays
- [ ] Photo is clear and properly oriented
- [ ] Can retake photo if needed
- [ ] Confirm photo selection

**3.8 Photo Upload**
- [ ] Upload progress indicator displays
- [ ] Upload completes within 10 seconds (on good connection)
- [ ] Success message displays
- [ ] Photo URL saved to order
- [ ] Photo visible in order details

**3.9 Photo Quality**
- [ ] Photo file size < 1MB (check Firebase Storage)
- [ ] Photo resolution appropriate (not too large)
- [ ] Photo quality acceptable for delivery proof
- [ ] Photo loads quickly when viewing

**3.10 Error Handling**
- [ ] Test with airplane mode (no internet)
- [ ] Appropriate error message displays
- [ ] Retry option available
- [ ] Photo queued for upload when connection restored

**Test Results:**
```
Camera Access: [ ] Pass [ ] Fail
Photo Capture: [ ] Pass [ ] Fail
Photo Upload: [ ] Pass [ ] Fail
Upload Time: _____ seconds
Photo Size: _____ KB
Photo Quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
Error Handling: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

---

### Phase 4: Location Services

#### Android Location Testing

**4.1 Location Permission**
- [ ] Location permission requested at appropriate time
- [ ] Permission dialog shows clear description
- [ ] Can grant "While using app" permission
- [ ] Can grant "Always" permission (if offered)

**4.2 Location Capture**
- [ ] Location captured automatically during delivery
- [ ] Capture completes within 5 seconds
- [ ] Latitude and longitude saved correctly
- [ ] Location accuracy acceptable (< 50 meters)

**4.3 Location Display**
- [ ] Location displays in order details
- [ ] Coordinates formatted correctly
- [ ] Map view displays (if implemented)
- [ ] Map marker at correct location

**4.4 Location Errors**
- [ ] Test with location services disabled
- [ ] Appropriate error message displays
- [ ] Option to enable location services
- [ ] Can complete delivery without location (if allowed)

**Test Results:**
```
Permission Request: [ ] Pass [ ] Fail
Location Capture: [ ] Pass [ ] Fail
Capture Time: _____ seconds
Location Accuracy: _____ meters
Location Display: [ ] Pass [ ] Fail
Error Handling: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### iOS Location Testing

**4.5 Location Permission**
- [ ] Location permission requested at appropriate time
- [ ] Permission dialog shows clear description
- [ ] Can grant "While Using App" permission
- [ ] Can grant "Always" permission (if offered)

**4.6 Location Capture**
- [ ] Location captured automatically during delivery
- [ ] Capture completes within 5 seconds
- [ ] Latitude and longitude saved correctly
- [ ] Location accuracy acceptable (< 50 meters)

**4.7 Location Display**
- [ ] Location displays in order details
- [ ] Coordinates formatted correctly
- [ ] Map view displays (if implemented)
- [ ] Map marker at correct location

**4.8 Location Errors**
- [ ] Test with location services disabled
- [ ] Appropriate error message displays
- [ ] Option to enable location services in Settings
- [ ] Can complete delivery without location (if allowed)

**Test Results:**
```
Permission Request: [ ] Pass [ ] Fail
Location Capture: [ ] Pass [ ] Fail
Capture Time: _____ seconds
Location Accuracy: _____ meters
Location Display: [ ] Pass [ ] Fail
Error Handling: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

---

### Phase 5: Notification Sound

#### Android Sound Testing

**5.1 Sound Playback**
- [ ] Notification received
- [ ] Sound plays automatically
- [ ] Sound is clear and audible
- [ ] Sound is appropriate length (not too long)
- [ ] Sound respects device volume settings
- [ ] Sound respects Do Not Disturb mode

**5.2 Sound Settings**
- [ ] Can access notification settings
- [ ] Can enable/disable notification sound
- [ ] Setting persists after app restart
- [ ] Sound plays when enabled
- [ ] Sound does not play when disabled

**Test Results:**
```
Sound Playback: [ ] Pass [ ] Fail
Sound Quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
Volume Control: [ ] Pass [ ] Fail
DND Respect: [ ] Pass [ ] Fail
Settings Control: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### iOS Sound Testing

**5.3 Sound Playback**
- [ ] Notification received
- [ ] Sound plays automatically
- [ ] Sound is clear and audible
- [ ] Sound is appropriate length (not too long)
- [ ] Sound respects device volume settings
- [ ] Sound respects Do Not Disturb mode
- [ ] Sound respects Silent mode (vibrate only)

**5.4 Sound Settings**
- [ ] Can access notification settings
- [ ] Can enable/disable notification sound
- [ ] Setting persists after app restart
- [ ] Sound plays when enabled
- [ ] Sound does not play when disabled

**Test Results:**
```
Sound Playback: [ ] Pass [ ] Fail
Sound Quality: [ ] Excellent [ ] Good [ ] Acceptable [ ] Poor
Volume Control: [ ] Pass [ ] Fail
DND Respect: [ ] Pass [ ] Fail
Silent Mode: [ ] Pass [ ] Fail
Settings Control: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

---

### Phase 6: Admin Features

#### Category Management

**6.1 Create Category**
- [ ] Access Category Management screen
- [ ] Tap "Add Category"
- [ ] Enter category name
- [ ] Enter category description (optional)
- [ ] Save category
- [ ] Category appears in list
- [ ] Category available in product form

**6.2 Edit Category**
- [ ] Select existing category
- [ ] Edit name
- [ ] Edit description
- [ ] Save changes
- [ ] Changes reflected immediately
- [ ] Products still associated correctly

**6.3 Delete Category**
- [ ] Attempt to delete category with products
- [ ] Validation prevents deletion
- [ ] Error message displays
- [ ] Delete empty category
- [ ] Confirmation dialog appears
- [ ] Category removed successfully

**Test Results:**
```
Create: [ ] Pass [ ] Fail
Edit: [ ] Pass [ ] Fail
Delete Validation: [ ] Pass [ ] Fail
Delete Empty: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### App Configuration

**6.4 View Configuration**
- [ ] Access App Configuration screen
- [ ] Current values display correctly
- [ ] Last updated info displays
- [ ] All fields editable

**6.5 Update Configuration**
- [ ] Change delivery charge
- [ ] Change free delivery threshold
- [ ] Change max cart value
- [ ] Change order capacity thresholds
- [ ] Save changes
- [ ] Confirmation dialog appears
- [ ] Changes save successfully
- [ ] Changes propagate to customer app within 2 seconds

**6.6 Configuration Validation**
- [ ] Try to set invalid values (negative, zero)
- [ ] Validation prevents save
- [ ] Error messages display
- [ ] Try to set maxCartValue < freeDeliveryThreshold
- [ ] Validation prevents save
- [ ] Try to set blockThreshold < warningThreshold
- [ ] Validation prevents save

**Test Results:**
```
View Config: [ ] Pass [ ] Fail
Update Config: [ ] Pass [ ] Fail
Propagation Time: _____ seconds
Validation: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### Product Management

**6.7 Add Product with New Fields**
- [ ] Access Product Form
- [ ] Select category (required)
- [ ] Enter product details
- [ ] Set discount price (optional)
- [ ] Set minimum order quantity
- [ ] Save product
- [ ] Product appears in list
- [ ] All fields saved correctly

**6.8 Discount Validation**
- [ ] Try to set discount >= regular price
- [ ] Validation prevents save
- [ ] Error message displays
- [ ] Set valid discount
- [ ] Discount percentage calculates correctly
- [ ] Save successful

**6.9 Minimum Quantity Validation**
- [ ] Try to set minimum quantity < 1
- [ ] Validation prevents save
- [ ] Error message displays
- [ ] Set valid minimum quantity
- [ ] Save successful

**Test Results:**
```
Add Product: [ ] Pass [ ] Fail
Discount Validation: [ ] Pass [ ] Fail
Min Qty Validation: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### Delivery Proof

**6.10 Complete Delivery Flow**
- [ ] Select order "Out for Delivery"
- [ ] Tap "Mark as Delivered"
- [ ] Camera opens
- [ ] Capture photo
- [ ] Location captured automatically
- [ ] Photo uploads successfully
- [ ] Location saves successfully
- [ ] Order status updates to "Delivered"
- [ ] Customer receives notification
- [ ] Delivery proof visible in order details

**Test Results:**
```
Complete Flow: [ ] Pass [ ] Fail
Total Time: _____ seconds
Notes: _______________________________________________
```

---

### Phase 7: Customer Features

#### Category Filtering

**7.1 Category Display**
- [ ] Home screen shows category chips
- [ ] "All" category displays
- [ ] All categories display
- [ ] Categories sorted alphabetically
- [ ] Product count badges display

**7.2 Category Filtering**
- [ ] Tap "All" category
- [ ] All products display
- [ ] Tap specific category
- [ ] Only products in that category display
- [ ] Active category highlighted
- [ ] Filtering is fast (< 1 second)

**Test Results:**
```
Display: [ ] Pass [ ] Fail
Filtering: [ ] Pass [ ] Fail
Performance: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### Discount Pricing

**7.3 Discount Display**
- [ ] Products with discounts show strikethrough price
- [ ] Discount price displays prominently
- [ ] Discount percentage badge shows
- [ ] Savings calculation correct
- [ ] Discount visible in product list
- [ ] Discount visible in product detail
- [ ] Discount visible in cart

**7.4 Cart Calculations**
- [ ] Add discounted product to cart
- [ ] Cart uses discount price
- [ ] Subtotal correct
- [ ] Order summary shows savings
- [ ] Total calculation correct

**Test Results:**
```
Display: [ ] Pass [ ] Fail
Calculations: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### Minimum Order Quantity

**7.5 Minimum Quantity Display**
- [ ] Product detail shows minimum quantity
- [ ] Minimum quantity prominently displayed
- [ ] Quantity selector starts at minimum
- [ ] Cannot select less than minimum

**7.6 Minimum Quantity Validation**
- [ ] Try to add less than minimum to cart
- [ ] Error message displays
- [ ] "Add to Cart" disabled when invalid
- [ ] Cart validation checks minimum
- [ ] Checkout blocked if minimum not met

**Test Results:**
```
Display: [ ] Pass [ ] Fail
Validation: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### Delivery Charges

**7.7 Delivery Charge Display**
- [ ] Cart shows delivery charge for < ₹200
- [ ] Cart shows FREE for >= ₹200
- [ ] "Add ₹X more" message displays
- [ ] Progress bar shows proximity to free delivery
- [ ] Delivery charge in order summary

**7.8 Delivery Charge Calculation**
- [ ] Add products totaling < ₹200
- [ ] Delivery charge = ₹20
- [ ] Add more products to reach >= ₹200
- [ ] Delivery charge = ₹0 (FREE)
- [ ] Calculation updates in real-time

**Test Results:**
```
Display: [ ] Pass [ ] Fail
Calculation: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### Order Capacity

**7.9 Order Capacity Warning**
- [ ] Create 2+ pending orders (as admin)
- [ ] Customer sees warning banner
- [ ] "Delivery might be delayed" message displays
- [ ] Can still place order
- [ ] Warning updates in real-time

**7.10 Order Capacity Blocking**
- [ ] Create 10+ pending orders (as admin)
- [ ] Customer sees blocking message
- [ ] "Order capacity full" message displays
- [ ] Cannot place order
- [ ] Checkout button disabled
- [ ] Process orders to reduce count
- [ ] Blocking removed automatically

**Test Results:**
```
Warning: [ ] Pass [ ] Fail
Blocking: [ ] Pass [ ] Fail
Real-time Update: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

#### Customer Remarks

**7.11 Add Remarks**
- [ ] Order delivered
- [ ] Remarks section appears
- [ ] Can enter remarks (up to 500 characters)
- [ ] Character counter displays
- [ ] Save remarks
- [ ] Remarks saved successfully
- [ ] Timestamp displays

**7.12 Edit Remarks**
- [ ] Edit remarks within 24 hours
- [ ] Changes save successfully
- [ ] Try to edit after 24 hours
- [ ] Edit disabled
- [ ] Message explains time limit

**Test Results:**
```
Add Remarks: [ ] Pass [ ] Fail
Edit Within 24h: [ ] Pass [ ] Fail
Edit After 24h: [ ] Pass [ ] Fail
Notes: _______________________________________________
```

---

## Performance Benchmarks

### Target Metrics
- Photo upload: < 10 seconds (average network)
- Location capture: < 5 seconds
- Config update propagation: < 2 seconds
- Category filtering: < 1 second
- Cart calculations: Instant (< 100ms)
- Notification delivery: < 5 seconds

### Actual Measurements

**Android Device:**
```
Photo Upload: _____ seconds
Location Capture: _____ seconds
Config Propagation: _____ seconds
Category Filtering: _____ seconds
Cart Calculations: _____ ms
Notification Delivery: _____ seconds
```

**iOS Device:**
```
Photo Upload: _____ seconds
Location Capture: _____ seconds
Config Propagation: _____ seconds
Category Filtering: _____ seconds
Cart Calculations: _____ ms
Notification Delivery: _____ seconds
```

---

## Final Checklist

### Critical Issues (Must Pass)
- [ ] No app crashes during testing
- [ ] All permissions work correctly
- [ ] FCM notifications received on both platforms
- [ ] Camera captures and uploads photos successfully
- [ ] Location captured accurately
- [ ] Notification sound plays correctly
- [ ] All admin features accessible and functional
- [ ] All customer features work as expected
- [ ] Performance meets target metrics

### Non-Critical Issues (Should Pass)
- [ ] UI displays correctly on all screen sizes
- [ ] Error messages are clear and helpful
- [ ] Loading states display appropriately
- [ ] Offline mode handles gracefully
- [ ] Network errors handled properly

---

## Sign-Off

### Android Testing
**Tester Name:** _______________  
**Date:** _______________  
**Device:** _______________  
**Android Version:** _______________  
**Result:** [ ] Pass [ ] Fail  
**Notes:** _______________________________________________

### iOS Testing
**Tester Name:** _______________  
**Date:** _______________  
**Device:** _______________  
**iOS Version:** _______________  
**Result:** [ ] Pass [ ] Fail  
**Notes:** _______________________________________________

### Overall Assessment
**Ready for Deployment:** [ ] Yes [ ] No  
**Critical Issues Found:** _______________  
**Recommendations:** _______________________________________________

---

**Document Version:** 1.0  
**Last Updated:** January 2025
