# Screens

This directory contains full-page screen widgets for the application.

## Structure

Screens represent complete pages in the app navigation flow.

### Planned Customer Screens:
- `auth/login_screen.dart` - Phone number login
- `auth/otp_verification_screen.dart` - OTP verification
- `home/home_screen.dart` - Product browsing
- `product/product_detail_screen.dart` - Product details
- `cart/cart_screen.dart` - Shopping cart
- `checkout/checkout_screen.dart` - Order checkout
- `order/order_confirmation_screen.dart` - Order confirmation
- `order/order_history_screen.dart` - Order history
- `order/order_detail_screen.dart` - Order details
- `address/address_list_screen.dart` - Address management
- `address/address_form_screen.dart` - Add/edit address
- `profile/profile_screen.dart` - User profile
- `notification/notifications_screen.dart` - Notifications

### Planned Admin Screens:
- `admin/admin_dashboard_screen.dart` - Admin dashboard
- `admin/inventory_list_screen.dart` - Inventory management
- `admin/product_form_screen.dart` - Add/edit product
- `admin/order_management_screen.dart` - Order management
- `admin/order_detail_admin_screen.dart` - Admin order details

Each screen should:
- Use providers for state management
- Handle loading and error states
- Follow Material Design guidelines
- Be responsive to different screen sizes
