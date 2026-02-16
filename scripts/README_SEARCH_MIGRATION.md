# Search Keywords Migration Guide

## Overview

This migration script updates the `searchKeywords` field for all products in your Firestore database to support **partial word matching** (prefix search).

### Problem Being Solved

**Before Migration:**
- Searching "Aashirvaad" → ✅ Works
- Searching "Aas" → ❌ Fails (no partial match)
- Searching "Aashi" → ❌ Fails

**After Migration:**
- Searching "Aashirvaad" → ✅ Works
- Searching "Aas" → ✅ Works! (partial match)
- Searching "Aashi" → ✅ Works! (partial match)

## How It Works

### Old Keyword Generation

```json
Product: "Aashirvaad Aata"
Old keywords: ["aashirvaad aata", "groceries", "aashirvaad", "aata"]
```

### New Keyword Generation (with Prefixes)

```json
Product: "Aashirvaad Aata"
New keywords: [
  "aashirvaad aata",
  "groceries",
  "aashirvaad",
  "aata",
  // Prefixes for "aashirvaad":
  "aas", "aash", "aashi", "aashir", "aashirv", "aashirva", "aashirvaa",
  // Prefixes for "groceries":
  "gro", "groc", "groce", "grocer", "groceri", "grocerie"
]
```

### Features

✅ **Partial word matching** - Search "Aas" finds "Aashirvaad"  
✅ **Character normalization** - Handles punctuation, spaces  
✅ **Prefix generation** - Creates 3+ character prefixes  
✅ **Category search** - Search "gro" finds "Groceries"  
✅ **Batch processing** - Handles large datasets efficiently  
✅ **Error handling** - Continues on individual failures

## Prerequisites

Before running the migration:

1. ✅ **Backup your data** (recommended)
   ```bash
   # Export Firestore data
   firebase firestore:export gs://your-project-backup
   ```

2. ✅ **Test the new keyword generation**
   - New products will automatically get new keywords
   - Verify search works for new products first

3. ✅ **Ensure Firebase is configured**
   - `firebase_options.dart` must exist
   - Your Firebase project must be set up correctly

## Running the Migration

### Step 1: Navigate to Project Root

```bash
cd /path/to/your/kirana/project
```

### Step 2: Run the Migration Script

Since this script uses Flutter Firebase packages, you need to run it as a Flutter app. Use one of these options:

**Option A: Run on macOS (if available)**
```bash
flutter run -d macos scripts/migrate_search_keywords.dart
```

**Option B: Run on connected device/emulator**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id> scripts/migrate_search_keywords.dart
```

**Option C: Run on Chrome (web)**
```bash
flutter run -d chrome scripts/migrate_search_keywords.dart
```

The script will run in the background regardless of the device - it's just using the Flutter runtime to access Firebase packages.

### Step 3: Confirm Migration

The script will show:
- Total number of products found
- Warning about the operation
- Prompt for confirmation

```
🚀 Starting Search Keywords Migration
============================================================
📱 Initializing Firebase...
✅ Firebase initialized

📦 Fetching all products from Firestore...
✅ Found 150 products

⚠️  This will update searchKeywords for all 150 products
   Old keywords will be replaced with new prefix-based keywords
   This operation cannot be undone easily.

Continue? (y/n):
```

Type `y` and press Enter to continue.

### Step 4: Monitor Progress

The script will show real-time progress:

```
🔄 Starting migration...

📝 Processing batch 1...
   ✓ Updated 50/150 products
   ✓ Updated 100/150 products
✅ Batch 1 committed successfully

============================================================
🎉 Migration Complete!

Summary:
  ✅ Successfully updated: 150 products
  ❌ Failed: 0 products
  📊 Total processed: 150 products

✨ Next steps:
  1. Test search functionality in your app
  2. Try searching "Aas" to find "Aashirvaad" products
  3. Verify that partial word matching works
