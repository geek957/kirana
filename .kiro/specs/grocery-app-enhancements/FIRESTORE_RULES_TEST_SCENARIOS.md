# Firestore Security Rules - Test Scenarios

## Overview
This document provides detailed test scenarios to verify the Firestore security rules are working correctly after deployment.

## Test Setup

### Test Users
You'll need the following test accounts:
1. **Admin User**: A user with `isAdmin: true` in their customer document
2. **Regular User**: A user with `isAdmin: false` or no isAdmin field
3. **Unauthenticated**: No authentication token

### Test Data
Create the following test data:
1. **Test Category**: A category with `productCount: 0`
2. **Test Category with Products**: A category with `productCount: 5`
3. **Test Product**: A product with all new fields
4. **Test Order**: An order with delivery proof fields

## Test Scenarios

### 1. Categories Collection Tests

#### Test 1.1: Read Categories (Authenticated User)
**Setup**: Login as regular user
**Action**: Read `/categories` collection
**Expected**: ✅ Success - User can read categories
**Validation**: Requirements 2.2.5, 2.2.6

#### Test 1.2: Read Categories (Unauthenticated)
**Setup**: No authentication
**Action**: Read `/categories` collection
**Expected**: ❌ Permission denied
**Validation**: Security requirement

#### Test 1.3: Create Category (Admin)
**Setup**: Login as admin user
**Action**: Create category with:
```json
{
  "name": "Test Category",
  "description": "Test description",
  "productCount": 0,
  "createdAt": [timestamp],
  "updatedAt": [timestamp]
}
```
**Expected**: ✅ Success
**Validation**: Requirements 2.2.1

#### Test 1.4: Create Category (Non-Admin)
**Setup**: Login as regular user
**Action**: Attempt to create category
**Expected**: ❌ Permission denied
**Validation**: Security requirement

#### Test 1.5: Create Category with Empty Name
**Setup**: Login as admin user
**Action**: Create category with `name: ""`
**Expected**: ❌ Validation error
**Validation**: Requirements 2.2.8

#### Test 1.6: Update Category (Admin)
**Setup**: Login as admin user
**Action**: Update existing category name
**Expected**: ✅ Success
**Validation**: Requirements 2.2.2

#### Test 1.7: Delete Category with Products
**Setup**: Login as admin user
**Action**: Delete category with `productCount: 5`
**Expected**: ❌ Permission denied
**Validation**: Requirements 2.2.7

#### Test 1.8: Delete Category without Products
**Setup**: Login as admin user
**Action**: Delete category with `productCount: 0`
**Expected**: ✅ Success
**Validation**: Requirements 2.2.3

---

### 2. App Configuration Tests

#### Test 2.1: Read Config (Authenticated User)
**Setup**: Login as regular user
**Action**: Read `/config/app_settings`
**Expected**: ✅ Success
**Validation**: Requirements 2.6.9-2.6.11

#### Test 2.2: Read Config (Unauthenticated)
**Setup**: No authentication
**Action**: Read `/config/app_settings`
**Expected**: ❌ Permission denied
**Validation**: Security requirement

#### Test 2.3: Update Config (Admin) - Valid Values
**Setup**: Login as admin user
**Action**: Update config with:
```json
{
  "deliveryCharge": 25.0,
  "freeDeliveryThreshold": 250.0,
  "maxCartValue": 3500.0,
  "orderCapacityWarningThreshold": 3,
  "orderCapacityBlockThreshold": 12,
  "updatedAt": [timestamp],
  "updatedBy": "admin-id"
}
```
**Expected**: ✅ Success
**Validation**: Requirements 2.6.9-2.6.11, 2.7.9

#### Test 2.4: Update Config (Non-Admin)
**Setup**: Login as regular user
**Action**: Attempt to update config
**Expected**: ❌ Permission denied
**Validation**: Security requirement

