# Quick Deployment Commands

## Step-by-Step Deployment

### 1. Install Function Dependencies
```bash
cd functions
npm install
cd ..
```

### 2. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 3. Deploy Cloud Functions
**IMPORTANT**: Requires Firebase Blaze (pay-as-you-go) plan

```bash
firebase deploy --only functions
```

If you get an error about billing, upgrade your Firebase project:
- Go to: https://console.firebase.google.com/project/kirana-grocery-app/usage/details
- Click "Modify plan"
- Select "Blaze" plan

### 4. Deploy Everything (Alternative)
```bash
firebase deploy
```

## Verification

After deployment, verify in Firebase Console:
1. Go to: https://console.firebase.google.com/project/kirana-grocery-app/functions
2. You should see two functions:
   - `sendOrderNotification`
   - `sendBulkNotification`

## Test the App

```bash
flutter clean
flutter pub get
flutter run --release
```

**Note**: Test on a physical device, not simulator/emulator for push notifications.

## Troubleshooting

### Error: "Cannot understand what targets to deploy"
✅ **FIXED** - Updated firebase.json with functions configuration

### Error: "Billing account not configured"
- Upgrade to Blaze plan (required for Cloud Functions)
- Don't worry - free tier is generous (2M invocations/month)

### Error: "Node version mismatch" or "Runtime decommissioned"
- Ensure Node.js 20 or higher: `node --version`
- Update if needed: https://nodejs.org/
- The functions are configured to use Node.js 20 (check `functions/package.json`)

### Build errors in functions
```bash
cd functions
rm -rf node_modules lib
npm install
npm run build
cd ..
firebase deploy --only functions
```

## Monitor Functions

View logs:
```bash
firebase functions:log
```

Or in Firebase Console:
https://console.firebase.google.com/project/kirana-grocery-app/functions/logs
