# Analytics and Monitoring Implementation

This document describes the analytics and monitoring implementation for the Kirana Online Grocery Application.

## Overview

The application now includes comprehensive analytics and monitoring capabilities using Firebase services:
- **Firebase Analytics** - Track user behavior and app usage
- **Firebase Crashlytics** - Monitor crashes and errors
- **Firebase Performance Monitoring** - Track app performance metrics

## Firebase Analytics

### Implementation

**Service**: `lib/services/analytics_service.dart`

The AnalyticsService provides methods to track:

#### User Properties
- `setUserIsAdmin(bool)` - Track admin vs customer users
- `setUserCustomerSince(DateTime)` - Track customer tenure
- `setUserId(String)` - Set user identifier
- `clearUserId()` - Clear user identifier on logout

#### Product Events
- `logProductView()` - Track product detail views
- `logProductSearch()` - Track search queries
- `logCategoryFilter()` - Track category filtering

#### Cart Events
- `logAddToCart()` - Track items added to cart
- `logRemoveFromCart()` - Track items removed from cart
- `logViewCart()` - Track cart views

#### Checkout Events
- `logBeginCheckout()` - Track checkout initiation
- `logAddressSelected()` - Track address selection

#### Order Events
- `logOrderPlaced()` - Track completed orders
- `logOrderCancelled()` - Track cancelled orders
- `logOrderStatusView()` - Track order status views

#### Authentication Events
- `logLogin()` - Track user logins
- `logSignUp()` - Track new user registrations

#### Admin Events
- `logAdminProductAdded()` - Track product additions
- `logAdminProductUpdated()` - Track product updates
- `logAdminStockUpdated()` - Track stock updates
- `logAdminOrderStatusUpdated()` - Track order status changes

#### Screen Views
- `logScreenView()` - Track screen navigation
- Automatically tracked via `FirebaseAnalyticsObserver` in navigation

### Integration

Analytics is integrated in:
- **main.dart** - Analytics observer added to MaterialApp
- **AuthProvider** - User properties set on login, cleared on logout
- Ready for integration in other providers (ProductProvider, CartProvider, OrderProvider, etc.)

### Usage Example

```dart
// In a provider or service
final analytics = AnalyticsService();

// Track product view
await analytics.logProductView(
  productId: product.id,
  productName: product.name,
  category: product.category,
  price: product.price,
);

// Track add to cart
await analytics.logAddToCart(
  productId: product.id,
  productName: product.name,
  category: product.category,
  price: product.price,
  quantity: quantity,
);
```

## Firebase Crashlytics

### Implementation

**Service**: `lib/services/crashlytics_service.dart`

The CrashlyticsService provides:

#### Core Features
- Automatic crash reporting in release mode
- Manual error recording with `recordError()`
- Custom keys for debugging context
- User identification

#### Custom Keys
- `setScreenName()` - Current screen context
- `setUserRole()` - User role (admin/customer)
- `setOrderContext()` - Order-related context
- `setProductContext()` - Product-related context
- `setCartContext()` - Cart-related context

#### Logging
- `log()` - Add breadcrumb logs
- `setCustomKey()` - Set individual custom keys
- `setCustomKeys()` - Set multiple custom keys

### Integration

Crashlytics is integrated in:
- **main.dart** - Initialized on app startup
- **ErrorService** - All errors logged to Crashlytics
- **AuthProvider** - User context set on login, cleared on logout

### Usage Example

```dart
// In a service or provider
final crashlytics = CrashlyticsService();

// Set context before operation
await crashlytics.setOrderContext(
  orderId: order.id,
  status: order.status,
  amount: order.totalAmount,
);

// Log breadcrumb
crashlytics.log('Starting order placement');

// Record non-fatal error
try {
  await placeOrder();
} catch (e, stack) {
  await crashlytics.recordError(
    e,
    stack,
    reason: 'Order placement failed',
    fatal: false,
  );
}
```

## Firebase Performance Monitoring

### Implementation

