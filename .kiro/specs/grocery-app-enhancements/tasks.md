# Grocery App Enhancements - Implementation Tasks

## Phase 1: Data Models & Core Infrastructure

- [x] 1. Create Category Model
  - Create `lib/models/category.dart` with id, name, description, productCount, createdAt, updatedAt
  - Add toJson/fromJson methods with Firestore Timestamp support
  - Add copyWith method and export in models.dart
  - _Validates: Requirements 2.2.1-2.2.9_

- [x] 2. Create AppConfig Model
  - Create `lib/models/app_config.dart` with deliveryCharge, freeDeliveryThreshold, maxCartValue, orderCapacityWarningThreshold, orderCapacityBlockThreshold, updatedAt, updatedBy
  - Add toJson/fromJson, copyWith, and default values factory constructor
  - Export in models.dart
  - _Validates: Requirements 2.6.1-2.6.11, 2.7.1-2.7.9_

- [x] 3. Extend Product Model
  - Add discountPrice (nullable), categoryId (required), minimumOrderQuantity (required, default 1)
  - Update toJson/fromJson and copyWith methods
  - Add helper methods: getEffectivePrice(), calculateSavings(), getDiscountPercentage()
  - _Validates: Requirements 2.1.1-2.1.7, 2.2.4, 2.4.1-2.4.7_

- [x] 4. Extend Order Model
  - Add deliveryPhotoUrl, deliveryLocation (GeoPoint), customerRemarks, remarksTimestamp, deliveryCharge
  - Update toJson/fromJson and copyWith methods
  - _Validates: Requirements 2.3.1-2.3.8, 2.8.1-2.8.7_

## Phase 2: Service Layer Implementation

- [x] 5. Create CategoryService
  - Create `lib/services/category_service.dart` with Firestore integration
  - Implement getCategories(), watchCategories(), createCategory() with unique name validation
  - Implement updateCategory(), deleteCategory() with product count validation
  - Implement getProductCount(), incrementProductCount(), decrementProductCount()
  - Add error handling with custom exceptions
  - _Validates: Requirements 2.2.1-2.2.9_

- [x] 6. Create ConfigService
  - Create `lib/services/config_service.dart` with singleton pattern
  - Implement getConfig() with caching, watchConfig() stream, updateConfig() (admin only)
  - Implement helper methods: calculateDeliveryCharge(), isCartValueValid(), getOrderCapacityStatus()
  - Add initializeDefaultConfig() and dispose() methods
  - _Validates: Requirements 2.6.1-2.6.11, 2.7.1-2.7.9_

- [x] 7. Extend ProductService
  - Add setDiscount() with validation (discountPrice < price), removeDiscount()
  - Add updateProductCategory() with batch operations, getProductsByCategory() with pagination
  - Add setMinimumQuantity() with validation (>= 1)
  - Update createProduct() and updateProduct() to handle new fields
  - Add validation methods for discount and minimum quantity
  - _Validates: Requirements 2.1.1-2.1.7, 2.2.4, 2.4.1-2.4.7_

- [x] 8. Extend OrderService
  - Add uploadDeliveryPhoto() using Firebase Storage, captureDeliveryLocation() with GeoPoint
  - Add completeDelivery() combining photo and location
  - Add addCustomerRemarks() with character limit, updateCustomerRemarks() with 24-hour check
  - Add canEditRemarks() validation, getPendingOrderCount(), watchPendingOrderCount() stream
  - Update createOrder() to include deliveryCharge
  - _Validates: Requirements 2.3.1-2.3.8, 2.8.1-2.8.7, 2.7.1-2.7.9_

- [x] 9. Extend NotificationService
  - Add initializeFCM(), getFCMToken(), requestPermissions()
  - Add sendPushNotification() for individual users, sendBulkNotification() for all customers
  - Add playNotificationSound() using audioplayers, setNotificationSoundEnabled(), isNotificationSoundEnabled()
  - Add setupBackgroundHandlers(), handleBackgroundMessage(), handleForegroundMessage()
  - _Validates: Requirements 2.5.1-2.5.10_

## Phase 3: Provider Layer Implementation

- [x] 10. Create CategoryProvider
  - Create `lib/providers/category_provider.dart` extending ChangeNotifier
  - Add state fields: categories list, selectedCategory, isLoading
  - Implement loadCategories(), createCategory(), updateCategory(), deleteCategory() with validation
  - Implement selectCategory() for filtering, add real-time listener, add dispose()
  - _Validates: Requirements 2.2.1-2.2.9_

