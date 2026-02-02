# Deployment Guide - Version 2.0

## Overview

This guide provides step-by-step instructions for deploying version 2.0 of the Grocery App to production. Follow each step carefully to ensure a smooth deployment.

**Target Version:** 2.0.0  
**Deployment Date:** _________________  
**Deployment Manager:** _________________

---

## Pre-Deployment Requirements

### Prerequisites Checklist
- [ ] All testing completed and passed (see FINAL_TESTING_CHECKLIST.md)
- [ ] All critical issues resolved
- [ ] Documentation updated
- [ ] Release notes prepared
- [ ] Stakeholders notified
- [ ] Deployment window scheduled
- [ ] Rollback plan prepared
- [ ] Backup plan ready

### Required Access
- [ ] Firebase Console access
- [ ] Google Play Console access (for Android)
- [ ] App Store Connect access (for iOS)
- [ ] Firebase CLI installed and authenticated
- [ ] Flutter SDK installed (version 3.16.0+)
- [ ] Xcode installed (for iOS builds)
- [ ] Android Studio installed (for Android builds)

### Team Availability
- [ ] Technical lead available
- [ ] QA lead available
- [ ] Product manager available
- [ ] Support team notified
- [ ] On-call engineer assigned

---

## Deployment Timeline

### Recommended Schedule

**Day -7 (One Week Before):**
- Complete all feature development
- Begin final testing phase
- Update documentation

**Day -3 (Three Days Before):**
- Complete final testing
- Fix any critical issues
- Prepare release builds

**Day -1 (One Day Before):**
- Create production backup
- Deploy Firebase changes to staging
- Test staging environment
- Prepare rollback plan

**Day 0 (Deployment Day):**
- Deploy Firebase changes to production
- Submit app builds to stores
- Monitor deployment
- Verify functionality

**Day +1 (Day After):**
- Monitor metrics and errors
- Respond to user feedback
- Address any issues

---

## Step-by-Step Deployment

### Step 1: Create Production Backup

**1.1 Backup Firestore Data**

```bash
# Export Firestore data
gcloud firestore export gs://[YOUR-BUCKET]/backups/$(date +%Y%m%d)

# Verify export completed
gcloud firestore operations list
```

**Checklist:**
- [ ] Firestore export initiated
- [ ] Export completed successfully
- [ ] Backup location noted: _________________
- [ ] Backup size verified: _____ GB

**1.2 Backup Firebase Storage**

```bash
# Copy storage bucket
gsutil -m cp -r gs://[YOUR-BUCKET]/delivery_photos gs://[BACKUP-BUCKET]/backup-$(date +%Y%m%d)/delivery_photos
```

**Checklist:**
- [ ] Storage backup initiated
- [ ] Backup completed successfully
- [ ] Backup location noted: _________________

**1.3 Document Current State**

Create a snapshot document with:
- Current app version in stores
- Current Firebase configuration
- Current security rules version
- Current indexes
- Number of users
- Number of orders
- Number of products

**Checklist:**
- [ ] Snapshot document created
- [ ] All current state documented

---

### Step 2: Deploy Firebase Changes

**2.1 Deploy Firestore Security Rules**

```bash
# Navigate to project directory
cd /path/to/grocery-app

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules get
```

**Checklist:**
- [ ] Rules deployed successfully
- [ ] Deployment timestamp noted: _________________
- [ ] Rules verified in Firebase Console

**2.2 Deploy Firestore Indexes**

```bash
# Deploy indexes
firebase deploy --only firestore:indexes

# Verify indexes
# Check Firebase Console → Firestore → Indexes
```

**Checklist:**
- [ ] Indexes deployed successfully
- [ ] All indexes show "Enabled" status
- [ ] No indexes show "Error" status

**2.3 Deploy Storage Security Rules**

```bash
# Deploy storage rules
firebase deploy --only storage

# Verify deployment
firebase storage:rules get
```

**Checklist:**
- [ ] Storage rules deployed successfully
- [ ] Deployment timestamp noted: _________________
- [ ] Rules verified in Firebase Console

**2.4 Create Default Configuration Document**

Using Firebase Console or Admin SDK:

```javascript
// Create config document
const configRef = db.collection('config').doc('app_settings');
await configRef.set({
  deliveryCharge: 20,
  freeDeliveryThreshold: 200,
  maxCartValue: 3000,
  orderCapacityWarningThreshold: 2,
  orderCapacityBlockThreshold: 10,
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedBy: '[ADMIN-USER-ID]'
});
```

**Checklist:**
- [ ] Config document created
- [ ] All fields present and correct
- [ ] Document verified in Firebase Console

