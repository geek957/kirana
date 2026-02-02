# Default Data Initialization - Quick Checklist

Quick reference checklist for initializing default data in Kirana Grocery App.

## Pre-Initialization Checklist

- [ ] Firebase project created
- [ ] Firestore database created
- [ ] Firebase Authentication enabled
- [ ] Admin account created
- [ ] Access to Firebase Console
- [ ] Service account key downloaded (for script method)

## Initialization Methods

Choose one method:

### Method 1: Firebase Console (Recommended for First-Time)
- [ ] Follow `docs/DEFAULT_DATA_INITIALIZATION.md` Method 1
- [ ] Create `/config/app_settings` document manually
- [ ] Create default categories manually
- [ ] Verify in Firebase Console

### Method 2: Node.js Script (Automated)
- [ ] Install Node.js dependencies: `cd scripts && npm install`
- [ ] Place `serviceAccountKey.json` in project root
- [ ] Run script: `node scripts/initialize_default_data.js`
- [ ] Verify output shows success
- [ ] Check Firebase Console

### Method 3: Dart Script (Template Generator)
- [ ] Run script: `dart scripts/initialize_default_data.dart`
- [ ] Review generated templates
- [ ] Use templates to create data manually
- [ ] Verify in Firebase Console

## App Configuration Document

**Path**: `/config/app_settings`

- [ ] Document exists
- [ ] `deliveryCharge` = 20.0
- [ ] `freeDeliveryThreshold` = 200.0
- [ ] `maxCartValue` = 3000.0
- [ ] `orderCapacityWarningThreshold` = 2
- [ ] `orderCapacityBlockThreshold` = 10
- [ ] `updatedAt` is valid timestamp
- [ ] `updatedBy` = "system"

## Default Categories

**Collection**: `categories`

- [ ] Collection exists
- [ ] At least 1 category exists (minimum requirement)
- [ ] Recommended: 5 categories created

### Category: Groceries
- [ ] `id` = auto-generated
- [ ] `name` = "Groceries"
- [ ] `description` = "Essential grocery items and daily needs"
- [ ] `productCount` = 0
- [ ] `createdAt` = valid timestamp
- [ ] `updatedAt` = valid timestamp

### Category: Fruits & Vegetables
- [ ] `id` = auto-generated
- [ ] `name` = "Fruits & Vegetables"
- [ ] `description` = "Fresh fruits and vegetables"
- [ ] `productCount` = 0
- [ ] `createdAt` = valid timestamp
- [ ] `updatedAt` = valid timestamp

### Category: Dairy & Eggs
- [ ] `id` = auto-generated
- [ ] `name` = "Dairy & Eggs"
- [ ] `description` = "Milk, cheese, yogurt, and eggs"
- [ ] `productCount` = 0
- [ ] `createdAt` = valid timestamp
- [ ] `updatedAt` = valid timestamp

### Category: Snacks & Beverages
- [ ] `id` = auto-generated
- [ ] `name` = "Snacks & Beverages"
- [ ] `description` = "Snacks, drinks, and refreshments"
- [ ] `productCount` = 0
- [ ] `createdAt` = valid timestamp
- [ ] `updatedAt` = valid timestamp

### Category: Personal Care
- [ ] `id` = auto-generated
- [ ] `name` = "Personal Care"
- [ ] `description` = "Personal hygiene and care products"
- [ ] `productCount` = 0
- [ ] `createdAt` = valid timestamp
- [ ] `updatedAt` = valid timestamp

## Firebase Console Verification

- [ ] Login to Firebase Console
- [ ] Navigate to Firestore Database
- [ ] Verify `config` collection exists
- [ ] Verify `app_settings` document exists with all fields
- [ ] Verify `categories` collection exists
- [ ] Verify all categories have required fields
- [ ] Check timestamps are valid (not null)
- [ ] Check no error messages in console

## App Verification

### Admin Panel Checks
- [ ] Login as admin
- [ ] Navigate to Category Management
- [ ] Verify all categories appear in list
- [ ] Verify categories are sorted alphabetically
- [ ] Navigate to App Configuration screen
- [ ] Verify all configuration values display correctly
- [ ] Verify values match defaults

### Functionality Checks
- [ ] Can add new product
- [ ] Can assign product to category
- [ ] Category product count updates when product added
- [ ] Can view products by category
- [ ] Cart shows delivery charge calculation
- [ ] Cart shows free delivery threshold message
- [ ] Cart validates maximum cart value
- [ ] Order capacity warnings work

## Post-Initialization Tasks

- [ ] Add initial products to catalog
- [ ] Assign products to appropriate categories
- [ ] Test customer flow (browse, cart, checkout)
- [ ] Test admin flow (manage products, orders)
- [ ] Verify notifications work
- [ ] Test configuration changes
- [ ] Document any custom categories added
- [ ] Train team on category management
- [ ] Set up monitoring and alerts

## Common Issues

### Issue: Config document not found
- [ ] Verify document ID is exactly `app_settings`
- [ ] Check collection name is exactly `config`
- [ ] Verify all fields are present

### Issue: Categories not appearing
- [ ] Check categories collection exists
- [ ] Verify category documents have all required fields
- [ ] Check `id` field matches document ID
- [ ] Restart app to refresh cache

### Issue: Timestamps showing as null
- [ ] Use "Set to current time" in Firebase Console
- [ ] Use `FieldValue.serverTimestamp()` in scripts
- [ ] Verify timestamp format is correct

### Issue: Script fails with auth error
- [ ] Verify `serviceAccountKey.json` exists
- [ ] Check service account has Firestore write permissions
- [ ] Regenerate service account key if needed

## Validation Commands

### Check Firestore Data (Firebase CLI)
```bash
# List config documents
firebase firestore:get config/app_settings

# List categories
firebase firestore:get categories
```

### Verify with Node.js Script
```bash
# Run verification only
node scripts/initialize_default_data.js --verify-only
```

## Rollback Procedure

If initialization fails or data is incorrect:

- [ ] Stop the app to prevent issues
- [ ] Delete incorrect documents from Firebase Console
- [ ] Re-run initialization script or recreate manually
- [ ] Verify all data is correct
- [ ] Test app functionality
- [ ] Resume normal operations

## Security Checklist

- [ ] Firestore security rules deployed
- [ ] Only admins can write to `config` collection
- [ ] Only admins can write to `categories` collection
- [ ] All users can read configuration
- [ ] Service account key not committed to git
- [ ] Service account key stored securely

## Documentation References

- [ ] Read `docs/DEFAULT_DATA_INITIALIZATION.md`
- [ ] Read `docs/FIREBASE_SETUP_GUIDE.md`
- [ ] Read `docs/INITIAL_ADMIN_SETUP.md`
- [ ] Read `scripts/README.md`
- [ ] Review `docs/TROUBLESHOOTING.md`

## Sign-Off

**Initialized By**: _______________  
**Date**: _______________  
**Method Used**: ☐ Console  ☐ Node.js Script  ☐ Dart Script  
**Verification Status**: ☐ Passed  ☐ Failed  
**Issues Encountered**: _______________  
**Notes**: _______________

---

**Status**: ☐ Complete  ☐ Incomplete  ☐ Needs Review

**Next Step**: Create admin account (see `docs/INITIAL_ADMIN_SETUP.md`)
