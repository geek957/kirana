# Services

This directory contains service classes that handle business logic and Firebase interactions.

## Structure

Services encapsulate all backend operations and provide a clean API for the UI layer.

### Planned Services:
- `auth_service.dart` - Authentication and user management
- `product_service.dart` - Product catalog operations
- `address_service.dart` - Address management
- `cart_service.dart` - Shopping cart operations
- `order_service.dart` - Order placement and management
- `admin_service.dart` - Admin inventory and order management
- `notification_service.dart` - In-app notification handling
- `encryption_service.dart` - Data encryption/decryption
- `audit_service.dart` - Audit logging for admin actions
- `error_service.dart` - Centralized error handling

Each service should:
- Use Firebase SDK for backend operations
- Handle errors gracefully
- Return Future-based async operations
- Log important actions for debugging
