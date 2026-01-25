# Firebase Security Rules Deployment Guide

## Overview

This document describes the Firebase Security Rules that have been implemented and deployed for the Kirana Grocery App. These rules enforce authentication, authorization, and data isolation at the database level.

## Deployed Rules

### Firestore Security Rules

**File:** `firestore.rules`

The Firestore security rules implement the following access control policies:

#### 1. Helper Functions

- **isAuthenticated()**: Checks if a user is logged in
- **isAdmin()**: Checks if the authenticated user has admin privileges
- **isOwner(userId)**: Checks if the authenticated user owns the resource

#### 2. Collection-Level Rules

**Addresses Collection** (`/addresses/{addressId}`)
- **Read**: Owner or Admin only
- **Create**: Authenticated users can create addresses for themselves
- **Update**: Owner only
- **Delete**: Owner only

**Customers Collection** (`/customers/{customerId}`)
- **Read**: Owner or Admin only
- **Create**: Any authenticated user
- **Update**: Owner only
- **Delete**: Blocked (no deletion allowed for audit trail)

**Products Collection** (`/products/{productId}`)
- **Read**: Public (anyone can browse products)
- **Write**: Admin only

**Carts Collection** (`/carts/{customerId}`)
- **Read/Write**: Owner only

**Orders Collection** (`/orders/{orderId}`)
- **Read**: Owner or Admin
- **Create**: Authenticated users can create orders for themselves
- **Update**: Admin only (for status updates)
- **Delete**: Blocked (no deletion allowed for audit trail)

**Notifications Collection** (`/notifications/{notificationId}`)
- **Read**: Owner or Admin
- **Create**: Admin only
- **Update**: Owner (to mark as read)
- **Delete**: Owner

**Verification Codes Collection** (`/verificationCodes/{phoneNumber}`)
- **Read/Write**: Blocked (Cloud Functions only)

**Audit Logs Collection** (`/auditLogs/{logId}`)
- **Read**: Admin only
- **Write**: Blocked (Cloud Functions only)

### Firebase Storage Rules

**File:** `storage.rules`

The Storage security rules implement the following access control policies:

**Product Images** (`/products/{imageId}`)
- **Read**: Public (anyone can view product images)
- **Write**: Authenticated users only

## Deployment Status

✅ **Firestore Rules**: Successfully deployed to `kirana-grocery-app` project
✅ **Storage Rules**: Successfully deployed to `kirana-grocery-app` project

### Deployment Commands Used

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules --project kirana-grocery-app

# Deploy Storage rules
firebase deploy --only storage --project kirana-grocery-app
```

## Testing

### Unit Tests

A comprehensive test suite has been created at `test/firestore_rules_test.dart` that validates:

1. **Product Rules**
   - Unauthenticated users can read products
   - Only admins can write products

2. **Customer Rules**
   - Users can only read their own customer data
   - Customers cannot delete their account

3. **Cart Rules**
   - Users can only access their own cart

4. **Order Rules**
   - Customers can create orders for themselves
   - Customers can read their own orders
   - Only admins can update order status
   - Orders cannot be deleted

5. **Address Rules**
   - Customers can create addresses for themselves
   - Customers can only access their own addresses

6. **Admin Rules**
   - Admins can read all customer data
   - Admins can read all orders

7. **Verification Codes Rules**
   - Verification codes are not accessible to clients

8. **Audit Logs Rules**
   - Only admins can read audit logs
   - Audit logs cannot be written by clients

### Test Results

```
✅ All 16 tests passed
```

### Firebase Emulator Testing

The rules were also tested using the Firebase Emulator Suite:

```bash
firebase emulators:start --only firestore,storage --project kirana-grocery-app
```

The emulator allows for local testing of security rules before deployment to production.

## Security Guarantees

The deployed security rules enforce the following security guarantees:

### 1. Authentication
- All sensitive operations require user authentication
- Unauthenticated users can only browse products (public catalog)

### 2. Authorization
- Admin users have elevated privileges for inventory and order management
- Regular customers can only access their own data

### 3. Data Isolation
- Customers cannot access other customers' data (orders, carts, addresses)
- Each user's data is protected by ownership checks

### 4. Audit Trail
- Orders and customers cannot be deleted (maintains audit trail)
- All admin actions should be logged (enforced by application logic)

### 5. Server-Side Operations
- Verification codes and audit logs can only be accessed by Cloud Functions
- Prevents client-side tampering with sensitive operations

## Validation Against Requirements

The security rules validate **Requirement 11, Acceptance Criteria 11.3**:

> "WHEN a customer accesses their account THEN the Application SHALL ensure only authenticated users can view their own data"

**Validation:**
- ✅ Authentication required for all personal data access
- ✅ Ownership checks prevent cross-customer data access
- ✅ Admin override allows support and management functions
- ✅ Public product catalog for browsing without authentication

## Maintenance

### Updating Rules

To update the security rules:

1. Edit `firestore.rules` or `storage.rules`
2. Test locally with Firebase Emulator:
   ```bash
   firebase emulators:start --only firestore,storage
   ```
3. Run unit tests:
   ```bash
   flutter test test/firestore_rules_test.dart
   ```
4. Deploy to production:
   ```bash
   firebase deploy --only firestore:rules --project kirana-grocery-app
   firebase deploy --only storage --project kirana-grocery-app
   ```

### Monitoring

Monitor security rule violations in the Firebase Console:
- Navigate to Firestore Database → Usage tab
- Check for denied read/write operations
- Investigate any unexpected access patterns

## Next Steps

1. ✅ Security rules deployed and tested
2. ⏭️ Implement data encryption for sensitive fields (Task 13.1)
3. ⏭️ Implement OTP hashing (Task 13.3)
4. ⏭️ Implement audit logging (Task 13.5)
5. ⏭️ Implement authorization checks in application code (Task 13.7)

## References

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- Design Document: `.kiro/specs/online-grocery-app/design.md`
- Requirements Document: `.kiro/specs/online-grocery-app/requirements.md`
