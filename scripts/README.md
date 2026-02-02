# Scripts Directory

This directory contains scripts for initializing default data and validating deployment readiness for the Kirana Grocery App.

## Available Scripts

### Initialization Scripts

#### 1. Node.js Initialization Script

**File**: `initialize_default_data.js`

Automated script that creates default data in Firestore.

**Prerequisites**:
- Node.js v14 or higher
- Firebase Admin SDK service account key
- npm or yarn

**Setup**:
```bash
# Install dependencies
cd scripts
npm install

# Get service account key from Firebase Console
# Project Settings → Service Accounts → Generate new private key
# Save as serviceAccountKey.json in project root
```

**Usage**:
```bash
# From project root
node scripts/initialize_default_data.js

# Or from scripts directory
npm run init
```

**Features**:
- Creates `/config/app_settings` document with default values
- Creates 5 default product categories
- Checks for existing data before creating
- Prompts before overwriting existing configuration
- Verifies all created data
- Provides detailed success/error messages

#### 2. Dart Template Generator

**File**: `initialize_default_data.dart`

Generates templates and instructions for manual data initialization.

**Prerequisites**:
- Dart SDK installed

**Usage**:
```bash
# From project root
dart scripts/initialize_default_data.dart
```

**Features**:
- Displays data templates in console
- Exports JSON templates to files
- Provides verification checklist
- Shows next steps

**Output Files**:
- `scripts/default_app_config.json` - App configuration template
- `scripts/default_categories.json` - Categories template

---

### Validation Scripts

#### 3. Pre-Deployment Validation Script

**File**: `pre_deployment_validation.dart`

Automated validation of project structure, dependencies, and configuration files before deployment.

**Prerequisites**:
- Dart SDK installed
- Project fully configured

**Usage**:
```bash
# From project root
dart scripts/pre_deployment_validation.dart
```

**Features**:
- Validates project directory structure
- Checks all required dependencies in pubspec.yaml
- Validates Android configuration (AndroidManifest.xml, permissions, google-services.json)
- Validates iOS configuration (Info.plist, permissions, GoogleService-Info.plist)
- Checks Firebase configuration files
- Validates asset files (notification sound)
- Verifies model, service, provider, and screen files exist
- Provides detailed pass/fail/warning summary
- Exits with appropriate status code for CI/CD integration

**Exit Codes**:
- `0` - All validations passed
- `1` - One or more validations failed

**Example Output**:
```
═══════════════════════════════════════════════════════════
   Grocery App - Pre-Deployment Validation Script
   Version: 2.0 (Enhanced Features)
═══════════════════════════════════════════════════════════

1. Project Structure Validation
────────────────────────────────────────────────────────────
  ✓ Directory: lib/models
  ✓ Directory: lib/services
  ...

VALIDATION SUMMARY
────────────────────────────────────────────────────────────
  ✓ Passed:   45
  ✗ Failed:   0
  ⚠ Warnings: 2
  ─────────────────────
  Total:      47

   ✓ VALIDATION PASSED - Ready for deployment!
```

#### 4. Firebase Setup Validation Script

**File**: `validate_firebase_setup.js`

Automated validation of Firebase configuration including Firestore, Storage, and default data.

**Prerequisites**:
- Node.js v14 or higher
- Firebase Admin SDK service account key
- npm dependencies installed

**Setup**:
```bash
# Install dependencies
cd scripts
npm install

# Get service account key from Firebase Console
# Save as serviceAccountKey.json in scripts/ directory
# OR set environment variable:
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
```

**Usage**:
```bash
# From project root
node scripts/validate_firebase_setup.js
```

**Features**:
- Validates Firestore collections exist
- Checks default configuration document (config/app_settings)
- Validates all required config fields and relationships
- Checks categories exist and are valid
- Validates products have required new fields (categoryId, minimumOrderQuantity)
- Checks for duplicate category names
- Validates discount prices
- Verifies Firebase Storage bucket exists
- Provides informational notes about Firestore indexes
- Detailed pass/fail/warning summary with color-coded output

**Exit Codes**:
- `0` - All validations passed
- `1` - One or more validations failed

