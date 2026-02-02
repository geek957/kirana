# Default Data Initialization Guide

This guide provides step-by-step instructions for initializing default data in the Kirana Online Grocery App. This must be done after Firebase setup and before the app becomes operational.

## Overview

The app requires the following default data to function properly:
1. **App Configuration Document** (`/config/app_settings`) - Business rules and settings
2. **Default Categories** - At least one product category (e.g., "Groceries")

## Prerequisites

Before starting, ensure you have:
- ✅ Firebase project created and configured
- ✅ Cloud Firestore database created
- ✅ Firebase Authentication enabled
- ✅ Admin account created (see `INITIAL_ADMIN_SETUP.md`)
- ✅ Access to Firebase Console
- ✅ Firebase CLI installed (optional, for script method)

---

## Method 1: Firebase Console (Recommended for First-Time Setup)

This is the recommended method for creating default data manually.

### Step 1: Create App Configuration Document

1. **Open Firebase Console**: https://console.firebase.google.com
2. **Select Your Project**: Choose the Kirana project
3. **Navigate to Firestore Database**:
   - Click "Firestore Database" in the left sidebar
   - You should see your collections

4. **Create Config Collection**:
   - Click "Start collection"
   - Collection ID: `config`
   - Click "Next"

5. **Create app_settings Document**:
   - Document ID: `app_settings` (type this exactly)
   - Add the following fields:

   | Field Name | Type | Value |
   |------------|------|-------|
   | `deliveryCharge` | number | `20` |
   | `freeDeliveryThreshold` | number | `200` |
   | `maxCartValue` | number | `3000` |
   | `orderCapacityWarningThreshold` | number | `2` |
   | `orderCapacityBlockThreshold` | number | `10` |
   | `updatedAt` | timestamp | (Click "Set to current time") |
   | `updatedBy` | string | `system` |

6. **Click "Save"**

7. **Verify the Document**:
   - Navigate to `config` → `app_settings`
   - Verify all fields are present with correct values
   - Verify `updatedAt` shows current timestamp

### Step 2: Create Default Categories

1. **In Firestore Database**, click "Start collection" (or add to existing)
2. **Collection ID**: `categories`
3. **Click "Next"**

4. **Create First Category - "Groceries"**:
   - Document ID: (Leave blank for auto-generated ID)
   - Add the following fields:

   | Field Name | Type | Value |
   |------------|------|-------|
   | `id` | string | (Copy the auto-generated document ID) |
   | `name` | string | `Groceries` |
   | `description` | string | `Essential grocery items and daily needs` |
   | `productCount` | number | `0` |
   | `createdAt` | timestamp | (Click "Set to current time") |
   | `updatedAt` | timestamp | (Click "Set to current time") |

5. **Click "Save"**

6. **Create Additional Categories** (Optional but Recommended):
   
   Repeat the process for these categories:

   **Category: "Fruits & Vegetables"**
   - `name`: `Fruits & Vegetables`
   - `description`: `Fresh fruits and vegetables`
   - `productCount`: `0`
   - `createdAt`: Current timestamp
   - `updatedAt`: Current timestamp

   **Category: "Dairy & Eggs"**
   - `name`: `Dairy & Eggs`
   - `description`: `Milk, cheese, yogurt, and eggs`
   - `productCount`: `0`
   - `createdAt`: Current timestamp
   - `updatedAt`: Current timestamp

   **Category: "Snacks & Beverages"**
   - `name`: `Snacks & Beverages`
   - `description`: `Snacks, drinks, and refreshments`
   - `productCount`: `0`
   - `createdAt`: Current timestamp
   - `updatedAt`: Current timestamp

   **Category: "Personal Care"**
   - `name`: `Personal Care`
   - `description`: `Personal hygiene and care products`
   - `productCount`: `0`
   - `createdAt`: Current timestamp
   - `updatedAt`: Current timestamp

7. **Verify Categories**:
   - Navigate to `categories` collection
   - Verify all categories are present
   - Verify each has all required fields

---

## Method 2: Firebase CLI with Scripts (Advanced)

For advanced users comfortable with command line tools and Node.js.

### Prerequisites
- Node.js installed (v14 or higher)
- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in to Firebase: `firebase login`
- Firebase Admin SDK credentials

### Step 1: Set Up Firebase Admin SDK

1. **Get Service Account Key**:
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save the JSON file as `serviceAccountKey.json` in your project root
   - **⚠️ IMPORTANT**: Add this file to `.gitignore` - never commit it!

2. **Install Dependencies**:
   ```bash
   npm install firebase-admin
   ```

### Step 2: Run Initialization Script

Use the provided initialization script (see `scripts/initialize_default_data.js`):

```bash
node scripts/initialize_default_data.js
```

The script will:
- Create the `config/app_settings` document with default values
- Create default categories
- Verify all data was created successfully
- Display a summary of created data

### Step 3: Verify Data

After running the script, verify in Firebase Console:
1. Check `config/app_settings` document exists
2. Check `categories` collection has entries
3. Verify all fields have correct values

