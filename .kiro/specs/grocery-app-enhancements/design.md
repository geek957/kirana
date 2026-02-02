# Grocery App Enhancements - Design Document

## 1. Overview

This design document outlines the technical implementation for enhancements to the existing Flutter-based online grocery application. The enhancements focus on improving product management, delivery operations, cart functionality, and customer experience through eight key feature areas.

### 1.1 Design Goals

- Extend existing models and services with minimal breaking changes
- Maintain consistency with current Firebase architecture
- Ensure real-time synchronization across all user devices
- Provide intuitive admin configuration capabilities
- Enhance customer experience with clear feedback and notifications

### 1.2 Technology Stack

- **Frontend**: Flutter (existing)
- **Backend**: Firebase (Firestore, Storage, Cloud Messaging, Authentication)
- **State Management**: Provider pattern (existing)
- **Storage**: Firebase Storage for images
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Location**: geolocator package
- **Camera**: image_picker package
- **Audio**: audioplayers package

## 2. Data Model Design

### 2.1 Product Model Extensions

**Rationale**: Extend the existing Product model to support discounts, categories, and minimum quantities.

```dart
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;        // Optional discount price
  final String imageUrl;
  final int stock;
  final String unit;
  final bool isAvailable;
  final String categoryId;            // Required: Reference to category
  final int minimumOrderQuantity;     // Required: Minimum 1
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Design Decisions**:
- `discountPrice` is nullable to indicate no discount
- `categoryId` is required (all products must belong to a category)
- `minimumOrderQuantity` is required (minimum value 1)
- Validation: `discountPrice < price` enforced at service layer

### 2.2 Category Model (New)

**Rationale**: Separate category management allows flexible product organization and easier filtering.

```dart
class Category {
  final String id;
  final String name;
  final String? description;
  final int productCount;             // Denormalized for performance
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Design Decisions**:
- `productCount` is denormalized to avoid expensive queries
- Category names must be unique (enforced via Firestore rules)
- Admin must reassign products before deletion

### 2.3 Order Model Extensions

**Rationale**: Capture delivery proof and customer feedback within the existing order structure.

```dart
class Order {
  // ... existing fields ...
  final String? deliveryPhotoUrl;     // Firebase Storage URL (set on delivery)
  final GeoPoint? deliveryLocation;   // GPS coordinates (set on delivery)
  final String? customerRemarks;      // Post-delivery feedback (optional)
  final DateTime? remarksTimestamp;   // When remarks were added
}
```

**Design Decisions**:
- `deliveryPhotoUrl` stores Firebase Storage path
- `deliveryLocation` uses Firestore GeoPoint type
- `remarksTimestamp` tracks when feedback was provided (for 24-hour edit window)
- All fields nullable as they're populated after order creation

### 2.4 App Configuration Model (New)

**Rationale**: Centralize configurable business rules in a single Firestore document for easy admin management. This uses the existing Firebase Firestore dependency - no new Firebase services required.

```dart
class AppConfig {
  final double deliveryCharge;              // Default: 20.0
  final double freeDeliveryThreshold;       // Default: 200.0
  final double maxCartValue;                // Default: 3000.0
  final int orderCapacityWarningThreshold;  // Default: 2
  final int orderCapacityBlockThreshold;    // Default: 10
  final DateTime updatedAt;
  final String updatedBy;                   // Admin ID
}
```

**Firestore Path**: `/config/app_settings`

**Design Decisions**:
- Single document approach for atomic updates
- Cached locally with real-time listener for instant updates
- Admin-only write access via Firestore security rules
- Audit trail via `updatedBy` field
- Uses existing Firestore - no additional Firebase dependencies


## 3. Architecture Design

### 3.1 Service Layer Extensions

#### 3.1.1 CategoryService (New)

**Responsibilities**:
- CRUD operations for categories
- Product count management
- Category validation (uniqueness, deletion checks)

**Key Methods**:
```dart
Future<List<Category>> getCategories()
Future<Category> createCategory(String name, String? description)
Future<void> updateCategory(String id, String name, String? description)
Future<void> deleteCategory(String id)  // Validates no products assigned
Future<int> getProductCountForCategory(String categoryId)
```

**Design Decisions**:
- Categories cached in provider for performance
- Real-time listener updates category list across devices
- Delete validation prevents orphaned products

#### 3.1.2 ProductService Extensions

**New Methods**:
```dart
Future<void> setDiscount(String productId, double? discountPrice)
Future<void> updateCategory(String productId, String categoryId)
Future<void> setMinimumQuantity(String productId, int quantity)
Future<List<Product>> getProductsByCategory(String categoryId)
```

**Design Decisions**:
- Discount validation happens before Firestore write
- Category changes update denormalized product count
- Batch operations for category reassignment

#### 3.1.3 OrderService Extensions

**New Methods**:
```dart
Future<void> uploadDeliveryPhoto(String orderId, File photo)
Future<void> captureDeliveryLocation(String orderId, Position position)
Future<void> addCustomerRemarks(String orderId, String remarks)
Future<bool> canEditRemarks(Order order)  // 24-hour window check
Future<int> getPendingOrderCount()
Stream<int> watchPendingOrderCount()
```

**Design Decisions**:
- Photo upload uses Firebase Storage with order ID as path prefix
- Location capture uses geolocator package with permission handling
- Remarks edit window enforced client-side and via Firestore rules
- Pending count uses real-time stream for instant updates

#### 3.1.4 ConfigService (New)

**Responsibilities**:
- Load and cache app configuration
- Provide real-time updates to configuration changes
- Admin-only configuration updates

**Key Methods**:
```dart
Future<AppConfig> getConfig()
Stream<AppConfig> watchConfig()
Future<void> updateConfig(AppConfig config)  // Admin only
double calculateDeliveryCharge(double cartValue)
bool isCartValueValid(double cartValue)
OrderCapacityStatus getOrderCapacityStatus(int pendingCount)
```

**Design Decisions**:
- Singleton pattern with in-memory cache
- Real-time listener ensures all devices see updates within 2 seconds
- Helper methods encapsulate business logic

#### 3.1.5 NotificationService Extensions

**New Methods**:
```dart
Future<void> initializePushNotifications()
Future<void> requestNotificationPermissions()
Future<void> sendPushNotification(String userId, String title, String body)
Future<void> sendBulkNotification(String title, String body)  // All customers
Future<void> playNotificationSound()
Future<void> toggleNotificationSound(bool enabled)
```

**Design Decisions**:
- FCM integration for cross-platform push notifications
- Sound playback uses audioplayers package
- Sound preference stored in local storage (shared_preferences)
- Background notification handling via FCM handlers

### 3.2 Provider Layer Extensions

#### 3.2.1 CategoryProvider (New)

**State Management**:
```dart
class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  
  Future<void> loadCategories()
  Future<void> createCategory(String name, String? description)
  Future<void> updateCategory(Category category)
  Future<void> deleteCategory(String id)
  void selectCategory(Category? category)
}
```

#### 3.2.2 CartProvider Extensions

**New Functionality**:
```dart
class CartProvider extends ChangeNotifier {
  // ... existing fields ...
  AppConfig? _config;
  
  double get deliveryCharge => _calculateDeliveryCharge();
  double get totalWithDelivery => subtotal + deliveryCharge;
  bool get isFreeDeliveryEligible => subtotal >= (_config?.freeDeliveryThreshold ?? 200);
  double get amountForFreeDelivery => max(0, (_config?.freeDeliveryThreshold ?? 200) - subtotal);
  bool get isCartValueValid => subtotal <= (_config?.maxCartValue ?? 3000);
  String? get cartValueError => !isCartValueValid ? 'Cart exceeds maximum value' : null;
  
  bool validateMinimumQuantity(Product product, int quantity);
}
```

**Design Decisions**:
- Config injected via dependency to avoid tight coupling
- Computed properties for reactive UI updates
- Validation methods return clear error messages

#### 3.2.3 OrderProvider Extensions

**New Functionality**:
```dart
class OrderProvider extends ChangeNotifier {
  // ... existing fields ...
  int _pendingOrderCount = 0;
  StreamSubscription? _pendingCountSubscription;
  
  int get pendingOrderCount => _pendingOrderCount;
  OrderCapacityStatus get capacityStatus => _getCapacityStatus();
  bool get canPlaceOrder => _pendingOrderCount < 10;
  String? get capacityWarning => _getCapacityWarning();
  
  Future<void> uploadDeliveryProof(String orderId, File photo, Position location);
  Future<void> addRemarks(String orderId, String remarks);
  void startWatchingPendingCount();
}
```

**Design Decisions**:
- Real-time subscription to pending count
- Capacity status computed from config thresholds
- Warning messages generated based on current state


## 4. User Interface Design

### 4.1 Admin Screens

#### 4.1.1 Category Management Screen (New)

**Location**: Admin Dashboard → Category Management

**Components**:
- Category list with product counts
- Add/Edit category dialog
- Delete confirmation with validation
- Alphabetically sorted display

**Validation**:
- Unique category names
- Cannot delete category with products
- Required name field

#### 4.1.2 Product Form Extensions

**New Fields**:
- Category dropdown (required)
- Discount price input (optional, validated < regular price)
- Minimum order quantity input (default 1, min 1)

**UI Enhancements**:
- Clear visual indicator when discount is active
- Discount percentage calculation display
- Minimum quantity helper text

#### 4.1.3 Order Management Extensions

**Delivery Completion Flow**:
1. "Mark as Delivered" button opens delivery proof dialog
2. Camera capture for delivery photo (mandatory)
3. Automatic GPS location capture
4. Confirmation with photo preview
5. Upload and order status update

**Order Detail Enhancements**:
- Delivery photo display (if available)
- Map view of delivery location
- Customer remarks section (read-only for admin)

#### 4.1.4 App Configuration Screen (New)

**Location**: Admin Dashboard → Settings → App Configuration

**Configurable Fields**:
- Delivery charge amount (₹)
- Free delivery threshold (₹)
- Maximum cart value (₹)
- Order capacity warning threshold (count)
- Order capacity block threshold (count)

**UI Features**:
- Input validation with min/max constraints
- Preview of how changes affect customers
- Save confirmation dialog
- Last updated timestamp and admin name

### 4.2 Customer Screens

#### 4.2.1 Home Screen Extensions

**Category Filter**:
- Horizontal scrollable category chips
- "All" option to show all products
- Active category highlighted
- Product count badge on each category

**Product Card Enhancements**:
- Strikethrough original price when discount active
- Discount price in prominent color (green)
- Discount percentage badge
- Category label

#### 4.2.2 Product Detail Screen Extensions

**New Information Display**:
- Discount pricing with savings calculation
- Minimum order quantity prominently displayed
- Category information
- Quantity selector starts at minimum quantity

**Validation**:
- Disable "Add to Cart" if quantity < minimum
- Error message for invalid quantity

#### 4.2.3 Cart Screen Extensions

**Delivery Charge Section**:
- Current delivery charge display
- Progress indicator for free delivery
- "Add ₹X more for free delivery" message
- Clear explanation of delivery rules

**Cart Value Validation**:
- Warning banner if approaching max cart value
- Error banner if exceeding max cart value
- Disable checkout button when invalid

**Order Capacity Warning**:
- Info banner when pending orders ≥ 2
- "Delivery might be delayed" message
- Current pending order count display

#### 4.2.4 Checkout Screen Extensions

**Pre-Checkout Validations**:
- Minimum quantity check for all items
- Cart value validation
- Order capacity check (block if ≥ 10)

**Order Summary**:
- Subtotal
- Delivery charge (with strikethrough if free)
- Total amount
- Savings from discounts

**Policy Acknowledgment**:
- No-return policy checkbox (first order only)
- Link to terms and conditions
- Verification process explanation

#### 4.2.5 Order Detail Screen Extensions

**Delivery Proof Section** (for delivered orders):
- Delivery photo display (expandable)
- Delivery location map view
- Delivery timestamp

**Customer Remarks Section**:
- Text input field (appears after delivery)
- 500 character limit with counter
- Edit button (available for 24 hours)
- Timestamp of last edit
- Placeholder encouraging feedback

### 4.3 Notification UI

#### 4.3.1 Push Notifications

**Notification Types**:
- Order status updates (placed, confirmed, out for delivery, delivered)
- Delivery completion with photo
- Admin announcements
- Capacity warnings

**Notification Content**:
- Title: Event type
- Body: Relevant details
- Action: Deep link to relevant screen
- Sound: Custom notification sound

#### 4.3.2 In-App Notifications Screen

**Enhancements**:
- Push notification badge on tab/icon
- Notification list with timestamps
- Tap to navigate to relevant screen
- Mark as read functionality

#### 4.3.3 Settings Screen

**New Options**:
- Enable/disable notification sounds
- Notification preferences
- Permission status display


## 5. Business Logic Design

### 5.1 Discount Pricing Logic

**Price Calculation**:
```dart
double getEffectivePrice(Product product) {
  return product.discountPrice ?? product.price;
}

double calculateSavings(Product product, int quantity) {
  if (product.discountPrice == null) return 0.0;
  return (product.price - product.discountPrice!) * quantity;
}

String getDiscountPercentage(Product product) {
  if (product.discountPrice == null) return '';
  double percentage = ((product.price - product.discountPrice!) / product.price) * 100;
  return '${percentage.toStringAsFixed(0)}% OFF';
}
```

**Validation Rules**:
- `discountPrice` must be > 0
- `discountPrice` must be < `price`
- Discount can be removed by setting to null

### 5.2 Category Management Logic

**Category Deletion Validation**:
```dart
Future<bool> canDeleteCategory(String categoryId) async {
  int productCount = await getProductCountForCategory(categoryId);
  return productCount == 0;
}
```

**Product Count Synchronization**:
- Increment on product creation
- Decrement on product deletion
- Update on category change
- Recalculate on data inconsistency

**Default Category**:
- System creates "Uncategorized" category on first launch
- Cannot be deleted
- Used as fallback for data migration

### 5.3 Delivery Charge Calculation

**Algorithm**:
```dart
double calculateDeliveryCharge(double cartValue, AppConfig config) {
  if (cartValue >= config.freeDeliveryThreshold) {
    return 0.0;
  }
  return config.deliveryCharge;
}
```

**Display Logic**:
- Show delivery charge on cart screen
- Show progress to free delivery if below threshold
- Strikethrough delivery charge when free

### 5.4 Cart Validation Logic

**Minimum Quantity Validation**:
```dart
bool validateCartItem(CartItem item) {
  return item.quantity >= item.product.minimumOrderQuantity;
}

List<String> getCartValidationErrors(Cart cart) {
  List<String> errors = [];
  for (var item in cart.items) {
    if (!validateCartItem(item)) {
      errors.add('${item.product.name} requires minimum ${item.product.minimumOrderQuantity} ${item.product.unit}');
    }
  }
  return errors;
}
```

**Cart Value Validation**:
```dart
bool isCartValueValid(double cartValue, AppConfig config) {
  return cartValue <= config.maxCartValue;
}
```

**Checkout Validation**:
1. Check minimum quantities for all items
2. Check cart value within limits
3. Check order capacity
4. Validate delivery address
5. All validations must pass to proceed

### 5.5 Order Capacity Logic

**Status Determination**:
```dart
enum OrderCapacityStatus {
  normal,      // < 2 pending orders
  warning,     // >= 2 and < 10 pending orders
  blocked      // >= 10 pending orders
}

OrderCapacityStatus getCapacityStatus(int pendingCount, AppConfig config) {
  if (pendingCount >= config.orderCapacityBlockThreshold) {
    return OrderCapacityStatus.blocked;
  } else if (pendingCount >= config.orderCapacityWarningThreshold) {
    return OrderCapacityStatus.warning;
  }
  return OrderCapacityStatus.normal;
}
```

**Pending Order Count**:
- Query: `orders.where('status', '==', 'pending').count()`
- Real-time listener updates count automatically
- Count displayed on admin dashboard
- Used for customer-facing warnings

### 5.6 Delivery Proof Logic

**Photo Upload Flow**:
1. Capture photo using device camera
2. Compress image to reduce storage (max 1MB)
3. Generate unique filename: `delivery_photos/{orderId}_{timestamp}.jpg`
4. Upload to Firebase Storage
5. Get download URL
6. Update order document with URL

**Location Capture Flow**:
1. Request location permissions
2. Get current position with high accuracy
3. Extract latitude and longitude
4. Store as Firestore GeoPoint
5. Update order document

**Validation**:
- Photo upload must succeed before marking delivered
- Location capture optional but encouraged
- Retry mechanism for failed uploads

### 5.7 Customer Remarks Logic

**Edit Window Validation**:
```dart
bool canEditRemarks(Order order) {
  if (order.remarksTimestamp == null) return true;
  Duration elapsed = DateTime.now().difference(order.remarksTimestamp!);
  return elapsed.inHours < 24;
}
```

**Character Limit**:
- Maximum 500 characters
- Real-time character counter
- Validation on submit

### 5.8 Notification Logic

**Push Notification Triggers**:
- Order placed → Notify admin
- Order status changed → Notify customer
- Order delivered → Notify customer with photo
- Admin announcement → Notify all customers
- Capacity warning → Notify customer at checkout

**Sound Playback**:
```dart
Future<void> playNotificationSound() async {
  bool soundEnabled = await getSoundPreference();
  if (soundEnabled) {
    await audioPlayer.play(AssetSource('sounds/notification.mp3'));
  }
}
```

**Notification Storage**:
- All notifications stored in Firestore
- User-specific collection: `/users/{userId}/notifications`
- Includes: title, body, timestamp, read status, type
- Ordered by timestamp descending


## 6. Database Design

### 6.1 Firestore Collections

#### 6.1.1 Products Collection (Extended)

**Path**: `/products/{productId}`

```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "price": "number",
  "discountPrice": "number | null",
  "imageUrl": "string",
  "stock": "number",
  "unit": "string",
  "isAvailable": "boolean",
  "categoryId": "string",
  "minimumOrderQuantity": "number",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Indexes**:
- `categoryId` (for filtering by category)
- `isAvailable` (for active products)
- Composite: `categoryId + isAvailable` (for category filtering)

#### 6.1.2 Categories Collection (New)

**Path**: `/categories/{categoryId}`

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

**Indexes**:
- `name` (for uniqueness check and sorting)

**Constraints**:
- Unique name (enforced via security rules)
- Cannot delete if productCount > 0

#### 6.1.3 Orders Collection (Extended)

**Path**: `/orders/{orderId}`

```json
{
  // ... existing fields ...
  "deliveryPhotoUrl": "string | null",
  "deliveryLocation": {
    "latitude": "number",
    "longitude": "number"
  } | null,
  "customerRemarks": "string | null",
  "remarksTimestamp": "timestamp | null"
}
```

**Indexes**:
- Existing indexes remain
- No new indexes needed for new fields

#### 6.1.4 Config Collection (New)

**Path**: `/config/app_settings`

```json
{
  "deliveryCharge": "number",
  "freeDeliveryThreshold": "number",
  "maxCartValue": "number",
  "orderCapacityWarningThreshold": "number",
  "orderCapacityBlockThreshold": "number",
  "updatedAt": "timestamp",
  "updatedBy": "string"
}
```

**Access Pattern**:
- Single document read on app launch
- Real-time listener for updates
- Admin-only writes

#### 6.1.5 Notifications Collection (Extended)

**Path**: `/users/{userId}/notifications/{notificationId}`

```json
{
  "id": "string",
  "title": "string",
  "body": "string",
  "type": "string",
  "orderId": "string | null",
  "isRead": "boolean",
  "createdAt": "timestamp"
}
```

**Indexes**:
- `createdAt` (for sorting)
- Composite: `isRead + createdAt` (for unread notifications)

### 6.2 Firebase Storage Structure

**Delivery Photos**:
```
/delivery_photos/
  /{orderId}_{timestamp}.jpg
```

**Access Control**:
- Admin: Read/Write
- Customer: Read only (for their orders)
- Authenticated users only

### 6.3 Security Rules

#### 6.3.1 Products Collection Rules

```javascript
match /products/{productId} {
  allow read: if request.auth != null;
  allow create, update: if isAdmin();
  allow delete: if isAdmin();
  
  // Validation
  allow write: if request.resource.data.discountPrice == null 
    || request.resource.data.discountPrice < request.resource.data.price;
  allow write: if request.resource.data.minimumOrderQuantity >= 1;
  allow write: if exists(/databases/$(database)/documents/categories/$(request.resource.data.categoryId));
}
```

#### 6.3.2 Categories Collection Rules

```javascript
match /categories/{categoryId} {
  allow read: if request.auth != null;
  allow create, update: if isAdmin();
  allow delete: if isAdmin() && resource.data.productCount == 0;
  
  // Unique name validation (requires query)
  allow create: if !exists(/databases/$(database)/documents/categories/$(request.resource.data.name));
}
```

#### 6.3.3 Orders Collection Rules

```javascript
match /orders/{orderId} {
  allow read: if request.auth != null && 
    (isAdmin() || resource.data.customerId == request.auth.uid);
  
  // Customer can add remarks
  allow update: if request.auth.uid == resource.data.customerId &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['customerRemarks', 'remarksTimestamp']) &&
    (resource.data.remarksTimestamp == null || 
     request.time < resource.data.remarksTimestamp + duration.value(24, 'h'));
  