#### Test 2.5: Update Config - Negative Delivery Charge
**Setup**: Login as admin user
**Action**: Update config with `deliveryCharge: -10`
**Expected**: ❌ Validation error
**Validation**: Data integrity

#### Test 2.6: Update Config - Invalid Free Delivery Threshold
**Setup**: Login as admin user
**Action**: Update config with `freeDeliveryThreshold: 0`
**Expected**: ❌ Validation error
**Validation**: Data integrity

#### Test 2.7: Update Config - Max Cart < Free Delivery
**Setup**: Login as admin user
**Action**: Update config with:
- `freeDeliveryThreshold: 300`
- `maxCartValue: 200`
**Expected**: ❌ Validation error
**Validation**: Data integrity

#### Test 2.8: Update Config - Block < Warning Threshold
**Setup**: Login as admin user
**Action**: Update config with:
- `orderCapacityWarningThreshold: 10`
- `orderCapacityBlockThreshold: 5`
**Expected**: ❌ Validation error
**Validation**: Data integrity

---

### 3. Product Collection Tests

#### Test 3.1: Create Product with Valid Discount
**Setup**: Login as admin user
**Action**: Create product with:
```json
{
  "name": "Test Product",
  "price": 100.0,
  "discountPrice": 80.0,
  "categoryId": "valid-category-id",
  "minimumOrderQuantity": 2
}
```
**Expected**: ✅ Success
**Validation**: Requirements 2.1.1, 2.1.2

#### Test 3.2: Create Product with Invalid Discount
**Setup**: Login as admin user
**Action**: Create product with:
- `price: 100.0`
- `discountPrice: 120.0`
**Expected**: ❌ Validation error
**Validation**: Requirements 2.1.2

#### Test 3.3: Create Product with Discount Equal to Price
**Setup**: Login as admin user
**Action**: Create product with:
- `price: 100.0`
- `discountPrice: 100.0`
**Expected**: ❌ Validation error
**Validation**: Requirements 2.1.2

#### Test 3.4: Create Product with Invalid Min Quantity
**Setup**: Login as admin user
**Action**: Create product with `minimumOrderQuantity: 0`
**Expected**: ❌ Validation error
**Validation**: Requirements 2.4.2

#### Test 3.5: Create Product with Non-Existent Category
**Setup**: Login as admin user
**Action**: Create product with `categoryId: "non-existent-id"`
**Expected**: ❌ Validation error
**Validation**: Requirements 2.2.4

#### Test 3.6: Create Product without Discount
**Setup**: Login as admin user
**Action**: Create product with `discountPrice: null`
**Expected**: ✅ Success
**Validation**: Requirements 2.1.1

#### Test 3.7: Update Product - Remove Discount
**Setup**: Login as admin user
**Action**: Update product, set `discountPrice: null`
**Expected**: ✅ Success
**Validation**: Requirements 2.1.7

#### Test 3.8: Read Product (Unauthenticated)
**Setup**: No authentication
**Action**: Read product
**Expected**: ✅ Success (public read)
**Validation**: Existing functionality

---

### 4. Order Collection Tests

#### Test 4.1: Admin Update - Delivery Proof
**Setup**: Login as admin user
**Action**: Update order with:
```json
{
  "deliveryPhotoUrl": "https://storage.../photo.jpg",
  "deliveryLocation": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "status": "delivered",
  "updatedAt": [timestamp]
}
```
**Expected**: ✅ Success
**Validation**: Requirements 2.3.1-2.3.8

#### Test 4.2: Admin Update - Invalid Fields
**Setup**: Login as admin user
**Action**: Attempt to update `customerId` field
**Expected**: ❌ Permission denied
**Validation**: Security requirement

#### Test 4.3: Customer Add Remarks (First Time)
**Setup**: Login as customer (order owner)
**Action**: Update order with:
```json
{
  "customerRemarks": "Great service!",
  "remarksTimestamp": [timestamp]
}
```
**Expected**: ✅ Success
**Validation**: Requirements 2.8.1

