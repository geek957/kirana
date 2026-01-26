import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Service for encrypting and decrypting sensitive data using AES-256-GCM
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _keyStorageKey = 'encryption_master_key';

  enc.Key? _masterKey;

  /// Initialize the encryption service and load or generate the master key
  Future<void> initialize() async {
    await _loadOrGenerateMasterKey();
  }

  /// Load existing master key or generate a new one
  Future<void> _loadOrGenerateMasterKey() async {
    try {
      // Try to load existing key
      final storedKey = await _secureStorage.read(key: _keyStorageKey);

      if (storedKey != null) {
        _masterKey = enc.Key.fromBase64(storedKey);
      } else {
        // Generate new key
        _masterKey = enc.Key.fromSecureRandom(32); // 256 bits
        await _secureStorage.write(
          key: _keyStorageKey,
          value: _masterKey!.base64,
        );
      }
    } catch (e) {
      throw Exception('Failed to initialize encryption key: $e');
    }
  }

  /// Encrypt a string using AES-256-GCM
  /// Returns base64 encoded string in format: iv:encryptedData:tag
  Future<String> encryptData(String plaintext) async {
    if (_masterKey == null) {
      await initialize();
    }

    try {
      // Generate random IV (Initialization Vector)
      final iv = enc.IV.fromSecureRandom(16);

      // Create encrypter with AES-GCM mode
      final encrypter = enc.Encrypter(
        enc.AES(_masterKey!, mode: enc.AESMode.gcm),
      );

      // Encrypt the data
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Combine IV, encrypted data, and authentication tag
      // Format: iv:encryptedData:tag
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt a string that was encrypted with AES-256-GCM
  /// Expects format: iv:encryptedData:tag
  Future<String> decryptData(String ciphertext) async {
    if (_masterKey == null) {
      await initialize();
    }

    try {
      // Split the combined string
      final parts = ciphertext.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid ciphertext format');
      }

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);

      // Create encrypter with AES-GCM mode
      final encrypter = enc.Encrypter(
        enc.AES(_masterKey!, mode: enc.AESMode.gcm),
      );

      // Decrypt the data
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Encrypt phone number before storage
  Future<String> encryptPhoneNumber(String phoneNumber) async {
    return await encryptData(phoneNumber);
  }

  /// Decrypt phone number after retrieval
  Future<String> decryptPhoneNumber(String encryptedPhoneNumber) async {
    return await decryptData(encryptedPhoneNumber);
  }

  /// Encrypt address before storage
  Future<String> encryptAddress(String address) async {
    return await encryptData(address);
  }

  /// Decrypt address after retrieval
  Future<String> decryptAddress(String encryptedAddress) async {
    return await decryptData(encryptedAddress);
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

  /// Clear the master key (for testing or key rotation)
  Future<void> clearMasterKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
    _masterKey = null;
  }

  /// Rotate the master key (re-encrypt all data with new key)
  /// Note: This should be used carefully and requires re-encrypting all existing data
  Future<void> rotateMasterKey() async {
    await clearMasterKey();
    await _loadOrGenerateMasterKey();
  }
}
