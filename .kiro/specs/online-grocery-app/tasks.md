# Implementation Plan

- [-] 1. Project Setup and Firebase Configuration
- [x] 1.1 Initialize Flutter project with required dependencies
  - Add Firebase SDK packages (firebase_core, cloud_firestore, firebase_auth, firebase_storage)
  - Add state management package (provider or riverpod)
  - Add UI packages (cached_network_image, image_picker, image)
  - Add utility packages (uuid, intl for formatting)
  - Configure pubspec.yaml with all dependencies
  - _Validates: Requirement 14, Acceptance Criteria 14.1, 14.2_

- [ ] 1.2 Set up Firebase project and configure Flutter app
  - Create Firebase project in Firebase Console with name "kirana-grocery-app"
  - Navigate to Authentication > Sign-in method and enable Phone authentication
  - Configure reCAPTCHA settings for phone auth
  - Navigate to Firestore Database and create database in production mode
  - Select region closest to target users (e.g., asia-south1 for India)
  - Navigate to Storage and create default storage bucket
  - Configure Storage rules to allow authenticated writes to /products/ path
  - For Android: Download google-services.json and place in android/app/
  - For iOS: Download GoogleService-Info.plist and place in ios/Runner/
  - Add FlutterFire CLI configuration: `flutterfire configure`
  - Initialize Firebase in main.dart with `Firebase.initializeApp()`
  - Enable Firestore offline persistence in initialization
  - Test Firebase connection with a simple read/write operation
  - _Validates: Requirement 14, Acceptance Criteria 14.1_

- [ ] 1.3 Deploy Firebase Security Rules
  - Implement Firestore security rules from design document
  - Deploy rules to Firebase
  - Test rules with Firebase Emulator
  - _Validates: Requirement 11, Acceptance Criteria 11.3_

- [ ] 1.4 Create project folder structure
  - Create folders: models/, services/, providers/, screens/, widgets/, utils/
  - Set up constants file for app-wide constants
  - Create theme configuration
  - _Validates: Requirement 14, Acceptance Criteria 14.2_

- [ ] 2. Data Models and Serialization
- [ ] 2.1 Implement core data models
  - Create Customer model with toJson/fromJson
  - Create Address model with toJson/fromJson
  - Create Product model with toJson/fromJson
  - Create Cart and CartItem models with toJson/fromJson
  - Create Order and OrderItem models with toJson/fromJson
  - Create Admin model with toJson/fromJson
  - _Validates: Requirement 1, Acceptance Criteria 1.1; Requirement 2, Acceptance Criteria 2.1_

- [ ]* 2.2 Write property test for data model serialization
  - **Property: Serialization round trip**
  - **Validates: Data integrity across all models**
  - Generate random model instances, serialize to JSON, deserialize back, verify equality

- [ ] 3. Authentication Service and UI
- [ ] 3.1 Implement Authentication Service
  - Create AuthService class with Firebase Auth integration
  - Implement phone number registration
  - Implement OTP sending with rate limiting (3 per hour)
  - Implement OTP verification with bcrypt hashing
  - Implement session management
  - Implement logout functionality
  - _Validates: Requirement 7, Acceptance Criteria 7.1, 7.2, 7.3, 7.4, 7.7_

- [ ]* 3.2 Write property test for OTP rate limiting
  - **Property 30: OTP rate limiting enforced**
  - **Validates: Requirement 7, Acceptance Criteria 7.3**

- [ ] 3.3 Create authentication UI screens
  - Create Login/Registration screen with phone input
  - Create OTP verification screen with 4-digit input
  - Implement loading states and error handling
  - Add resend OTP functionality with countdown timer
  - _Validates: Requirement 7, Acceptance Criteria 7.2, 7.4_

- [ ]* 3.4 Write property test for authentication flow
  - **Property 31: Valid verification code authenticates user**
  - **Validates: Requirement 7, Acceptance Criteria 7.4**

- [ ] 3.5 Implement AuthProvider for state management
  - Create AuthProvider with user state
  - Implement authentication state listeners
  - Handle admin vs customer routing
  - _Validates: Requirement 7, Acceptance Criteria 7.4; Requirement 8, Acceptance Criteria 8.1_

