# Firebase Test Phone Numbers Setup Guide

This guide will help you add test phone numbers to Firebase Authentication, allowing you to test phone authentication without receiving actual SMS messages.

## Quick Setup Steps

### 1. Access Firebase Console

1. Open your browser and go to: https://console.firebase.google.com
2. Select your project: **kirana-grocery-app**
3. Click on **Authentication** in the left sidebar

### 2. Enable Phone Authentication (If Not Already Enabled)

1. Click on **Sign-in method** tab
2. Find **Phone** in the list of providers
3. If not enabled:
   - Click on **Phone**
   - Toggle the **Enable** switch
   - Click **Save**

### 3. Add Test Phone Numbers

1. In the **Sign-in method** tab, scroll down to find **Phone numbers for testing**
2. Click on the dropdown/expansion arrow to reveal the test phone section
3. Click **Add phone number**
4. Enter the following details:
   - **Phone number**: `+91 98765 43210` (or any test number you prefer)
   - **Verification code**: `123456` (or any 6-digit code)
5. Click **Add** to save

### 4. Add Multiple Test Numbers (Recommended)

Add these test accounts for different scenarios:

| Phone Number | Verification Code | Purpose |
|--------------|-------------------|---------|
| +91 98765 43210 | 123456 | Customer Test Account |
| +91 98765 43211 | 123456 | Admin Test Account |
| +91 98765 43212 | 123456 | Additional Customer |

**To add each number:**
1. Click **Add phone number** button
2. Enter the phone number (include country code with +)
3. Enter the verification code (6 digits)
4. Click **Add**

### 5. Create Admin Test User in Firestore

Since you'll need an admin account, you need to manually create one in Firestore:

1. In Firebase Console, go to **Firestore Database**
2. Navigate to the **customers** collection
3. Click **Add document**
4. Set the **Document ID** to the UID you'll get after first login
5. Add these fields:
   ```
   id: (auto-generated UID after first login)
   phoneNumber: "+919876543211" (encrypted, but for now use plain)
   name: "Admin User"
   isAdmin: true
   createdAt: (current timestamp)
   lastLogin: (current timestamp)
   ```

**OR** after first login with test phone:
1. Find your user document in Firestore → customers collection
2. Click on the document
3. Click **Edit field**
4. Find `isAdmin` field and change it from `false` to `true`
5. Click **Update**

### 6. Test in the App

1. Open the Kirana app in the emulator
2. On the login screen, enter the test phone number: `+919876543210`
3. Click **Send OTP**
4. When prompted for the verification code, enter: `123456`
5. You should be logged in without receiving an actual SMS

## Important Notes

### Security Warning
⚠️ **Test phone numbers should NEVER be used in production!** 
- They bypass SMS verification completely
- Remove all test numbers before deploying to production
- Use only for development and testing

### Phone Number Format
- Always include the country code with `+` prefix
- For India: `+91` followed by 10-digit number
- Example: `+91 98765 43210` or `+919876543210` (spaces optional)

### Verification Code
- Can be any 6-digit number
- The same code will work every time for that test number
- No expiration or rate limiting for test numbers

### Common Issues

**Issue: "Invalid phone number"**
- Solution: Ensure you're using the correct format with country code (+91 for India)

**Issue: "Invalid verification code"**
- Solution: Make sure you're entering the exact code you configured (e.g., 123456)

**Issue: Not able to login after entering code**
- Solution: Check if the user exists in Firestore customers collection
- The app requires user registration after first successful authentication

**Issue: App says "Too many OTP requests"**
- Solution: This shouldn't happen with test numbers, but if it does, restart the app

## Cleanup

When you're done testing and ready for production:

1. Go to Firebase Console → Authentication → Sign-in method
2. Expand **Phone numbers for testing** section
3. Remove all test phone numbers by clicking the trash icon
4. Configure reCAPTCHA Enterprise for production use

## Next Steps

After setting up test phone numbers:

1. **Test Customer Flow:**
   - Login with `+919876543210` (code: 123456)
   - Complete registration form
   - Browse products, add to cart, place order

2. **Test Admin Flow:**
   - Login with `+919876543211` (code: 123456)
   - Complete registration
   - Manually set `isAdmin: true` in Firestore
   - Logout and login again
   - Access admin dashboard

3. **For Production Deployment:**
   - Remove all test phone numbers
   - Configure reCAPTCHA Enterprise
   - Follow the [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

## Additional Resources

- [Firebase Phone Auth Documentation](https://firebase.google.com/docs/auth/android/phone-auth)
- [Testing Phone Auth](https://firebase.google.com/docs/auth/android/phone-auth#test-with-fictional-phone-numbers)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