**Service**: `lib/services/performance_service.dart`

The PerformanceService provides:

#### Predefined Traces
- `traceProductLoad()` - Product loading performance
- `traceProductSearch()` - Search performance
- `traceCartOperation()` - Cart operations
- `traceOrderPlacement()` - Order placement
- `traceCheckout()` - Checkout process
- `traceImageUpload()` - Image upload performance
- `traceAuthentication()` - Authentication performance
- `traceAdminOperation()` - Admin operations
- `traceDatabaseQuery()` - Database queries
- `traceScreenLoad()` - Screen loading

#### Firebase Operations
- `traceFirestoreRead()` - Firestore read operations
- `traceFirestoreWrite()` - Firestore write operations
- `traceStorageUpload()` - Storage uploads
- `traceStorageDownload()` - Storage downloads

#### HTTP Metrics
- `traceHttpRequest()` - HTTP request performance
- Automatic network request monitoring

### Usage Example

```dart
// In a service
final performance = PerformanceService();

// Trace an operation
final products = await performance.traceProductLoad(() async {
  return await _firestore.collection('products').get();
});

// Trace with attributes
final results = await performance.traceProductSearch(
  () async {
    return await searchProducts(query);
  },
  query,
);

// Trace Firestore operation
final order = await performance.traceFirestoreWrite(
  () async {
    return await _firestore.collection('orders').add(orderData);
  },
  'orders',
);
```

## Configuration

### Dependencies Added

```yaml
firebase_analytics: ^11.3.8
firebase_crashlytics: ^4.3.8
firebase_performance: ^0.10.1+10
```

### Initialization

All services are initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CrashlyticsService().initialize();
  
  // ... rest of initialization
  
  runApp(const MyApp());
}
```

## Best Practices

### Analytics
1. Log events at key user actions
2. Set user properties on authentication
3. Clear user data on logout
4. Use consistent event naming
5. Include relevant parameters with events

### Crashlytics
1. Set custom keys before operations
2. Log breadcrumbs for debugging context
3. Record non-fatal errors for monitoring
4. Clear sensitive data from custom keys
5. Set user context on authentication

### Performance
1. Trace critical user flows
2. Monitor database operations
3. Track network requests
4. Measure screen load times
5. Use attributes for filtering

## Testing

### Analytics Testing
- Events can be viewed in Firebase Console > Analytics > Events
- Debug view available in Firebase Console for real-time testing
- Use `flutter run --debug` to see analytics events in console

### Crashlytics Testing
- Test crashes only in release mode
- Use `crashlytics.forceCrash()` for testing (remove after testing)
- View crashes in Firebase Console > Crashlytics

### Performance Testing
- Traces visible in Firebase Console > Performance
- Monitor in real-time during development
- Review metrics after deployment

## Monitoring Dashboard

Access monitoring data in Firebase Console:
- **Analytics**: https://console.firebase.google.com/project/YOUR_PROJECT/analytics
- **Crashlytics**: https://console.firebase.google.com/project/YOUR_PROJECT/crashlytics
- **Performance**: https://console.firebase.google.com/project/YOUR_PROJECT/performance

## Next Steps

To fully utilize these services:

1. **Add analytics calls** to remaining providers:
   - ProductProvider (product views, searches)
   - CartProvider (cart operations)
   - OrderProvider (order placement, cancellation)
   - AdminProvider (admin operations)

2. **Set performance traces** in critical operations:
   - Product loading in ProductService
   - Cart operations in CartService
   - Order placement in OrderService
   - Image uploads in ImageUploadService

3. **Configure alerts** in Firebase Console:
   - Crash rate alerts
   - Performance degradation alerts
   - Custom event alerts

4. **Review metrics regularly**:
   - Weekly analytics review
   - Daily crash monitoring
   - Performance baseline tracking

## Compliance

- Analytics data collection complies with privacy requirements
- User data is anonymized where appropriate
- Crashlytics only enabled in release mode
- Performance monitoring respects user privacy
