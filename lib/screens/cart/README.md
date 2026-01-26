# Cart Screen

This directory contains the cart screen implementation for the online grocery application.

## Files

- `cart_screen.dart` - Main cart screen UI with item list, quantity controls, and checkout button

## Features Implemented

### Cart Display
- Shows all items in the cart with product images, names, prices, and quantities
- Displays subtotal, delivery fee (free), and total amount
- Empty cart state with "Continue Shopping" button
- Real-time updates via CartProvider

### Quantity Controls
- Increment/decrement buttons for each item
- Stock validation when updating quantities
- Error messages for insufficient stock

### Item Removal
- Delete button for each item with confirmation dialog
- Updates cart total automatically after removal

### Checkout
- "Proceed to Checkout" button (placeholder for future implementation)
- Displays order summary with all pricing details

## Integration

The cart screen integrates with:
- `CartProvider` for state management and real-time updates
- `AuthProvider` to get the current user ID
- `CartService` for all cart operations (add, remove, update)

## Usage

Navigate to the cart screen from:
- Home screen app bar cart icon (with badge showing item count)
- Product detail screen after adding an item (via snackbar action)

## Validation

- Requires user to be logged in
- Validates stock availability when updating quantities
- Shows appropriate error messages for all failure cases
