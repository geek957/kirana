import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';

/// Service for encrypting and decrypting sensitive data using AES-256-GCM
/// Uses user-based encryption keys derived from userId for cross-device compatibility
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Application-wide salt for key derivation (unique per app)
  static const String _appSalt = 'kirana_encryption_salt_v1_2026';
  
  // Cache of user keys to avoid recomputing
  final Map<String, enc.Key> _userKeys = {};

  /// Generate encryption key from userId
  /// This ensures same user has same key across all devices
  enc.Key _deriveKeyFromUserId(String userId) {
    // Check cache first
    if (_userKeys.containsKey(userId)) {
      return _userKeys[userId]!;
    }

    // Derive key from userId + app salt using SHA-256
    final keyMaterial = utf8.encode('$userId:$_appSalt');
    final digest = sha256.convert(keyMaterial);
    
    // Use the hash bytes as the key (32 bytes for AES-256)
    final key = enc.Key(Uint8List.fromList(digest.bytes));
    
    // Cache for future use
    _userKeys[userId] = key;
    return key;
  }

  /// Encrypt a string using AES-256-GCM with user-specific key
  /// Returns base64 encoded string in format: iv:encryptedData
  Future<String> encryptData(String plaintext, String userId) async {
    try {
      final key = _deriveKeyFromUserId(userId);
      
      // Generate random IV (Initialization Vector)
      final iv = enc.IV.fromSecureRandom(16);

      // Create encrypter with AES-GCM mode
      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.gcm),
      );

      // Encrypt the data
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Combine IV and encrypted data
      // Format: iv:encryptedData
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt a string that was encrypted with AES-256-GCM
  /// Expects format: iv:encryptedData
  Future<String> decryptData(String ciphertext, String userId) async {
    try {
      // Split the combined string
      final parts = ciphertext.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid ciphertext format');
      }

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);
      final key = _deriveKeyFromUserId(userId);

      // Create encrypter with AES-GCM mode
      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.gcm),
      );

      // Decrypt the data
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Check if data is encrypted (has our format: iv:encryptedData)
  bool _isEncrypted(String data) {
    return data.contains(':') && data.split(':').length == 2;
  }

  /// Decrypt with fallback for unencrypted data
  /// Returns the original data if decryption fails or data is not encrypted
  Future<String> decryptDataSafe(String data, String userId) async {
    // If data is not in encrypted format, return as-is
    if (!_isEncrypted(data)) {
      return data;
    }

    try {
      return await decryptData(data, userId);
    } catch (e) {
      // Log error but return original data instead of throwing
      // This can happen when:
      // 1. Data was encrypted with a different key (different user or old device-based key)
      // 2. Data is corrupted
      // 3. Format looks like encrypted but isn't
      print('⚠️ Decryption failed for user $userId, returning original data: $e');
      return data;
    }
  }

  /// Encrypt phone number before storage
  Future<String> encryptPhoneNumber(String phoneNumber, String userId) async {
    return await encryptData(phoneNumber, userId);
  }

  /// Decrypt phone number after retrieval
  Future<String> decryptPhoneNumber(String encryptedPhoneNumber, String userId) async {
    return await decryptData(encryptedPhoneNumber, userId);
  }

  /// Safe decryption for phone numbers with error handling
  Future<String> decryptPhoneNumberSafe(String encryptedPhoneNumber, String userId) async {
    return await decryptDataSafe(encryptedPhoneNumber, userId);
  }

  /// Encrypt address before storage
  Future<String> encryptAddress(String address, String userId) async {
    return await encryptData(address, userId);
  }

  /// Decrypt address after retrieval
  Future<String> decryptAddress(String encryptedAddress, String userId) async {
    return await decryptData(encryptedAddress, userId);
  }

  /// Safe decryption for addresses with error handling
  Future<String> decryptAddressSafe(String encryptedAddress, String userId) async {
    return await decryptDataSafe(encryptedAddress, userId);
  }

  /// Hash data using SHA-256 (one-way, for verification purposes)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify hashed data
  bool verifyHash(String data, String hash) {
    return hashData(data) == hash;
  }

  /// Clear user key cache (useful for logout or testing)
  void clearUserKeyCache() {
    _userKeys.clear();
  }
}