  // Admin can update delivery proof
  allow update: if isAdmin() &&
    request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['deliveryPhotoUrl', 'deliveryLocation', 'status', 'updatedAt']);
}
```

#### 6.3.4 Config Collection Rules

```javascript
match /config/app_settings {
  allow read: if request.auth != null;
  allow write: if isAdmin();
  
  // Validation
  allow write: if request.resource.data.deliveryCharge >= 0;
  allow write: if request.resource.data.freeDeliveryThreshold > 0;
  allow write: if request.resource.data.maxCartValue > request.resource.data.freeDeliveryThreshold;
  allow write: if request.resource.data.orderCapacityWarningThreshold > 0;
  allow write: if request.resource.data.orderCapacityBlockThreshold > request.resource.data.orderCapacityWarningThreshold;
}
```

#### 6.3.5 Storage Rules

```javascript
match /delivery_photos/{orderId}_{timestamp}.jpg {
  allow read: if request.auth != null;
  allow write: if isAdmin();
  allow delete: if false; // Never delete delivery proof
}
```

### 6.4 Initial Data Setup

**Default Configuration Document**:
Create `/config/app_settings` with default values:
```json
{
  "deliveryCharge": 20.0,
  "freeDeliveryThreshold": 200.0,
  "maxCartValue": 3000.0,
  "orderCapacityWarningThreshold": 2,
  "orderCapacityBlockThreshold": 10,
  "updatedAt": [timestamp],
  "updatedBy": "[admin-id]"
}
```

**Default Category**:
Create at least one category (e.g., "General", "Groceries") before adding products.


## 7. API Design

### 7.1 CategoryService API

```dart
class CategoryService {
  final FirebaseFirestore _firestore;
  
