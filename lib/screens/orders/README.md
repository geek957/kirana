# Orders Screens

This directory contains screens related to order management for customers.

## Screens

### OrderHistoryScreen
- Displays a list of all customer orders
- Shows order ID, date, status, and total amount
- Status badges with color coding
- Real-time updates via Firestore listeners
- Pull-to-refresh functionality
- Tap to view order details

### OrderDetailScreen
- Shows complete order information
- Displays order items with quantities and prices
- Shows delivery address snapshot
- Payment method information
- Order status with visual indicators
- Cancel order button (for eligible orders)
- Real-time status updates

## Features

### Status Management
Orders can have the following statuses:
- **Pending**: Order placed, awaiting confirmation
- **Confirmed**: Order confirmed by admin
- **Preparing**: Order is being prepared
- **Out for Delivery**: Order is on the way
- **Delivered**: Order successfully delivered
- **Cancelled**: Order cancelled by customer or admin

### Order Cancellation
- Only orders with status "Pending" or "Confirmed" can be cancelled
- Cancelling an order restores stock quantities
- Confirmation dialog before cancellation
- Real-time UI updates after cancellation

### Real-time Updates
- Uses Firestore real-time listeners
- Automatic UI updates when order status changes
- No manual refresh needed for status updates

## Navigation

From HomeScreen:
- Bottom navigation bar → Orders tab → OrderHistoryScreen

From OrderHistoryScreen:
- Tap order card → OrderDetailScreen

From CheckoutScreen:
- After successful order placement → OrderConfirmationScreen → OrderDetailScreen

## State Management

Uses OrderProvider for:
- Fetching customer orders
- Real-time order updates
- Order cancellation
- Error handling
- Loading states
