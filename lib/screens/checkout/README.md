# Checkout Screens

This directory contains screens related to the checkout and order placement process.

## Screens

### CheckoutScreen
- Address selection with radio buttons
- Displays all saved addresses
- Option to add new address
- Order summary with items and total
- Payment method display (Cash on Delivery)
- Place order button with loading state
- Validates cart and address before order placement

### OrderConfirmationScreen
- Success message with checkmark icon
- Order ID display
- Total amount and payment method
- "View Order Details" button
- "Continue Shopping" button
- Replaces navigation stack to prevent back navigation

## Features

### Address Selection
- Lists all saved customer addresses
- Radio button selection
- Highlights default address
- Shows address label, full address, landmark, and contact
- Quick add new address option

### Order Summary
- Lists all cart items with quantities
- Shows individual item prices
- Displays total amount
- Real-time cart data

### Order Placement
- Validates selected address
- Validates cart is not empty
- Creates order with Firestore transaction
- Deducts stock quantities atomically
- Clears cart after successful order
- Shows loading indicator during placement
- Error handling with user-friendly messages

### Payment Method
- Currently supports Cash on Delivery only
- Visual indicator with money icon
- Future-ready for additional payment methods

## Navigation Flow

```
CartScreen → CheckoutScreen → OrderConfirmationScreen → OrderDetailScreen
                ↓
         AddressFormScreen (optional)
```

## State Management

Uses multiple providers:
- **CartProvider**: Cart data and items
- **AddressProvider**: Customer addresses
- **AuthProvider**: Current user information
- **OrderProvider**: Order creation and management

## Error Handling

- Empty cart validation
- Missing address validation
- Stock availability validation (in OrderService)
- Network error handling
- User-friendly error messages via SnackBar