  // Read operations
  Future<List<Category>> getCategories();
  Stream<List<Category>> watchCategories();
  Future<Category?> getCategoryById(String id);
  
  // Write operations
  Future<Category> createCategory({
    required String name,
    String? description,
  });
  
  Future<void> updateCategory({
    required String id,
    required String name,
    String? description,
  });
  
  Future<void> deleteCategory(String id);
  
  // Validation
  Future<bool> isCategoryNameUnique(String name, {String? excludeId});
  Future<int> getProductCount(String categoryId);
  Future<void> incrementProductCount(String categoryId);
  Future<void> decrementProductCount(String categoryId);
}
```

### 7.2 ProductService API Extensions

```dart
class ProductService {
  // ... existing methods ...
  
  // Discount management
  Future<void> setDiscount({
    required String productId,
    required double? discountPrice,
  });
  
  Future<void> removeDiscount(String productId);
  
  // Category management
  Future<void> updateProductCategory({
    required String productId,
    required String categoryId,
  });
  
  Future<List<Product>> getProductsByCategory(String categoryId);
  
  // Minimum quantity
  Future<void> setMinimumQuantity({
    required String productId,
    required int quantity,
  });
  
  // Validation
  bool validateDiscountPrice(double price, double? discountPrice);
  bool validateMinimumQuantity(int quantity);
}
```

### 7.3 OrderService API Extensions

```dart
class OrderService {
  // ... existing methods ...
  
