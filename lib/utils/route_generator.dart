import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/products/home_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_confirmation_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/address/address_list_screen.dart';
import '../screens/address/address_form_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/inventory_management_screen.dart';
import '../screens/admin/category_management_screen.dart';
import '../screens/admin/product_form_screen.dart';
import '../screens/admin/order_management_screen.dart';
import '../screens/admin/admin_order_detail_screen.dart';
import '../screens/admin/app_config_screen.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/address.dart';
import 'routes.dart';
import 'auth_guard.dart';

/// Generates routes for the application with authentication guards
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Auth routes (no guard needed)
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case Routes.register:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => RegistrationScreen(phoneNumber: args),
          );
        }
        return _errorRoute('Phone number required for registration');

      case Routes.otpVerification:
        if (args is Map<String, dynamic>) {
          final verificationId = args['verificationId'] as String?;
          if (verificationId == null) {
            return _errorRoute('Verification ID is required');
          }
          return MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: args['phoneNumber'] as String,
              verificationId: verificationId,
            ),
          );
        }
        return _errorRoute('Invalid arguments for OTP verification');

      // Customer routes (require authentication)
      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: HomeScreen()),
        );

      case Routes.productDetail:
        if (args is Product) {
          return MaterialPageRoute(
            builder: (_) =>
                AuthGuard(child: ProductDetailScreen(product: args)),
          );
        }
        return _errorRoute('Product required');

      case Routes.cart:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: CartScreen()),
        );

      case Routes.checkout:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: CheckoutScreen()),
        );

      case Routes.orderConfirmation:
        if (args is Order) {
          return MaterialPageRoute(
            builder: (_) =>
                AuthGuard(child: OrderConfirmationScreen(order: args)),
          );
        }
        return _errorRoute('Order required');

      case Routes.orderHistory:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: OrderHistoryScreen()),
        );

      case Routes.orderDetail:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => AuthGuard(child: OrderDetailScreen(orderId: args)),
          );
        }
        return _errorRoute('Order ID required');

      case Routes.profile:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: ProfileScreen()),
        );

      case Routes.addressList:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: AddressListScreen()),
        );

      case Routes.addressForm:
        if (args is Address) {
          return MaterialPageRoute(
            builder: (_) => AuthGuard(child: AddressFormScreen(address: args)),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: AddressFormScreen()),
        );

      case Routes.notifications:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: NotificationsScreen()),
        );

      // Admin routes (require authentication AND admin role)
      case Routes.adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            requireAdmin: true,
            child: AdminDashboardScreen(),
          ),
        );

      case Routes.adminInventory:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            requireAdmin: true,
            child: InventoryManagementScreen(),
          ),
        );

      case Routes.adminCategoryManagement:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            requireAdmin: true,
            child: CategoryManagementScreen(),
          ),
        );

      case Routes.adminProductAdd:
        return MaterialPageRoute(
          builder: (_) =>
              const AuthGuard(requireAdmin: true, child: ProductFormScreen()),
        );

      case Routes.adminProductEdit:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => AuthGuard(
              requireAdmin: true,
              child: ProductFormScreen(productId: args),
            ),
          );
        }
        return _errorRoute('Product ID required');

      case Routes.adminOrders:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(
            requireAdmin: true,
            child: OrderManagementScreen(),
          ),
        );

      case Routes.adminOrderDetail:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => AuthGuard(
              requireAdmin: true,
              child: AdminOrderDetailScreen(orderId: args),
            ),
          );
        }
        return _errorRoute('Order ID required');

      case Routes.adminAppConfig:
        return MaterialPageRoute(
          builder: (_) =>
              const AuthGuard(requireAdmin: true, child: AppConfigScreen()),
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
