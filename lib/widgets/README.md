# Widgets

This directory contains reusable widget components used across multiple screens.

## Structure

Widgets are small, reusable UI components that can be composed into screens.

### Implemented Widgets:
- `product_card.dart` - Product display card
- `error_dialog.dart` - Error message dialogs with retry support
- `error_snackbar.dart` - Brief error/success/warning messages
- `loading_indicator.dart` - Loading spinner and error state widgets

### Planned Widgets:
- `cart_item_card.dart` - Cart item display
- `order_card.dart` - Order summary card
- `address_card.dart` - Address display card
- `status_badge.dart` - Order status badge
- `empty_state.dart` - Empty state placeholder
- `search_bar.dart` - Search input widget
- `category_chip.dart` - Category filter chip
- `quantity_selector.dart` - Quantity +/- controls
- `image_upload_widget.dart` - Image picker and upload

### Error Handling Widgets

#### ErrorDialog
Displays error messages in a dialog with optional retry functionality:
- `ErrorDialog.show()` - Generic error dialog
- `NetworkErrorDialog.show()` - Network-specific error with retry
- `PermissionErrorDialog.show()` - Permission denied errors

#### ErrorSnackbar
Shows brief messages at the bottom of the screen:
- `ErrorSnackbar.show()` - Error messages with optional retry
- `ErrorSnackbar.showSuccess()` - Success messages
- `ErrorSnackbar.showWarning()` - Warning messages
- `ErrorSnackbar.showInfo()` - Informational messages
- `ErrorSnackbar.showNetworkError()` - Network error with retry

#### LoadingIndicator
Loading and error state widgets:
- `LoadingIndicator` - Circular progress indicator with optional message
- `ErrorStateWidget` - Full-screen error state with retry button
- `NetworkErrorWidget` - Network error state with retry
- `EmptyStateWidget` - Empty state placeholder

Each widget should:
- Be self-contained and reusable
- Accept necessary data via constructor parameters
- Use callbacks for user interactions
- Follow consistent styling from theme
- Be well-documented with comments
