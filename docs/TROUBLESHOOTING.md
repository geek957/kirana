# Troubleshooting Guide - Kirana Online Grocery App

This guide helps you diagnose and resolve common issues with the Kirana app.

## Table of Contents

1. [Authentication Issues](#authentication-issues)
2. [Product Browsing Issues](#product-browsing-issues)
3. [Cart Issues](#cart-issues)
4. [Order Issues](#order-issues)
5. [Image Upload Issues](#image-upload-issues)
6. [Network & Connectivity Issues](#network--connectivity-issues)
7. [Performance Issues](#performance-issues)
8. [Admin-Specific Issues](#admin-specific-issues)
9. [Error Messages](#error-messages)
10. [Getting Additional Help](#getting-additional-help)

---

## Authentication Issues

### Issue: Not Receiving OTP Code

**Symptoms**: No SMS received after requesting OTP

**Possible Causes**:
- Poor network connectivity
- Incorrect phone number
- SMS service delay
- Phone number not registered

**Solutions**:
1. **Verify Phone Number**: Ensure you entered the correct 10-digit number with country code
2. **Check Network**: Ensure you have cellular network or WiFi
3. **Wait and Retry**: Wait 60 seconds and tap "Resend OTP"
4. **Check SMS Inbox**: Look for messages from Firebase or the app
5. **Try Different Network**: Switch between WiFi and cellular data

**Prevention**:
- Ensure phone number is correct before submitting
- Have stable network connection
- Check if SMS is blocked by carrier

---

### Issue: OTP Code Expired

**Symptoms**: "Invalid or expired code" error when entering OTP

**Possible Causes**:
- Took too long to enter code (>5 minutes)
- Code already used
- System time incorrect

**Solutions**:
1. **Request New OTP**: Tap "Resend OTP" to get a fresh code
2. **Enter Quickly**: Enter the new code within 5 minutes
3. **Check Device Time**: Ensure your device time is set correctly (automatic)

**Prevention**:
- Enter OTP immediately after receiving
- Keep the app open while waiting for OTP

---

### Issue: OTP Rate Limit Exceeded

**Symptoms**: "Too many OTP requests" error message

**Possible Causes**:
- Requested OTP more than 3 times in 1 hour
- Security rate limiting triggered

**Solutions**:
1. **Wait**: Wait for 1 hour before requesting again
2. **Use Last OTP**: Try the most recent OTP code you received
3. **Check Time**: Ensure device time is correct

**Prevention**:
- Don't repeatedly request OTP
- Wait for SMS to arrive before requesting again
- Verify phone number is correct before first request

---

### Issue: Cannot Login as Admin

**Symptoms**: Logged in but see customer interface instead of admin dashboard

**Possible Causes**:
- Account not marked as admin in database
- Admin flag not set correctly
- Using wrong phone number

**Solutions**:
1. **Verify Admin Status**: Check Firebase Console → Firestore → customers collection
2. **Check isAdmin Field**: Ensure your user document has `isAdmin: true`
3. **Contact System Admin**: Request admin privileges if not set
4. **Logout and Login**: Try logging out and back in

**For System Admins**:
```
1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to customers/{userId}
4. Set isAdmin field to true
5. User must logout and login again
```

---

## Product Browsing Issues

### Issue: Products Not Loading

**Symptoms**: Empty product list or infinite loading

**Possible Causes**:
- No internet connection
- Firebase connection issue
- No products in database
- App cache issue

**Solutions**:
1. **Check Internet**: Verify WiFi or cellular data is working
2. **Refresh**: Pull down to refresh the product list
3. **Restart App**: Close and reopen the app
4. **Clear Cache**: Clear app cache in device settings
5. **Reinstall**: Uninstall and reinstall the app (last resort)

**For Admins**:
- Verify products exist in Firebase Console
- Check Firebase Security Rules allow product reads
- Ensure products have `isActive: true`

---

### Issue: Search Not Working

**Symptoms**: Search returns no results or wrong results

**Possible Causes**:
- Typo in search query
- Product names don't match search
- Search keywords not indexed
- Case sensitivity issue

**Solutions**:
1. **Check Spelling**: Verify search term spelling
2. **Try Partial Match**: Search with fewer characters
3. **Use Category Filter**: Filter by category instead
4. **Browse Manually**: Scroll through product list

**For Admins**:
- Ensure products have searchKeywords array populated
- Check product names are descriptive
- Verify Firestore indexes are deployed

---

### Issue: Product Images Not Displaying

**Symptoms**: Broken image icons or blank image areas

**Possible Causes**:
- Image URL invalid or expired
- Network connectivity issue
- Image deleted from Firebase Storage
- Image format not supported

**Solutions**:
1. **Check Internet**: Verify network connection
2. **Refresh**: Pull down to refresh
3. **Wait**: Images may be loading slowly
4. **Clear Cache**: Clear app cache

**For Admins**:
- Verify image URLs in Firebase Console
- Check Firebase Storage rules allow reads
- Re-upload missing images
- Ensure images are in JPG or PNG format

---

## Cart Issues

### Issue: Cart Items Disappearing

**Symptoms**: Items added to cart are gone after reopening app

**Possible Causes**:
- Not logged in (guest mode)
- Firestore sync issue
- Cart cleared by another action
- App data cleared

**Solutions**:
1. **Verify Login**: Ensure you're logged in
2. **Check Internet**: Verify network connection for sync
3. **Wait for Sync**: Give app time to sync with server
4. **Re-add Items**: Add items to cart again

**Prevention**:
- Stay logged in
- Maintain internet connection
- Don't clear app data

---

### Issue: Cannot Add Item to Cart

**Symptoms**: "Add to Cart" button doesn't work or shows error

**Possible Causes**:
- Item out of stock
- Quantity exceeds available stock
- Not logged in
- Network issue

**Solutions**:
1. **Check Stock**: Verify item shows "In Stock"
2. **Reduce Quantity**: Try adding fewer units
3. **Login**: Ensure you're logged in
4. **Refresh**: Refresh product details
5. **Try Again**: Wait a moment and retry

**Error Messages**:
- "Out of stock": Item unavailable, try later
- "Insufficient stock": Reduce quantity
- "Please login": Login to add items

---

### Issue: Cart Total Incorrect

**Symptoms**: Cart total doesn't match sum of item prices

**Possible Causes**:
- Price changed after adding to cart
- Calculation error
- Delivery fee confusion
- Display sync issue

**Solutions**:
1. **Refresh Cart**: Pull down to refresh
2. **Check Prices**: Verify individual item prices
3. **Recalculate**: Remove and re-add items
4. **Check Delivery**: Note delivery fee (currently FREE)

**Prevention**:
- Review cart before checkout
- Refresh cart before placing order

---

## Order Issues

### Issue: Cannot Place Order

**Symptoms**: "Place Order" button doesn't work or shows error

**Possible Causes**:
- No delivery address selected
- Items out of stock
- Network connectivity issue
- Cart validation failed

**Solutions**:
1. **Select Address**: Choose or add delivery address
2. **Check Stock**: Verify all items are in stock
3. **Refresh Cart**: Update cart to check stock
4. **Check Internet**: Ensure stable connection
5. **Try Again**: Wait and retry order placement

**Common Error Messages**:
- "Please select delivery address": Add/select address
- "Some items are out of stock": Remove unavailable items
- "Network error": Check internet connection

---

### Issue: Order Status Not Updating

**Symptoms**: Order stuck in same status for long time

**Possible Causes**:
- Admin hasn't updated status
- Notification sync delay
- Network connectivity issue
- App not refreshing

**Solutions**:
1. **Refresh**: Pull down to refresh order list
2. **Check Internet**: Verify network connection
3. **Wait**: Status updates may take time
4. **Contact Admin**: Reach out if status unchanged for >24 hours

**For Admins**:
- Ensure you're updating order status regularly
- Check Firebase connection
- Verify notifications are being sent

---

### Issue: Cannot Cancel Order

**Symptoms**: Cancel button disabled or shows error

**Possible Causes**:
- Order status doesn't allow cancellation
- Order already being prepared
- Order out for delivery
- Network issue

**Solutions**:
1. **Check Status**: Cancellation only allowed for Pending/Confirmed
2. **Contact Admin**: Request cancellation if urgent
3. **Accept Delivery**: If out for delivery, accept and return if needed

**Cancellation Rules**:
- ✅ Can cancel: Pending, Confirmed
- ❌ Cannot cancel: Preparing, Out for Delivery, Delivered

---

## Image Upload Issues

### Issue: Cannot Upload Product Image (Admin)

**Symptoms**: Image upload fails or shows error

**Possible Causes**:
- File size too large (>500KB before compression)
- Unsupported file format
- Network connectivity issue
- Firebase Storage permission issue
- Storage quota exceeded

**Solutions**:
1. **Check Format**: Use JPG or PNG only
2. **Compress Image**: Use smaller image or compress before upload
3. **Check Internet**: Ensure stable connection
4. **Try Different Image**: Use another image file
5. **Check Storage**: Verify Firebase Storage quota

**Image Requirements**:
- Format: JPG or PNG
- Max size: 500KB (auto-compressed)
- Recommended: 800x800px square
- Clear, well-lit product photo

---

### Issue: Uploaded Image Not Appearing

**Symptoms**: Image uploaded but not showing in product

**Possible Causes**:
- Upload still in progress
- Image URL not saved to database
- Cache issue
- Storage rules blocking access

**Solutions**:
1. **Wait**: Give upload time to complete
2. **Refresh**: Close and reopen product
3. **Re-upload**: Try uploading again
4. **Check URL**: Verify imageUrl field in Firestore

**For System Admins**:
- Check Firebase Storage rules allow public reads
- Verify image exists in Storage bucket
- Check Firestore document has valid imageUrl

---

## Network & Connectivity Issues

### Issue: "No Internet Connection" Error

**Symptoms**: App shows offline message or errors

**Possible Causes**:
- WiFi or cellular data disabled
- Poor network signal
- Firewall blocking Firebase
- Firebase service outage

**Solutions**:
1. **Check WiFi/Data**: Enable WiFi or cellular data
2. **Check Signal**: Move to area with better signal
3. **Toggle Airplane Mode**: Turn on/off to reset connection
4. **Restart Device**: Reboot phone
5. **Try Different Network**: Switch between WiFi and cellular

**Testing Connection**:
- Open web browser and visit a website
- Check other apps requiring internet
- Verify Firebase status: status.firebase.google.com

---

### Issue: Slow App Performance

**Symptoms**: App laggy, slow loading, delayed responses

**Possible Causes**:
- Slow internet connection
- Device low on memory
- Too many apps running
- Large cache size
- Old device/OS version

**Solutions**:
1. **Check Internet Speed**: Test connection speed
2. **Close Other Apps**: Free up device memory
3. **Clear Cache**: Clear app cache in settings
4. **Restart App**: Close and reopen
5. **Restart Device**: Reboot phone
6. **Update App**: Install latest version
7. **Free Storage**: Delete unused apps/files

**Performance Tips**:
- Keep app updated
- Maintain 1GB+ free storage
- Use WiFi for better performance
- Close unused apps

---

## Performance Issues

### Issue: App Crashes or Freezes

**Symptoms**: App closes unexpectedly or becomes unresponsive

**Possible Causes**:
- Low device memory
- App bug or error
- Corrupted app data
- OS compatibility issue
- Device overheating

**Solutions**:
1. **Force Close**: Close app from recent apps
2. **Clear Cache**: Clear app cache in device settings
3. **Restart Device**: Reboot phone
4. **Update App**: Install latest version
5. **Reinstall App**: Uninstall and reinstall
6. **Report Bug**: Contact support with crash details

**Crash Prevention**:
- Keep app updated
- Maintain adequate free storage
- Don't run too many apps simultaneously
- Update device OS

---

### Issue: Battery Drain

**Symptoms**: App consuming excessive battery

**Possible Causes**:
- Background sync enabled
- Location services running
- Poor network causing constant retries
- App bug

**Solutions**:
1. **Check Battery Usage**: View battery stats in device settings
2. **Disable Background Refresh**: Turn off if not needed
3. **Close When Not Using**: Don't leave app running
4. **Update App**: Install latest version
5. **Report Issue**: Contact support if excessive

---

## Admin-Specific Issues

### Issue: Cannot Update Order Status

**Symptoms**: Status update fails or doesn't save

**Possible Causes**:
- Network connectivity issue
- Invalid status transition
- Firebase permission issue
- Order already updated

**Solutions**:
1. **Check Internet**: Verify network connection
2. **Verify Status**: Ensure valid status transition
3. **Refresh Order**: Close and reopen order details
4. **Try Again**: Wait and retry update
5. **Check Permissions**: Verify admin privileges

**Valid Status Transitions**:
- Pending → Confirmed or Cancelled
- Confirmed → Preparing or Cancelled
- Preparing → Out for Delivery
- Out for Delivery → Delivered

---

### Issue: Cannot Add/Edit Products

**Symptoms**: Product save fails or shows error

**Possible Causes**:
- Missing required fields
- Invalid data format
- Network connectivity issue
- Firebase permission issue

**Solutions**:
1. **Check Required Fields**: Ensure all required fields filled
2. **Verify Data**: Check price is number, stock is integer
3. **Check Internet**: Ensure stable connection
4. **Try Again**: Wait and retry save
5. **Check Permissions**: Verify admin privileges

**Required Fields**:
- Product Name
- Price (number)
- Unit Size
- Category
- Stock Quantity (integer)

---

## Error Messages

### Common Error Messages and Solutions

**"Authentication failed"**
- Cause: Invalid OTP or expired session
- Solution: Request new OTP and try again

**"Network error"**
- Cause: No internet connection
- Solution: Check WiFi/cellular data and retry

**"Out of stock"**
- Cause: Product unavailable
- Solution: Remove item or try later

**"Insufficient stock"**
- Cause: Requested quantity exceeds available
- Solution: Reduce quantity

**"Please login to continue"**
- Cause: Not authenticated
- Solution: Login with phone number

**"Permission denied"**
- Cause: Trying to access unauthorized data
- Solution: Ensure logged in with correct account

**"Invalid address"**
- Cause: Address fields incomplete or invalid
- Solution: Fill all required address fields

**"Order cannot be cancelled"**
- Cause: Order status doesn't allow cancellation
- Solution: Contact admin for assistance

**"Image upload failed"**
- Cause: Network issue or invalid image
- Solution: Check internet and image format

**"Rate limit exceeded"**
- Cause: Too many requests in short time
- Solution: Wait and try again later

---

## Getting Additional Help

### Before Contacting Support

Gather this information:
- Device model and OS version
- App version
- Error message (screenshot if possible)
- Steps to reproduce the issue
- When the issue started
- What you've already tried

### Contact Channels

**For Customers**:
- In-app support (if available)
- Email support
- Phone support during business hours

**For Admins**:
- System administrator
- Technical support team
- Firebase Console for backend issues

### Reporting Bugs

When reporting bugs, include:
1. Detailed description of the issue
2. Steps to reproduce
3. Expected vs actual behavior
4. Screenshots or screen recording
5. Device and app version
6. Error messages

### Emergency Issues

**Critical Issues** (app completely broken):
- Contact system administrator immediately
- Check Firebase status page
- Verify internet connectivity
- Try on different device

**Non-Critical Issues** (minor inconvenience):
- Try troubleshooting steps first
- Report through normal channels
- Include detailed information

---

## Preventive Measures

### For All Users

✅ **Keep app updated** to latest version
✅ **Maintain stable internet** connection
✅ **Clear cache periodically** if app slows down
✅ **Don't clear app data** unless necessary
✅ **Report bugs** to help improve the app
✅ **Follow user guides** for proper usage

### For Admins

✅ **Regular backups** of critical data
✅ **Monitor Firebase quotas** and usage
✅ **Keep Firebase rules** updated
✅ **Test changes** before deploying
✅ **Document custom configurations**
✅ **Train team members** on proper usage

---

## Quick Reference

### Restart Checklist
1. Close app completely
2. Clear from recent apps
3. Wait 10 seconds
4. Reopen app
5. Check if issue resolved

### Network Troubleshooting
1. Check WiFi/cellular enabled
2. Toggle airplane mode
3. Restart router (if WiFi)
4. Try different network
5. Test with other apps

### Cache Clearing (Android)
1. Settings → Apps
2. Find Kirana app
3. Storage → Clear Cache
4. Reopen app

### Cache Clearing (iOS)
1. Settings → General
2. iPhone Storage
3. Find Kirana app
4. Offload App (preserves data)
5. Reinstall from App Store

---

**Still having issues? Contact support with detailed information about your problem.**