**Example Output**:
```
═══════════════════════════════════════════════════════════
   Firebase Setup Validation Script
   Version: 2.0 (Enhanced Features)
═══════════════════════════════════════════════════════════

1. Firestore Collections Validation
────────────────────────────────────────────────────────────
  ✓ Collection 'products' exists
  ✓ Collection 'categories' exists
  ✓ Collection 'config' exists with app_settings document
  ...

VALIDATION SUMMARY
────────────────────────────────────────────────────────────
  ✓ Passed:   28
  ✗ Failed:   0
  ⚠ Warnings: 1
  ─────────────────────
  Total:      29

   ✓ VALIDATION PASSED - Firebase setup complete!
```

---

## Default Data

### App Configuration

**Document Path**: `/config/app_settings`

```json
{
  "deliveryCharge": 20.0,
  "freeDeliveryThreshold": 200.0,
  "maxCartValue": 3000.0,
  "orderCapacityWarningThreshold": 2,
  "orderCapacityBlockThreshold": 10,
  "updatedAt": "[timestamp]",
  "updatedBy": "system"
}
```

### Default Categories

**Collection**: `categories`

1. **Groceries** - Essential grocery items and daily needs
2. **Fruits & Vegetables** - Fresh fruits and vegetables
3. **Dairy & Eggs** - Milk, cheese, yogurt, and eggs
4. **Snacks & Beverages** - Snacks, drinks, and refreshments
5. **Personal Care** - Personal hygiene and care products

Each category includes:
- `id`: Auto-generated document ID
- `name`: Category name (unique)
- `description`: Category description
- `productCount`: Number of products (starts at 0)
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

## Pre-Deployment Validation Workflow

Before deploying to production, follow this validation workflow:

### Step 1: Run Project Validation
```bash
dart scripts/pre_deployment_validation.dart
```
- Fix any failures before proceeding
- Address warnings if possible

### Step 2: Run Firebase Validation
```bash
node scripts/validate_firebase_setup.js
```
- Fix any failures before proceeding
- Verify warnings are acceptable

### Step 3: Manual Verification
- Check Firestore indexes in Firebase Console
- Verify security rules deployed
- Test FCM notifications on real devices
- Complete device testing checklist

### Step 4: Device Testing
- Follow `docs/DEVICE_TESTING_GUIDE.md`
- Test on real Android device
- Test on real iOS device
- Verify all features work correctly

### Step 5: Final Sign-Off
- Complete `docs/PRE_DEPLOYMENT_VALIDATION.md`
- Get approvals from Technical Lead, QA Lead, and Product Manager
- Proceed with deployment

For complete pre-deployment validation process, see:
- `docs/PRE_DEPLOYMENT_VALIDATION.md` - Complete validation guide
- `docs/DEVICE_TESTING_GUIDE.md` - Device testing procedures
- `docs/DEPLOYMENT_CHECKLIST_ENHANCEMENTS.md` - Deployment checklist

---

## Security Notes

⚠️ **Important**: 
- Never commit `serviceAccountKey.json` to version control
- Add to `.gitignore` if not already present
- Store service account keys securely
- Rotate keys periodically
- Use environment-specific keys for dev/staging/prod

## Troubleshooting

### Initialization Scripts

#### Error: Service account key not found

**Solution**: Download service account key from Firebase Console and save as `serviceAccountKey.json` in project root.

#### Error: Permission denied

**Solution**: Ensure service account has Firestore write permissions (Firebase Admin role).

#### Error: Already exists

**Solution**: Script will prompt before overwriting. Choose 'yes' to overwrite or 'no' to keep existing data.

#### Error: Network timeout

**Solution**: Check internet connection and Firebase project status.

### Validation Scripts

#### Error: Validation script won't run

**Solution**: 
- Ensure Dart SDK is installed: `dart --version`
- Check file permissions: `chmod +x scripts/pre_deployment_validation.dart`
- Verify working directory is project root

#### Error: Firebase validation fails to initialize

**Solution**:
- Check service account key path
- Verify `GOOGLE_APPLICATION_CREDENTIALS` environment variable
- Ensure service account has read permissions
- Verify Firebase project ID is correct

#### Error: Many validation failures

**Solution**:
- Review each failure message carefully
- Fix critical issues first (missing files, permissions)
- Address warnings after critical issues resolved
- Re-run validation after fixes

#### Error: Indexes not found

