# Fix Android FCM Configuration Error

## Problem
```
E/GoogleApiManager: SecurityException: Unknown calling package name 'com.google.android.gms'
ConnectionResult{statusCode=DEVELOPER_ERROR...}
```

This error prevents push notifications from working on Android.

## Solution Steps

### Step 1: Get Your App's SHA-1 Fingerprint

**For Debug Build:**
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 fingerprint under `Variant: debug` -> `Config: debug`:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**For Release Build (if testing with release):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ (Settings) → Project settings
4. Scroll to "Your apps" section
5. Find your Android app
6. Click "Add fingerprint"
7. Paste your SHA-1 fingerprint
8. Click "Save"

### Step 3: Download New google-services.json

1. In Firebase Console, same page as above
2. Click "google-services.json" download button
3. Replace the file in your project:
   ```bash
   cp ~/Downloads/google-services.json android/app/google-services.json
   ```

### Step 4: Rebuild and Test

```bash
# Clean and rebuild
flutter clean
cd android
./gradlew clean
cd ..
flutter run
```

## Alternative Issues

### Issue 2: Package Name Mismatch

Verify package names match:

**In Firebase Console:**
- Settings → Your apps → Android package name

**In Your App:**
```bash
# Check android/app/build.gradle
grep applicationId android/app/build.gradle.kts
```

Should output something like:
```
applicationId = "com.example.kirana"
```

These MUST match exactly.

### Issue 3: Google Play Services Version

If using emulator, ensure Google Play Services is installed:
1. Android Studio → Tools → SDK Manager
2. SDK Tools tab
3. Check "Google Play services"
4. Click Apply

### Issue 4: google-services.json Not Applied

Verify the file is being processed:
```bash
# Check if plugin is applied
grep 'com.google.gms.google-services' android/app/build.gradle.kts
```

Should see:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## Testing FCM After Fix

### Test 1: Check Token Generation
After rebuilding, check logs for:
```
🟢 [AuthProvider] FCM token saved for user: [USER_ID]
```

### Test 2: Send Test Notification

From Firebase Console:
1. Engage → Messaging
2. Create campaign → Firebase Notification messages
3. Enter title and text
4. Click "Send test message"
5. Enter your FCM token (from logs above)
6. Test

### Test 3: Verify in Code
Add this temporary test code in your admin login:
```dart
// After successful login
final fcmToken = await FirebaseMessaging.instance.getToken();
print('📱 FCM Token: $fcmToken');

final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('📱 Auth Status: ${settings.authorizationStatus}');
```

If you see:
- `Auth Status: AuthorizationStatus.authorized` ✅
- A valid FCM token ✅

Then FCM is properly configured!

## Common Mistakes

❌ **Forgetting to download new google-services.json after adding SHA-1**
✅ Always re-download and replace the file

❌ **Using wrong keystore for release build**
✅ Use the same keystore you'll use for Play Store

❌ **Not rebuilding after configuration changes**
✅ Always flutter clean and rebuild

❌ **Testing on emulator without Google Play**
✅ Use a physical device or emulator with Google Play Services

## Still Not Working?

If errors persist after following all steps:

1. **Check Firebase Console Setup:**
   - Ensure Cloud Messaging API is enabled
   - Go to Project Settings → Cloud Messaging
   - Verify "Cloud Messaging API (Legacy)" is enabled

2. **Check Android Manifest:**
   ```xml
   <!-- Should be in android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```

3. **Enable Debug Logging:**
   ```kotlin
   // In android/app/src/main/kotlin/.../MainActivity.kt
   import android.util.Log
   
   // In onCreate
   Log.d("FCM_DEBUG", "Starting app...")
   ```

4. **Contact Support:**
   - Include your SHA-1 fingerprint
   - Include package name from both Firebase and app
   - Include relevant error logs

---

**Quick Command Reference:**
```bash
# Get SHA-1
cd android && ./gradlew signingReport

# Clean rebuild
flutter clean && flutter run

# Check package name
grep applicationId android/app/build.gradle.kts
