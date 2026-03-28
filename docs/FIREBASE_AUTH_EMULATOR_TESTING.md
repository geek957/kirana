# Firebase Authentication Emulator Testing Guide

## The Problem: "Invalid app info in play_integrity_token"

When testing phone/OTP authentication on an **emulator**, you may encounter this error:
```
This app is not authorized to use Firebase Authentication.
Please verify that the correct package name, SHA-1, and SHA-256 are
configured in the Firebase Console. [ Invalid app info in play_integrity_token ]
```

## Root Cause

This error is caused by **Firebase Auth's built-in Play Integrity check** (not Firebase App Check). Firebase uses Play Integrity to prevent SMS abuse for phone authentication.

### Key Understanding:

```
┌─────────────────────────────────────────────────┐
│  Firebase App Check (your code in main.dart)    │
│  - You control this (can enable/disable)        │
│  - Protects Firestore, Storage, Functions       │
│  - Works on emulators with debug token          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Firebase Auth's Play Integrity (internal)      │
│  - Google controls this (always on)             │
│  - Prevents phone auth SMS abuse                │
│  - ❌ Does NOT work on emulators                │
│  - Built into firebase_auth SDK                 │
└─────────────────────────────────────────────────┘
```

**These are SEPARATE systems!** Commenting out your App Check code does NOT disable Firebase Auth's internal Play Integrity check.

## Why Emulators Fail

Play Integrity attestation requires:
- ✅ Real physical device with Google Play Services
- ✅ Genuine device (not rooted)
- ✅ Authentic app binary

Emulators fail because:
- ❌ Not recognized as "real devices"
- ❌ No proper Play Services integration
- ❌ Play Integrity rejects by design

## Solutions

### Option 1: Use Firebase Test Phone Numbers ⭐ RECOMMENDED

This is the **official Google-provided solution** for emulator testing.

#### Setup Steps:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → **Authentication**
3. Click **Sign-in method** tab → **Phone**
4. Scroll to **"Phone numbers for testing"** section
5. Click **"Add phone number"**
6. Enter:
   - **Phone number**: e.g., `+1 555 123 4567` or `+91 9999999999`
   - **Verification code**: e.g., `123456` (any 6-digit code you choose)
7. Click **Save**

#### Testing:

```dart
// In your app, when testing on emulator:
// 1. Enter the test phone number: +1 555 123 4567
// 2. When prompted for OTP, enter: 123456
// ✅ Login will succeed without Play Integrity check!
```

#### Benefits:
- ✅ Works on ANY emulator
- ✅ No SMS charges
- ✅ No Play Integrity check
- ✅ Official Google solution
- ✅ Unlimited testing

### Option 2: Test on Real Device

Connect a physical Android phone:

```bash
# Connect phone via USB
flutter devices  # Verify device is detected
flutter run      # Run on connected device
```

#### Requirements:
- Real Android device with Google Play Services
- USB debugging enabled
- SHA fingerprints added to Firebase Console

### Option 3: Use Play Store Emulator Image

Some emulator images have better Play Services support:

1. In Android Studio → **AVD Manager**
2. Create emulator with **"Google Play"** icon (not just "Google APIs")
3. These emulators have real Play Store and better attestation
4. May still require test phone numbers or real device for reliable testing

## SHA Fingerprints Setup

Even with test phone numbers, you should add SHA fingerprints to Firebase Console:

### Get Debug Keystore SHA:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Get Release Keystore SHA:

```bash
keytool -list -v -keystore /path/to/your-release-key.jks -alias your-alias-name -storepass your-store-password -keypass your-key-password
```

### Add to Firebase Console:

1. Go to **Firebase Console → Project Settings**
2. Scroll to **"Your apps"** → Select your Android app
3. Click **"Add fingerprint"**
4. Add both **SHA-1** and **SHA-256** for:
   - Debug keystore (for development)
   - Release keystore (for production)
   - Play Store signing key (if using Google Play App Signing)

## App Check Configuration

Our app uses Firebase App Check with graceful error handling:

```dart
// main.dart - App Check with try-catch
try {
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug         // Emulator/debug
        : AndroidProvider.playIntegrity, // Real device/release
    appleProvider: AppleProvider.deviceCheck,
  );
} catch (e) {
  // App continues to work even if App Check fails
  debugPrint('App Check activation failed: $e');
}
```

### App Check Debug Token (Optional):

If App Check is enforced in Firebase Console, register the debug token:

1. Run app on emulator: `flutter run`
2. Look for log line:
   ```
   D DebugAppCheckProvider: Enter this debug token in the Firebase Console: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
3. Copy the UUID token
4. Go to **Firebase Console → App Check → Apps tab**
5. Find your Android app → **⋮** menu → **"Manage debug tokens"**
6. Click **"Add debug token"** → Paste the token → **Save**

## Comparison Table

| Method | Emulator | Real Device | SMS Cost | Play Integrity |
|--------|----------|-------------|----------|----------------|
| **Test Phone Numbers** | ✅ Works | ✅ Works | Free | Bypassed |
| **Real Phone Numbers** | ❌ Fails | ✅ Works | Charges apply | Required |
| **Play Store Emulator** | ⚠️ Maybe | ✅ Works | Charges apply | Required |

## Troubleshooting

### "Invalid app info" on Emulator
**Solution**: Use test phone numbers in Firebase Console

### "Invalid app info" on Real Device
**Cause**: Missing SHA fingerprints
**Solution**: Add debug/release SHA to Firebase Console

### App Check enforcement errors
**Solution**: 
- Add App Check debug token to Firebase Console, OR
- Set App Check to "Monitoring" mode (not "Enforced") for development

### "Too many attempts" error
**Cause**: Firebase rate limiting
**Solution**: 
- Wait a few minutes
- Use test phone numbers
- Register App Check debug token

## Production Checklist

Before deploying to production:

- ✅ Add release keystore SHA-1 and SHA-256 to Firebase Console
- ✅ Add Play Store signing key SHA (if using Google Play App Signing)
- ✅ Remove or limit test phone numbers (security risk in production)
- ✅ App Check uses `AndroidProvider.playIntegrity` (automatically done via `kDebugMode` check)
- ✅ Test on real device before releasing

## Summary

**For Development (Emulator):**
- Use Firebase test phone numbers (no Play Integrity check)
- Or use real device for realistic testing

**For Production (Real Device):**
- Real phone numbers work automatically
- Play Integrity validates the app
- SHA fingerprints must be registered

**Firebase App Check is separate** from Firebase Auth's Play Integrity - one doesn't affect the other!