- [x] 11. Extend CartProvider
  - Inject ConfigService dependency
  - Add computed properties: deliveryCharge, totalWithDelivery, isFreeDeliveryEligible, amountForFreeDelivery, isCartValueValid, cartValueError
  - Add validateMinimumQuantity(), getCartValidationErrors()
  - Update addToCart() to enforce minimum quantity
  - _Validates: Requirements 2.1.5, 2.4.3-2.4.7, 2.6.1-2.6.8_

- [x] 12. Extend OrderProvider
  - Add pendingOrderCount state field
  - Add computed properties: capacityStatus, canPlaceOrder, capacityWarning
  - Implement uploadDeliveryProof(), addRemarks(), startWatchingPendingCount()
  - Add StreamSubscription management, update dispose() to cancel subscriptions
  - _Validates: Requirements 2.7.1-2.7.9, 2.8.1-2.8.7_

## Phase 4: UI Implementation - Admin Screens

- [x] 13. Create Category Management Screen
  - Create `lib/screens/admin/category_management_screen.dart`
  - Display category list with product counts, alphabetical sorting
  - Add "Create Category" button and dialog, edit dialog, delete confirmation with validation
  - Add loading and error states, navigation from admin dashboard
  - _Validates: Requirements 2.2.1-2.2.9_

- [x] 14. Extend Product Form Screen
  - Add category dropdown selector, discount price input with validation
  - Add discount percentage display, minimum order quantity input
  - Add validation for discountPrice < price and minimumOrderQuantity >= 1
  - Update form submission to include new fields, add visual indicators for discount status
  - _Validates: Requirements 2.1.1-2.1.7, 2.2.4, 2.4.1-2.4.7_

- [x] 15. Extend Order Management Screen
  - Add pending order count display on dashboard
  - Create delivery completion dialog with camera capture and GPS location
  - Add photo preview, upload progress indicator, error handling
  - Update order status after successful delivery proof
  - _Validates: Requirements 2.3.1-2.3.8, 2.7.8_

- [x] 16. Extend Admin Order Detail Screen
  - Add delivery photo display section, map view for delivery location (optional)
  - Add customer remarks display section, delivery timestamp
  - Handle cases where delivery proof is not available
  - _Validates: Requirements 2.3.4, 2.8.4_

- [x] 17. Create App Configuration Screen
  - Create `lib/screens/admin/app_config_screen.dart`
  - Add input fields for: delivery charge, free delivery threshold, max cart value, order capacity thresholds
  - Add validation for all fields, save confirmation dialog
  - Display last updated info, add navigation from admin dashboard
  - _Validates: Requirements 2.6.9-2.6.11, 2.7.9_

## Phase 5: UI Implementation - Customer Screens

- [x] 18. Extend Home Screen
  - Add horizontal category filter chips with "All" option
  - Implement category selection and filtering
  - Update product cards to show discount pricing with strikethrough
  - Add discount percentage badge, category label, use effective price
  - _Validates: Requirements 2.2.5, 2.1.3-2.1.4_

- [x] 19. Extend Product Detail Screen
  - Add discount pricing display with savings calculation
  - Add prominent minimum order quantity display
  - Update quantity selector to start at minimum quantity
  - Add validation to prevent quantity < minimum, disable "Add to Cart" when invalid
  - Add category information display
  - _Validates: Requirements 2.1.3-2.1.4, 2.4.4-2.4.7_

- [x] 20. Extend Cart Screen
  - Add delivery charge section with current charge, free delivery progress indicator
  - Add "Add ₹X more for free delivery" message
  - Add cart value validation with max limit, warning/error banners
  - Add order capacity warning banner (when pending >= 2)
  - Add minimum quantity validation errors, disable checkout when invalid
  - _Validates: Requirements 2.6.1-2.6.8, 2.7.2-2.7.6, 2.4.5_

- [x] 21. Extend Checkout Screen
  - Add order summary with subtotal, delivery charge line item (strikethrough if free), total
  - Add savings from discounts display
  - Add no-return policy checkbox (first order only), link to terms, verification explanation
  - Add order capacity check before placement, block if pending >= 10
  - Add clear error messages for validation failures
  - _Validates: Requirements 2.6.7-2.6.8, 2.7.2-2.7.3, 2.9.1-2.9.7_

- [x] 22. Extend Order Detail Screen (Customer)
  - Add delivery photo display section, delivery location display (with optional map)
  - Add customer remarks input section with 500 character limit and counter
  - Add edit button (available for 24 hours), remarks timestamp
  - Add placeholder encouraging feedback, implement remarks submission
  - Disable editing after 24 hours
  - _Validates: Requirements 2.3.4, 2.8.1-2.8.7_