**Solution**:
- Indexes must be created manually in Firebase Console
- Or deploy using: `firebase deploy --only firestore:indexes`
- Wait for index building to complete (can take several minutes)
- Verify in Firebase Console → Firestore → Indexes

---

## Environment Variables

The Node.js scripts support these environment variables:

- `SERVICE_ACCOUNT_PATH` - Path to service account key (default: `./serviceAccountKey.json`)
- `GOOGLE_APPLICATION_CREDENTIALS` - Alternative path to service account key
- `FIREBASE_PROJECT_ID` - Firebase project ID (optional, read from service account key)

**Example**:
```bash
SERVICE_ACCOUNT_PATH=/path/to/key.json node scripts/initialize_default_data.js
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node scripts/validate_firebase_setup.js
```

---

## CI/CD Integration

The validation scripts can be integrated into CI/CD pipelines:

### GitHub Actions Example
```yaml
- name: Validate Project Structure
  run: dart scripts/pre_deployment_validation.dart

- name: Validate Firebase Setup
  env:
    GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
  run: node scripts/validate_firebase_setup.js
```

### GitLab CI Example
```yaml
validate:
  script:
    - dart scripts/pre_deployment_validation.dart
    - node scripts/validate_firebase_setup.js
  only:
    - main
```

Both scripts exit with status code 1 on failure, which will fail the CI/CD pipeline.

---

## Manual Initialization

If you prefer manual initialization, see:
- `docs/DEFAULT_DATA_INITIALIZATION.md` - Complete manual setup guide
- Use Firebase Console to create documents directly

## Verification

### After Initialization

After running the initialization script, verify in Firebase Console:

1. **App Configuration**:
   - Navigate to Firestore → `config` → `app_settings`
   - Verify all fields are present with correct values

2. **Categories**:
   - Navigate to Firestore → `categories`
   - Verify all 5 categories exist
   - Check each has required fields

3. **In App**:
   - Login as admin
   - Check Category Management screen
   - Check App Configuration screen
   - Verify values match defaults

### After Validation

After running validation scripts:

1. **Review Output**:
   - Check for any failures (✗)
   - Review warnings (⚠)
   - Verify all critical checks passed

2. **Fix Issues**:
   - Address all failures before deployment
   - Review and address warnings
   - Re-run validation after fixes

3. **Document Results**:
   - Record validation results in `docs/PRE_DEPLOYMENT_VALIDATION.md`
   - Note any issues and resolutions
   - Get sign-off from team leads

---

## Next Steps

### After Initialization

After initializing default data:

1. Create admin account (see `docs/INITIAL_ADMIN_SETUP.md`)
2. Add products to categories
3. Test app functionality
4. Adjust configuration values as needed

### Before Deployment

Before deploying to production:

1. Run validation scripts (see Pre-Deployment Validation Workflow above)
2. Complete device testing (see `docs/DEVICE_TESTING_GUIDE.md`)
3. Review deployment checklist (see `docs/DEPLOYMENT_CHECKLIST_ENHANCEMENTS.md`)
4. Get sign-off from team leads
5. Proceed with deployment

---

## Support

For issues or questions:
- Check `docs/DEFAULT_DATA_INITIALIZATION.md` for detailed instructions
- Review `docs/TROUBLESHOOTING.md` for common issues
- Check Firebase Console for error messages

## Related Documentation

### Initialization
- `docs/DEFAULT_DATA_INITIALIZATION.md` - Complete initialization guide
- `docs/FIREBASE_SETUP_GUIDE.md` - Firebase project setup
- `docs/INITIAL_ADMIN_SETUP.md` - Admin account creation

### Validation & Deployment
- `docs/PRE_DEPLOYMENT_VALIDATION.md` - Complete validation guide
- `docs/DEVICE_TESTING_GUIDE.md` - Device testing procedures
- `docs/DEPLOYMENT_CHECKLIST_ENHANCEMENTS.md` - Deployment checklist
- `docs/DEPLOYMENT_GUIDE.md` - App deployment guide

### Troubleshooting
- `docs/TROUBLESHOOTING.md` - Common issues and solutions
- `docs/ERROR_HANDLING_GUIDE.md` - Error handling reference

---

**Last Updated:** January 2025  
**Version:** 2.0 (Enhanced Features)
