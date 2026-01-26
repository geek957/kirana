# Firestore Indexes Guide

## Overview

Firestore requires composite indexes for queries that combine multiple `where` clauses or combine `where` with `orderBy`. This document explains the indexes needed for the Kirana grocery app.

## Required Indexes

### 1. Products Collection - Basic Listing

**Index:** `isActive (Ascending) + name (Ascending)`

**Used for:** Loading all products on the home screen

**Query:**
```dart
products
  .where('isActive', isEqualTo: true)
  .orderBy('name')
```

### 2. Products Collection - Category Filter

**Index:** `category (Ascending) + isActive (Ascending)`

**Used for:** Filtering products by category

**Query:**
```dart
products
  .where('category', isEqualTo: 'Fruits')
  .where('isActive', isEqualTo: true)
```

### 3. Products Collection - Search

**Index:** `searchKeywords (Array) + isActive (Ascending)`

**Used for:** Searching products

**Query:**
```dart
products
  .where('searchKeywords', arrayContains: 'tomato')
  .where('isActive', isEqualTo: true)
```

### 4. Addresses Collection - Customer Addresses

**Index:** `customerId (Ascending) + createdAt (Descending)`

**Used for:** Loading customer addresses sorted by creation date

**Query:**
```dart
addresses
  .where('customerId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
```

### 5. Addresses Collection - Default Address

**Index:** `customerId (Ascending) + isDefault (Ascending)`

**Used for:** Finding customer's default address

**Query:**
```dart
addresses
  .where('customerId', isEqualTo: userId)
  .where('isDefault', isEqualTo: true)
```

## How to Create Indexes

### Method 1: Automatic (Recommended)

1. Run the app and trigger the query that needs an index
2. Check the Flutter console/logs for an error message
3. The error will contain a direct link to create the index
4. Click the link - it will open Firebase Console with the index pre-configured
5. Click "Create Index" button
6. Wait 2-5 minutes for the index to build

**Example error message:**
```
The query requires an index. You can create it here: 
https://console.firebase.google.com/v1/r/project/kirana-grocery-app/firestore/indexes?create_composite=...
```

### Method 2: Manual via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Firestore Database → Indexes
4. Click "Create Index"
5. Configure:
   - Collection ID: `products`
   - Add fields as specified above
   - Query scope: Collection
6. Click "Create"

### Method 3: Firebase CLI

Create a `firestore.indexes.json` file:

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "name",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "category",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "searchKeywords",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "isActive",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "addresses",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "customerId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "addresses",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "customerId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "isDefault",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

## Index Build Time

- Simple indexes: 1-2 minutes
- Composite indexes: 2-5 minutes
- Large collections (>10,000 docs): 10-30 minutes

## Development vs Production

### Development (Current Implementation)

The app is designed to work with minimal indexes initially:
- Queries are structured to minimize index requirements
- Error messages guide you to create needed indexes
- You can start with just the basic `isActive + name` index

### Production

Before launching, ensure all indexes are created:
1. Test all features (browse, search, filter)
2. Create any indexes that Firebase requests
3. Monitor index usage in Firebase Console
4. Consider creating indexes proactively based on expected queries

## Troubleshooting

### "Failed to load products" Error

**Cause:** Missing composite index

**Solution:**
1. Check Flutter console for the index creation link
2. Click the link and create the index
3. Wait 2-5 minutes for index to build
4. Refresh the app

### Index Build Failed

**Cause:** Usually due to invalid field names or configuration

**Solution:**
1. Verify field names match your Firestore documents exactly
2. Check that field types are correct (string, number, array, etc.)
3. Delete the failed index and recreate it

### Slow Queries

**Cause:** Missing or inefficient indexes

**Solution:**
1. Check Firebase Console → Firestore → Usage tab
2. Look for slow queries
3. Create appropriate composite indexes
4. Consider restructuring queries if needed

## Best Practices

1. **Create indexes proactively** for production apps
2. **Monitor index usage** in Firebase Console
3. **Delete unused indexes** to save storage
4. **Test all query paths** before deploying
5. **Use Firebase Emulator** for local development to avoid index creation delays

## Additional Resources

- [Firestore Index Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Query Limitations](https://firebase.google.com/docs/firestore/query-data/queries#query_limitations)
- [Index Best Practices](https://firebase.google.com/docs/firestore/query-data/index-overview)