## Phase 6: Dependencies & Configuration

- [x] 23. Add Required Dependencies
  - Add to pubspec.yaml: geolocator ^10.1.0, firebase_messaging ^14.7.10, flutter_local_notifications ^16.3.0
  - Add audioplayers ^5.2.1, flutter_image_compress ^2.1.0, shared_preferences ^2.2.2, path_provider ^2.1.2
  - Run flutter pub get
  - _Validates: All features_

- [x] 24. Configure Android Permissions
  - Add to AndroidManifest.xml: CAMERA, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, POST_NOTIFICATIONS
  - Add FCM metadata for default notification channel and icon
  - _Validates: Requirements 2.3.1-2.3.8, 2.5.1-2.5.10_

- [x] 25. Configure iOS Permissions
  - Add to Info.plist: NSCameraUsageDescription, NSLocationWhenInUseUsageDescription
  - Add UIBackgroundModes for remote-notification
  - Configure APNs in Firebase Console, upload APNs certificate
  - _Validates: Requirements 2.3.1-2.3.8, 2.5.1-2.5.10_

- [x] 26. Add Notification Sound Asset
  - Create assets/sounds/ directory, add notification.mp3 sound file
  - Update pubspec.yaml to include sound asset
  - Verify sound file is accessible
  - _Validates: Requirements 2.5.5-2.5.8_

## Phase 7: Firebase Configuration

- [x] 27. Create Firestore Indexes
  - Create composite index: products (categoryId ASC, isActive ASC, name ASC)
  - Create single field index: categories (name ASC)
  - Create index for pending order count query
  - Verify indexes in Firebase Console
  - _Validates: All features_

- [x] 28. Update Firestore Security Rules
  - Add rules for categories collection (admin write, authenticated read)
  - Add rules for config/app_settings document (admin write, authenticated read)
  - Update products and orders collection rules for new fields
  - Add validation rules for discount pricing, minimum quantity, config values
  - Deploy security rules using Firebase CLI
  - _Validates: All features_

- [x] 29. Update Firebase Storage Rules
  - Add rules for delivery_photos/ path (admin write, authenticated read)
  - Add file size validation (max 5MB), file type validation (images only)
  - Prevent deletion of delivery photos
  - Deploy storage rules using Firebase CLI
  - _Validates: Requirements 2.3.1-2.3.8_

- [x] 30. Initialize Default Data
  - Create config/app_settings document with default values
  - Create at least one default category (e.g., "Groceries")
  - Verify default data in Firebase Console
  - _Validates: Requirements 2.2.9, 2.6.1-2.6.11_

##
## Phase 9: Documentation & Deployment

- [x] 35. Update Documentation
  - Update README with new features
  - Create admin user guides for category management, app configuration, delivery proof capture
  - Update customer user guide, document Firebase setup requirements
  - Create deployment checklist
  - _Validates: All features_

- [x] 36. Pre-Deployment Validation
  - Verify all Firestore indexes are created, security rules are deployed
  - Verify default config document and at least one category exists
  - Test FCM on real Android and iOS devices
  - Test camera and location permissions on both platforms
  - Test notification sound playback, verify all admin features accessible
  - _Validates: All features_

- [x] 37. Performance Optimization
  - Implement image compression for delivery photos
  - Add caching for AppConfig and categories
  - Optimize pending order count queries, add pagination for product lists
  - Optimize real-time listeners, test app performance with large datasets
  - _Validates: Non-functional requirements_

- [x] 38. Error Handling & Monitoring
  - Add error handling for photo upload, location permission denial, FCM failures, config load failures
  - Add Firebase Crashlytics logging for critical errors
  - Add Analytics events for feature usage, test offline scenarios
  - _Validates: Non-functional requirements_

## Phase 10: Final Polish

- [x] 39. UI/UX Refinements
  - Add loading states for all async operations
  - Add empty states for category list and filtered products
  - Improve error messages for user clarity, add tooltips for configuration fields
  - Add confirmation dialogs for destructive actions
  - Ensure consistent styling across new screens, test accessibility features
  - _Validates: Non-functional requirements_

- [x] 40. Final Testing & Release
  - Perform full regression testing, test all user flows end-to-end
  - Verify all requirements are met, test on multiple device sizes
  - Test on different Android and iOS versions
  - Create release notes, deploy to production
  - Monitor for errors post-deployment, gather user feedback
  - _Validates: All features_