  // Delivery proof
  Future<String> uploadDeliveryPhoto({
    required String orderId,
    required File photoFile,
  });
  
  Future<void> saveDeliveryLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  });
  
  Future<void> completeDelivery({
    required String orderId,
    required File deliveryPhoto,
    required Position location,
  });
  
  // Customer remarks
  Future<void> addCustomerRemarks({
    required String orderId,
    required String remarks,
  });
  
  Future<void> updateCustomerRemarks({
    required String orderId,
    required String remarks,
  });
  
  bool canEditRemarks(Order order);
  
  // Order capacity
  Future<int> getPendingOrderCount();
  Stream<int> watchPendingOrderCount();
}
```

### 7.4 ConfigService API

```dart
class ConfigService {
  final FirebaseFirestore _firestore;
  AppConfig? _cachedConfig;
  StreamSubscription? _configSubscription;
  
  // Read operations
  Future<AppConfig> getConfig();
  Stream<AppConfig> watchConfig();
  
  // Write operations (admin only)
  Future<void> updateConfig(AppConfig config);
  
  // Helper methods
  double calculateDeliveryCharge(double cartValue);
  bool isCartValueValid(double cartValue);
  OrderCapacityStatus getOrderCapacityStatus(int pendingCount);
  double getAmountForFreeDelivery(double cartValue);
  
