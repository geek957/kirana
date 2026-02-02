# Firestore Security Rules Deployment Guide

## Overview
This document provides instructions for deploying the updated Firestore security rules for the Grocery App Enhancements.

## What's New in These Rules

### 1. Categories Collection Rules
- **Read**: All authenticated users can read categories
- **Write**: Only admins can create/update categories
- **Delete**: Only admins can delete, and only if `productCount == 0`
- **Validation**: Category name is required and must be non-empty

### 2. App Configuration Rules (`/config/app_settings`)
- **Read**: All authenticated users can read configuration
- **Write**: Only admins can update with validation
- **Validation Rules**:
  - `deliveryCharge >= 0`
  - `freeDeliveryThreshold > 0`
  - `maxCartValue > freeDeliveryThreshold`
  - `orderCapacityWarningThreshold > 0`
  - `orderCapacityBlockThreshold > orderCapacityWarningThreshold`

### 3. Enhanced Product Rules
- **Validation for new fields**:
  - `discountPrice < price` (if discount is set)
  - `minimumOrderQuantity >= 1`
  - `categoryId` must reference an existing category
- **Backward compatible**: Existing product operations continue to work

### 4. Enhanced Order Rules
- **Admin updates**: Can update status, delivery proof, and delivery charge
- **Customer remarks**: 
  - Customers can add/update remarks within 24 hours
  - Maximum 500 characters
  - Only `customerRemarks` and `remarksTimestamp` fields can be modified
- **Validation**: Enforces 24-hour edit window and character limits

## Prerequisites

1. **Firebase CLI installed**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase project initialized**:
   ```bash
   firebase login
   firebase init firestore
   ```

3. **Verify you're in the correct project**:
   ```bash
   firebase projects:list
   firebase use <project-id>
   ```

## Deployment Steps

### Step 1: Validate Rules Syntax
Before deploying, validate the rules syntax:

```bash
firebase deploy --only firestore:rules --dry-run
```

This will check for syntax errors without actually deploying.

### Step 2: Deploy Rules
Deploy the security rules to Firebase:

```bash
firebase deploy --only firestore:rules
```

### Step 3: Verify Deployment
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Verify the rules are updated with the new timestamp

### Step 4: Test Rules (Optional but Recommended)
Use the Firebase Console Rules Playground to test:

1. Go to **Firestore Database** → **Rules** → **Rules Playground**
2. Test scenarios:
   - **Category read** (authenticated user): Should succeed
   - **Category create** (non-admin): Should fail
   - **Config read** (authenticated user): Should succeed
   - **Config write** (non-admin): Should fail
   - **Product with invalid discount**: Should fail
   - **Order remarks update after 24h**: Should fail

## Testing Checklist

After deployment, verify these scenarios work correctly:

### Categories
- [ ] Authenticated users can read categories
- [ ] Non-admin users cannot create categories
- [ ] Admin users can create categories
- [ ] Cannot delete category with products (productCount > 0)
- [ ] Can delete category with no products (productCount == 0)

### App Configuration
- [ ] Authenticated users can read config
- [ ] Non-admin users cannot update config
- [ ] Admin users can update config with valid values
- [ ] Invalid config values are rejected (e.g., negative delivery charge)

### Products
- [ ] Cannot create product with discountPrice >= price
- [ ] Cannot create product with minimumOrderQuantity < 1
- [ ] Cannot create product with non-existent categoryId
- [ ] Valid products can be created by admins

### Orders
- [ ] Admin can update order status and delivery proof
- [ ] Customer can add remarks to their own orders
- [ ] Customer cannot update remarks after 24 hours
- [ ] Customer cannot add remarks longer than 500 characters
- [ ] Customer cannot update other order fields

## Rollback Procedure

If issues occur after deployment, you can rollback to previous rules:

1. Go to Firebase Console → Firestore Database → Rules
2. Click on the **History** tab
3. Select the previous version
4. Click **Restore**

Alternatively, if you have the previous rules file:

```bash
# Restore from backup
cp firestore.rules.backup firestore.rules
firebase deploy --only firestore:rules
```

## Common Issues and Solutions

### Issue: "Permission denied" errors after deployment
**Solution**: Verify that:
- Users are properly authenticated
- Admin users have `isAdmin: true` in their customer document
- The `isAdmin()` helper function is working correctly

### Issue: Category validation failing
**Solution**: Ensure category documents have:
- `name` field (required, non-empty)
- `productCount` field (required for deletion validation)

### Issue: Config validation failing
**Solution**: Verify all required fields are present:
- `deliveryCharge`, `freeDeliveryThreshold`, `maxCartValue`
- `orderCapacityWarningThreshold`, `orderCapacityBlockThreshold`
- All values meet validation constraints

### Issue: Product creation failing
**Solution**: Check that:
- Category exists before creating product
- `discountPrice < price` (if discount is set)
- `minimumOrderQuantity >= 1`

## Monitoring

After deployment, monitor for:
1. **Error rates**: Check Firebase Console → Firestore → Usage
2. **Permission denied errors**: Look for spikes in denied requests
3. **User reports**: Watch for user-reported issues with data access

## Notes

- These rules are **backward compatible** with existing data
- Existing products without new fields will continue to work
- The rules enforce data integrity at the database level
- Client-side validation should still be implemented for better UX

## Support

If you encounter issues:
1. Check Firebase Console logs
2. Review the Rules Playground test results
3. Verify the rules syntax with `firebase deploy --only firestore:rules --dry-run`
4. Consult the [Firebase Security Rules documentation](https://firebase.google.com/docs/firestore/security/get-started)

## Related Files

- `firestore.rules` - The security rules file
- `.kiro/specs/grocery-app-enhancements/design.md` - Section 6.3 for rule specifications
- `FIRESTORE_INDEXES_README.md` - For index configuration

---

**Last Updated**: Task 28 - Firestore Security Rules Update
**Validates**: All features in Grocery App Enhancements spec