#### Test 4.4: Customer Update Remarks (Within 24h)
**Setup**: Login as customer, order has remarks from 12 hours ago
**Action**: Update `customerRemarks`
**Expected**: ✅ Success
**Validation**: Requirements 2.8.3

#### Test 4.5: Customer Update Remarks (After 24h)
**Setup**: Login as customer, order has remarks from 25 hours ago
**Action**: Attempt to update `customerRemarks`
**Expected**: ❌ Permission denied
**Validation**: Requirements 2.8.3

#### Test 4.6: Customer Add Remarks - Too Long
**Setup**: Login as customer
**Action**: Add remarks with 501 characters
**Expected**: ❌ Validation error
**Validation**: Requirements 2.8.6

#### Test 4.7: Customer Add Remarks - Max Length
**Setup**: Login as customer
**Action**: Add remarks with exactly 500 characters
**Expected**: ✅ Success
**Validation**: Requirements 2.8.6

#### Test 4.8: Customer Update Other Fields
**Setup**: Login as customer
**Action**: Attempt to update `status` field
**Expected**: ❌ Permission denied
**Validation**: Security requirement

#### Test 4.9: Customer Update Another User's Order
**Setup**: Login as customer A
**Action**: Attempt to update customer B's order remarks
**Expected**: ❌ Permission denied
**Validation**: Security requirement

---

## Automated Testing with Firebase Emulator

You can use the Firebase Emulator Suite to automate these tests:

### Setup
```bash
npm install -D @firebase/rules-unit-testing
firebase emulators:start --only firestore
```

### Example Test (Jest/Mocha)
```javascript
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

describe('Firestore Security Rules', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'test-project',
      firestore: {
        rules: fs.readFileSync('firestore.rules', 'utf8'),
      },
    });
  });

  test('authenticated user can read categories', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const categoriesRef = alice.firestore().collection('categories');
    await assertSucceeds(categoriesRef.get());
  });

  test('non-admin cannot create category', async () => {
    const alice = testEnv.authenticatedContext('alice', { isAdmin: false });
    const categoriesRef = alice.firestore().collection('categories');
    await assertFails(categoriesRef.add({ name: 'Test' }));
  });

  // Add more tests...
});
```

## Manual Testing Checklist

Use this checklist when manually testing in Firebase Console:

### Categories
- [ ] ✅ Authenticated read succeeds
- [ ] ❌ Unauthenticated read fails
- [ ] ✅ Admin create succeeds
- [ ] ❌ Non-admin create fails
- [ ] ❌ Empty name validation fails
- [ ] ❌ Delete with products fails
- [ ] ✅ Delete without products succeeds

### App Configuration
- [ ] ✅ Authenticated read succeeds
- [ ] ❌ Unauthenticated read fails
- [ ] ✅ Admin update with valid values succeeds
- [ ] ❌ Non-admin update fails
- [ ] ❌ Negative delivery charge fails
- [ ] ❌ Invalid threshold values fail

### Products
- [ ] ✅ Valid discount succeeds
- [ ] ❌ Discount >= price fails
- [ ] ❌ Min quantity < 1 fails
- [ ] ❌ Non-existent category fails
- [ ] ✅ Public read succeeds

### Orders
- [ ] ✅ Admin delivery proof update succeeds
- [ ] ✅ Customer remarks within 24h succeeds
- [ ] ❌ Customer remarks after 24h fails
- [ ] ❌ Remarks > 500 chars fails
- [ ] ❌ Customer update other fields fails

## Reporting Issues

If any test fails unexpectedly:
1. Document the exact test scenario
2. Include the error message from Firebase
3. Check the Firebase Console logs
4. Verify the rules syntax
5. Review the design document section 6.3

---

**Last Updated**: Task 28 - Firestore Security Rules Update
**Related Files**: 
- `firestore.rules`
- `FIRESTORE_RULES_DEPLOYMENT.md`