- [ ] 4. Product Service and Browsing UI
- [ ] 4.1 Implement Product Service
  - Create ProductService class with Firestore integration
  - Implement getProducts with category and search filters
  - Implement getProductById
  - Implement checkStockAvailability
  - Implement getCategories
  - Add search keyword generation for products
  - _Validates: Requirement 1, Acceptance Criteria 1.1, 1.2, 1.3, 1.5_

- [ ]* 4.2 Write property test for search functionality
  - **Property 2: Search returns only matching items**
  - **Validates: Requirement 1, Acceptance Criteria 1.2**

- [ ]* 4.3 Write property test for category filtering
  - **Property 4: Category filter returns only matching items**
  - **Validates: Requirement 1, Acceptance Criteria 1.5**

- [ ] 4.4 Create product browsing UI
  - Create Home screen with product grid
  - Implement search bar with real-time filtering
  - Implement category chips for filtering
  - Add product card widget with image, name, price, stock status
  - Implement pagination (20 items per page)
  - Add loading states and empty states
  - _Validates: Requirement 1, Acceptance Criteria 1.1, 1.2, 1.5_

- [ ]* 4.5 Write property test for product display
  - **Property 1: Product listing displays all required fields**
  - **Validates: Requirement 1, Acceptance Criteria 1.1**

- [ ] 4.6 Create product detail screen
  - Display product image, name, description, price, unit size, stock
  - Add quantity selector (+ / - buttons)
  - Add "Add to Cart" button
  - Handle out-of-stock state
  - _Validates: Requirement 1, Acceptance Criteria 1.3, 1.4_

- [ ]* 4.7 Write property test for product details
  - **Property 3: Product details contain complete information**
  - **Validates: Requirement 1, Acceptance Criteria 1.3**

- [ ] 4.8 Implement ProductProvider for state management
  - Create ProductProvider with product list state
  - Implement search and filter state
  - Add real-time Firestore listeners
  - _Validates: Requirement 1, Acceptance Criteria 1.1, 1.2_

- [ ] 5. Address Management
- [ ] 5.1 Implement Address Service
  - Create AddressService class with Firestore integration
  - Implement addAddress
  - Implement getCustomerAddresses
  - Implement getAddressById
  - Implement updateAddress
  - Implement deleteAddress (with order check)
  - Implement setDefaultAddress
  - Implement getDefaultAddress
  - _Validates: Requirement 4A, Acceptance Criteria 4A.1, 4A.2, 4A.3, 4A.4, 4A.5_

- [ ]* 5.2 Write property test for address creation
  - **Property 17: Address creation stores all fields**
  - **Validates: Requirement 4A, Acceptance Criteria 4A.1**

- [ ]* 5.3 Write property test for default address
  - **Property 19: Default address is set correctly**
  - **Validates: Requirement 4A, Acceptance Criteria 4A.3**

- [ ] 5.4 Create address management UI
  - Create Address List screen showing all saved addresses
  - Create Add/Edit Address form with validation
  - Add default address toggle
  - Implement address deletion with confirmation
  - _Validates: Requirement 4A, Acceptance Criteria 4A.1, 4A.2, 4A.3, 4A.4, 4A.5_

- [ ] 5.5 Implement AddressProvider for state management
  - Create AddressProvider with address list state
  - Add real-time Firestore listeners
  - _Validates: Requirement 4A, Acceptance Criteria 4A.2_

- [ ] 6. Shopping Cart
- [ ] 6.1 Implement Cart Service
  - Create CartService class with Firestore integration
  - Implement addToCart with stock validation
  - Implement removeFromCart
  - Implement updateQuantity with stock validation
  - Implement getCart
  - Implement validateCartStock
  - Implement calculateTotal
  - Enable Firestore offline persistence for cart
  - _Validates: Requirement 2, Acceptance Criteria 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ]* 6.2 Write property test for add to cart
  - **Property 5: Add to cart preserves item and quantity**
  - **Validates: Requirement 2, Acceptance Criteria 2.1**

