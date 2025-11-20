# Database Scripts

## Role to isStudent Migration

This script migrates user data in Firebase Firestore from using a `role` string field to using an `isStudent` boolean field, while maintaining backward compatibility.

### What the Migration Does

1. Updates all existing user documents in the `users` collection to add the `isStudent` boolean field
2. Converts `role` values to `isStudent` boolean values:
   - `role: 'student'` → `isStudent: true`
   - `role: 'instructor'` → `isStudent: false`
3. Keeps the original `role` field for backward compatibility

### How to Run the Migration

#### Option 1: Using the Batch File (Windows)

Simply double-click the `run_migration.bat` file in the `lib/core/scripts` directory.

#### Option 2: Using the Command Line

```bash
# Navigate to the project root directory
cd pathfitcapstone

# Run the migration script
dart run lib/core/scripts/migrate_role_to_isStudent.dart
```

### Expected Output

The script will output detailed information about the migration process:

```
🔥 Initializing Firebase...
✅ Firebase initialized
🚀 Starting user role to isStudent migration...
📊 Migration progress: 10/50 (20.0%)
📊 Migration progress: 20/50 (40.0%)
📊 Migration progress: 30/50 (60.0%)
📊 Migration progress: 40/50 (80.0%)
📊 Migration progress: 50/50 (100.0%)
✅ Migration complete: 50 users migrated successfully, 0 failed

📊 Migration Results:
  - Total users: 50
  - Successfully migrated: 50
  - Failed migrations: 0

🔍 Verifying migration...
📊 Users with isStudent field: 50/50

✅ Migration verification successful!
  - Total users: 50
  - Users with isStudent field: 50

🔄 Finalizing migration...
🎉 Role to isStudent migration completed successfully
✅ All users now have both role and isStudent fields
✅ New users will be created with both fields

🎉 Migration completed successfully!
```

## User Deletion Scripts

These scripts help resolve the "email-already-in-use" error by removing user data from Firebase.

### 1. Clear Users Database (clear_users_database.dart)

This script removes ALL user documents from the Firestore database. Use with caution as it will delete all user data.

**To run:**

1. Navigate to the project root directory
2. Execute the batch file: `run_clear_users_database.bat`
3. The script will delete all user documents from Firestore
4. Users will still exist in Firebase Authentication

### 2. Delete Specific User (delete_user.dart)

This script removes the user from Firestore but cannot automatically delete from Firebase Authentication due to security restrictions.

**To run:**

1. Navigate to the project root directory
2. Execute the batch file: `run_delete_user.bat`
3. The script will delete the user document from Firestore
4. You'll need to manually delete the user from Firebase Authentication using the Firebase Console

### 3. Node.js Admin Script (admin_delete_user.js)

This script uses the Firebase Admin SDK to delete the user from both Firebase Authentication and Firestore.

**Prerequisites:**

1. Node.js installed on your system
2. Firebase Admin SDK service account key (firebase-admin-key.json) in the project root

**To run:**

1. Navigate to the project root directory
2. Execute the batch file: `run_admin_delete_user.bat`

### 4. Delete Deleted Account Record (delete_deleted_accounts.js)

This script removes an email from the `deletedAccounts` collection, allowing it to be used for new registrations even if the user was previously deleted.

**Prerequisites:**

1. Node.js installed on your system
2. Firebase Admin SDK service account key (firebase-admin-key.json) in the project root

**To run:**

1. Navigate to the project root directory
2. Execute the batch file: `run_delete_deleted_accounts.bat`
3. Enter the email address when prompted

### 5. Complete User Deletion (delete_user_completely.js)

This script provides the most comprehensive solution by:
1. Deleting the user from Firebase Authentication
2. Removing the user document from Firestore
3. Deleting the record from the `deletedAccounts` collection
4. Cleaning up related user data in other collections

After running this script, the email can be used for new registrations.

**Prerequisites:**

1. Node.js installed on your system
2. Firebase Admin SDK service account key (firebase-admin-key.json) in the project root

**To run:**

1. Navigate to the project root directory
2. Execute the batch file: `run_delete_user_completely.bat`
3. Enter the email address when prompted

### Manual Deletion via Firebase Console

If the scripts don't work, you can manually delete the user:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Authentication > Users
4. Find the user with email "charlesmiembro24@gmail.com"
5. Click the three dots menu and select "Delete account"
6. Then go to Firestore > Data
7. Find the "users" collection
8. Delete any documents with the email "charlesmiembro24@gmail.com"

Once the user is deleted from both Firebase Authentication and Firestore, you should be able to register a new account with the same email address.

### Troubleshooting

If the migration fails, the script will output detailed error information. Common issues include:

- Firebase initialization failure: Check your Firebase configuration
- Permission issues: Ensure you have write access to the Firestore database
- Network issues: Check your internet connection

If specific users fail to migrate, their IDs will be listed in the output. You can investigate these users individually in the Firebase console.