---

## Method 3: Using Dart Script (Flutter Developers)

For Flutter developers who prefer Dart.

### Step 1: Create Dart Initialization Script

Use the provided Dart script (see `scripts/initialize_default_data.dart`):

```bash
dart scripts/initialize_default_data.dart
```

### Step 2: Verify Data

Check Firebase Console to verify data was created.

---

## Default Values Reference

### App Configuration (`/config/app_settings`)

```json
{
  "deliveryCharge": 20.0,
  "freeDeliveryThreshold": 200.0,
  "maxCartValue": 3000.0,
  "orderCapacityWarningThreshold": 2,
  "orderCapacityBlockThreshold": 10,
  "updatedAt": "2024-01-01T00:00:00.000Z",
  "updatedBy": "system"
}
```

**Field Descriptions**:
- `deliveryCharge`: Delivery fee in rupees (₹20)
- `freeDeliveryThreshold`: Cart value for free delivery (₹200)
- `maxCartValue`: Maximum allowed cart value (₹3000)
- `orderCapacityWarningThreshold`: Pending orders count to show warning (2)
- `orderCapacityBlockThreshold`: Pending orders count to block new orders (10)
- `updatedAt`: Last update timestamp
- `updatedBy`: User ID or "system" for initial setup

### Default Categories

**Minimum Required**: At least 1 category

**Recommended Categories**:

1. **Groceries**
   - Description: Essential grocery items and daily needs
   - Use for: Rice, flour, pulses, spices, oil, etc.

2. **Fruits & Vegetables**
   - Description: Fresh fruits and vegetables
   - Use for: All fresh produce

3. **Dairy & Eggs**
   - Description: Milk, cheese, yogurt, and eggs
   - Use for: All dairy products

4. **Snacks & Beverages**
   - Description: Snacks, drinks, and refreshments
   - Use for: Chips, biscuits, soft drinks, tea, coffee

5. **Personal Care**
   - Description: Personal hygiene and care products
   - Use for: Soap, shampoo, toothpaste, etc.

---

## Verification Checklist

After initializing default data, verify the following:

### App Configuration Verification

- [ ] Document exists at `/config/app_settings`
- [ ] `deliveryCharge` = 20.0
- [ ] `freeDeliveryThreshold` = 200.0
- [ ] `maxCartValue` = 3000.0
- [ ] `orderCapacityWarningThreshold` = 2
- [ ] `orderCapacityBlockThreshold` = 10
- [ ] `updatedAt` is a valid timestamp
- [ ] `updatedBy` = "system"

### Categories Verification

- [ ] `categories` collection exists
- [ ] At least one category exists
- [ ] Each category has:
  - [ ] Unique auto-generated `id`
  - [ ] Valid `name` (non-empty string)
  - [ ] Optional `description`
  - [ ] `productCount` = 0
  - [ ] Valid `createdAt` timestamp
  - [ ] Valid `updatedAt` timestamp

### App Functionality Verification

- [ ] Admin can view categories in Category Management screen
- [ ] Admin can add new products and assign to categories
- [ ] Cart screen shows delivery charge calculation
- [ ] Cart screen shows free delivery threshold message
- [ ] Cart validates maximum cart value
- [ ] Order capacity warnings work correctly
- [ ] App Configuration screen displays current values
- [ ] Admin can update configuration values

---

## Troubleshooting

### Issue: Cannot Create Config Collection

**Possible Causes**:
- Insufficient permissions
- Firestore security rules blocking write
- Network connectivity issue

**Solutions**:
1. Verify you have owner/editor role in Firebase project
2. Check Firestore security rules allow admin writes
3. Try again with stable internet connection
4. Use Firebase Console instead of scripts

### Issue: Categories Not Appearing in App

**Possible Causes**:
- Category documents missing required fields
- App not fetching categories correctly
- Cache issue in app

**Solutions**:
1. Verify all required fields exist in Firestore
2. Check category documents have correct structure
3. Restart the app
4. Clear app cache and retry

### Issue: Timestamp Fields Not Saving

**Possible Causes**:
- Using wrong timestamp format
- Firestore expecting Timestamp object

**Solutions**:
1. In Firebase Console, use "Set to current time" option
2. In scripts, use `Timestamp.now()` or `FieldValue.serverTimestamp()`
3. Verify timestamp appears in Firestore Console

### Issue: Script Fails with Authentication Error

**Possible Causes**:
- Service account key not found
- Invalid credentials
- Insufficient permissions

**Solutions**:
1. Verify `serviceAccountKey.json` exists and is valid
2. Regenerate service account key from Firebase Console
3. Ensure service account has Firestore write permissions
4. Check file path in script is correct

### Issue: Duplicate Categories Created

**Possible Causes**:
- Script run multiple times
- Manual creation + script creation

**Solutions**:
1. Delete duplicate categories from Firebase Console
2. Modify script to check for existing categories before creating
3. Use unique category names

---

