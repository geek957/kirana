# Firebase Authentication App Check Fix

## Problem
After registering App Check in Firebase Console, getting error:
```
Invalid app info in play_integrity_token
Error: No AppCheckProvider installed / Too many attempts
```

## Root Cause
When you register App Check in Firebase Console, Firebase starts requiring App Check tokens from your app. Without the `firebase_app_check` SDK, the app can't generate these tokens.

## Solution Applied

### 1. Added firebase_app_check SDK
✅ Added to `pubspec.yaml`: `firebase_app_check: ^0.3.2+7`

### 2. Initialized App Check in main.dart
✅ Added initialization code:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
);
```

## Next Steps to Test

### For Debug Builds (flutter run):

1. **Clean rebuild:**
   ```bash
   /Users/ralakhil/flutter/bin/flutter clean
   /Users/ralakhil/flutter/bin/flutter pub get
   /Users/ralakhil/flutter/bin/flutter run
   ```

2. **Get the debug token from console output:**
   Look for a line like:
   ```
   D DebugAppCheckProvider: Enter this debug token in the Firebase Console: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
   Copy that entire token (UUID format).

3. **Register debug token in Firebase:**
   - Go to: https://console.firebase.google.com/project/kirana-grocery-app/appcheck
   - Find `com.akhilralla.flash` → click the **⋮** menu → **"Manage debug tokens"**
   - Click **"Add debug token"**
   - Paste the token → **Save**

4. **Restart the app and test OTP** — should work now!

### For Release Builds (flutter build):

Release builds use Play Integrity (not debug tokens), which should work automatically because:
- ✅ Play Integrity API is enabled
- ✅ App Check is registered with Play Integrity
- ✅ Release keystore SHA fingerprints are in Firebase Console

Just build and test:
```bash
/Users/ralakhil/flutter/bin/flutter build apk --release
/Users/ralakhil/flutter/bin/flutter install --release
```

## Verification Checklist

### Firebase Console:
- ✅ SHA fingerprints added (all 4: debug/release SHA-1/SHA-256)
- ✅ App Check registered with Play Integrity
- ✅ Phone authentication enabled in Sign-in methods
- ⏳ Debug token registered (needed for debug builds only)

### Google Cloud Console:
- ✅ Play Integrity API enabled
- ✅ Project matches Firebase project

### Code:
- ✅ `firebase_app_check` package added
- ✅ App Check initialized in main.dart
- ✅ Package name: `com.akhilralla.flash` everywhere
- ✅ MainActivity in correct location

## Troubleshooting

### "Too many attempts" error:
- This happens when App Check repeatedly fails to generate tokens
- Solution: Register the debug token (see steps above)

### "Invalid app info" still showing:
- Wait 2-5 minutes after enabling Play Integrity API
- Make sure you did a full `flutter clean` and rebuild
- Check that package name in app matches Firebase Console

### Debug token not showing in logs:
- Make sure you're running in debug mode (`flutter run`, not `flutter run --release`)
- Check the full console output, not just the errors
- The token line starts with `D DebugAppCheckProvider:`

## Summary

**For Development/Testing:**
- Use `AndroidProvider.debug` (automatically done via `kDebugMode` check)
- Register the debug token from console logs in Firebase
- Rebuild after registering the token

**For Production (Play Store):**
- Use `AndroidProvider.playIntegrity` (automatically done when not in debug)
- SHA fingerprints + Play Integrity API handle verification
- No debug token needed

Both are now properly configured in the code!
