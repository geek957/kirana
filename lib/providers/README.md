# Providers

This directory contains state management providers using the Provider pattern.

## Structure

Providers manage application state and notify listeners of changes.

### Planned Providers:
- `auth_provider.dart` - User authentication state
- `product_provider.dart` - Product catalog state
- `cart_provider.dart` - Shopping cart state
- `order_provider.dart` - Order management state
- `address_provider.dart` - Address management state
- `admin_provider.dart` - Admin-specific state
- `notification_provider.dart` - Notification state

Each provider should:
- Extend `ChangeNotifier`
- Use services for backend operations
- Call `notifyListeners()` after state changes
- Handle loading and error states
- Set up real-time Firestore listeners where appropriate