  // Initialization
  Future<void> initializeDefaultConfig();
  void dispose();
}
```

### 7.5 NotificationService API Extensions

```dart
class NotificationService {
  // ... existing methods ...
  
  // Push notifications
  Future<void> initializeFCM();
  Future<String?> getFCMToken();
  Future<void> requestPermissions();
  
  // Send notifications
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
  
  Future<void> sendBulkNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
  
  // Sound management
  Future<void> playNotificationSound();
  Future<void> setNotificationSoundEnabled(bool enabled);
  Future<bool> isNotificationSoundEnabled();
  
  // Background handlers
  void setupBackgroundHandlers();
  Future<void> handleBackgroundMessage(RemoteMessage message);
  Future<void> handleForegroundMessage(RemoteMessage message);
}
```

### 7.6 Error Handling

**Error Types**:
```dart
class CategoryException implements Exception {
  final String message;
  CategoryException(this.message);
}

class CategoryNameNotUniqueException extends CategoryException {
  CategoryNameNotUniqueException() : super('Category name already exists');
}

class CategoryHasProductsException extends CategoryException {
  CategoryHasProductsException() : super('Cannot delete category with products');
}

class InvalidDiscountPriceException implements Exception {
  final String message;
  InvalidDiscountPriceException(this.message);
}

class CartValueExceededException implements Exception {
  final double maxValue;
  CartValueExceededException(this.maxValue);
}

class OrderCapacityExceededException implements Exception {
  OrderCapacityExceededException();
}

class DeliveryPhotoUploadException implements Exception {
  final String message;
  DeliveryPhotoUploadException(this.message);
}

class RemarksEditWindowExpiredException implements Exception {
  RemarksEditWindowExpiredException();
}
```

**Error Handling Strategy**:
- Service layer throws typed exceptions
- Provider layer catches and converts to user-friendly messages
- UI displays errors via snackbars or dialogs
- Critical errors logged to Firebase Crashlytics


## 8. Integration Design

### 8.1 Firebase Cloud Messaging Integration

**Setup Requirements**:
- Configure FCM in Firebase Console
- Add google-services.json (Android) and GoogleService-Info.plist (iOS)
- Configure notification channels (Android)
- Request notification permissions (iOS)

**Message Structure**:
```json
{
  "notification": {
    "title": "Order Delivered",
    "body": "Your order #12345 has been delivered"
  },
  "data": {
    "type": "order_delivered",
    "orderId": "12345",
    "photoUrl": "https://...",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "android": {
    "priority": "high",
    "notification": {
      "sound": "notification_sound",
      "channel_id": "order_updates"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "notification_sound.mp3"
      }
    }
  }
}
```

**Background Handler**:
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Store notification in Firestore
  // Play sound if enabled
  // Update badge count
}
```

### 8.2 Image Picker Integration

**Package**: `image_picker: ^1.0.0`

**Usage**:
```dart
Future<File?> captureDeliveryPhoto() async {
  final ImagePicker picker = ImagePicker();
  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  return photo != null ? File(photo.path) : null;
}
```

**Permissions**:
- Android: `CAMERA` permission in AndroidManifest.xml
- iOS: `NSCameraUsageDescription` in Info.plist

### 8.3 Geolocator Integration

**Package**: `geolocator: ^10.0.0`

**Usage**:
```dart
Future<Position?> captureCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw LocationServiceDisabledException();
  }
  
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }
  }
  
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 5),
  );
}
```

**Permissions**:
- Android: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- iOS: `NSLocationWhenInUseUsageDescription`

### 8.4 Audio Player Integration

**Package**: `audioplayers: ^5.0.0`

**Usage**:
```dart
class NotificationSoundPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Future<void> playSound() async {
    await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}
```

**Asset Configuration** (pubspec.yaml):
```yaml
flutter:
  assets:
    - assets/sounds/notification.mp3
```

### 8.5 Firebase Storage Integration

**Upload Strategy**:
```dart
Future<String> uploadDeliveryPhoto(String orderId, File photo) async {
  final storageRef = FirebaseStorage.instance.ref();
  final photoRef = storageRef.child('delivery_photos/${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
  
  // Compress image
  final compressedPhoto = await compressImage(photo);
  
  // Upload with metadata
  final metadata = SettableMetadata(
    contentType: 'image/jpeg',
    customMetadata: {
      'orderId': orderId,
      'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
    },
  );
  
  final uploadTask = photoRef.putFile(compressedPhoto, metadata);
  
  // Monitor progress
  uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
    double progress = snapshot.bytesTransferred / snapshot.totalBytes;
    // Update UI with progress
  });
  
  final snapshot = await uploadTask;
  return await snapshot.ref.getDownloadURL();
}
```

### 8.6 Map Integration (Optional Enhancement)

**Package**: `google_maps_flutter: ^2.5.0` or `flutter_map: ^6.0.0`

**Usage for Delivery Location Display**:
```dart
Widget buildDeliveryLocationMap(GeoPoint location) {
  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 15,
    ),
    markers: {
      Marker(
        markerId: MarkerId('delivery_location'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: 'Delivery Location'),
      ),
    },
  );
}
```

**Alternative**: Use static map image from Google Maps Static API to avoid SDK overhead.


## 9. Pre-Deployment Setup

### 9.1 Firebase Configuration

**Firestore Indexes**:
Create the following indexes in Firebase Console:

1. **Products Collection**:
   - Composite index: `categoryId` (Ascending) + `isAvailable` (Ascending) + `name` (Ascending)

2. **Categories Collection**:
   - Single field index: `name` (Ascending)

**Firestore Security Rules**:
Deploy the security rules defined in Section 6.3 using:
```bash
firebase deploy --only firestore:rules
```

**Firebase Storage Rules**:
Deploy the storage rules defined in Section 11.3 using:
```bash
firebase deploy --only storage
```

### 9.2 Initial Data Setup

**Create Default Configuration**:
Create the config document in Firestore Console:
- Collection: `config`
- Document ID: `app_settings`
- Fields:
  ```json
  {
    "deliveryCharge": 20.0,
    "freeDeliveryThreshold": 200.0,
    "maxCartValue": 3000.0,
    "orderCapacityWarningThreshold": 2,
    "orderCapacityBlockThreshold": 10,
    "updatedAt": [current timestamp],
    "updatedBy": "[your admin user ID]"
  }
  ```

