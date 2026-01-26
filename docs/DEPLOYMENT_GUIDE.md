# Deployment Guide - Kirana Online Grocery App

This guide provides step-by-step instructions for deploying the Kirana app to production, including Firebase configuration, security setup, monitoring, and maintenance procedures.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Firebase Production Configuration](#firebase-production-configuration)
3. [Security Configuration](#security-configuration)
4. [Database Setup](#database-setup)
5. [Storage Configuration](#storage-configuration)
6. [Monitoring and Alerts](#monitoring-and-alerts)
7. [Backup Configuration](#backup-configuration)
8. [App Store Deployment](#app-store-deployment)
9. [Post-Deployment Verification](#post-deployment-verification)
10. [Maintenance and Updates](#maintenance-and-updates)

---

## Pre-Deployment Checklist

Before deploying to production, ensure all items are completed:

### Code Readiness
- [ ] All tests passing (unit, integration, property-based)
- [ ] No critical bugs or issues
- [ ] Code reviewed and approved
- [ ] Performance optimized
- [ ] Error handling implemented
- [ ] Security measures in place

### Firebase Setup
- [ ] Production Firebase project created
- [ ] Firebase services enabled (Auth, Firestore, Storage)
- [ ] Security rules deployed and tested
- [ ] Indexes created and deployed
- [ ] Billing account configured (if needed)

### Configuration
- [ ] Environment variables configured
- [ ] API keys secured
- [ ] Firebase config files updated
- [ ] App version numbers updated
- [ ] Release notes prepared

### Documentation
- [ ] User guides completed
- [ ] Admin documentation ready
- [ ] Troubleshooting guide available
- [ ] API documentation (if applicable)

### Testing
- [ ] Tested on multiple devices
- [ ] Tested on different OS versions
- [ ] Load testing completed
- [ ] Security testing performed
- [ ] User acceptance testing done

---

## Firebase Production Configuration

### 1. Create Production Firebase Project

1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Create New Project**:
   - Click "Add project"
   - Project name: `kirana-grocery-prod` (or your choice)
   - Enable Google Analytics (recommended)
   - Select or create Analytics account
   - Accept terms and create project

3. **Configure Project Settings**:
   - Go to Project Settings (gear icon)
   - Set project ID (cannot be changed later)
   - Configure support email
   - Set public-facing name

### 2. Enable Firebase Services

#### Firebase Authentication

1. Navigate to **Authentication** → **Sign-in method**
2. Enable **Phone** authentication:
   - Click on Phone provider
   - Enable the provider
   - Configure reCAPTCHA settings:
     - For production, use reCAPTCHA v2 or v3
     - Add authorized domains
   - Save changes

3. **Configure Phone Auth Settings**:
   - Set up SMS quota (default: 10,000/day)
   - Configure test phone numbers (for testing)
   - Set up App Verification (for iOS)

#### Cloud Firestore

1. Navigate to **Firestore Database**
2. Click **Create database**
3. **Select Mode**: Start in **production mode**
4. **Choose Location**: 
   - Select region closest to your users
   - For India: `asia-south1` (Mumbai)
   - For US: `us-central1`
   - **Note**: Location cannot be changed later

5. **Configure Settings**:
   - Enable offline persistence (done in app code)
   - Set up automatic backups (see Backup section)

#### Firebase Storage

1. Navigate to **Storage**
2. Click **Get started**
3. **Security Rules**: Start in production mode
4. **Choose Location**: Same as Firestore
5. **Configure Bucket**:
   - Default bucket created automatically
   - Note bucket URL for app configuration

#### Firebase Analytics

1. Navigate to **Analytics**
2. **Enable Analytics** (if not done during project creation)
3. **Configure Data Settings**:
   - Data retention: 14 months (maximum)
   - Enable Google Signals (for demographics)
   - Configure user properties

#### Firebase Crashlytics

1. Navigate to **Crashlytics**
2. Click **Enable Crashlytics**
3. Follow setup instructions for Flutter
4. Verify SDK integration

#### Firebase Performance Monitoring

1. Navigate to **Performance**
2. Click **Get started**
3. Follow setup instructions
4. Configure custom traces (already in code)

### 3. Configure Firebase for Flutter

#### Android Configuration

1. **Add Android App**:
   - Go to Project Settings → Your apps
   - Click Android icon
   - Package name: `com.example.kirana` (or your package)
   - App nickname: `Kirana Android`
   - SHA-1 certificate (for Phone Auth):
     ```bash
     # Debug certificate
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     
     # Release certificate
     keytool -list -v -keystore /path/to/release.keystore -alias your-alias
     ```
   - Register app

2. **Download google-services.json**:
   - Download the config file
   - Place in `android/app/google-services.json`
   - Commit to repository (production config)

3. **Verify Configuration**:
   - Ensure `google-services.json` has correct project ID
   - Check package name matches

#### iOS Configuration

1. **Add iOS App**:
   - Go to Project Settings → Your apps
   - Click iOS icon
   - Bundle ID: `com.example.kirana` (or your bundle)
   - App nickname: `Kirana iOS`
   - App Store ID (optional, for later)
   - Register app

2. **Download GoogleService-Info.plist**:
   - Download the config file
   - Place in `ios/Runner/GoogleService-Info.plist`
   - Add to Xcode project
   - Commit to repository

3. **Configure iOS Capabilities**:
   - Open Xcode project
   - Enable Push Notifications (if using FCM)
   - Configure App Groups (if needed)

#### Web Configuration (Optional)

1. **Add Web App**:
   - Go to Project Settings → Your apps
   - Click Web icon
   - App nickname: `Kirana Web`
   - Register app

2. **Copy Firebase Config**:
   - Copy the Firebase configuration object
   - Update `web/index.html` with config

### 4. Update Firebase Options in App

1. **Run FlutterFire Configure**:
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for all platforms
   flutterfire configure --project=kirana-grocery-prod
   ```

2. **Verify Generated Files**:
   - Check `lib/firebase_options.dart`
   - Ensure all platforms configured
   - Commit changes

---

## Security Configuration

### 1. Deploy Firestore Security Rules

The security rules are already defined in `firestore.rules`. Deploy them:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not done)
firebase init firestore

# Deploy security rules
firebase deploy --only firestore:rules
```

**Verify Rules**:
1. Go to Firebase Console → Firestore → Rules
2. Review deployed rules
3. Test rules using Rules Playground

### 2. Deploy Storage Security Rules

Update `storage.rules` for production:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Product images - public read, admin write
    match /products/{imageId} {
      allow read: if true;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/customers/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Prevent all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

Deploy:
```bash
firebase deploy --only storage
```

### 3. Configure Firebase Security Settings

1. **App Check** (Recommended for production):
   - Navigate to App Check in Firebase Console
   - Register your app
   - Enable enforcement for:
     - Firestore
     - Storage
     - Authentication
   - Configure providers (reCAPTCHA for web, DeviceCheck for iOS, Play Integrity for Android)

2. **Authentication Security**:
   - Set up authorized domains
   - Configure OAuth redirect domains
   - Enable email enumeration protection
   - Set up abuse prevention

3. **API Key Restrictions**:
   - Go to Google Cloud Console
   - Navigate to APIs & Services → Credentials
   - Restrict API keys by:
     - Application (Android/iOS bundle ID)
     - API (only enable needed APIs)
     - IP address (for server keys)

---

## Database Setup

### 1. Deploy Firestore Indexes

Indexes are defined in `firestore.indexes.json`. Deploy them:

```bash
firebase deploy --only firestore:indexes
```

**Required Indexes** (already in firestore.indexes.json):
- addresses: (customerId, isDefault)
- addresses: (customerId, createdAt DESC)
- products: (category, isActive)
- products: (searchKeywords, isActive)
- orders: (customerId, createdAt DESC)
- orders: (status, createdAt DESC)
- products: (stockQuantity ASC)

**Verify Indexes**:
1. Go to Firebase Console → Firestore → Indexes
2. Wait for all indexes to build (can take minutes)
3. Status should show "Enabled"

### 2. Initialize Database Collections

Create initial collections with proper structure:

```javascript
// Run this script once to initialize collections
// Can be done via Firebase Console or Cloud Functions

// Create initial categories (optional)
const categories = [
  'Fruits',
  'Vegetables',
  'Dairy',
  'Snacks',
  'Beverages',
  'Grains & Cereals',
  'Spices & Condiments',
  'Personal Care',
  'Household Items',
  'Others'
];

// Add to a 'categories' collection if needed
```

### 3. Set Up Data Validation

Firestore security rules already include validation. Verify:
- Required fields are enforced
- Data types are validated
- Field constraints are checked

---

## Storage Configuration

### 1. Configure Storage Bucket

1. **Set CORS Policy** (for web uploads):
   ```bash
   # Create cors.json
   echo '[
     {
       "origin": ["*"],
       "method": ["GET"],
       "maxAgeSeconds": 3600
     }
   ]' > cors.json
   
   # Apply CORS
   gsutil cors set cors.json gs://your-bucket-name.appspot.com
   ```

2. **Set Storage Quotas**:
   - Free tier: 5GB storage, 1GB/day downloads
   - Monitor usage in Firebase Console
   - Set up billing alerts

### 2. Organize Storage Structure

Recommended folder structure:
```
/products/
  /{productId}/
    /image.jpg
```

This is already implemented in `ImageUploadService`.

---

## Monitoring and Alerts

### 1. Configure Firebase Alerts

1. **Go to Firebase Console** → **Alerts**

2. **Enable Recommended Alerts**:
   - Crashlytics: New crash-free users below threshold
   - Performance: App start time degradation
   - Firestore: High read/write costs
   - Storage: Approaching quota limits
   - Authentication: Unusual activity

3. **Configure Alert Channels**:
   - Email notifications
   - Slack integration (optional)
   - PagerDuty (optional)

### 2. Set Up Budget Alerts

1. **Go to Google Cloud Console** → **Billing** → **Budgets & alerts**

2. **Create Budget**:
   - Name: "Kirana Monthly Budget"
   - Projects: Select your Firebase project
   - Budget amount: Set based on expected usage
   - Alert thresholds: 50%, 90%, 100%
   - Email notifications: Add admin emails

### 3. Configure Performance Monitoring

Already implemented in code. Verify:
- Custom traces are working
- Network requests are monitored
- Screen rendering is tracked

**Access Performance Data**:
- Firebase Console → Performance
- Review metrics regularly
- Set up alerts for degradation

### 4. Set Up Analytics Reporting

1. **Configure Analytics**:
   - Enable BigQuery export (optional, for advanced analytics)
   - Set up custom audiences
   - Configure conversion events

2. **Key Events to Monitor**:
   - `product_view`
   - `add_to_cart`
   - `begin_checkout`
   - `purchase` (order_placed)
   - `search`
   - `login`

3. **Create Custom Dashboards**:
   - Daily active users
   - Order conversion rate
   - Popular products
   - User retention

---

## Backup Configuration

### 1. Automated Firestore Backups

**Option 1: Scheduled Exports (Recommended)**

1. **Set Up Cloud Scheduler**:
   ```bash
   # Enable required APIs
   gcloud services enable cloudscheduler.googleapis.com
   gcloud services enable firestore.googleapis.com
   
   # Create Cloud Storage bucket for backups
   gsutil mb -l asia-south1 gs://kirana-firestore-backups
   
   # Create scheduled export job
   gcloud firestore export gs://kirana-firestore-backups \
     --async \
     --collection-ids='customers,products,orders,addresses'
   ```

2. **Schedule Daily Backups**:
   - Use Cloud Scheduler to run exports daily
   - Retention: Keep last 30 days
   - Cost: ~$0.026 per GB exported

**Option 2: Manual Backups**

```bash
# Export all collections
gcloud firestore export gs://kirana-firestore-backups/$(date +%Y%m%d)

# Export specific collections
gcloud firestore export gs://kirana-firestore-backups/$(date +%Y%m%d) \
  --collection-ids='customers,products,orders'
```

### 2. Storage Backups

Firebase Storage doesn't have built-in backups. Options:

1. **Versioning** (Recommended):
   - Enable object versioning on bucket
   - Keeps previous versions of files
   - Can restore deleted files

2. **Manual Backup**:
   ```bash
   # Download all files
   gsutil -m cp -r gs://your-bucket-name.appspot.com ./backup/
   ```

### 3. Backup Restoration

**Restore Firestore**:
```bash
# Import from backup
gcloud firestore import gs://kirana-firestore-backups/BACKUP_DATE
```

**Restore Storage**:
```bash
# Upload files back
gsutil -m cp -r ./backup/* gs://your-bucket-name.appspot.com/
```

### 4. Backup Testing

- Test restoration process quarterly
- Verify data integrity after restore
- Document restoration procedures
- Train team on backup/restore process

---

## App Store Deployment

### Android (Google Play Store)

1. **Prepare Release Build**:
   ```bash
   # Generate release keystore (first time only)
   keytool -genkey -v -keystore ~/kirana-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias kirana
   
   # Update android/key.properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=kirana
   storeFile=<path-to-keystore>
   ```

2. **Build Release APK/AAB**:
   ```bash
   # Build App Bundle (recommended)
   flutter build appbundle --release
   
   # Or build APK
   flutter build apk --release --split-per-abi
   ```

3. **Google Play Console**:
   - Create app listing
   - Upload app bundle
   - Complete store listing (description, screenshots, etc.)
   - Set up pricing and distribution
   - Submit for review

4. **Release Tracks**:
   - Internal testing → Closed testing → Open testing → Production
   - Use staged rollout (10% → 50% → 100%)

### iOS (Apple App Store)

1. **Prepare Release Build**:
   ```bash
   # Update version in pubspec.yaml
   version: 1.0.0+1
   
   # Build iOS release
   flutter build ios --release
   ```

2. **Xcode Configuration**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select "Any iOS Device" as target
   - Product → Archive
   - Validate app
   - Distribute app

3. **App Store Connect**:
   - Create app listing
   - Upload build via Xcode or Transporter
   - Complete app information
   - Add screenshots and preview videos
   - Submit for review

4. **TestFlight** (Optional):
   - Upload build to TestFlight
   - Invite beta testers
   - Gather feedback before production release

---

## Post-Deployment Verification

### 1. Smoke Testing

After deployment, verify core functionality:

**Customer Flow**:
- [ ] Registration and login works
- [ ] Products load correctly
- [ ] Search and filters work
- [ ] Add to cart functions
- [ ] Checkout process completes
- [ ] Order confirmation received
- [ ] Order appears in history

**Admin Flow**:
- [ ] Admin login works
- [ ] Dashboard loads with stats
- [ ] Can view inventory
- [ ] Can add/edit products
- [ ] Can upload images
- [ ] Can view orders
- [ ] Can update order status
- [ ] Notifications sent correctly

### 2. Monitor Initial Metrics

**First 24 Hours**:
- Crash-free users rate (target: >99%)
- App start time (target: <3 seconds)
- API response times (target: <2 seconds)
- Error rate (target: <1%)
- User registrations
- Orders placed

**First Week**:
- Daily active users
- User retention (Day 1, Day 7)
- Order conversion rate
- Average order value
- Customer feedback/reviews

### 3. Check Firebase Quotas

Monitor usage to ensure within limits:
- Firestore reads/writes
- Storage downloads
- Authentication requests
- Cloud Functions invocations (if used)

### 4. Review Logs and Errors

- Check Crashlytics for crashes
- Review error logs in Firebase
- Monitor performance metrics
- Check for security rule violations

---

## Maintenance and Updates

### Regular Maintenance Tasks

**Daily**:
- Monitor crash reports
- Check error logs
- Review customer support tickets
- Monitor order processing

**Weekly**:
- Review analytics data
- Check performance metrics
- Update inventory (admin task)
- Review user feedback

**Monthly**:
- Security audit
- Performance optimization
- Backup verification
- Cost analysis
- Feature planning

### Updating the App

1. **Version Numbering**:
   - Follow semantic versioning: MAJOR.MINOR.PATCH
   - Update in `pubspec.yaml`
   - Update build number for each release

2. **Release Process**:
   - Create release branch
   - Update version numbers
   - Update changelog
   - Build and test
   - Deploy to stores
   - Monitor rollout

3. **Hotfix Process**:
   - Create hotfix branch from production
   - Fix critical issue
   - Fast-track testing
   - Deploy immediately
   - Merge back to main branch

### Firebase Maintenance

**Regular Tasks**:
- Review and optimize security rules
- Clean up old data (if needed)
- Optimize indexes
- Monitor costs
- Update Firebase SDKs

**Quarterly Reviews**:
- Security audit
- Performance review
- Cost optimization
- Backup testing
- Disaster recovery drill

---

## Deployment Checklist

Use this checklist for each deployment:

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Version numbers updated
- [ ] Changelog updated
- [ ] Firebase config updated
- [ ] Security rules deployed
- [ ] Indexes deployed
- [ ] Backup created

### Deployment
- [ ] Build release version
- [ ] Test release build
- [ ] Upload to stores
- [ ] Submit for review
- [ ] Monitor review status

### Post-Deployment
- [ ] Smoke testing completed
- [ ] Metrics monitored
- [ ] No critical errors
- [ ] User feedback reviewed
- [ ] Team notified
- [ ] Documentation updated

---

## Rollback Procedure

If critical issues are found after deployment:

1. **Immediate Actions**:
   - Pause rollout in Play Console/App Store Connect
   - Assess severity and impact
   - Notify team and stakeholders

2. **Rollback Options**:
   - **App Stores**: Promote previous version
   - **Firebase**: Revert security rules/indexes if needed
   - **Database**: Restore from backup (last resort)

3. **Post-Rollback**:
   - Investigate root cause
   - Fix issue
   - Test thoroughly
   - Redeploy with fix

---

## Support and Resources

### Firebase Documentation
- Firebase Console: https://console.firebase.google.com
- Firebase Docs: https://firebase.google.com/docs
- FlutterFire: https://firebase.flutter.dev

### Monitoring
- Firebase Console for real-time monitoring
- Google Cloud Console for billing and quotas
- App Store Connect / Play Console for app metrics

### Emergency Contacts
- System Administrator: [contact info]
- Firebase Support: https://firebase.google.com/support
- Google Cloud Support: [if applicable]

---

**Deployment is complete! Monitor the app closely for the first few days and be ready to respond to any issues.**
