import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final CrashlyticsService _crashlyticsService = CrashlyticsService();
  final NotificationService _notificationService = NotificationService();

  AuthStatus _status = AuthStatus.initial;
  Customer? _currentCustomer;
  User? _firebaseUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  Customer? get currentCustomer => _currentCustomer;
  User? get firebaseUser => _firebaseUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _currentCustomer?.isAdmin ?? false;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    print('🔵 [AuthProvider] Initializing auth state listener');
    _authService.authStateChanges.listen((User? user) async {
      print('🔵 [AuthProvider] Auth state changed - User: ${user?.uid ?? "null"}');
      if (user != null) {
        _firebaseUser = user;
        print('🔵 [AuthProvider] Calling _loadCustomerData for user: ${user.uid}');
        await _loadCustomerData(user.uid);
      } else {
        print('🔵 [AuthProvider] No user - setting unauthenticated');
        _firebaseUser = null;
        _currentCustomer = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<void> _loadCustomerData(String userId) async {
    print('🟡 [AuthProvider] _loadCustomerData START for userId: $userId');
    print('🟡 [AuthProvider] Current status before load: $_status');
    try {
      _status = AuthStatus.loading;
      print('🟡 [AuthProvider] Status set to LOADING');
      notifyListeners();

      print('🟡 [AuthProvider] Fetching customer from Firestore...');
      final customer = await _authService.getCustomer(userId);
      print('🟡 [AuthProvider] Firestore fetch complete. Customer found: ${customer != null}');

      if (customer != null) {
        _currentCustomer = customer;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        print('🟢 [AuthProvider] Status set to AUTHENTICATED');
        print('🟢 [AuthProvider] Customer name: ${customer.name}, isAdmin: ${customer.isAdmin}');

        // Set analytics user properties
        await _analyticsService.setUserId(userId);
        await _analyticsService.setUserIsAdmin(customer.isAdmin);
        await _analyticsService.setUserCustomerSince(customer.createdAt);

        // Set Crashlytics user context
        await _crashlyticsService.setUserId(userId);
        await _crashlyticsService.setUserRole(
          customer.isAdmin ? 'admin' : 'customer',
        );

        // Save FCM token for push notifications
        await _saveFCMToken(userId);
      } else {
        // User authenticated but no customer record
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Customer record not found';
        print('🔴 [AuthProvider] Customer NOT FOUND - Status set to UNAUTHENTICATED');
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Failed to load customer data: $e';
      print('🔴 [AuthProvider] ERROR loading customer: $e');
      print('🔴 [AuthProvider] Status set to UNAUTHENTICATED');
    }
    print('🟡 [AuthProvider] _loadCustomerData END. Final status: $_status');
    notifyListeners();
  }

  Future<void> sendVerificationCode(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await _authService.sendVerificationCode(
      phoneNumber,
      onCodeSent: (verificationId) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        onCodeSent(verificationId);
      },
      onError: (error) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = error;
        notifyListeners();
        onError(error);
      },
    );
  }

  Future<Customer?> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    print('🟣 [AuthProvider] verifyCode START');
    try {
      // Don't set loading status here - let the auth state listener handle it
      // This prevents race conditions with the listener
      
      print('🟣 [AuthProvider] Calling auth service verifyCode...');
      final customer = await _authService.verifyCode(
        verificationId: verificationId,
        code: code,
      );
      print('🟣 [AuthProvider] Auth service returned. Customer: ${customer != null ? customer.name : "null"}');

      // Log login event if existing user
      if (customer != null) {
        await _analyticsService.logLogin('phone');
        print('🟣 [AuthProvider] Logged analytics login event');
      }

      // Return customer for navigation decisions in UI
      // The auth state listener will handle updating _currentCustomer and _status
      print('🟣 [AuthProvider] verifyCode END - returning customer');
      return customer;
    } catch (e) {
      _errorMessage = 'Verification failed: $e';
      print('🔴 [AuthProvider] verifyCode ERROR: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerCustomer({
    required String phoneNumber,
    required String name,
    String? defaultAddressId,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final customer = await _authService.registerCustomer(
        phoneNumber: phoneNumber,
        name: name,
        defaultAddressId: defaultAddressId,
      );

      _currentCustomer = customer;
      _status = AuthStatus.authenticated;

      // Log sign up event
      await _analyticsService.logSignUp('phone');

      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Registration failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? defaultAddressId}) async {
    if (_currentCustomer == null) {
      throw Exception('No customer logged in');
    }

    try {
      await _authService.updateProfile(
        userId: _currentCustomer!.id,
        name: name,
        defaultAddressId: defaultAddressId,
      );

      // Reload customer data
      await _loadCustomerData(_currentCustomer!.id);
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authService.logout();

      // Clear analytics user ID
      await _analyticsService.clearUserId();

      // Clear Crashlytics user ID
      await _crashlyticsService.clearUserId();

      _currentCustomer = null;
      _firebaseUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshCustomerData() async {
    if (_firebaseUser != null) {
      await _loadCustomerData(_firebaseUser!.uid);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper method to get remaining OTP attempts
  int getRemainingOtpAttempts(String phoneNumber) {
    return _authService.getRemainingOtpAttempts(phoneNumber);
  }

  // Helper method to get time until next OTP attempt
  Duration? getTimeUntilNextOtpAttempt(String phoneNumber) {
    return _authService.getTimeUntilNextOtpAttempt(phoneNumber);
  }

  /// Save FCM token to user document for push notifications
  Future<void> _saveFCMToken(String userId) async {
    try {
      final token = await _notificationService.getFCMToken();
      if (token != null) {
        await _authService.saveFCMToken(userId, token);
        print('🟢 [AuthProvider] FCM token saved for user: $userId');
      } else {
        print('🟡 [AuthProvider] No FCM token available');
      }
    } catch (e) {
      print('🔴 [AuthProvider] Failed to save FCM token: $e');
      // Don't throw - this shouldn't block login
    }
  }
}