## Updating Default Values

### Updating App Configuration

**Via Firebase Console**:
1. Navigate to `config/app_settings`
2. Click on the field to edit
3. Update the value
4. Update `updatedAt` to current timestamp
5. Update `updatedBy` to admin user ID
6. Click "Update"

**Via Admin Panel** (Recommended):
1. Login as admin
2. Navigate to Settings → App Configuration
3. Update values in the form
4. Click "Save"
5. Changes are automatically synced to all devices

### Adding New Categories

**Via Firebase Console**:
1. Navigate to `categories` collection
2. Click "Add document"
3. Follow the same structure as default categories
4. Ensure `productCount` starts at 0

**Via Admin Panel** (Recommended):
1. Login as admin
2. Navigate to Category Management
3. Click "Add Category"
4. Enter name and description
5. Click "Save"

---

## Data Migration

If you need to migrate from old data structure:

### Migrating Existing Products

If you have products without categories:
1. Create default "Uncategorized" category
2. Update all products to reference this category
3. Manually reassign products to appropriate categories

### Migrating from Old Config Format

If you have configuration in different format:
1. Export old configuration values
2. Map to new AppConfig structure
3. Create new `config/app_settings` document
4. Verify all values are correct
5. Test app functionality

---

## Security Considerations

### Access Control

⚠️ **Important Security Notes**:
- Only admins should be able to modify configuration
- Configuration changes affect all users immediately
- Invalid configuration can break app functionality
- Always test configuration changes in development first

✅ **Best Practices**:
- Use Firestore security rules to restrict config writes to admins
- Validate configuration values before saving
- Keep audit trail of configuration changes
- Back up configuration before making changes
- Test configuration changes with test orders

### Firestore Security Rules

Ensure these rules are in place:

```javascript
match /config/app_settings {
  allow read: if request.auth != null;
  allow write: if isAdmin();
  
  // Validation
  allow write: if request.resource.data.deliveryCharge >= 0;
  allow write: if request.resource.data.freeDeliveryThreshold > 0;
  allow write: if request.resource.data.maxCartValue > request.resource.data.freeDeliveryThreshold;
}

match /categories/{categoryId} {
  allow read: if request.auth != null;
  allow create, update: if isAdmin();
  allow delete: if isAdmin() && resource.data.productCount == 0;
}
```

---

## Backup and Recovery

### Backing Up Default Data

**Manual Backup**:
1. Export Firestore data from Firebase Console
2. Save configuration values in a secure document
3. Keep backup of category list

**Automated Backup**:
1. Set up Firestore automatic backups
2. Schedule regular exports
3. Store backups in Cloud Storage

### Restoring Default Data

If data is accidentally deleted:
1. Stop the app to prevent further issues
2. Restore from backup or recreate using this guide
3. Verify all data is correct
4. Test app functionality
5. Resume normal operations

---

## Initial Setup Workflow

Recommended workflow for first-time setup:

### 1. Initialize Default Data
- Follow Method 1 (Firebase Console) for first-time setup
- Create app configuration document
- Create at least 3-5 default categories
- Verify all data in Firebase Console

### 2. Verify in App
- Login as admin
- Check Category Management screen shows categories
- Check App Configuration screen shows settings
- Verify all values are correct

### 3. Add Initial Products
- Navigate to Inventory Management
- Add 5-10 initial products
- Assign each product to a category
- Verify category product counts update

### 4. Test Configuration
- Create test customer account
- Add items to cart
- Verify delivery charge calculation
- Test free delivery threshold
- Test maximum cart value validation
- Test order capacity warnings

### 5. Monitor and Adjust
- Monitor app usage
- Adjust configuration values as needed
- Add more categories based on product catalog
- Update descriptions for clarity

---

## Next Steps

After initializing default data:

1. **Add Products**:
   - Login as admin
   - Navigate to Inventory Management
   - Add your product catalog
   - Assign products to categories

2. **Configure Settings**:
   - Review default configuration values
   - Adjust based on business needs
   - Test changes with test orders

3. **Train Team**:
   - Train admins on category management
   - Explain configuration settings
   - Document custom procedures

4. **Monitor Usage**:
   - Track order capacity
   - Monitor delivery charge impact
   - Adjust thresholds as needed

---

## Support

If you encounter issues during data initialization:

1. **Check Verification Checklist** above
2. **Review Troubleshooting Section**
3. **Check Firebase Console** for errors
4. **Verify Firestore Security Rules**
5. **Test with Admin Account**
6. **Contact Technical Support** if issues persist

---

## Related Documentation

- `FIREBASE_SETUP_GUIDE.md` - Firebase project setup
- `INITIAL_ADMIN_SETUP.md` - Creating admin accounts
- `ADMIN_USER_GUIDE.md` - Using admin features
- `DEPLOYMENT_GUIDE.md` - Deploying the app
- `TROUBLESHOOTING.md` - Common issues and solutions

---

**Default data initialization is complete! Your app is now ready for product catalog setup.**
