# Firebase Setup Guide for Kirana Grocery App

## Step 1: Create Firebase Project (Manual Steps Required)

Since you don't have any Firebase projects yet, you need to create one manually:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: **kirana-grocery-app**
4. Accept Firebase terms and click "Continue"
5. Disable Google Analytics (optional for this project) or enable it
6. Click "Create project"
7. Wait for the project to be created

## Step 2: Enable Firebase Authentication

1. In your Firebase project, click on "Authentication" in the left sidebar
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Click on "Phone" provider
5. Click "Enable"
6. Configure reCAPTCHA settings:
   - For testing, you can add test phone numbers
   - For production, ensure reCAPTCHA is properly configured
7. Click "Save"

## Step 3: Create Firestore Database

1. In your Firebase project, click on "Firestore Database" in the left sidebar
2. Click "Create database"
3. Select "Start in production mode" (we'll add security rules later)
4. Choose a location: **asia-south1** (Mumbai, India) - closest to target users
5. Click "Enable"

## Step 4: Create Firebase Storage

1. In your Firebase project, click on "Storage" in the left sidebar
2. Click "Get started"
3. Start in production mode
4. Choose the same location as Firestore: **asia-south1**
5. Click "Done"

## Step 5: Configure Storage Rules

1. In Storage, go to the "Rules" tab
2. Replace the default rules with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{imageId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click "Publish"

## Step 6: Run FlutterFire Configure

After completing the above steps, run this command in your terminal:

```bash
flutterfire configure --project=kirana-grocery-app
```

This will:
- Connect your Flutter app to the Firebase project
- Generate `firebase_options.dart` file
- Download and place configuration files for Android and iOS

## Step 7: Verify Setup

After running `flutterfire configure`, you can test the connection by running:

```bash
flutter run
```

Then click the "Test Firebase Connection" button in the app.

## Notes

- The Firebase free tier supports:
  - Unlimited users for Authentication
  - 1GB storage for Firestore
  - 50K reads/day, 20K writes/day for Firestore
  - 5GB storage for Firebase Storage
  - 1GB/day downloads for Storage

This is sufficient for 10,000 customers and 100 orders/day as per requirements.
