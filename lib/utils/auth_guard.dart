import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/products/home_screen.dart';

/// Widget that guards routes requiring authentication
class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAdmin;

  const AuthGuard({super.key, required this.child, this.requireAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while checking auth state
        if (authProvider.status == AuthStatus.loading ||
            authProvider.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not authenticated, redirect to login
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If admin access required but user is not admin, show error
        if (requireAdmin && !authProvider.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You do not have permission to access this page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // User is authenticated and has required permissions
        return child;
      },
    );
  }
}

/// Wrapper that checks authentication state and routes accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print('🏠 [AuthWrapper] Building with status: ${authProvider.status}');
        print('🏠 [AuthWrapper] isAuthenticated: ${authProvider.isAuthenticated}');
        print('🏠 [AuthWrapper] isAdmin: ${authProvider.isAdmin}');
        print('🏠 [AuthWrapper] currentCustomer: ${authProvider.currentCustomer?.name ?? "null"}');
        
        // Show loading while checking auth state
        if (authProvider.status == AuthStatus.loading ||
            authProvider.status == AuthStatus.initial) {
          print('🏠 [AuthWrapper] → Showing LOADING spinner');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is authenticated, route based on role
        // Otherwise, show login screen
        if (authProvider.isAuthenticated) {
          // Route admin users to admin dashboard
          if (authProvider.isAdmin) {
            print('🏠 [AuthWrapper] → Routing to ADMIN DASHBOARD');
            return const AdminDashboardScreen();
          }
          // Route regular customers to home screen
          print('🏠 [AuthWrapper] → Routing to HOME SCREEN');
          return const HomeScreen();
        } else {
          print('🏠 [AuthWrapper] → Routing to LOGIN SCREEN');
          return const LoginScreen();
        }
      },
    );
  }
}