- [ ]* 6.3 Write property test for quantity updates
  - **Property 7: Quantity update recalculates total correctly**
  - **Validates: Requirement 2, Acceptance Criteria 2.4**

- [ ]* 6.4 Write property test for item removal
  - **Property 8: Item removal updates cart correctly**
  - **Validates: Requirement 2, Acceptance Criteria 2.5**

- [ ]* 6.5 Write property test for cart persistence
  - **Property 9: Cart persists across sessions**
  - **Validates: Requirement 2, Acceptance Criteria 2.6**

- [ ] 6.6 Create cart UI screen
  - Create Cart screen with list of cart items
  - Add quantity controls for each item
  - Add remove item button
  - Display subtotal, delivery fee, and total
  - Add "Proceed to Checkout" button
  - Handle empty cart state
  - _Validates: Requirement 2, Acceptance Criteria 2.3, 2.4, 2.5_

- [ ]* 6.7 Write property test for cart display
  - **Property 6: Cart display shows complete information**
  - **Validates: Requirement 2, Acceptance Criteria 2.3**

- [ ] 6.8 Implement CartProvider for state management
  - Create CartProvider with cart state
  - Add real-time Firestore listeners
  - Implement cart badge count
  - _Validates: Requirement 2, Acceptance Criteria 2.3_

- [ ] 7. Order Placement and Management
- [ ] 7.1 Implement Order Service
  - Create OrderService class with Firestore integration
  - Implement createOrder with Firestore transaction (stock deduction + order creation)
  - Implement getCustomerOrders
  - Implement getOrderById
  - Implement updateOrderStatus
  - Implement cancelOrder with stock restoration
  - _Validates: Requirement 3, Acceptance Criteria 3.2, 3.3, 3.4; Requirement 4, Acceptance Criteria 4.1, 4.2, 4.4_

- [ ]* 7.2 Write property test for order creation
  - **Property 10: Order creation transfers all cart data**
  - **Validates: Requirement 3, Acceptance Criteria 3.2**

- [ ]* 7.3 Write property test for stock reduction
  - **Property 11: Order creation reduces stock quantities**
  - **Validates: Requirement 3, Acceptance Criteria 3.3**

- [ ]* 7.4 Write property test for cart clearing
  - **Property 12: Order confirmation clears cart**
  - **Validates: Requirement 3, Acceptance Criteria 3.4**

- [ ]* 7.5 Write property test for order cancellation
  - **Property 16: Order cancellation restores stock**
  - **Validates: Requirement 4, Acceptance Criteria 4.4**

- [ ]* 7.6 Write property test for failed transactions
  - **Property 41: Failed transactions don't modify stock**
  - **Validates: Requirement 10, Acceptance Criteria 10.2**

- [ ] 7.7 Create checkout UI screen
  - Create Checkout screen with address selection
  - Display all saved addresses with radio buttons
  - Add "Add New Address" option
  - Display order summary with items and total
  - Show payment method (COD only)
  - Add "Place Order" button
  - _Validates: Requirement 3, Acceptance Criteria 3.1; Requirement 4A, Acceptance Criteria 4A.6_

- [ ] 7.8 Create order confirmation screen
  - Display success message with order ID
  - Show order total and payment method
  - Add "View Order Details" button
  - Add "Continue Shopping" button
  - _Validates: Requirement 3, Acceptance Criteria 3.4_

- [ ] 7.9 Create order history UI
  - Create Order History screen with list of orders
  - Display order ID, date, status, total for each order
  - Add status badges with colors
  - Implement order detail view
  - Add cancel order button for eligible orders
  - _Validates: Requirement 4, Acceptance Criteria 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ]* 7.10 Write property test for order history display
  - **Property 13: Order history displays required fields**
  - **Validates: Requirement 4, Acceptance Criteria 4.1**

- [ ]* 7.11 Write property test for status updates
  - **Property 15: Status changes are reflected in order history**
  - **Validates: Requirement 4, Acceptance Criteria 4.3**

- [ ] 7.12 Implement OrderProvider for state management
  - Create OrderProvider with order list state
  - Add real-time Firestore listeners for order updates
  - _Validates: Requirement 4, Acceptance Criteria 4.3_