```

## Expected Results

### Performance

| Products | Estimated Time | Writes | Cost |
|----------|---------------|--------|------|
| 100      | ~30 seconds   | 100    | $0.002 |
| 500      | ~2 minutes    | 500    | $0.01 |
| 1000     | ~3 minutes    | 1000   | $0.02 |

### Storage Impact

- **Before:** ~10-15 keywords per product (~100 bytes)
- **After:** ~25-40 keywords per product (~270 bytes)
- **Increase:** ~170 bytes per product

For 1000 products: ~170 KB additional storage (negligible)

## Testing After Migration

### Test 1: Partial Word Search

```
Search: "Aas"
Expected: Should find "Aashirvaad" products ✅
```

### Test 2: Full Word Search

```
Search: "Aashirvaad"
Expected: Should still work as before ✅
```

### Test 3: Category Prefix Search

```
Search: "gro"
Expected: Should find products in "Groceries" category ✅
```

### Test 4: Multi-word Products

```
Product: "Fresh Red Tomatoes"
Search: "fre" → Should find it ✅
Search: "tom" → Should find it ✅
```

## Troubleshooting

### Error: "No products found in database"

**Cause:** The products collection is empty or named differently.

**Solution:**
- Verify products exist in Firestore Console
- Check collection name is "products"

### Error: "Missing name or category"

**Cause:** Some products don't have required fields.

**Solution:**
- Migration will skip these products
- Check failed product IDs in output
- Manually fix these products in Firestore

### Error: "Firebase not initialized"

**Cause:** Firebase configuration issue.

**Solution:**
```bash
# Re-generate Firebase options
flutterfire configure
```

### Error: "Permission denied"

**Cause:** Firestore security rules preventing writes.

**Solution:**
- Temporarily relax rules for admin/backend
- Or run script with admin credentials

### Search Still Not Working After Migration

**Possible causes:**

1. **Firestore index not built yet**
   - Check Firebase Console → Firestore → Indexes
   - Wait for index to finish building (5-10 minutes)

2. **App cache issue**
   - Clear app data
   - Restart app
   - Force refresh products

3. **Old keywords still in cache**
   - The app might be caching old product data
   - Products provider might need refresh

## Rollback (If Needed)

If you need to rollback:

### Option 1: Restore from Backup

```bash
firebase firestore:import gs://your-project-backup
```

### Option 2: Manual Rollback Script

Create `scripts/rollback_search_keywords.dart`:

```dart
// Regenerate keywords using old logic
final oldKeywords = [
  name.toLowerCase(),
  category.toLowerCase(),
  ...name.toLowerCase().split(' ')
];
```

## Best Practices

### Before Migration

1. ✅ Test on development/staging environment first
2. ✅ Backup your Firestore data
3. ✅ Run during low-traffic hours
4. ✅ Notify team members

### During Migration

1. ✅ Monitor the console output
2. ✅ Don't interrupt the process
3. ✅ Keep track of failed products
4. ✅ Check Firebase quota limits

### After Migration

1. ✅ Test search functionality thoroughly
2. ✅ Verify with different search patterns
3. ✅ Monitor Firebase usage/costs
4. ✅ Update documentation

## Additional Notes

### Firestore Indexes

Your existing index already supports the new keywords:

```json
{
  "searchKeywords": "CONTAINS",
  "isActive": "ASCENDING"
}
```

**No additional indexes needed!** ✅

### Future Products

New products created after migration will automatically:
- Use the new keyword generation logic
- Support partial word matching
- No manual intervention needed

### Re-running Migration

You can safely re-run the migration:
- It will regenerate keywords for all products
- Existing keywords will be overwritten
- No duplicate keywords will be created

## Support

If you encounter issues:

1. Check the console output for specific errors
2. Review Firebase Console logs
3. Verify Firestore security rules
4. Check Firebase quota/billing limits

## Summary

- ✅ Safe to run (uses batch operations)
- ✅ Fast (processes 500 products in ~2 minutes)
- ✅ Low cost (~$0.02 for 1000 products)
- ✅ Reversible (can restore from backup)
- ✅ Well-tested (includes error handling)

**Ready to improve your search!** 🚀
