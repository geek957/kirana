import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility helpers for improving screen reader support and keyboard navigation
/// Validates: Non-functional requirements - Accessibility

class AccessibilityHelper {
  /// Announce a message to screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Create semantic label for price with discount
  static String priceLabel({required double price, double? discountPrice}) {
    if (discountPrice != null && discountPrice < price) {
      final savings = price - discountPrice;
      final percentage = ((savings / price) * 100).toStringAsFixed(0);
      return 'Original price ₹${price.toStringAsFixed(2)}, '
          'now ₹${discountPrice.toStringAsFixed(2)}, '
          'save ₹${savings.toStringAsFixed(2)}, '
          '$percentage percent off';
    }
    return 'Price ₹${price.toStringAsFixed(2)}';
  }

  /// Create semantic label for cart item count
  static String cartCountLabel(int count) {
    if (count == 0) {
      return 'Cart is empty';
    } else if (count == 1) {
      return '1 item in cart';
    } else {
      return '$count items in cart';
    }
  }

  /// Create semantic label for notification count
  static String notificationCountLabel(int count) {
    if (count == 0) {
      return 'No unread notifications';
    } else if (count == 1) {
      return '1 unread notification';
    } else {
      return '$count unread notifications';
    }
  }

  /// Create semantic label for order status
  static String orderStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order status: Pending, waiting for confirmation';
      case 'confirmed':
        return 'Order status: Confirmed, being prepared';
      case 'out_for_delivery':
        return 'Order status: Out for delivery, on the way';
      case 'delivered':
        return 'Order status: Delivered, order complete';
      case 'cancelled':
        return 'Order status: Cancelled';
      default:
        return 'Order status: $status';
    }
  }

  /// Create semantic label for product availability
  static String availabilityLabel({
    required bool isAvailable,
    required int stock,
  }) {
    if (!isAvailable) {
      return 'Product unavailable';
    } else if (stock == 0) {
      return 'Out of stock';
    } else if (stock < 5) {
      return 'Low stock, only $stock remaining';
    } else {
      return 'In stock, $stock available';
    }
  }

  /// Create semantic label for minimum order quantity
  static String minimumQuantityLabel(int minQty, String unit) {
    if (minQty == 1) {
      return 'Minimum order: 1 $unit';
    } else {
      return 'Minimum order: $minQty $unit';
    }
  }

  /// Create semantic label for delivery charge
  static String deliveryChargeLabel({
    required double charge,
    required bool isFree,
  }) {
    if (isFree) {
      return 'Free delivery';
    } else {
      return 'Delivery charge: ₹${charge.toStringAsFixed(2)}';
    }
  }

  /// Create semantic label for form field with validation
  static String formFieldLabel({
    required String label,
    required bool isRequired,
    String? hint,
    String? error,
  }) {
    String semanticLabel = label;
    if (isRequired) {
      semanticLabel += ', required field';
    }
    if (hint != null && hint.isNotEmpty) {
      semanticLabel += ', $hint';
    }
    if (error != null && error.isNotEmpty) {
      semanticLabel += ', error: $error';
    }
    return semanticLabel;
  }

  /// Wrap widget with semantic label
  static Widget withLabel({
    required Widget child,
    required String label,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: label,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Wrap button with semantic label and hint
  static Widget button({
    required Widget child,
    required String label,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: child,
    );
  }

  /// Wrap image with semantic label
  static Widget image({required Widget child, required String label}) {
    return Semantics(image: true, label: label, child: child);
  }

  /// Create semantic header
  static Widget header({required Widget child, required String label}) {
    return Semantics(header: true, label: label, child: child);
  }

  /// Create semantic link
  static Widget link({
    required Widget child,
    required String label,
    String? hint,
  }) {
    return Semantics(link: true, label: label, hint: hint, child: child);
  }

  /// Focus management helpers
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Get text scale factor for dynamic text sizing
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Check if bold text is enabled
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Minimum touch target size for accessibility (48x48 dp)
  static const double minTouchTargetSize = 48.0;

  /// Check if touch target meets minimum size
  static bool isTouchTargetAccessible(double width, double height) {
    return width >= minTouchTargetSize && height >= minTouchTargetSize;
  }

  /// Wrap widget to ensure minimum touch target size
  static Widget ensureTouchTarget({
    required Widget child,
    double minSize = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: child,
    );
  }
}

/// Semantic wrapper widgets for common UI patterns

/// Semantic card with proper labeling
class SemanticCard extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback? onTap;

  const SemanticCard({
    super.key,
    required this.child,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: onTap != null,
      child: Card(
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

/// Semantic list tile with proper labeling
class SemanticListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String semanticLabel;

  const SemanticListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// Semantic icon button with proper labeling
class SemanticIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Color? color;

  const SemanticIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      hint: hint,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: color,
        tooltip: label,
      ),
    );
  }
}
