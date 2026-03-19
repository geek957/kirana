# Play Store Deployment Steps - Kirana (Flash Mart)

This guide provides the exact steps to deploy your Kirana app to Google Play Store with the application ID `com.flash.mart`.

## ✅ Code Changes Completed

The following code changes have been completed:
- ✅ Application ID changed to `com.flash.mart`
- ✅ Release signing configuration added
- ✅ `key.properties.template` created
- ✅ `.gitignore` updated for keystore security

---

## 📋 Deployment Steps

### Step 1: Generate Release Keystore (ONE-TIME ONLY)

Run this command to create your signing key:

```bash
keytool -genkey -v -keystore ~/kirana-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias kirana
```

**You will be asked for:**
- Keystore password (choose a strong password)
- Key password (can be the same as keystore password)
- Your name, organization, city, state, country

**⚠️ CRITICAL:** 
- **Back up this keystore file securely** (cloud storage, password manager, external drive)
- **Save the passwords** in a secure password manager
- **If you lose this keystore, you can NEVER update your app on Play Store!**
- Consider storing a backup on a separate device or cloud storage

---

### Step 2: Create `android/key.properties`

Copy the template and fill in your actual values:

```bash
cp android/key.properties.template android/key.properties
```

Then edit `android/key.properties` with your real passwords:

```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=kirana
storeFile=/Users/ralakhil/kirana-release-key.jks
```

**Security:** This file is in `.gitignore` and will NOT be committed to git.

---

### Step 3: Update Firebase Configuration

Since you changed the package name from `com.example.kirana` to `com.flash.mart`, you need to update Firebase:

**Option A: Add New Android App in Firebase Console**
1. Go to https://console.firebase.google.com
2. Select your Firebase project
3. Go to **Project Settings** → **General**
4. Under "Your apps", click **Add app** → **Android**
5. Android package name: `com.flash.mart`
6. App nickname: "Flash Mart Android"
7. **SHA-1 certificate** (get from your keystore):
   ```bash
   keytool -list -v -keystore ~/kirana-release-key.jks -alias kirana
   ```
   Copy the SHA-1 fingerprint and paste it in Firebase
8. Download the new `google-services.json`
9. Replace `android/app/google-services.json` with the new file

**Option B: Use FlutterFire CLI (Automated)**
```bash
# Install if not already installed
dart pub global activate flutterfire_cli

# Reconfigure with new package name
flutterfire configure --project=<your-firebase-project-id> --out=lib/firebase_options.dart
```

---

### Step 4: Update App Icon and Name

**App Icon:**
- Replace `android/app/src/main/res/mipmap-*/ic_launcher.png` with your app icon
- Use a tool like https://appicon.co/ to generate all sizes
- Or use `flutter_launcher_icons` package

**App Name:**
Edit `android/app/src/main/AndroidManifest.xml` and update:
```xml
<application
    android:label="Flash Mart"
    ...>
```

---

