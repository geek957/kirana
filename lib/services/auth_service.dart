import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import 'encryption_service.dart';
import 'otp_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService();
  final OtpService _otpService = OtpService();

  // Rate limiting: Track OTP requests per phone number
  final Map<String, List<DateTime>> _otpRequestHistory = {};
  static const int maxOtpRequestsPerHour = 3;
  static const Duration otpRateLimitWindow = Duration(hours: 1);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register a new customer
  Future<Customer> registerCustomer({
    required String phoneNumber,
    required String name,
    String? defaultAddressId,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User must be authenticated to register');
      }

      // Encrypt phone number before storage
      final encryptedPhone = await _encryptionService.encryptPhoneNumber(
        phoneNumber,
      );

      final customer = Customer(
        id: userId,
        phoneNumber: encryptedPhone,
        name: name,
        defaultAddressId: defaultAddressId,
        isAdmin: false,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('customers')
          .doc(userId)
          .set(customer.toJson());

      // Return customer with decrypted phone number for display
      return customer.copyWith(phoneNumber: phoneNumber);
    } catch (e) {
      throw Exception('Failed to register customer: $e');
    }
  }

  // Send verification code with rate limiting
  Future<void> sendVerificationCode(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      // Check rate limiting
      if (!_canSendOtp(phoneNumber)) {
        onError('Too many OTP requests. Please try again later.');
        return;
      }

      // Record this OTP request
      _recordOtpRequest(phoneNumber);

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
      );
    } catch (e) {
      onError('Failed to send verification code: $e');
    }
  }

  // Verify OTP code and sign in
  Future<Customer?> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Authentication failed');
      }

      // Check if customer exists in Firestore
      final customerDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        // Update last login
        await _firestore.collection('customers').doc(user.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
        });

        return Customer.fromJson(customerDoc.data()!);
      }

      // Customer doesn't exist yet - return null to indicate registration needed
      return null;
    } catch (e) {
      throw Exception('Failed to verify code: $e');
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      final customerDoc = await _firestore
          .collection('customers')
          .doc(userId)
          .get();
      if (!customerDoc.exists) {
        return false;
      }
      final customer = Customer.fromJson(customerDoc.data()!);
      return customer.isAdmin;
    } catch (e) {
      return false;
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomer(String userId) async {
    try {
      final customerDoc = await _firestore
          .collection('customers')
          .doc(userId)
          .get();
      if (!customerDoc.exists) {
        return null;
      }
      final customer = Customer.fromJson(customerDoc.data()!);

      // Try to decrypt phone number
      // If decryption fails (different device/key), use phone number as-is
      try {
        final decryptedPhone = await _encryptionService.decryptPhoneNumber(
          customer.phoneNumber,
        );
        return customer.copyWith(phoneNumber: decryptedPhone);
      } catch (decryptError) {
        // Decryption failed - phone might be plain text or encrypted with different key
        // This can happen when:
        // 1. User was created manually in Firebase Console (plain text)
        // 2. User logging in on different device (different encryption key)
        print('⚠️ Failed to decrypt phone number, using as-is: $decryptError');
        return customer; // Return with phone number as stored
      }
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  // Update customer profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? defaultAddressId,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (defaultAddressId != null) {
        updates['defaultAddressId'] = defaultAddressId;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('customers').doc(userId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // Rate limiting helper methods
  bool _canSendOtp(String phoneNumber) {
    final now = DateTime.now();
    final requests = _otpRequestHistory[phoneNumber] ?? [];

    // Remove requests older than the rate limit window
    requests.removeWhere((time) => now.difference(time) > otpRateLimitWindow);

    // Check if under the limit
    return requests.length < maxOtpRequestsPerHour;
  }

  void _recordOtpRequest(String phoneNumber) {
    final now = DateTime.now();
    if (_otpRequestHistory.containsKey(phoneNumber)) {
      _otpRequestHistory[phoneNumber]!.add(now);
    } else {
      _otpRequestHistory[phoneNumber] = [now];
    }
  }

  // Get remaining OTP attempts
  int getRemainingOtpAttempts(String phoneNumber) {
    final now = DateTime.now();
    final requests = _otpRequestHistory[phoneNumber] ?? [];

    // Remove requests older than the rate limit window
    requests.removeWhere((time) => now.difference(time) > otpRateLimitWindow);

    return maxOtpRequestsPerHour - requests.length;
  }

  // Get time until next OTP attempt is available
  Duration? getTimeUntilNextOtpAttempt(String phoneNumber) {
    final now = DateTime.now();
    final requests = _otpRequestHistory[phoneNumber] ?? [];

    // Remove requests older than the rate limit window
    requests.removeWhere((time) => now.difference(time) > otpRateLimitWindow);

    if (requests.length < maxOtpRequestsPerHour) {
      return null; // Can send immediately
    }

    // Find the oldest request and calculate when it expires
    requests.sort();
    final oldestRequest = requests.first;
    final expiryTime = oldestRequest.add(otpRateLimitWindow);
    return expiryTime.difference(now);
  }

  // Save FCM token for push notifications
  Future<void> saveFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save FCM token: $e');
    }
  }
}
