# Models

This directory contains data model classes for the Kirana Grocery Application.

## Structure

Data models represent the core entities in the application and handle serialization/deserialization to/from Firestore.

### Planned Models:
- `customer.dart` - Customer account information
- `address.dart` - Delivery address information
- `product.dart` - Product catalog items
- `cart.dart` - Shopping cart and cart items
- `order.dart` - Order and order items
- `admin.dart` - Admin user information
- `notification.dart` - In-app notifications

Each model should include:
- Properties matching Firestore document structure
- `toJson()` method for serialization
- `fromJson()` factory constructor for deserialization
- Validation methods where appropriate
