# Firestore Indexes Configuration

This document explains the Firestore indexes configured in `firestore.indexes.json` for the Grocery App.

## Overview

Firestore indexes are required for efficient querying of data. This file defines composite indexes that enable complex queries involving multiple fields.

## Configured Indexes

### Products Collection

#### 1. Active Products by Name
- **Fields**: `isActive` (ASC), `name` (ASC)
- **Purpose**: Query active products sorted alphabetically by name
- **Used by**: Product listing screens

#### 2. Products by Category (Legacy)
- **Fields**: `category` (ASC), `isActive` (ASC)
- **Purpose**: Legacy index for old category field
- **Status**: Kept for backward compatibility

#### 3. **NEW: Products by Category with Name Sorting**
- **Fields**: `categoryId` (ASC), `isActive` (ASC), `name` (ASC)
- **Purpose**: Query active products by category, sorted alphabetically
- **Used by**: Home screen category filtering, category management
- **Validates**: Requirements 2.2.5 - Category-based product filtering

#### 4. Products by Search Keywords
- **Fields**: `searchKeywords` (CONTAINS), `isActive` (ASC)
- **Purpose**: Search active products by keywords
- **Used by**: Product search functionality

### Categories Collection

#### 5. **NEW: Categories by Name**
- **Fields**: `name` (ASC)
- **Purpose**: Query categories sorted alphabetically, check name uniqueness
- **Used by**: Category management screen, category dropdown
- **Validates**: Requirements 2.2.6, 2.2.8 - Alphabetical sorting and unique names

### Addresses Collection

#### 6. Customer Addresses by Creation Date
- **Fields**: `customerId` (ASC), `createdAt` (DESC)
- **Purpose**: Query customer addresses sorted by most recent
- **Used by**: Address management screens

#### 7. Customer Default Address
- **Fields**: `customerId` (ASC), `isDefault` (ASC)
- **Purpose**: Query customer's default address
- **Used by**: Checkout flow

### Notifications Collection

#### 8. Customer Notifications by Date
- **Fields**: `customerId` (ASC), `createdAt` (DESC)
- **Purpose**: Query customer notifications sorted by most recent
- **Used by**: Notifications screen

#### 9. Customer Unread Notifications
- **Fields**: `customerId` (ASC), `isRead` (ASC)
- **Purpose**: Query customer's unread notifications
- **Used by**: Notification badge count

### Orders Collection

#### 10. Customer Orders by Date
- **Fields**: `customerId` (ASC), `createdAt` (DESC)
- **Purpose**: Query customer orders sorted by most recent
- **Used by**: Order history screen

#### 11. Orders by Status and Date
- **Fields**: `status` (ASC), `createdAt` (DESC)
- **Purpose**: Query orders by status sorted by date
- **Used by**: Admin order management

#### 12. **NEW: Pending Orders Count**
- **Fields**: `status` (ASC)
- **Purpose**: Efficiently count orders with "pending" status
- **Used by**: Order capacity management system
- **Validates**: Requirements 2.7.1, 2.7.7 - Real-time pending order tracking

## Deployment Instructions

### Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in to Firebase: `firebase login`
- Firebase project initialized in this directory

### Deploy Indexes

1. **Review the indexes file**:
   ```bash
   cat firestore.indexes.json
   ```

2. **Deploy to Firebase**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

3. **Monitor deployment**:
   - The command will show progress
   - Index creation can take several minutes depending on data size
   - You'll see a success message when complete

4. **Verify in Firebase Console**:
   - Go to Firebase Console: https://console.firebase.google.com
   - Select your project
   - Navigate to Firestore Database → Indexes
   - Verify all indexes are listed and status is "Enabled"

### Troubleshooting

**Index already exists error**:
- This is normal if indexes were auto-created by Firestore
- The deployment will skip existing indexes

**Index creation taking too long**:
- Large collections may take 10-30 minutes to index
- Check status in Firebase Console
- App will work but queries may be slower until indexes complete

**Permission denied**:
- Ensure you're logged in: `firebase login`
- Verify you have Editor or Owner role on the Firebase project

## Index Maintenance

### When to Update Indexes

Update indexes when:
- Adding new query patterns to the app
- Firestore suggests an index in error messages
- Query performance degrades

### Testing Indexes Locally

1. **Start Firestore emulator**:
   ```bash
   firebase emulators:start --only firestore
   ```

2. **Test queries**:
   - Run the app against the emulator
   - Check emulator logs for missing index warnings

3. **Export indexes**:
   ```bash
   firebase firestore:indexes > firestore.indexes.json
   ```

## Performance Considerations

- **Composite indexes** enable complex queries but increase write costs
- Each indexed field adds to write latency
- Monitor index usage in Firebase Console
- Remove unused indexes to optimize performance

## Related Files

- `firestore.rules` - Security rules for Firestore
- `lib/services/*_service.dart` - Services that use these indexes
- `.kiro/specs/grocery-app-enhancements/design.md` - Database design documentation

## Support

For issues with indexes:
1. Check Firebase Console for index status
2. Review Firestore documentation: https://firebase.google.com/docs/firestore/query-data/indexing
3. Check app logs for missing index errors
4. Consult the design document for query patterns

---

**Last Updated**: Task 27 - Firestore Indexes Configuration
**Validates**: All features requiring efficient querying
