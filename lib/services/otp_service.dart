import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

/// Service for handling OTP verification with secure hashing
class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int bcryptCostFactor = 12;
  static const Duration otpExpiryDuration = Duration(minutes: 10);
  static const int maxVerificationAttempts = 5;

  /// Store OTP hash in Firestore
  /// Uses bcrypt with cost factor 12 for secure hashing
  Future<void> storeOtpHash({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // Hash the OTP using bcrypt
      final hash = BCrypt.hashpw(
        otp,
        BCrypt.gensalt(logRounds: bcryptCostFactor),
      );

      final expiresAt = DateTime.now().add(otpExpiryDuration);

      await _firestore.collection('verificationCodes').doc(phoneNumber).set({
        'phoneNumber': phoneNumber,
        'codeHash': hash,
        'expiresAt': expiresAt.toIso8601String(),
        'attempts': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to store OTP hash: $e');
    }
  }

  /// Verify OTP against stored hash
  /// Returns true if OTP is valid and not expired
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final doc = await _firestore
          .collection('verificationCodes')
          .doc(phoneNumber)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final codeHash = data['codeHash'] as String;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);
      final attempts = data['attempts'] as int;

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        // Clean up expired OTP
        await _deleteOtp(phoneNumber);
        return false;
      }

      // Check if max attempts exceeded
      if (attempts >= maxVerificationAttempts) {
        return false;
      }

      // Increment attempt counter
      await _firestore.collection('verificationCodes').doc(phoneNumber).update({
        'attempts': FieldValue.increment(1),
      });

      // Verify OTP using bcrypt
      final isValid = BCrypt.checkpw(otp, codeHash);

      // If valid, delete the OTP record
      if (isValid) {
        await _deleteOtp(phoneNumber);
      }

      return isValid;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Delete OTP record
  Future<void> _deleteOtp(String phoneNumber) async {
    try {
      await _firestore
          .collection('verificationCodes')
          .doc(phoneNumber)
          .delete();
    } catch (e) {
      // Log error but don't throw - deletion failure shouldn't block verification
      print('Failed to delete OTP: $e');
    }
  }

  /// Check if OTP exists and is not expired
  Future<bool> hasValidOtp(String phoneNumber) async {
    try {
      final doc = await _firestore
          .collection('verificationCodes')
          .doc(phoneNumber)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        await _deleteOtp(phoneNumber);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get remaining verification attempts
  Future<int> getRemainingAttempts(String phoneNumber) async {
    try {
      final doc = await _firestore
          .collection('verificationCodes')
          .doc(phoneNumber)
          .get();

      if (!doc.exists) {
        return maxVerificationAttempts;
      }

      final data = doc.data()!;
      final attempts = data['attempts'] as int;
      return maxVerificationAttempts - attempts;
    } catch (e) {
      return maxVerificationAttempts;
    }
  }

  /// Clean up expired OTPs (should be called periodically)
  Future<void> cleanupExpiredOtps() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore.collection('verificationCodes').get();

      final batch = _firestore.batch();
      int deleteCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final expiresAt = DateTime.parse(data['expiresAt'] as String);

        if (now.isAfter(expiresAt)) {
          batch.delete(doc.reference);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        print('Cleaned up $deleteCount expired OTPs');
      }
    } catch (e) {
      print('Failed to cleanup expired OTPs: $e');
    }
  }
}
