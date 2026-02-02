# Grocery App Enhancements - Requirements Document

## 1. Overview

This document outlines enhancements to the existing online grocery application to improve product management, delivery operations, cart functionality, and customer experience.

## 2. User Stories and Acceptance Criteria

### 2.1 Product Discount Pricing

**User Story**: As an admin, I want to set discount prices on products so that I can run promotions and sales.

**Acceptance Criteria**:
- 2.1.1 Admin can add an optional discount price when creating/editing a product
- 2.1.2 Discount price must be less than the regular price
- 2.1.3 Products with discounts display both original and discounted prices
- 2.1.4 Discount price is shown with strikethrough on original price in product listings
- 2.1.5 Cart calculations use discount price when available
- 2.1.6 Order history shows which price was applied at purchase time
- 2.1.7 Admin can remove discount by clearing the discount price field

### 2.2 Product Categories Management

**User Story**: As an admin, I want to create and manage product categories so that customers can find products more easily.

**Acceptance Criteria**:
- 2.2.1 Admin can create new categories with name and optional description
- 2.2.2 Admin can edit existing category names and descriptions
- 2.2.3 Admin can delete categories (with validation)
- 2.2.4 Products can be assigned to any category
- 2.2.5 Customer home screen shows products filtered by category
- 2.2.6 Category list is displayed in alphabetical order
- 2.2.7 Deleting a category requires reassigning its products first
- 2.2.8 Category names must be unique
- 2.2.9 At least one category must exist in the system

### 2.3 Delivery Photo and Location Capture

**User Story**: As an admin/delivery person, I want to take a photo and capture location during delivery so that I have proof of delivery.

**Acceptance Criteria**:
- 2.3.1 Admin can capture a photo when marking order as delivered
- 2.3.2 Photo is uploaded to Firebase Storage
- 2.3.3 Photo URL is stored with the order record
- 2.3.4 Delivery photo is visible in order details for both admin and customer
- 2.3.5 Photo capture is mandatory before completing delivery
- 2.3.6 App captures GPS location (latitude/longitude) when delivery is marked complete
- 2.3.7 Location data is stored with the order record
- 2.3.8 Delivery location is displayed on order details (with map view if possible)

### 2.4 Minimum Order Quantity per Product

**User Story**: As an admin, I want to set minimum order quantities for products so that customers order appropriate amounts.

**Acceptance Criteria**:
- 2.4.1 Admin can set a minimum order quantity when creating/editing products
- 2.4.2 Default minimum quantity is 1 if not specified
- 2.4.3 Customer cannot add less than minimum quantity to cart
- 2.4.4 Product detail page displays minimum order quantity clearly
- 2.4.5 Cart validation prevents checkout if any item is below minimum
- 2.4.6 Error message explains minimum quantity requirement
- 2.4.7 Quantity selector starts at minimum quantity value

### 2.5 Enhanced Notification System

**User Story**: As a user, I want to receive notifications both in-app and on my phone with sound alerts so that I don't miss important updates.

**Acceptance Criteria**:
- 2.5.1 All notifications are sent as push notifications to user's device
- 2.5.2 Push notifications appear in device notification tray
- 2.5.3 All notifications are also stored and displayed in the in-app notifications screen
- 2.5.4 Notification sound plays when push notification is received
- 2.5.5 Sound is distinct and attention-grabbing but not annoying
- 2.5.6 Sound plays for order status updates and admin notifications
- 2.5.7 User can enable/disable notification sounds in settings
- 2.5.8 Sound respects device's notification and volume settings
- 2.5.9 Notifications include order updates, delivery status, and general announcements
- 2.5.10 Admin can send general notifications to all customers

### 2.6 Configurable Delivery Charges and Cart Limits

**User Story**: As a customer, I want to know delivery charges based on my cart value so that I can plan my purchases.

**Acceptance Criteria**:
- 2.6.1 Delivery charge is ₹20 for all orders
- 2.6.2 Orders with cart value ≥ ₹200 have free delivery (₹0 delivery charge)
- 2.6.3 Maximum cart value is capped at ₹3000
- 2.6.4 Cart screen displays current delivery charge
- 2.6.5 Cart shows how much more to add for free delivery (if below ₹200)
- 2.6.6 Checkout is blocked if cart exceeds ₹3000
- 2.6.7 Clear messaging explains delivery charge rules
- 2.6.8 Order summary shows delivery charge as separate line item
- 2.6.9 Delivery charge threshold (₹200) is configurable in admin settings
- 2.6.10 Delivery charge amount (₹20) is configurable in admin settings
- 2.6.11 Maximum cart value (₹3000) is configurable in admin settings