**2.5 Create Default Categories**

Using Firebase Console or Admin SDK:

```javascript
// Create default categories
const categories = [
  { name: 'Fresh Fruits', description: 'Fresh seasonal fruits' },
  { name: 'Fresh Vegetables', description: 'Farm fresh vegetables' },
  { name: 'Dairy Products', description: 'Milk, cheese, yogurt, and more' },
  { name: 'Snacks & Beverages', description: 'Snacks, drinks, and refreshments' },
  { name: 'Grains & Cereals', description: 'Rice, wheat, and cereals' },
  { name: 'Spices & Condiments', description: 'Spices, sauces, and condiments' },
  { name: 'Personal Care', description: 'Personal hygiene products' },
  { name: 'Household Items', description: 'Cleaning and household supplies' }
];

for (const category of categories) {
  await db.collection('categories').add({
    ...category,
    productCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
}
```

**Checklist:**
- [ ] All categories created
- [ ] Categories verified in Firebase Console
- [ ] Category names are unique

**2.6 Run Data Migration Script**

```bash
# Run migration to update existing products and orders
dart scripts/data_migration.dart

# Or use Node.js version
node scripts/data_migration.js
```

**Migration Tasks:**
- Assign all products to categories
- Set minimumOrderQuantity = 1 for all products
- Add deliveryCharge = 0 to historical orders

**Checklist:**
- [ ] Migration script executed
- [ ] All products have categoryId
- [ ] All products have minimumOrderQuantity
- [ ] All orders have deliveryCharge field
- [ ] No data corruption
- [ ] Sample data verified

---

### Step 3: Build Release Versions

**3.1 Update Version Numbers**

**Android (android/app/build.gradle):**
```gradle
android {
    defaultConfig {
        versionCode 20
        versionName "2.0.0"
    }
}
```

**iOS (ios/Runner/Info.plist):**
```xml
<key>CFBundleShortVersionString</key>
<string>2.0.0</string>
<key>CFBundleVersion</key>
<string>20</string>
```

**Checklist:**
- [ ] Android version updated
- [ ] iOS version updated
- [ ] Version numbers match

**3.2 Build Android Release**

```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

**Output Location:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

**Checklist:**
- [ ] Build completed successfully
- [ ] No build errors
- [ ] APK/AAB size reasonable: _____ MB
- [ ] Build signed correctly

**3.3 Build iOS Release**

```bash
# Clean build
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Create archive in Xcode
# Open ios/Runner.xcworkspace in Xcode
# Product → Archive
```

**Checklist:**
- [ ] Build completed successfully
- [ ] No build errors
- [ ] Archive created in Xcode
- [ ] Archive signed correctly

**3.4 Test Release Builds**

**Android:**
- [ ] Install APK on test device
- [ ] App launches successfully
- [ ] All features work
- [ ] No crashes
- [ ] Performance acceptable

**iOS:**
- [ ] Install via TestFlight or direct
- [ ] App launches successfully
- [ ] All features work
- [ ] No crashes
- [ ] Performance acceptable

---

### Step 4: Submit to App Stores

**4.1 Google Play Store (Android)**

**Prepare Store Listing:**
- [ ] Update app description with new features
- [ ] Update screenshots (include new features)
- [ ] Update "What's New" section
- [ ] Update privacy policy (if needed)
- [ ] Review store listing

**Upload Build:**
1. Open Google Play Console
2. Navigate to your app
3. Go to Release → Production
4. Create new release
5. Upload app-release.aab
6. Add release notes
7. Review and rollout

**Release Notes Template:**
```
Version 2.0 - Major Update!

New Features:
• Product discounts and promotions
• Browse products by category
• Delivery proof with photo and location
• Smart delivery charges (Free delivery on orders ₹200+)
• Order capacity management
• Enhanced push notifications
• Customer feedback system
• Configurable app settings

Improvements:
• Better product browsing
• Improved cart experience
• Enhanced admin tools
• Performance optimizations

Update now to enjoy these new features!
```

**Checklist:**
- [ ] Build uploaded
- [ ] Release notes added
- [ ] Store listing updated
- [ ] Screenshots updated
- [ ] Privacy policy updated
- [ ] Release submitted for review

**4.2 Apple App Store (iOS)**

**Prepare Store Listing:**
- [ ] Update app description with new features
- [ ] Update screenshots (include new features)
- [ ] Update "What's New" section
- [ ] Update privacy policy (if needed)
- [ ] Review store listing

**Upload Build:**
1. Open Xcode
2. Window → Organizer
3. Select archive
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Upload build

**Submit for Review:**
1. Open App Store Connect
2. Navigate to your app
3. Go to App Store → iOS App
4. Create new version (2.0.0)
5. Select uploaded build
6. Add release notes
7. Submit for review

**Release Notes Template:**
```
Version 2.0 - Major Update!

