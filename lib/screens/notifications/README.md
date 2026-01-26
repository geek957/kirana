# Notifications Screen

This directory contains the notification-related UI screens for the Kirana grocery app.

## Files

- `notifications_screen.dart` - Main notifications list screen showing all customer notifications

## Features

- Display all notifications for the logged-in customer
- Show unread notifications with visual indicators (blue dot, highlighted background)
- Mark individual notifications as read when tapped
- Mark all notifications as read with a single action
- Navigate to order details when tapping a notification
- Real-time updates via Firestore listeners
- Pull-to-refresh functionality
- Empty state when no notifications exist

## Notification Types

- `order_status_change` - Order status updates (confirmed, preparing, out for delivery, delivered)
- `order_confirmed` - Initial order confirmation

## Integration

The notifications screen is accessed via the notification bell icon in the app bar of the home screen. The bell icon displays a badge with the count of unread notifications.

## State Management

Uses `NotificationProvider` for state management with real-time Firestore listeners for automatic updates.