**Create Initial Categories**:
Create at least one category before adding products (e.g., "Groceries", "Vegetables", "Dairy").

### 9.3 Firebase Cloud Messaging Setup

**Android Setup**:
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/` directory
3. Ensure FCM is enabled in Firebase Console

**iOS Setup**:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/` directory
3. Upload APNs certificate to Firebase Console
4. Enable Push Notifications capability in Xcode

**Test Notifications**:
Send a test notification from Firebase Console to verify setup.

### 9.4 Permissions Configuration

**Verify AndroidManifest.xml** includes:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**Verify Info.plist** includes:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture delivery photos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to record delivery location</string>
```

### 9.5 Asset Setup

**Add Notification Sound**:
1. Add `notification.mp3` to `assets/sounds/` directory
2. Update `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/sounds/notification.mp3
   ```

### 9.6 Deployment Checklist

Before deploying to production:

- [ ] Firestore indexes created
- [ ] Security rules deployed for Firestore and Storage
- [ ] Default config document created
- [ ] At least one category created
- [ ] FCM configured for Android and iOS
- [ ] Notification sound asset added
- [ ] Permissions configured in manifests
- [ ] Test on both Android and iOS devices
- [ ] Verify camera and location permissions work
- [ ] Test push notifications on real devices
- [ ] Verify admin can access new features
- [ ] Verify customers see new UI elements


## 10. Performance Considerations

### 10.1 Caching Strategy

**AppConfig Caching**:
- Load once on app start
- Cache in memory with singleton pattern
- Real-time listener updates cache automatically
- Fallback to cached values if offline

**Category Caching**:
- Load all categories on app start (small dataset)
- Cache in CategoryProvider
- Real-time listener keeps cache fresh
- No pagination needed (expected < 50 categories)

**Product Filtering**:
- Use Firestore indexes for category filtering
- Implement pagination for large product lists
- Cache product images with flutter_cache_manager

**Pending Order Count**:
- Use Firestore count aggregation query
- Cache result with 30-second TTL
- Real-time listener for instant updates
- Fallback to cached value if query fails

### 10.2 Image Optimization

**Photo Compression**:
```dart
Future<File> compressImage(File image) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    image.absolute.path,
    '${image.parent.path}/compressed_${image.path.split('/').last}',
    quality: 85,
    minWidth: 1920,
    minHeight: 1080,
  );
  return result ?? image;
}
```

**Progressive Upload**:
- Show upload progress indicator
- Allow cancellation
- Retry on failure with exponential backoff

**Image Loading**:
- Use cached_network_image for product images
- Lazy load images in lists
- Placeholder images during load

### 10.3 Real-Time Listener Optimization

**Selective Listeners**:
- Only subscribe to necessary collections
- Unsubscribe when screen is disposed
- Use `limit()` queries where appropriate

**Listener Management**:
```dart
class OrderProvider extends ChangeNotifier {
  StreamSubscription? _pendingCountSubscription;
  
  void startWatchingPendingCount() {
    _pendingCountSubscription = orderService
      .watchPendingOrderCount()
      .listen((count) {
        _pendingOrderCount = count;
        notifyListeners();
      });
  }
  
  @override
  void dispose() {
    _pendingCountSubscription?.cancel();
    super.dispose();
  }
}
```

### 10.4 Query Optimization

**Indexed Queries**:
- Create composite indexes for common queries
- Use `where()` clauses efficiently
- Avoid `array-contains-any` with large arrays

**Pagination**:
```dart
Future<List<Product>> getProductsByCategory(
  String categoryId, {
  int limit = 20,
  DocumentSnapshot? startAfter,
}) async {
  Query query = _firestore
    .collection('products')
    .where('categoryId', isEqualTo: categoryId)
    .where('isAvailable', isEqualTo: true)
    .orderBy('name')
    .limit(limit);
  
  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }
  
  final snapshot = await query.get();
  return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
}
```

### 10.5 Network Optimization

**Batch Operations**:
- Use Firestore batch writes for related updates
- Combine multiple reads into single query where possible

**Offline Support**:
- Enable Firestore offline persistence
- Handle offline scenarios gracefully
- Queue operations for when online

**Example Batch Write**:
```dart
Future<void> updateProductCategory(String productId, String newCategoryId, String oldCategoryId) async {
  final batch = _firestore.batch();
  
  // Update product
  batch.update(
    _firestore.collection('products').doc(productId),
    {'categoryId': newCategoryId, 'updatedAt': FieldValue.serverTimestamp()},
  );
  
  // Update old category count
  batch.update(
    _firestore.collection('categories').doc(oldCategoryId),
    {'productCount': FieldValue.increment(-1)},
  );
  
  // Update new category count
  batch.update(
    _firestore.collection('categories').doc(newCategoryId),
    {'productCount': FieldValue.increment(1)},
  );
  
  await batch.commit();
}
```

### 10.6 Memory Management

**Image Memory**:
- Dispose image controllers properly
- Clear image cache periodically
- Use appropriate image resolutions

**Provider Disposal**:
- Dispose all providers properly
- Cancel stream subscriptions
- Clear cached data when not needed

**Large Lists**:
- Use ListView.builder for efficient rendering
- Implement pagination for long lists
- Dispose list items properly


## 11. Security Considerations

### 11.1 Authentication & Authorization

**Admin Verification**:
```dart
Future<bool> isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  final adminDoc = await FirebaseFirestore.instance
    .collection('admins')
    .doc(user.uid)
    .get();
  
  return adminDoc.exists;
}
```

**Security Rules Helper**:
```javascript
function isAdmin() {
  return exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}

function isOwner(userId) {
  return request.auth.uid == userId;
}
```

### 11.2 Data Validation

**Client-Side Validation**:
- Validate all inputs before submission
- Enforce minimum/maximum constraints
- Sanitize user input (remarks, category names)

**Server-Side Validation** (Firestore Rules):
- Validate data types and ranges
- Enforce business rules
- Prevent unauthorized modifications

**Example Validation**:
```javascript
match /products/{productId} {
  allow write: if 
    request.resource.data.price is number &&
    request.resource.data.price > 0 &&
    (request.resource.data.discountPrice == null || 
     (request.resource.data.discountPrice is number &&
      request.resource.data.discountPrice > 0 &&
      request.resource.data.discountPrice < request.resource.data.price)) &&
    request.resource.data.minimumOrderQuantity is int &&
    request.resource.data.minimumOrderQuantity >= 1 &&
    request.resource.data.minimumOrderQuantity <= 1000;
}
```

### 11.3 File Upload Security

**Storage Security Rules**:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /delivery_photos/{orderId}_{timestamp}.jpg {
      // Only admins can upload
      allow write: if request.auth != null && isAdmin();
      
      // Authenticated users can read
      allow read: if request.auth != null;
      
      // Validate file size (max 5MB)
      allow write: if request.resource.size < 5 * 1024 * 1024;
      
      // Validate file type
      allow write: if request.resource.contentType.matches('image/.*');
    }
  }
}
```

