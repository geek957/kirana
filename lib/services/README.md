# Services

This directory contains service classes that handle business logic and interact with Firebase backend services.

## Services

### AuthService
Handles customer authentication and registration using Firebase Auth with phone number verification.

### ProductService
Manages product catalog operations including fetching, searching, and filtering products from Firestore.

### CartService
Handles shopping cart operations with stock validation and offline persistence.

### AddressService
Manages customer delivery addresses with CRUD operations and default address handling.

### OrderService
**NEW** - Manages order lifecycle including:
- Order creation with Firestore transactions
- Stock deduction during order placement
- Order retrieval and history
- Order status updates
- Order cancellation with stock restoration
- Real-time order updates via Firestore streams

## Key Features

### OrderService Transaction Safety
The OrderService uses Firestore transactions to ensure atomic operations:
1. **Order Creation**: Validates stock, deducts quantities, creates order, and clears cart in a single transaction
2. **Order Cancellation**: Restores stock quantities and updates order status atomically
3. **Rollback on Failure**: If any step fails, all changes are rolled back automatically

### Real-time Updates
All services provide both one-time fetch methods and real-time stream methods for live data synchronization.

### Error Handling
Services throw descriptive exceptions that are caught and handled by providers for user-friendly error messages.

**Using ErrorService:**
```dart
import '../services/error_service.dart';

final errorService = ErrorService();

try {
  await someOperation();
} catch (e, stackTrace) {
  final message = await errorService.handleError(
    error: e,
    stackTrace: stackTrace,
    context: 'OrderService.createOrder',
  );
  // Show error to user
  ErrorSnackbar.show(context: context, message: message);
}
```

**Retry Logic:**
```dart
final result = await errorService.retryOperation(
  operation: () => someNetworkCall(),
  maxAttempts: 3,
  delay: Duration(seconds: 2),
);
```

**Error UI Components:**
- `ErrorDialog` - Modal error dialogs with retry
- `ErrorSnackbar` - Brief error messages
- `ErrorStateWidget` - Full-screen error states
- `NetworkErrorWidget` - Network-specific errors