- [ ] 8. Checkpoint - Ensure all customer-facing features work
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Admin - Inventory Management
- [ ] 9.1 Implement Admin Service for inventory
  - Create AdminService class with Firestore integration
  - Implement addProduct
  - Implement updateProduct
  - Implement deleteProduct (soft delete - set isActive to false)
  - Implement updateStock
  - Implement getLowStockProducts
  - _Validates: Requirement 5, Acceptance Criteria 5.1, 5.4, 5.5, 5.6, 5.7_

- [ ]* 9.2 Write property test for product creation
  - **Property 22: Product creation stores all fields**
  - **Validates: Requirement 5, Acceptance Criteria 5.1**

- [ ]* 9.3 Write property test for product updates
  - **Property 25: Product updates persist changes**
  - **Validates: Requirement 5, Acceptance Criteria 5.4**

- [ ]* 9.4 Write property test for stock updates
  - **Property 26: Stock updates persist new quantity**
  - **Validates: Requirement 5, Acceptance Criteria 5.5**

- [ ]* 9.5 Write property test for product deletion
  - **Property 27: Deleted products don't appear in searches**
  - **Validates: Requirement 5, Acceptance Criteria 5.6**

- [ ] 9.6 Implement image upload functionality
  - Add image picker for product images
  - Implement image compression (max 800x800px, <500KB)
  - Upload to Firebase Storage
  - Store download URL in product document
  - _Validates: Requirement 5, Acceptance Criteria 5.2, 5.3_

- [ ]* 9.7 Write property test for image upload
  - **Property 23: Image upload accepts valid formats**
  - **Validates: Requirement 5, Acceptance Criteria 5.2**

- [ ] 9.8 Create admin dashboard UI
  - Create Admin Dashboard screen with quick stats
  - Display total products, today's orders, low stock count
  - Add navigation to inventory and order management
  - Show recent orders list
  - _Validates: Requirement 5, Acceptance Criteria 5.7; Requirement 6, Acceptance Criteria 6.1_

- [ ] 9.9 Create inventory management UI
  - Create Inventory List screen with product grid
  - Add search and filter functionality
  - Add "Add Product" button
  - Display stock levels with low stock indicators
  - Add edit and delete buttons for each product
  - _Validates: Requirement 5, Acceptance Criteria 5.7_

- [ ]* 9.10 Write property test for inventory display
  - **Property 28: Inventory display shows all items and stock**
  - **Validates: Requirement 5, Acceptance Criteria 5.7**

- [ ] 9.11 Create add/edit product form
  - Create Product Form screen with all fields
  - Add image upload with preview
  - Implement form validation
  - Add save button with loading state
  - _Validates: Requirement 5, Acceptance Criteria 5.1, 5.2, 5.3, 5.4_

- [ ] 9.12 Implement AdminProvider for state management
  - Create AdminProvider with inventory state
  - Add real-time Firestore listeners
  - _Validates: Requirement 5, Acceptance Criteria 5.7_

- [ ] 10. Admin - Order Management
- [ ] 10.1 Implement Admin Service for orders
  - Extend AdminService with order management methods
  - Implement getAllOrders with status filter
  - Implement updateOrderStatus with notification creation
  - _Validates: Requirement 6, Acceptance Criteria 6.1, 6.2, 6.4_

- [ ]* 10.2 Write property test for order filtering
  - **Property 30: Order status filter returns only matching orders**
  - **Validates: Requirement 6, Acceptance Criteria 6.2**

- [ ]* 10.3 Write property test for status updates
  - **Property 32: Order status updates persist and notify**
  - **Validates: Requirement 6, Acceptance Criteria 6.4**

- [ ] 10.4 Create order management UI
  - Create Order Management screen with order list
  - Add status filter chips
  - Display customer details, order date, status, total
  - Add "View Details" button for each order
  - _Validates: Requirement 6, Acceptance Criteria 6.1, 6.2_

- [ ]* 10.5 Write property test for order management display
  - **Property 29: Order management displays all required fields**
  - **Validates: Requirement 6, Acceptance Criteria 6.1**