**Upload Validation**:
```dart
Future<void> validatePhotoUpload(File photo) async {
  // Check file size
  final fileSize = await photo.length();
  if (fileSize > 5 * 1024 * 1024) {
    throw Exception('Photo size exceeds 5MB limit');
  }
  
  // Check file type
  final mimeType = lookupMimeType(photo.path);
  if (mimeType == null || !mimeType.startsWith('image/')) {
    throw Exception('Invalid file type. Only images are allowed.');
  }
}
```

### 11.4 Location Data Privacy

**Permission Handling**:
- Request permissions with clear explanation
- Handle permission denial gracefully
- Don't block critical functionality on location

**Data Minimization**:
- Only capture location when necessary (delivery completion)
- Don't track continuous location
- Store only coordinates, not full address

**Access Control**:
- Location visible only to order owner and admin
- No public access to location data
- Encrypted in transit (HTTPS)

### 11.5 Notification Security

**FCM Token Management**:
```dart
Future<void> updateFCMToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .update({'fcmToken': token});
  }
}
```

**Message Validation**:
- Validate notification content server-side
- Prevent injection attacks in notification body
- Sanitize user-generated content in notifications

**Token Security**:
- Store FCM tokens securely in Firestore
- Refresh tokens on expiration
- Remove tokens on logout

### 11.6 Configuration Security

**Admin-Only Access**:
- Config updates require admin authentication
- Audit trail for all config changes
- Validate config values before saving

**Rate Limiting**:
- Limit config update frequency
- Prevent abuse of configuration changes
- Log suspicious activity

**Validation Rules**:
```javascript
match /config/app_settings {
  allow read: if request.auth != null;
  allow write: if isAdmin() &&
    request.resource.data.deliveryCharge >= 0 &&
    request.resource.data.deliveryCharge <= 1000 &&
    request.resource.data.freeDeliveryThreshold > 0 &&
    request.resource.data.freeDeliveryThreshold <= 10000 &&
    request.resource.data.maxCartValue > request.resource.data.freeDeliveryThreshold &&
    request.resource.data.maxCartValue <= 100000 &&
    request.resource.data.orderCapacityWarningThreshold > 0 &&
    request.resource.data.orderCapacityWarningThreshold < request.resource.data.orderCapacityBlockThreshold &&
    request.resource.data.orderCapacityBlockThreshold <= 1000;
}
```

### 11.7 Input Sanitization

**Customer Remarks**:
```dart
String sanitizeRemarks(String input) {
  // Remove potentially harmful characters
  String sanitized = input.replaceAll(RegExp(r'[<>]'), '');
  
  // Trim whitespace
  sanitized = sanitized.trim();
  
  // Limit length
  if (sanitized.length > 500) {
    sanitized = sanitized.substring(0, 500);
  }
  
  return sanitized;
}
```

**Category Names**:
```dart
String sanitizeCategoryName(String input) {
  // Remove special characters except spaces and hyphens
  String sanitized = input.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-]'), '');
  
  // Trim and normalize whitespace
  sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');
  
  // Limit length
  if (sanitized.length > 50) {
    sanitized = sanitized.substring(0, 50);
  }
  
  return sanitized;
}
```

### 11.8 Error Information Disclosure

**Safe Error Messages**:
```dart
String getSafeErrorMessage(Exception e) {
  // Don't expose internal error details to users
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'not-found':
        return 'The requested resource was not found';
      case 'already-exists':
        return 'This item already exists';
      default:
        return 'An error occurred. Please try again.';
    }
  }
  
  // Log full error for debugging
  FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
  
  return 'An unexpected error occurred. Please try again.';
}
```





## 13. Dependencies & Packages

### 13.1 New Package Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  
  # Image handling
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0
  cached_network_image: ^3.3.1
  
  # Location services
  geolocator: ^10.1.0
  
  # Notifications
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  
  # Audio
  audioplayers: ^5.2.1
  
  # Maps (optional)
  google_maps_flutter: ^2.5.3
  # OR
  flutter_map: ^6.1.0
  
  # Utilities
  path_provider: ^2.1.2
  mime: ^1.0.4

dev_dependencies:
  # Existing dev dependencies...
  
  # Testing
  mockito: ^5.4.4
  fake_cloud_firestore: ^2.5.0
  firebase_storage_mocks: ^0.6.1
```

### 13.2 Package Justifications

**image_picker**: Camera access for delivery photos
- Well-maintained official plugin
- Cross-platform support
- Handles permissions automatically

**flutter_image_compress**: Reduce photo file sizes
- Efficient compression algorithms
- Maintains image quality
- Reduces storage costs

**geolocator**: GPS location capture
- Accurate location services
- Permission handling
- Cross-platform support

**firebase_messaging**: Push notifications
- Official Firebase plugin
- Reliable delivery
- Background message handling

**flutter_local_notifications**: Local notification display
- Custom notification channels
- Sound support
- Action buttons

**audioplayers**: Notification sound playback
- Simple API
- Multiple audio formats
- Background playback support

**google_maps_flutter** or **flutter_map**: Map display
- google_maps_flutter: Official Google Maps integration
- flutter_map: Open-source alternative, no API key needed
- Choose based on requirements and budget

### 13.3 Version Compatibility

**Minimum SDK Versions**:
- Flutter: 3.16.0
- Dart: 3.2.0
- Android: API 21 (Android 5.0)
- iOS: 12.0

**Firebase SDK Versions**:
- firebase_core: ^2.24.2
- cloud_firestore: ^4.14.0
- firebase_storage: ^11.6.0
- firebase_auth: ^4.16.0
- firebase_messaging: ^14.7.10

### 13.4 Platform-Specific Configuration

**Android Configuration** (android/app/build.gradle):
```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

