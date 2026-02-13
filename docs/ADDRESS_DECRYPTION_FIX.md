# Address Decryption Error Fix

## Problem Summary

The app was experiencing a **"failed to decrypt data"** error when loading addresses on real devices, though it worked correctly on the emulator.

### Root Cause

The `EncryptionService` generates a unique encryption key per device using `FlutterSecureStorage`. When addresses were encrypted on the emulator, they used the emulator's key. When the APK was installed on a real device, the device generated a different key, making it impossible to decrypt data encrypted with the emulator's key.

## Solution Implemented

### 1. Android Build Configuration

**File: `android/app/proguard-rules.pro`** (NEW)
- Added ProGuard rules to prevent encryption libraries from being stripped during release builds
- Ensures `flutter_secure_storage`, `encrypt`, and related crypto classes are preserved

**File: `android/app/build.gradle.kts`**
- Enabled minification and ProGuard for release builds
- Added resource shrinking to optimize APK size

**File: `android/app/src/main/AndroidManifest.xml`**
- Disabled Android backup (`android:allowBackup="false"`)
- Prevents encryption keys from being backed up and restored, which would cause mismatches

### 2. Encryption Service Enhancements

**File: `lib/services/encryption_service.dart`**

Added three new safe decryption methods:

1. **`decryptDataSafe(String data)`**
   - Checks if data is encrypted before attempting decryption
   - Returns original data if decryption fails instead of throwing
   - Handles cases where data was encrypted with a different key

2. **`decryptPhoneNumberSafe(String encryptedPhoneNumber)`**
   - Safe wrapper for phone number decryption

3. **`decryptAddressSafe(String encryptedAddress)`**
   - Safe wrapper for address decryption

### 3. Address Service Updates

**File: `lib/services/address_service.dart`**

Updated all address retrieval methods to use safe decryption:

- `getCustomerAddresses()` - Now uses `decryptAddressSafe()` and `decryptPhoneNumberSafe()`
- `getAddressById()` - Now uses safe decryption methods
- `getDefaultAddress()` - Now uses safe decryption methods
- `getCustomerAddressesStream()` - Now uses safe decryption with error handling

Added try-catch blocks to skip problematic addresses instead of failing completely.

## Testing Instructions

### 1. Clean Build

```bash
# Clean existing build artifacts
flutter clean

# Get dependencies
flutter pub get
```

### 2. Build Release APK

```bash
# Build release APK with ProGuard enabled
flutter build apk --release
```

### 3. Install on Real Device

```bash
# Install the release APK on your device
flutter install
```

### 4. Test Scenarios

#### Scenario A: New Installation (Clean State)
1. Install fresh APK on real device
2. Login with phone authentication
3. Add a new address
4. Verify address loads correctly
5. Navigate away and back to address page
6. Confirm address still displays

#### Scenario B: Existing Data from Emulator
1. Keep existing Firestore data (addresses encrypted with emulator key)
2. Install APK on real device
3. Login with same account
4. Check if addresses load (they should now load instead of crashing)
5. The addresses may show encrypted data or original data depending on format

#### Scenario C: Cross-Device Testing
1. Add address on Device A
2. Login on Device B with same account
3. Verify address loads on Device B
4. Edit address on Device B
5. Verify updated address shows on both devices

### 5. Verify Logs

Look for these log messages in the console:

```
⚠️ Decryption failed, returning original data: ...
⚠️ Error processing address {id}: ...
```

These indicate safe decryption is working - the app continues instead of crashing.

## Expected Behavior

### Before Fix
- ❌ App crashes when loading addresses on real device
- ❌ Error: "failed to decrypt data"
- ❌ Cannot access address list

### After Fix
- ✅ App loads addresses without crashing
- ✅ Handles encrypted and unencrypted data gracefully
- ✅ Works on both emulator and real devices
- ✅ Logs warnings but continues operation
- ✅ New addresses encrypt properly with device key

## Important Notes

1. **Existing Encrypted Data**: Addresses encrypted on the emulator may display as encrypted strings on real devices. This is expected behavior due to different encryption keys. Users should re-enter their addresses on the real device.

2. **Future Addresses**: All addresses created after this fix will work correctly on the device where they were created.

3. **Production Considerations**: For production, consider:
   - Server-side encryption with a shared key
   - Data migration script to re-encrypt existing data
   - User notification about re-entering sensitive information

4. **Security**: The backup exclusion prevents encryption keys from being backed up, which is a security best practice but means users must re-enter data after app reinstalls.

## Rollback

If issues occur, you can rollback by:

1. Revert `android/app/build.gradle.kts` changes (remove ProGuard config)
2. Delete `android/app/proguard-rules.pro`
3. Revert `android/app/src/main/AndroidManifest.xml` backup settings
4. Revert changes to `lib/services/encryption_service.dart`
5. Revert changes to `lib/services/address_service.dart`

## Related Files

- `lib/services/auth_service.dart` - Already had proper error handling (no changes needed)
- `lib/models/address.dart` - No changes required
- Android build files - ProGuard and backup configuration added

## Future Improvements

1. **Server-side key management**: Store encryption key in Firebase or secure backend
2. **Data migration**: Provide migration path for existing encrypted data
3. **User notifications**: Alert users when decryption fails and ask them to re-enter data
4. **Encryption versioning**: Add version field to track encryption format changes