- [ ] 10.6 Create admin order detail screen
  - Display complete order information
  - Show customer details and delivery address
  - List all order items with quantities and prices
  - Add status update dropdown
  - Add "Update Status" button
  - _Validates: Requirement 6, Acceptance Criteria 6.3, 6.4, 6.5_

- [ ]* 10.7 Write property test for admin order details
  - **Property 31: Admin order details contain complete information**
  - **Validates: Requirement 6, Acceptance Criteria 6.3**

- [ ] 11. Notification System
- [ ] 11.1 Implement Notification Service
  - Create NotificationService class with Firestore integration
  - Implement createNotification method
  - Implement getCustomerNotifications method
  - Implement markAsRead method
  - Implement deleteOldNotifications method (>30 days)
  - _Validates: Requirement 6, Acceptance Criteria 6.4_

- [ ] 11.2 Integrate notifications with order status updates
  - Modify OrderService.updateOrderStatus to call NotificationService.createNotification
  - Create notification when status changes to: Confirmed, Preparing, Out for Delivery, Delivered
  - Include order ID, new status, and customer-friendly message in notification
  - Ensure notification is created in same transaction as status update
  - _Validates: Requirement 6, Acceptance Criteria 6.4_

- [ ]* 11.3 Write property test for notification creation
  - **Property 32: Order status updates persist and notify**
  - **Validates: Requirement 6, Acceptance Criteria 6.4**
  - Generate random orders, update status, verify notification created with correct details

- [ ] 11.4 Create notification UI
  - Add notification bell icon in app bar with unread count badge
  - Create Notifications screen with list of notifications
  - Display notification title, message, timestamp
  - Add mark as read functionality
  - Add tap to navigate to order details
  - _Validates: Requirement 6, Acceptance Criteria 6.4_

- [ ] 11.5 Implement NotificationProvider for state management
  - Create NotificationProvider with notification list state
  - Add real-time Firestore listeners for new notifications
  - Update unread badge count automatically
  - _Validates: Requirement 6, Acceptance Criteria 6.4_

- [ ] 12. Profile Management
- [ ] 12.1 Implement profile update functionality
  - Add updateProfile method to AuthService
  - Implement name and default address update
  - Add validation
  - _Validates: Requirement 7, Acceptance Criteria 7.6_

- [ ]* 12.2 Write property test for profile updates
  - **Property 37: Profile updates persist changes**
  - **Validates: Requirement 7, Acceptance Criteria 7.6**

- [ ] 12.3 Create profile UI screen
  - Create Profile screen with user information
  - Add edit name functionality
  - Add manage addresses button
  - Add order history button
  - Add logout button
  - _Validates: Requirement 7, Acceptance Criteria 7.6, 7.7_

- [ ]* 12.4 Write property test for logout
  - **Property 38: Logout clears session**
  - **Validates: Requirement 7, Acceptance Criteria 7.7**

- [ ] 13. Security Implementation
- [ ] 13.1 Implement data encryption
  - Create EncryptionService with AES-256-GCM
  - Encrypt phone numbers before storage
  - Encrypt addresses before storage
  - Decrypt on retrieval
  - _Validates: Requirement 11, Acceptance Criteria 11.2_

- [ ]* 13.2 Write property test for encryption
  - **Property 43: Sensitive data is encrypted at rest**
  - **Validates: Requirement 11, Acceptance Criteria 11.2**

- [ ] 13.3 Implement OTP hashing
  - Use bcrypt with cost factor 12 for OTP codes
  - Hash before storage
  - Verify hash on authentication
  - _Validates: Requirement 11, Acceptance Criteria 11.5_

- [ ]* 13.4 Write property test for OTP hashing
  - **Property 46: Verification codes are hashed**
  - **Validates: Requirement 11, Acceptance Criteria 11.5**

- [ ] 13.5 Implement audit logging
  - Create AuditService for logging admin actions
  - Log all admin data access
  - Log all admin modifications
  - _Validates: Requirement 11, Acceptance Criteria 11.4_

- [ ]* 13.6 Write property test for audit logging
  - **Property 45: Admin data access is logged**
  - **Validates: Requirement 11, Acceptance Criteria 11.4**