New Features:
• Product discounts and promotions
• Browse products by category
• Delivery proof with photo and location
• Smart delivery charges (Free delivery on orders ₹200+)
• Order capacity management
• Enhanced push notifications
• Customer feedback system
• Configurable app settings

Improvements:
• Better product browsing
• Improved cart experience
• Enhanced admin tools
• Performance optimizations

Update now to enjoy these new features!
```

**Checklist:**
- [ ] Build uploaded to App Store Connect
- [ ] Build processed successfully
- [ ] Release notes added
- [ ] Store listing updated
- [ ] Screenshots updated
- [ ] Privacy policy updated
- [ ] Submitted for review

---

### Step 5: Monitor Deployment

**5.1 App Store Review Status**

**Google Play Store:**
- Review typically takes 1-3 days
- Monitor status in Play Console
- Respond to any review questions promptly

**Apple App Store:**
- Review typically takes 1-2 days
- Monitor status in App Store Connect
- Respond to any review questions promptly

**Checklist:**
- [ ] Android review status: _________________
- [ ] iOS review status: _________________
- [ ] Any review issues: _________________

**5.2 Firebase Monitoring**

**Monitor Firebase Console:**
- [ ] Check Firestore usage
- [ ] Check Storage usage
- [ ] Check FCM delivery rates
- [ ] Check for errors in logs

**Key Metrics:**
```
Firestore Reads: _____
Firestore Writes: _____
Storage Downloads: _____
Storage Uploads: _____
FCM Success Rate: _____%
```

**5.3 Crashlytics Monitoring**

**Monitor Crashlytics:**
- [ ] Check crash-free users percentage
- [ ] Check for new crash types
- [ ] Check error logs
- [ ] Respond to critical crashes

**Target Metrics:**
```
Crash-Free Users: > 99.5%
Critical Crashes: 0
Non-Critical Crashes: < 5
```

**5.4 Analytics Monitoring**

**Monitor Firebase Analytics:**
- [ ] Check active users
- [ ] Check feature adoption rates
- [ ] Check user engagement
- [ ] Check conversion rates

**Key Events to Monitor:**
```
- category_filter_used
- discount_product_viewed
- free_delivery_achieved
- delivery_proof_captured
- customer_remarks_added
```

---

### Step 6: Post-Deployment Verification

**6.1 Verify App Availability**

**Google Play Store:**
- [ ] App visible in Play Store
- [ ] Correct version number displayed
- [ ] Release notes visible
- [ ] Screenshots updated
- [ ] Can download and install

**Apple App Store:**
- [ ] App visible in App Store
- [ ] Correct version number displayed
- [ ] Release notes visible
- [ ] Screenshots updated
- [ ] Can download and install

**6.2 Verify Firebase Configuration**

- [ ] Config document accessible
- [ ] Categories visible
- [ ] Products have new fields
- [ ] Orders have new fields
- [ ] Security rules active
- [ ] Indexes enabled

**6.3 Test Critical Flows**

**Customer Flow:**
1. [ ] Download and install app
2. [ ] Browse products by category
3. [ ] Add discounted product to cart
4. [ ] Verify delivery charge calculation
5. [ ] Place order
6. [ ] Receive notifications

**Admin Flow:**
1. [ ] Log in as admin
2. [ ] Access category management
3. [ ] Access app configuration
4. [ ] Process order
5. [ ] Capture delivery proof
6. [ ] Verify customer receives notification

**6.4 Monitor User Feedback**

**First 24 Hours:**
- [ ] Monitor app store reviews
- [ ] Monitor support tickets
- [ ] Monitor social media
- [ ] Respond to user questions
- [ ] Address critical issues immediately

**First Week:**
- [ ] Analyze user feedback
- [ ] Identify common issues
- [ ] Plan hotfixes if needed
- [ ] Gather feature requests

---

## Rollback Plan

### When to Rollback

Rollback if:
- Critical crashes affecting > 5% of users
- Data corruption detected
- Security vulnerability discovered
- Core functionality broken
- App store rejection with critical issues

### Rollback Steps

**1. Immediate Actions:**
- [ ] Notify stakeholders
- [ ] Stop any ongoing deployments
- [ ] Document the issue

**2. Revert Firebase Changes:**

```bash
# Revert Firestore rules
firebase deploy --only firestore:rules --version [PREVIOUS-VERSION]