### 2.7 Order Capacity Management

**User Story**: As a customer, I want to know if the store can handle my order based on current pending orders so that I have realistic delivery expectations.

**Acceptance Criteria**:
- 2.7.1 System tracks count of orders in "pending" status in real-time
- 2.7.2 If pending orders ≥ 10, new order placement is blocked
- 2.7.3 Clear message explains that order capacity is full when blocked
- 2.7.4 If pending orders ≥ 2 but < 10, warning message shows "Delivery might be delayed"
- 2.7.5 Warning is displayed on cart screen and checkout screen
- 2.7.6 Customer can still place order when warning is shown (only blocked at ≥10)
- 2.7.7 Pending order count updates automatically across all customer devices
- 2.7.8 Admin dashboard shows current pending order count
- 2.7.9 Thresholds (2 and 10) are configurable in admin settings

### 2.8 Customer Delivery Remarks

**User Story**: As a customer, I want to provide feedback after delivery so that I can share my experience.

**Acceptance Criteria**:
- 2.8.1 Customer can add remarks/feedback after order is delivered
- 2.8.2 Remarks field appears in order detail screen for delivered orders
- 2.8.3 Customer can edit remarks within 24 hours of delivery
- 2.8.4 Admin can view customer remarks in order management
- 2.8.5 Remarks are optional but encouraged with UI prompt
- 2.8.6 Character limit of 500 characters for remarks
- 2.8.7 Remarks are timestamped

### 2.9 No Return Policy Clarification

**User Story**: As a customer, I understand that returns are not accepted because verification happens at delivery.

**Acceptance Criteria**:
- 2.9.1 Return policy is clearly stated during checkout
- 2.9.2 Delivery process includes product verification step
- 2.9.3 Customer must confirm products are correct before delivery completion
- 2.9.4 Delivery photo serves as proof of delivered items
- 2.9.5 Terms and conditions include no-return policy
- 2.9.6 Customer acknowledges policy before first order
- 2.9.7 Help/FAQ section explains verification process

## 3. Non-Functional Requirements

### 3.1 Performance
- Photo uploads should complete within 10 seconds on average network
- Real-time order count updates should reflect within 2 seconds
- Cart calculations should be instant
- Location capture should complete within 5 seconds

### 3.2 Security
- Delivery photos should be stored securely with proper access controls
- Location data should be encrypted in transit and at rest
- Configuration settings should only be accessible to admin users
- Cart value limits should be enforced server-side

### 3.3 Usability
- All new features should follow existing app design patterns
- Error messages should be clear and actionable
- UI should be intuitive without requiring training
- Configuration interface should be simple for admin users

### 3.4 Compatibility
- Features should work on both Android and iOS
- Support for devices with cameras for photo capture
- Support for devices with GPS for location capture
- Graceful degradation if camera or GPS is unavailable
- Push notifications should work on both platforms

## 4. Dependencies

- Firebase Storage for delivery photo storage
- Firebase Cloud Messaging (FCM) for push notifications
- Image picker plugin for camera access
- Location/GPS plugin for location capture
- Audio player plugin for notification sounds
- Existing product, cart, and order models will need updates

## 5. Out of Scope

- Return/refund processing system
- Customer rating system (separate from remarks)
- Scheduled delivery time slots
- Multiple admin accounts with different statuses
- Route optimization for deliveries
- Real-time delivery tracking

## 6. Assumptions

- Admin has access to a device with camera and GPS for delivery
- Customers have stable internet for real-time updates
- Current Firebase plan supports additional storage for photos
- Existing notification infrastructure can be extended for push notifications
- Users grant necessary permissions for camera, location, and notifications

## 7. Success Metrics

- Reduction in delivery disputes due to photo and location proof
- Increased average order value due to free delivery threshold
- Improved customer satisfaction from delivery remarks
- Better product discoverability through categories
- Increased sales during discount promotions
- Reduced customer complaints about delayed deliveries due to capacity warnings
- Higher notification engagement rates with push notifications