- [ ] 13.7 Implement authorization checks
  - Add isAdmin check middleware
  - Verify user can only access own data
  - Add authorization error handling
  - _Validates: Requirement 8, Acceptance Criteria 8.2; Requirement 11, Acceptance Criteria 11.3_

- [ ]* 13.8 Write property test for data isolation
  - **Property 44: Users can only access their own data**
  - **Validates: Requirement 11, Acceptance Criteria 11.3**

- [ ] 14. Error Handling and Logging
- [ ] 14.1 Implement global error handling
  - Create ErrorService for centralized error handling
  - Implement error logging to Firestore
  - Add user-friendly error messages
  - Implement retry logic for transient failures
  - _Validates: Requirement 10, Acceptance Criteria 10.4_

- [ ]* 14.2 Write property test for error logging
  - **Property 42: Errors are logged with details**
  - **Validates: Requirement 10, Acceptance Criteria 10.4**

- [ ] 14.3 Add error UI components
  - Create error dialog widget
  - Create error snackbar widget
  - Add retry buttons where appropriate
  - _Validates: Requirement 10, Acceptance Criteria 10.4_

- [ ] 15. Navigation and Routing
- [ ] 15.1 Implement app navigation
  - Set up named routes
  - Implement role-based routing (customer vs admin)
  - Add bottom navigation bar for customer
  - Add drawer navigation for admin
  - Handle deep linking for order details
  - _Validates: Requirement 7, Acceptance Criteria 7.4; Requirement 8, Acceptance Criteria 8.1_

- [ ] 15.2 Implement authentication guards
  - Add route guards for protected screens
  - Redirect to login if not authenticated
  - Redirect to appropriate home based on role
  - _Validates: Requirement 7, Acceptance Criteria 7.7; Requirement 8, Acceptance Criteria 8.1_

- [ ] 16. Analytics and Monitoring
- [ ] 16.1 Implement Firebase Analytics
  - Add Firebase Analytics package
  - Log key events (product_view, add_to_cart, order_placed, etc.)
  - Set user properties (isAdmin, customerSince)
  - _Validates: Requirement 9, Acceptance Criteria 9.1, 9.2, 9.3_

- [ ] 16.2 Implement Firebase Crashlytics
  - Add Firebase Crashlytics package
  - Configure crash reporting
  - Add custom crash keys for debugging
  - _Validates: Requirement 10, Acceptance Criteria 10.1_

- [ ] 16.3 Implement Firebase Performance Monitoring
  - Add Firebase Performance package
  - Add custom traces for key operations
  - Monitor network requests
  - _Validates: Requirement 9, Acceptance Criteria 9.1, 9.2, 9.3_

- [ ] 17. Testing and Quality Assurance
- [ ]* 17.1 Write remaining property-based tests
  - Implement all property tests marked in previous tasks
  - Configure each test to run 100 iterations
  - Add proper test annotations with property numbers
  - _Validates: All correctness properties_

- [ ]* 17.2 Write integration tests
  - Test complete order placement flow
  - Test admin inventory management flow
  - Test authentication flow
  - Test cart persistence
  - _Validates: Requirements 1-7_

- [ ]* 17.3 Write widget tests
  - Test product list rendering
  - Test cart updates
  - Test order confirmation display
  - Test admin dashboard
  - _Validates: Requirements 1-6_

- [ ] 18. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 19. Documentation and Deployment Preparation
- [ ] 19.1 Create user documentation
  - Write customer user guide
  - Write admin user guide
  - Document common troubleshooting steps
  - _Validates: All requirements_

- [ ] 19.2 Prepare for deployment
  - Configure Firebase for production
  - Set up Firebase backup schedule
  - Configure monitoring alerts
  - Create deployment checklist
  - _Validates: Requirement 14, Acceptance Criteria 14.1, 14.2_

- [ ] 19.3 Create initial admin account
  - Follow initial setup guide from design document
  - Create first admin user in Firebase Console
  - Verify admin access works
  - _Validates: Requirement 8, Acceptance Criteria 8.1_