# Revert Storage rules
firebase deploy --only storage --version [PREVIOUS-VERSION]
```

**3. Restore Database (if needed):**

```bash
# Import previous backup
gcloud firestore import gs://[YOUR-BUCKET]/backups/[BACKUP-DATE]
```

**4. Revert App Stores:**

**Google Play Store:**
- Create new release with previous version
- Or halt rollout and revert to previous version

**Apple App Store:**
- Remove current version from sale
- Submit previous version as new release

**5. Notify Users:**
- [ ] Send in-app notification
- [ ] Update app store description
- [ ] Post on social media
- [ ] Email affected users

**6. Post-Rollback:**
- [ ] Analyze root cause
- [ ] Fix issues
- [ ] Re-test thoroughly
- [ ] Plan re-deployment

---

## Post-Deployment Checklist

### Day 1 (Deployment Day)
- [ ] Apps submitted to stores
- [ ] Firebase changes deployed
- [ ] Monitoring active
- [ ] Team on standby
- [ ] No critical issues

### Day 2-7 (First Week)
- [ ] Monitor crash rates daily
- [ ] Monitor error rates daily
- [ ] Review user feedback daily
- [ ] Track feature adoption
- [ ] Address any issues

### Day 8-30 (First Month)
- [ ] Comprehensive analytics review
- [ ] User satisfaction assessment
- [ ] Performance optimization review
- [ ] Plan next iteration

---

## Success Criteria

### Technical Metrics
- [ ] Crash-free users > 99.5%
- [ ] API error rate < 2%
- [ ] Photo upload success rate > 95%
- [ ] Notification delivery rate > 95%
- [ ] App rating maintained or improved

### Business Metrics
- [ ] Feature adoption > 70% within 1 month
- [ ] Average order value increase > 15%
- [ ] Customer satisfaction > 4.5/5
- [ ] Support tickets not increased significantly

### User Feedback
- [ ] Positive app store reviews
- [ ] No major complaints
- [ ] Feature requests indicate engagement
- [ ] Users understand new features

---

## Communication Plan

### Stakeholder Updates

**Before Deployment:**
- Email to all stakeholders with deployment plan
- Slack/Teams announcement
- Schedule deployment meeting

**During Deployment:**
- Real-time updates in dedicated channel
- Notify of each major milestone
- Report any issues immediately

**After Deployment:**
- Deployment completion announcement
- Summary of deployment
- Initial metrics report
- Next steps

### User Communication

**In-App Announcement:**
```
🎉 New Features Available!

We've added exciting new features:
• Product discounts and categories
• Delivery proof with photos
• Free delivery on orders ₹200+
• Enhanced notifications
• And much more!

Update now to enjoy these features!
```

**Email to Users:**
- Highlight major features
- Explain benefits
- Provide links to user guides
- Encourage feedback

**Social Media:**
- Announcement posts
- Feature highlights
- Screenshots/videos
- User testimonials

---

## Deployment Sign-Off

### Pre-Deployment Approval

**Technical Lead:**  
Name: _________________  
Date: _________________  
Signature: _________________  
Status: [ ] Approved [ ] Rejected

**QA Lead:**  
Name: _________________  
Date: _________________  
Signature: _________________  
Status: [ ] Approved [ ] Rejected

**Product Manager:**  
Name: _________________  
Date: _________________  
Signature: _________________  
Status: [ ] Approved [ ] Rejected

### Post-Deployment Confirmation

**Deployment Manager:**  
Name: _________________  
Deployment Date: _________________  
Deployment Time: _________________  
Status: [ ] Successful [ ] Failed [ ] Rolled Back

**Notes:**
_________________________________
_________________________________
_________________________________

---

## Appendix

### Useful Commands

**Firebase Deployment:**
```bash
# Deploy all
firebase deploy

# Deploy specific
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage

# Check deployment status
firebase deploy:list
```

**Flutter Build:**
```bash
# Clean
flutter clean
flutter pub get

# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

**Firebase Backup:**
```bash
# Export Firestore
gcloud firestore export gs://[BUCKET]/backups/$(date +%Y%m%d)

# Import Firestore
gcloud firestore import gs://[BUCKET]/backups/[DATE]

# Copy Storage
gsutil -m cp -r gs://[SOURCE] gs://[DESTINATION]
```

### Contact Information

**Technical Support:**
- Email: tech-support@groceryapp.com
- Phone: +91-XXXX-XXXXXX
- Slack: #tech-support

**On-Call Engineer:**
- Name: _________________
- Phone: _________________
- Email: _________________

**Escalation:**
- Technical Lead: _________________
- Product Manager: _________________
- CTO: _________________

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Next Review:** Before next major deployment