**Android Permissions** (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<application>
    <!-- FCM -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="order_updates" />
    
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />
</application>
```

**iOS Configuration** (ios/Runner/Info.plist):
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture delivery photos</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to record delivery location</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## 14. Risk Assessment & Mitigation

### 14.1 Technical Risks

**Risk 1: Photo Upload Failures**
- **Impact**: High - Blocks delivery completion
- **Probability**: Medium
- **Mitigation**: 
  - Implement retry mechanism with exponential backoff
  - Allow offline queueing of uploads
  - Provide manual retry option
  - Compress images before upload
  - Show clear error messages

**Risk 2: Location Permission Denial**
- **Impact**: Medium - Delivery location not captured
- **Probability**: Medium
- **Mitigation**:
  - Make location optional but encouraged
  - Provide clear permission rationale
  - Allow delivery completion without location
  - Show permission settings link

**Risk 3: Real-Time Sync Delays**
- **Impact**: Medium - Stale order capacity data
- **Probability**: Low
- **Mitigation**:
  - Implement fallback to cached data
  - Show "last updated" timestamp
  - Manual refresh option
  - Offline mode handling

**Risk 4: Notification Delivery Failures**
- **Impact**: Medium - Users miss important updates
- **Probability**: Medium
- **Mitigation**:
  - Store all notifications in Firestore
  - In-app notification center as backup
  - Retry failed notifications
  - Monitor delivery rates

### 14.2 Business Risks

**Risk 1: Category Mismanagement**
- **Impact**: Medium - Poor product organization
- **Probability**: Low
- **Mitigation**:
  - Validation prevents deletion with products
  - Bulk category reassignment tool
  - Admin training on category management
  - Default "Uncategorized" category

**Risk 2: Incorrect Discount Pricing**
- **Impact**: High - Revenue loss
- **Probability**: Low
- **Mitigation**:
  - Validation: discount < regular price
  - Admin confirmation before saving
  - Audit trail of price changes
  - Discount preview before publishing

**Risk 3: Order Capacity Threshold Misconfiguration**
- **Impact**: High - Lost sales or poor service
- **Probability**: Low
- **Mitigation**:
  - Sensible default values
  - Preview impact before saving
  - Easy adjustment in admin panel
  - Monitor order patterns

### 14.3 User Experience Risks

**Risk 1: Confusing Delivery Charge Rules**
- **Impact**: Medium - Cart abandonment
- **Probability**: Medium
- **Mitigation**:
  - Clear messaging on cart screen
  - Progress indicator for free delivery
  - Tooltip explanations
  - Help section with examples

**Risk 2: Minimum Quantity Confusion**
- **Impact**: Low - User frustration
- **Probability**: Medium
- **Mitigation**:
  - Prominent display on product page
  - Clear error messages
  - Quantity selector starts at minimum
  - Help text explaining requirement

**Risk 3: Notification Fatigue**
- **Impact**: Medium - Users disable notifications
- **Probability**: Medium
- **Mitigation**:
  - Send only important notifications
  - Allow sound customization
  - Notification preferences
  - Respect quiet hours

### 14.4 Security Risks

**Risk 1: Unauthorized Config Changes**
- **Impact**: High - Business disruption
- **Probability**: Low
- **Mitigation**:
  - Admin-only access via Firestore rules
  - Audit trail of changes
  - Change confirmation dialogs
  - Monitor suspicious activity

**Risk 2: Delivery Photo Tampering**
- **Impact**: Medium - Dispute resolution issues
- **Probability**: Low
- **Mitigation**:
  - Immutable storage (no delete)
  - Timestamp in filename
  - Metadata tracking uploader
  - Admin-only upload access

### 14.5 Performance Risks

**Risk 1: Large Photo File Sizes**
- **Impact**: Medium - Slow uploads, high storage costs
- **Probability**: High
- **Mitigation**:
  - Automatic image compression
  - File size validation (max 5MB)
  - Progress indicators
  - Storage quota monitoring

**Risk 2: Excessive Real-Time Listeners**
- **Impact**: Medium - High Firebase costs
- **Probability**: Medium
- **Mitigation**:
  - Dispose listeners properly
  - Use pagination for large lists
  - Cache frequently accessed data
  - Monitor Firebase usage

## 15. Success Criteria

### 15.1 Technical Success Metrics

- Photo upload success rate > 95%
- Location capture success rate > 90%
- Notification delivery rate > 95%
- App crash rate < 0.5%
- API error rate < 2%
- Average photo upload time < 8 seconds
- Config update propagation < 2 seconds

### 15.2 Business Success Metrics

- Average order value increase > 15%
- Discount feature usage > 30% of products
- Category filter usage > 60% of sessions
- Free delivery threshold achievement > 40% of orders
- Customer remarks completion > 50% of delivered orders
- Delivery disputes reduction > 70%
- Order capacity warnings reduce complaints > 50%

### 15.3 User Satisfaction Metrics

- Customer satisfaction score > 4.5/5
- Admin satisfaction with new tools > 4.0/5
- Feature adoption rate > 70% within 1 month
- Support ticket reduction > 30%
- App store rating improvement > 0.3 points

## 16. Future Enhancements

### 16.1 Potential Features (Out of Current Scope)

- **Advanced Analytics Dashboard**: Sales by category, discount effectiveness
- **Customer Rating System**: Star ratings separate from remarks
- **Scheduled Deliveries**: Time slot selection
- **Multi-Admin Support**: Different admin roles and permissions
- **Route Optimization**: Efficient delivery routing
- **Real-Time Tracking**: Live delivery location tracking
- **Loyalty Program**: Points and rewards integration
- **Bulk Operations**: Bulk discount application, category changes
- **Product Recommendations**: AI-based suggestions
- **Inventory Alerts**: Low stock notifications

### 16.2 Technical Improvements

- **Offline Mode**: Full offline functionality with sync
- **Progressive Web App**: Web version of the app
- **GraphQL API**: More efficient data fetching
- **Microservices**: Separate services for different features
- **CDN Integration**: Faster image delivery
- **Advanced Caching**: Redis for frequently accessed data

## 17. Conclusion

This design document provides a comprehensive blueprint for implementing eight key enhancements to the grocery app. The design prioritizes:

1. **Clean Implementation**: Direct implementation of new features with required fields
2. **Security**: Robust authentication, authorization, and validation
3. **Performance**: Efficient queries, caching, and real-time updates
4. **User Experience**: Clear messaging, intuitive interfaces, helpful feedback
5. **Maintainability**: Clean architecture, proper error handling

The implementation assumes all data will be updated with new required fields during initial setup. The design provides a robust, scalable, and user-friendly enhancement to the existing grocery app that meets all requirements while maintaining high quality standards.

