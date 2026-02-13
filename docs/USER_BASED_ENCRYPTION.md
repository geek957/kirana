# User-Based Encryption Implementation

## Overview

Successfully migrated from device-specific encryption to user-based encryption for cross-device compatibility.

## Problem Solved

**Previous Issue**: Addresses encrypted on one device couldn't be decrypted on another device because each device generated its own unique encryption key.

**Solution**: Encryption keys are now derived from the user's ID (customerId), ensuring the same user has the same encryption key across all devices.

## Changes Made

### 1. EncryptionService (`lib/services/encryption_service.dart`)
**Complete rewrite** - Now uses user-based key derivation:

**Key Changes:**
- Removed `FlutterSecureStorage` dependency for key storage
- Removed device-specific key generation
- Added `_deriveKeyFromUserId()` method that creates encryption keys from userId + app salt
- All encryption/decryption methods now require `userId` parameter
- Keys are cached in memory for performance
- Safe decryption methods handle both encrypted and plain text data

**New Signature:**
```dart
Future<String> encryptData(String plaintext, String userId)
Future<String> decryptData(String ciphertext, String userId)
Future<String> decryptDataSafe(String data, String userId)
```

### 2. AddressService (`lib/services/address_service.dart`)
Updated all encryption/decryption calls to pass `customerId`:

**Methods Updated:**
- `addAddress()` - Pass customerId when encrypting
- `getCustomerAddresses()` - Pass customerId when decrypting
- `getAddressById()` - Pass customerId when decrypting  
- `updateAddress()` - Pass customerId when encrypting
- `getDefaultAddress()` - Pass customerId when decrypting
- `getCustomerAddressesStream()` - Pass customerId when decrypting

### 3. AuthService (`lib/services/auth_service.dart`)
Updated phone number encryption to use userId:

**Methods Updated:**
- `registerCustomer()` - Pass userId when encrypting phone number
- `getCustomer()` - Pass userId when decrypting phone number

### 4. Main App (`lib/main.dart`)
Removed encryption service initialization:
- Deleted `await EncryptionService().initialize()` call
- No initialization needed with user-based keys

## How It Works

### Key Derivation
```dart
// Derive encryption key from userId
final keyMaterial = utf8.encode('$userId:$_appSalt');
final digest = sha256.convert(keyMaterial);
final key = enc.Key(Uint8List.fromList(digest.bytes));
```

**Security:**
- Uses SHA-256 hash of userId + application salt
- 256-bit AES-GCM encryption
- Each user has unique encryption key
- Keys are cached in memory for performance

### Cross-Device Compatibility
- Same user = Same userId = Same encryption key
- Data encrypted on Device A can be decrypted on Device B
- No device-specific storage needed

## Important Notes

### ⚠️ Breaking Change
**Old addresses encrypted with device-based keys will show as encrypted strings.**

### Migration Required
You must delete all existing addresses from Firestore before testing:

**Option 1: Manual Deletion (Firebase Console)**
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Open `addresses` collection
4. Delete all documents

**Option 2: Script (if needed)**
```dart
// Run this once to clear old addresses
await FirebaseFirestore.instance
    .collection('addresses')
    .get()
    .then((snapshot) {
  for (var doc in snapshot.docs) {
    doc.reference.delete();
  }
});
```

## Testing Instructions

### 1. Clean Build
```bash
flutter clean
flutter pub get
```

### 2. Delete Old Addresses
- Clear all addresses from Firestore (see Migration section)

### 3. Test on Device A
```bash
flutter run --release
```
- Login with your account
- Add a new address
- Verify address displays correctly
- Note the address details

### 4. Test on Device B
```bash
# Install same APK on different device
flutter install
```
- Login with **same account**
- Navigate to addresses
- **✅ Verify**: Address from Device A displays correctly!
- Add another address on Device B

### 5. Verify Cross-Device
- Go back to Device A
- **✅ Verify**: Address from Device B now appears!
- Both devices show all addresses correctly

## Security Considerations

### Strengths
- ✅ Per-user encryption (data isolation)
- ✅ AES-256-GCM (industry standard)
- ✅ Random IV per encryption
- ✅ Works across devices

### Limitations
- ⚠️ UserId is stored in Firestore (known to attackers with database access)
- ⚠️ Key derivation uses simple hash (not PBKDF2/Argon2)
- ⚠️ No server-side key management

### Production Recommendations
For production deployment, consider:
1. **Server-side key management**: Store master key in Cloud Functions
2. **Stronger key derivation**: Use PBKDF2 with high iteration count
3. **Key rotation**: Ability to re-encrypt with new keys
4. **Audit logging**: Track encryption/decryption operations

## Comparison

### Before (Device-Based)
```dart
// Each device generates random key
_masterKey = enc.Key.fromSecureRandom(32);
await _secureStorage.write(key: _keyStorageKey, value: _masterKey!.base64);

// Problem: Different key on each device
```

### After (User-Based)
```dart
// Derive key from userId
final keyMaterial = utf8.encode('$userId:$_appSalt');
final digest = sha256.convert(keyMaterial);
_masterKey = enc.Key(Uint8List.fromList(digest.bytes));

// Solution: Same key for same user across all devices
```

## Files Modified

1. ✅ `lib/services/encryption_service.dart` - Complete rewrite
2. ✅ `lib/services/address_service.dart` - Updated all encryption calls
3. ✅ `lib/services/auth_service.dart` - Updated phone encryption
4. ✅ `lib/main.dart` - Removed initialization

## Dependencies

**Removed:**
- `flutter_secure_storage` (no longer needed for key storage)

**Still Required:**
- `encrypt: ^5.0.3` - AES encryption
- `crypto: ^3.0.6` - SHA-256 hashing

## Next Steps

1. **Delete old addresses** from Firestore
2. **Test thoroughly** on multiple devices
3. **Verify** cross-device functionality
4. **Consider** implementing server-side encryption for production
5. **Update** any other services that use encryption (if any)

## Rollback

If issues occur, revert these commits:
1. Restore old `encryption_service.dart`
2. Restore old `address_service.dart`  
3. Restore old `auth_service.dart`
4. Restore old `main.dart` with initialization

## Support

For issues or questions, refer to:
- `docs/ADDRESS_DECRYPTION_FIX.md` - Original decryption error fix
- This document - User-based encryption implementation
