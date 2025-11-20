# Delete All Users Guide

This guide will help you delete all user accounts from Firebase Authentication and their associated data.

## ⚠️ WARNING
This is a **DESTRUCTIVE** operation that will **permanently** delete:
- All Firebase Authentication accounts
- All user data in Firestore
- All user profile images in Storage
- All workout data, goals, achievements, notifications, etc.

## Prerequisites

1. **Firebase Admin SDK Key**: You need the service account key file
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project: `pathfit-capstone-515e3`
   - Go to Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save the file as `firebase-admin-key.json` in the `scripts/` folder

## How to Delete All Users

### Option 1: Safe Deletion (Recommended)
This option includes preview and confirmation prompts:

```bash
cd scripts
node delete_all_users_safe.js
```

### Option 2: Direct Deletion
This option runs without confirmation:

```bash
cd scripts
node delete_all_users.js
```

## What the Script Does

1. **Lists all users** to be deleted
2. **Shows preview** of first 10 users (safe version)
3. **Requires double confirmation** (safe version)
4. **Deletes user data** from Firestore:
   - users collection
   - workouts, goals, healthMetrics, achievements, notifications
   - All subcollections
5. **Deletes profile images** from Storage
6. **Deletes user accounts** from Firebase Authentication

## Sample Output

```
=== USERS TO BE DELETED ===
Total users found: 5

1. UID: abc123...
   Email: user@example.com
   Display Name: John Doe
   Created: 1/1/2024

⚠️  WARNING: This will permanently delete all user accounts...
Type "DELETE ALL USERS" to confirm: DELETE ALL USERS
Type your project ID to confirm: pathfit-capstone-515e3

🗑️  Starting deletion process...
✅ Firestore user data deleted successfully
✅ Deleted 3 profile images
✅ Deleted 5 users

🎉 All user accounts and associated data have been deleted successfully!
Total users deleted: 5
```

## Troubleshooting

### Error: Cannot find module './firebase-admin-key.json'
Make sure you have the Firebase Admin SDK key file in the `scripts/` folder.

### Permission Denied
Ensure your service account has these permissions:
- Firebase Authentication Admin
- Cloud Firestore Admin
- Cloud Storage Admin

### Large Number of Users
The script handles up to 1000 users per batch. For larger numbers, it will process in chunks automatically.

## After Deletion

- All user accounts will be removed from Firebase Authentication
- All user data will be removed from Firestore
- All user profile images will be removed from Storage
- The app will have no registered users
- New users can register normally

## Reverting

**There is no undo for this operation.** All data is permanently deleted. Make sure you have backups if needed.