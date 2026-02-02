# Firebase Storage Rules Deployment Guide

## Overview
This document provides instructions for deploying the updated Firebase Storage rules for the grocery app enhancements, specifically for delivery photo storage.

## What Was Updated

### New Rules Added for Delivery Photos
The storage rules now include security rules for the `delivery_photos/` path with the following features:

1. **Admin Write Access**: Only admin users can upload delivery photos
2. **Authenticated Read Access**: All authenticated users can view delivery photos
3. **File Size Validation**: Maximum file size of 5MB enforced
4. **File Type Validation**: Only image files (jpeg, jpg, png, gif, webp) are allowed
5. **Deletion Prevention**: Delivery photos cannot be deleted (immutable proof of delivery)

### Requirements Validated
These rules validate requirements 2.3.1-2.3.8:
- ✅ 2.3.1: Admin can capture a photo when marking order as delivered
- ✅ 2.3.2: Photo is uploaded to Firebase Storage
- ✅ 2.3.3: Photo URL is stored with the order record
- ✅ 2.3.4: Delivery photo is visible in order details for both admin and customer
- ✅ 2.3.5: Photo capture is mandatory before completing delivery
- ✅ 2.3.6-2.3.8: Location data (handled by Firestore rules)

## Storage Rules Structure

```
delivery_photos/
  ├── {orderId}_{timestamp}.jpg
  └── {orderId}_{timestamp}.jpg
```

### Rule Details

**Path Pattern**: `/delivery_photos/{photoFile}`

**Read Access**:
- Authenticated users only
- Allows customers to view their delivery photos
- Allows admins to view all delivery photos

**Write Access**:
- Admin users only (verified via Firestore `/admins/{uid}` collection)
- File size must be < 5MB
- Content type must match `image/*` pattern

**Delete Access**:
- Explicitly denied for all users
- Ensures delivery photos remain as permanent proof of delivery

## Deployment Instructions

### Prerequisites
1. Firebase CLI installed: `npm install -g firebase-tools`
2. Logged in to Firebase: `firebase login`
3. Firebase project initialized in the current directory

### Deployment Steps

1. **Review the Rules**
   ```bash
   cat storage.rules
   ```

2. **Deploy Storage Rules Only**
   ```bash
   firebase deploy --only storage
   ```

3. **Verify Deployment**
   - Go to Firebase Console: https://console.firebase.google.com
   - Navigate to your project
   - Go to Storage → Rules
   - Verify the rules are updated with the delivery_photos section

### Alternative: Deploy All Rules
If you want to deploy both Firestore and Storage rules together:
```bash
firebase deploy --only firestore:rules,storage
```

## Testing the Rules

### Test 1: Admin Upload (Should Succeed)
```dart
// As an admin user
final storageRef = FirebaseStorage.instance.ref();
final photoRef = storageRef.child('delivery_photos/order123_1234567890.jpg');
await photoRef.putFile(imageFile); // Should succeed
```

### Test 2: Non-Admin Upload (Should Fail)
```dart
// As a regular customer user
final storageRef = FirebaseStorage.instance.ref();
final photoRef = storageRef.child('delivery_photos/order123_1234567890.jpg');
await photoRef.putFile(imageFile); // Should fail with permission-denied
```

### Test 3: File Size Validation (Should Fail)
```dart
// As an admin with a file > 5MB
final storageRef = FirebaseStorage.instance.ref();
final photoRef = storageRef.child('delivery_photos/order123_1234567890.jpg');
await photoRef.putFile(largeImageFile); // Should fail with permission-denied
```

### Test 4: File Type Validation (Should Fail)
```dart
// As an admin with a non-image file
final storageRef = FirebaseStorage.instance.ref();
final photoRef = storageRef.child('delivery_photos/order123_1234567890.pdf');
await photoRef.putFile(pdfFile); // Should fail with permission-denied
```

