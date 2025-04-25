# Firestore Security Rules

These are the recommended security rules to fix the permission denied errors in your application.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Default deny all access
    match /{document=**} {
      allow read, write: if false;
    }
    
    // Allow users to read and write only their own documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow admin to read and write any user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.token.email == "admin@gmail.com";
    }

    // Allow events to be read by anyone but only written by admin
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.email == "admin@gmail.com";
    }
    
    // Allow donations to be read by anyone but only written by admin
    match /donations/{donationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.email == "admin@gmail.com";
    }
    
    // Allow orders to be read and written only by the owner or admin
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || request.auth.token.email == "admin@gmail.com");
    }
  }
}
```

## How to Apply These Rules

1. Go to the Firebase Console: https://console.firebase.google.com/
2. Select your project
3. In the left navigation menu, click on "Firestore Database"
4. Click on the "Rules" tab
5. Replace the existing rules with the rules above
6. Click "Publish" to save the changes

## What This Fixes

- The "Permission Denied" error when trying to read user data
- Properly secures your Firestore data based on authentication
- Ensures admin access to all collections
- Restricts normal users to only access their own data

## Important Note

The rules use email authentication for admin access. Make sure the admin email (admin@gmail.com) matches exactly with what's defined in your app's ADMIN_EMAIL constant. 