### Step 5: Build the Release AAB (App Bundle)

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release AAB
flutter build appbundle --release
```

**Output location:**
```
build/app/outputs/bundle/release/app-release.aab
```

**Verify the build:**
- Check file size (should be reasonable, typically 20-50MB)
- Test the release build on a physical device if possible

---

### Step 6: Create Google Play Developer Account

1. Go to https://play.google.com/console/signup
2. **Pay the $25 registration fee** (one-time)
3. Complete identity verification:
   - Personal information
   - ID verification (may take 1-3 days)
4. Accept developer agreement
5. Complete account details

---

### Step 7: Create App in Play Console

1. **Login to Play Console:** https://play.google.com/console
2. Click **"Create app"**
3. Fill in the form:
   - **App name:** Flash Mart (or "Kirana" or your choice)
   - **Default language:** English (United States) or Hindi
   - **App or game:** App
   - **Free or paid:** Free (or Paid)
   - **Declarations:** Check all boxes
4. Click **"Create app"**

---

### Step 8: Complete Store Listing (Dashboard → Store presence → Main store listing)

#### Required Information:

**App Details:**
- **App name:** Flash Mart
- **Short description:** (max 80 chars)
  ```
  Order fresh groceries online. Fast delivery. Easy shopping experience.
  ```
- **Full description:** (max 4000 chars)
  ```
  Flash Mart brings your neighborhood grocery store online. Order fresh 
  fruits, vegetables, dairy, snacks, and household essentials from the 
  comfort of your home.
  
  Features:
  • Browse products by category
  • Smart search and filters
  • Easy cart management
  • Secure phone number authentication
  • Multiple delivery addresses
  • Real-time order tracking
  • Push notifications for order updates
  • Save favorite addresses
  
  Fresh products, convenient delivery, trusted service.
  ```

**Graphics:** (All required)
- **App icon:** 512x512 px (PNG, 32-bit PNG with alpha)
- **Feature graphic:** 1024x500 px (JPEG or PNG, no transparency)
- **Phone screenshots:** Min 2, max 8 (JPEG/PNG, 16:9 or 9:16 ratio)
- **7-inch tablet screenshots:** Optional but recommended
- **10-inch tablet screenshots:** Optional

**Contact Details:**
- **Email:** your-support@email.com
- **Phone:** Optional
- **Website:** Optional (your website URL)

**Privacy Policy:**
- **Privacy policy URL:** **REQUIRED** (your app collects user data)
  - Must be accessible and valid
  - Should explain: data collection, usage, storage, sharing, user rights
  - Can use services like: https://www.freeprivacypolicy.com/

**App Category:**
- **App category:** Shopping
- **Tags:** Optional (grocery, shopping, delivery, etc.)

---

### Step 9: Complete App Content Section

#### 9.1 Privacy Policy
Upload or provide URL to your privacy policy (required since you collect phone numbers, addresses, location).

#### 9.2 App Access
If your app requires login:
- Provide **test account credentials**:
  ```
  Phone: +91 XXXXXXXXXX (or your test number)
  OTP: (explain how reviewers can get OTP)
  ```
- Or provide instructions: "Use any valid phone number, OTP will be sent via SMS"

#### 9.3 Ads Declaration
- Does your app contain ads? **No** (unless you've added ads)

#### 9.4 Content Rating
1. Click **"Start questionnaire"**
2. Select email for certificate
3. Answer questions about app content:
   - Violence: No
   - Sexual content: No
   - Profanity: No
   - Controlled substances: No
   - etc.
4. Submit and get rating (likely "Everyone" or "3+")

#### 9.5 Target Audience
- **Age group:** Select age ranges (likely 3+ or 18+)
- **Store presence:** Kids section? (Likely No)

#### 9.6 News App Declaration
- Is this a news app? **No**

#### 9.7 COVID-19 Contact Tracing & Status
- Contact tracing/status app? **No**

#### 9.8 Data Safety Section (IMPORTANT)
You must declare what data your app collects:

**Data Types Collected:**
- ✅ **Personal info:** 
  - Name
  - Phone number
  - Address (or location)
- ✅ **Financial info:** 
  - Purchase history
- ✅ **App activity:**
  - App interactions
  - In-app search history

**Data Usage:**
- App functionality
- Analytics
- Account management
- Personalization

**Data Sharing:**
- No third party sharing (unless you share data)

**Security Practices:**
- Data encrypted in transit (HTTPS)
- Data encrypted at rest (Firebase)
- User can request deletion
- Committed to Google Play Families Policy

---

### Step 10: Set Up Release with App Signing

1. **Go to:** Release → Setup → App integrity
2. **Choose App Signing:**
   - **Play App Signing (Recommended):** Google manages your signing key
     - Safer (Google keeps backup)
     - Required for app bundles
   - Select this option and follow prompts

3. **Upload Key:** Google will generate an upload certificate or you can use your existing keystore

---

### Step 11: Create Internal Testing Release

1. **Go to:** Testing → Internal testing
2. Click **"Create new release"**
3. **Upload AAB:**
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Google will analyze and may show warnings (review them)
4. **Release name:** 1.0.0 (1) or similar
5. **Release notes:**
   ```
   Initial release of Flash Mart
   
   Features:
   - Browse products by category
   - Search and filter products
   - Add items to cart
   - Secure checkout
   - Order tracking
   - Multiple delivery addresses
   - Push notifications
   ```
6. **Save** and **Review release**
7. Click **"Start rollout to Internal testing"**

---

### Step 12: Add Testers

1. In **Internal testing** → **Testers tab**
2. Create email list:
   - Add tester emails (Google accounts)
   - Or create a Google Group
3. **Save changes**
4. **Copy testing link** and share with testers
5. Testers need to:
   - Click the link
   - Accept invitation
   - Download app from Play Store

**Test thoroughly before moving to production!**

---

### Step 13: Move to Production

Once internal/closed testing is successful:

1. **Go to:** Production → Releases
2. **Create new release**
3. **Select the tested release** from previous track
4. **Add production release notes**
5. **Choose rollout percentage:**
   - Start with **staged rollout** (20% → 50% → 100%)
   - Recommended for first release: 20%
6. **Review and rollout**

---

### Step 14: Submit for Review

1. **Complete all required sections** (green checkmarks)
2. **Send for review:**
   - Go to Dashboard
   - Click **"Send X items for review"**
3. **Wait for review:**
   - Can take **hours to a few days**
   - You'll receive email updates
4. **If rejected:**
   - Review rejection reasons
   - Fix issues
   - Resubmit

---

## 🛠️ Quick Command Reference

```bash
# 1. Generate keystore (one-time)
keytool -genkey -v -keystore ~/kirana-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias kirana

