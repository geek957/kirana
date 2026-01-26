import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling authorization checks
class AuthorizationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if the current user is an admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final customerDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        return false;
      }

      return customerDoc.data()?['isAdmin'] as bool? ?? false;
    } catch (e) {
      throw AuthorizationException('Failed to check admin status: $e');
    }
  }

  /// Check if the current user can access a specific customer's data
  Future<bool> canAccessCustomerData(String customerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // User can access their own data
      if (user.uid == customerId) {
        return true;
      }

      // Admin can access any customer's data
      return await isAdmin();
    } catch (e) {
      throw AuthorizationException('Failed to check customer data access: $e');
    }
  }

  /// Check if the current user can access a specific order
  Future<bool> canAccessOrder(String orderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Check if user is admin
      if (await isAdmin()) {
        return true;
      }

      // Check if order belongs to the user
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        return false;
      }

      final customerId = orderDoc.data()?['customerId'] as String?;
      return customerId == user.uid;
    } catch (e) {
      throw AuthorizationException('Failed to check order access: $e');
    }
  }

  /// Check if the current user can access a specific address
  Future<bool> canAccessAddress(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Check if user is admin
      if (await isAdmin()) {
        return true;
      }

      // Check if address belongs to the user
      final addressDoc = await _firestore
          .collection('addresses')
          .doc(addressId)
          .get();

      if (!addressDoc.exists) {
        return false;
      }

      final customerId = addressDoc.data()?['customerId'] as String?;
      return customerId == user.uid;
    } catch (e) {
      throw AuthorizationException('Failed to check address access: $e');
    }
  }

  /// Check if the current user can modify inventory
  Future<bool> canModifyInventory() async {
    return await isAdmin();
  }

  /// Check if the current user can manage orders
  Future<bool> canManageOrders() async {
    return await isAdmin();
  }

  /// Verify admin access or throw exception
  Future<void> requireAdmin() async {
    if (!await isAdmin()) {
      throw UnauthorizedException('Admin access required for this operation');
    }
  }

  /// Verify customer data access or throw exception
  Future<void> requireCustomerDataAccess(String customerId) async {
    if (!await canAccessCustomerData(customerId)) {
      throw UnauthorizedException(
        'You do not have permission to access this customer data',
      );
    }
  }

  /// Verify order access or throw exception
  Future<void> requireOrderAccess(String orderId) async {
    if (!await canAccessOrder(orderId)) {
      throw UnauthorizedException(
        'You do not have permission to access this order',
      );
    }
  }

  /// Verify address access or throw exception
  Future<void> requireAddressAccess(String addressId) async {
    if (!await canAccessAddress(addressId)) {
      throw UnauthorizedException(
        'You do not have permission to access this address',
      );
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Require authentication or throw exception
  void requireAuthentication() {
    if (!isAuthenticated()) {
      throw UnauthenticatedException('Authentication required');
    }
  }
}

/// Exception thrown when authorization fails
class AuthorizationException implements Exception {
  final String message;
  AuthorizationException(this.message);

  @override
  String toString() => 'AuthorizationException: $message';
}

/// Exception thrown when user is not authorized
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception thrown when user is not authenticated
class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException(this.message);

  @override
  String toString() => 'UnauthenticatedException: $message';
}
