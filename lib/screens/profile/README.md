# Profile Screen

## Overview
The Profile Screen provides customers with access to their account information and profile management features.

## Features

### User Information Display
- **Profile Avatar**: Displays user's initial in a circular avatar
- **Name**: Shows the customer's name prominently
- **Phone Number**: Displays the registered phone number (read-only)
- **Member Since**: Shows the account creation date

### Profile Management
- **Edit Name**: Allows customers to update their name
  - Inline editing with form validation
  - Minimum 2 characters required
  - Save/Cancel buttons for confirmation
  - Loading state during update

### Quick Actions
- **Manage Addresses**: Navigate to address list screen
- **Order History**: Navigate to order history screen

### Authentication
- **Logout**: Secure logout with confirmation dialog
  - Clears user session
  - Returns to login screen

## Navigation
- Accessible from the home screen via the profile icon in the app bar
- Also available via route: `/profile`

## Validation Rules
- Name must not be empty
- Name must be at least 2 characters long

## Error Handling
- Shows error messages via SnackBar for failed operations
- Displays success confirmation after profile updates
- Handles network errors gracefully

## Implementation Details
- Uses `AuthProvider` for state management
- Integrates with `AuthService` for profile updates
- Form validation using Flutter's Form widget
- Responsive layout with SingleChildScrollView

## Related Files
- `lib/services/auth_service.dart` - Profile update logic
- `lib/providers/auth_provider.dart` - State management
- `lib/models/customer.dart` - Customer data model
