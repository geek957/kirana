# Error Handling Guide

This guide explains how to use the error handling system in the Kirana Grocery App.

## Overview

The app provides a centralized error handling system with three main components:

1. **ErrorService** - Backend error handling, logging, and retry logic
2. **Error Dialogs** - Modal error messages with retry options
3. **Error Snackbars** - Brief error notifications

## ErrorService

The `ErrorService` provides centralized error handling with logging and retry capabilities.

### Basic Usage

```dart
import 'package:kirana/services/error_service.dart';
import 'package:kirana/widgets/error_snackbar.dart';

final errorService = ErrorService();

try {
  await someOperation();
} catch (e, stackTrace) {
  final message = await errorService.handleError(
    error: e,
    stackTrace: stackTrace,
    context: 'ProductService.getProducts',
    additionalData: {'category': 'vegetables'},
  );
  
  if (mounted) {
    ErrorSnackbar.show(context: context, message: message);
  }
}
```

### Retry Logic

Use `retryOperation` for operations that might fail due to transient issues:

```dart
final products = await errorService.retryOperation(
  operation: () => _firestore.collection('products').get(),
  maxAttempts: 3,
  delay: Duration(seconds: 2),
);
```

### Custom Retry Logic

```dart
final result = await errorService.retryOperation(
  operation: () => someNetworkCall(),
  maxAttempts: 3,
  shouldRetry: (error) {
    // Only retry on network errors
    return errorService.isNetworkError(error);
  },
);
```

### Error Type Checking

```dart
if (errorService.isNetworkError(error)) {
  // Show network-specific error
  NetworkErrorDialog.show(context: context, onRetry: _retry);
} else if (errorService.isAuthError(error)) {
  // Redirect to login
  Navigator.pushReplacementNamed(context, '/login');
} else if (errorService.isPermissionError(error)) {
  // Show permission error
  PermissionErrorDialog.show(context: context);
}
```

## Error Dialogs

Use error dialogs for important errors that require user attention.

### Generic Error Dialog

```dart
import 'package:kirana/widgets/error_dialog.dart';

ErrorDialog.show(
  context: context,
  title: 'Order Failed',
  message: 'Unable to place your order. Please try again.',
  showRetry: true,
  onRetry: () {
    // Retry the operation
    _placeOrder();
  },
);
```

### Network Error Dialog

```dart
NetworkErrorDialog.show(
  context: context,
  onRetry: () {
    // Retry the operation
    _loadProducts();
  },
);
```

### Permission Error Dialog

```dart
PermissionErrorDialog.show(
  context: context,
  message: 'You need admin privileges to access this feature.',
);
```

## Error Snackbars

Use snackbars for brief, non-critical error messages.

### Error Snackbar

```dart
import 'package:kirana/widgets/error_snackbar.dart';

ErrorSnackbar.show(
  context: context,
  message: 'Failed to add item to cart',
  onRetry: () {
    _addToCart();
  },
);
```

### Success Snackbar

```dart
ErrorSnackbar.showSuccess(
  context: context,
  message: 'Order placed successfully!',
);
```

### Warning Snackbar

```dart
ErrorSnackbar.showWarning(
  context: context,
  message: 'Low stock available',
  actionLabel: 'View',
  onAction: () {
    // Navigate to product details
  },
);
```

### Info Snackbar

```dart
ErrorSnackbar.showInfo(
  context: context,
  message: 'New products added to catalog',
);
```

### Network Error Snackbar

```dart
ErrorSnackbar.showNetworkError(
  context: context,
  onRetry: _loadData,
);
```

## Error State Widgets

Use error state widgets for full-screen error states.

### Error State Widget

```dart
import 'package:kirana/widgets/loading_indicator.dart';

ErrorStateWidget(
  message: 'Failed to load products',
  onRetry: _loadProducts,
)
```

### Network Error Widget

```dart
NetworkErrorWidget(
  onRetry: _loadData,
)
```

### Empty State Widget

```dart
EmptyStateWidget(
  message: 'No orders yet',
  icon: Icons.shopping_bag_outlined,
  action: ElevatedButton(
    onPressed: () => Navigator.pushNamed(context, '/home'),
    child: Text('Start Shopping'),
  ),
)
```

## Complete Example

Here's a complete example showing error handling in a provider:

```dart
import 'package:flutter/material.dart';
import 'package:kirana/services/product_service.dart';
import 'package:kirana/services/error_service.dart';
import 'package:kirana/models/product.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final ErrorService _errorService = ErrorService();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Use retry logic for network operations
      _products = await _errorService.retryOperation(
        operation: () => _productService.getProducts(),
        maxAttempts: 3,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      // Log error and get user-friendly message
      _error = await _errorService.handleError(
        error: e,
        stackTrace: stackTrace,
        context: 'ProductProvider.loadProducts',
      );
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

And in the UI:

```dart
class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return LoadingIndicator(message: 'Loading products...');
        }
        
        if (provider.error != null) {
          return ErrorStateWidget(
            message: provider.error!,
            onRetry: () => provider.loadProducts(),
          );
        }
        
        if (provider.products.isEmpty) {
          return EmptyStateWidget(
            message: 'No products available',
            icon: Icons.inventory_2_outlined,
          );
        }
        
        return ListView.builder(
          itemCount: provider.products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: provider.products[index]);
          },
        );
      },
    );
  }
}
```

## Best Practices

1. **Always log errors** - Use `ErrorService.handleError()` to log errors to Firestore
2. **Use appropriate UI components** - Dialogs for critical errors, snackbars for brief messages
3. **Provide retry options** - For network errors and transient failures
4. **Show user-friendly messages** - Use `ErrorService.getUserFriendlyMessage()` to convert technical errors
5. **Handle specific error types** - Check error types and show appropriate UI
6. **Use retry logic** - Wrap network operations in `retryOperation()` for automatic retries
7. **Check mounted state** - Always check `if (mounted)` before showing UI after async operations

## Error Logging

All errors logged via `ErrorService` are stored in Firestore under the `errorLogs` collection with:

- Error message and stack trace
- User ID (if authenticated)
- Context (where the error occurred)
- Timestamp
- Platform information
- Additional custom data

This allows monitoring and debugging production issues.