# 2. Get SHA-1 from keystore
keytool -list -v -keystore ~/kirana-release-key.jks -alias kirana

# 3. Configure Firebase
flutterfire configure --project=<your-firebase-project-id>

# 4. Clean build
flutter clean && flutter pub get

# 5. Build release AAB
flutter build appbundle --release

# 6. Build release APK (for testing)
flutter build apk --release

# 7. Test release build on device
flutter install --release
```

---

## 📱 Testing Release Build

Before uploading to Play Store, test the release build:

```bash
# Build and install release APK
flutter build apk --release
flutter install --release

# Or manually install:
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Test checklist:**
- [ ] App launches successfully
- [ ] Firebase connection works (login, data loads)
- [ ] All features functional
- [ ] No crashes or errors
- [ ] Performance is good
- [ ] Images load correctly
- [ ] Notifications work
- [ ] Order flow completes

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Upload failed - Package name already exists"
**Solution:** Another app with `com.flash.mart` exists. Choose a different ID like:
- `com.yourname.flashmart`
- `com.flashmart.grocery`
- `com.yourdomain.kirana`

Then update `build.gradle.kts` and Firebase config.

### Issue 2: "App not signed properly"
**Solution:** 
- Verify `key.properties` exists and has correct paths
- Ensure keystore file exists at specified location
- Check passwords are correct

### Issue 3: "Firebase not working after package name change"
**Solution:** 
- Download new `google-services.json` from Firebase Console
- Ensure package name in `google-services.json` matches `com.flash.mart`
- Run `flutterfire configure` again

### Issue 4: "SHA-1 certificate error"
**Solution:** Add SHA-1 fingerprint to Firebase:
```bash
# Get SHA-1 from release keystore
keytool -list -v -keystore ~/kirana-release-key.jks -alias kirana
```
Add this to Firebase Console → Project Settings → Your apps → Android app → Add fingerprint

### Issue 5: "Review rejection - Missing privacy policy"
**Solution:** 
- Create a privacy policy (required for apps with user data)
- Host it on a public URL
- Add URL in Play Console store listing

### Issue 6: "App crashes on release build"
**Solution:** 
- Check ProGuard rules in `proguard-rules.pro`
- May need to add keep rules for Firebase/Flutter classes
- Test release build locally before uploading

---

## 📊 Post-Deployment Monitoring

After your app goes live, monitor:

### First 24 Hours:
- **Crashes:** Firebase Crashlytics dashboard
- **Ratings/Reviews:** Play Console → User feedback
- **Install metrics:** Play Console → Statistics
- **Performance:** Firebase Performance dashboard

### Ongoing:
- **Weekly:** Check reviews, crashes, performance
- **Monthly:** Analyze user metrics, plan updates
- **Updates:** Release updates for bugs, features, security

---

## 🔄 Future Updates

When releasing updates:

1. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 1.0.1+2  # version_name+build_number
   ```
   - Increment build number for every release
   - Increment version for user-facing changes

2. **Build new AAB:**
   ```bash
   flutter build appbundle --release
   ```

3. **Upload to Play Console:**
   - Go to existing app
   - Create new release in desired track
   - Upload new AAB
   - Add release notes
   - Roll out

---

## 📞 Support Resources

- **Play Console:** https://play.google.com/console
- **Google Play Developer Documentation:** https://developer.android.com/distribute/console
- **Flutter Release Documentation:** https://docs.flutter.dev/deployment/android
- **Firebase Console:** https://console.firebase.google.com

---

## Next Steps Summary

1. ✅ Code changes complete (applicationId, signing config)
2. ⏳ **Generate release keystore** (Step 1)
3. ⏳ **Create key.properties** (Step 2)
4. ⏳ **Update Firebase config** (Step 3)
5. ⏳ **Build release AAB** (Step 5)
6. ⏳ **Create Play Developer account** ($25 fee)
7. ⏳ **Set up app in Play Console** (Steps 7-9)
8. ⏳ **Upload and test** (Steps 11-12)
9. ⏳ **Submit for review** (Step 14)

**Time estimate:** 2-3 hours for setup + 1-3 days for Google review

Good luck with your launch! 🚀