### Test 5: Authenticated Read (Should Succeed)
```dart
// As any authenticated user
final storageRef = FirebaseStorage.instance.ref();
final photoRef = storageRef.child('delivery_photos/order123_1234567890.jpg');
final url = await photoRef.getDownloadURL(); // Should succeed
```

### Test 6: Delete Prevention (Should Fail)
```dart
// As an admin user
final storageRef = FirebaseStorage.instance.ref();
final photoRef = storageRef.child('delivery_photos/order123_1234567890.jpg');
await photoRef.delete(); // Should fail with permission-denied
```

## Security Considerations

### Admin Verification
The rules use a helper function `isAdmin()` that checks if the user exists in the `/admins/{uid}` Firestore collection. Ensure:
1. The `admins` collection exists in Firestore
2. Admin user IDs are properly added to this collection
3. The collection has appropriate Firestore security rules

### File Size Limit
The 5MB limit is enforced to:
- Reduce storage costs
- Ensure reasonable upload times
- Prevent abuse

**Recommendation**: Compress images on the client side before upload to stay well under the limit.

### Immutable Storage
Delivery photos cannot be deleted to:
- Maintain proof of delivery for dispute resolution
- Comply with record-keeping requirements
- Prevent accidental or malicious deletion

**Note**: If you need to remove a photo for legitimate reasons, it must be done manually through Firebase Console by a project owner.

## Troubleshooting

### Issue: "Permission denied" when admin uploads
**Cause**: Admin user not in `/admins/{uid}` collection
**Solution**: Add the admin user ID to the Firestore `admins` collection

### Issue: "Permission denied" for valid image under 5MB
**Cause**: Content type not recognized as image
**Solution**: Ensure the file has proper MIME type (image/jpeg, image/png, etc.)

### Issue: Rules not taking effect
**Cause**: Deployment didn't complete or cached rules
**Solution**: 
1. Redeploy: `firebase deploy --only storage --force`
2. Wait a few minutes for propagation
3. Clear browser cache if testing via web

### Issue: Cannot read delivery photos
**Cause**: User not authenticated
**Solution**: Ensure user is logged in with Firebase Authentication

## Monitoring

### Firebase Console
Monitor storage usage and access patterns:
1. Go to Firebase Console → Storage
2. Check the "Usage" tab for storage metrics
3. Review "Files" tab to see uploaded delivery photos

### Error Monitoring
Set up error monitoring in your app to catch:
- Upload failures
- Permission denied errors
- File size/type validation errors

## Cost Considerations

### Storage Costs
- Firebase Storage pricing: https://firebase.google.com/pricing
- Estimate: ~0.026 USD per GB per month
- With 5MB max per photo, 1000 photos = ~5GB = ~$0.13/month

### Bandwidth Costs
- Download: ~0.12 USD per GB
- Estimate: If each photo is viewed 3 times, 1000 photos = ~15GB = ~$1.80/month

### Optimization Tips
1. Compress images before upload (target 1-2MB)
2. Use thumbnail generation for list views
3. Implement caching on client side
4. Consider CDN for frequently accessed photos

## Next Steps

After deploying storage rules:
1. ✅ Deploy Firestore rules (if not already done)
2. ✅ Ensure `admins` collection exists in Firestore
3. ✅ Test upload functionality in the app
4. ✅ Verify photos are accessible to customers
5. ✅ Monitor storage usage and costs

## Related Documentation
- [Firestore Rules Deployment](FIRESTORE_RULES_DEPLOYMENT.md)
- [Task 28 Completion Summary](TASK_28_COMPLETION_SUMMARY.md)
- [Design Document](../.kiro/specs/grocery-app-enhancements/design.md) - Section 6.3.5 & 11.3

## Support
For issues or questions:
1. Check Firebase Console for error messages
2. Review Firebase Storage documentation
3. Check app logs for detailed error information
4. Verify admin collection setup in Firestore
