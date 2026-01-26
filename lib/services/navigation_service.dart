import 'package:flutter/material.dart';

/// Service for handling navigation throughout the app
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate to a named route
  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and remove all previous routes
  static Future<dynamic>? navigateToAndRemoveUntil(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Replace the current route with a new one
  static Future<dynamic>? navigateReplaceTo(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Go back to the previous screen
  static void goBack({dynamic result}) {
    return navigatorKey.currentState?.pop(result);
  }

  /// Check if we can go back
  static bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  /// Get the current context
  static BuildContext? get currentContext {
    return navigatorKey.currentContext;
  }
}
