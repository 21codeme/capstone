# User Database Deletion Scripts

This directory contains scripts for managing user data in the PathFit application. These scripts should be used with caution as they perform destructive operations that cannot be undone.

## Available Scripts

### 1. Test Firebase Admin SDK (`test_firebase_admin.js`)

**Purpose:** Verifies that the Firebase Admin SDK is properly configured before running the deletion scripts.

**What it does:**
- Checks if the service account key file exists and can be loaded
- Initializes the Firebase Admin SDK
- Verifies connections to Firebase Authentication and Firestore

**How to run:**
1. Double-click the `run_test_firebase_admin.bat` file
2. Check the output for any errors

### 2. Delete ALL Users (`delete_all_users.js`)

**Purpose:** Completely purges all user data from both Firebase Authentication and Firestore databases, and terminates all active user sessions.

**What it does:**
- Deletes all users from Firebase Authentication
- Revokes all refresh tokens to terminate active sessions
- Removes all user documents from Firestore
- Cleans up related user data collections (userAchievements, studentQuizzes, studentModules, messages)

**Requirements:**
- Node.js installed
- Firebase Admin SDK
- Service account key file (`firebase-admin-key.json`) in the project root

**How to run:**
1. Double-click the `run_delete_all_users.bat` file
2. Confirm the warning prompt
3. Wait for the script to complete

**⚠️ WARNING: This operation is irreversible and will delete ALL user data!**

### 3. Clear Users Database (`clear_users_database.dart`)

**Purpose:** Removes all user documents from Firestore only (does not affect Firebase Authentication).

**What it does:**
- Deletes all documents in the 'users' collection in Firestore

**How to run:**
1. Double-click the `run_clear_users_database.bat` file
2. Wait for the script to complete

### 4. Delete Specific User (`delete_user.dart` and `admin_delete_user.js`)

**Purpose:** Removes a specific user by email address.

**What it does:**
- `delete_user.dart`: Removes a specific user document from Firestore only
- `admin_delete_user.js`: Removes a specific user from both Firebase Authentication and Firestore

**How to run:**
1. Double-click the appropriate batch file
2. Enter the user's email when prompted (for interactive scripts)
3. Wait for the script to complete

### 5. Delete Deleted Account Record (`delete_deleted_accounts.js`)

**Purpose:** Removes an email from the `deletedAccounts` collection to allow reuse.

**What it does:**
- Searches for a record in the `deletedAccounts` collection by email
- Deletes the record if found, allowing the email to be used for new registrations

**How to run:**
1. Double-click the `run_delete_deleted_accounts.bat` file
2. Enter the email address when prompted
3. Wait for the script to complete

### 6. Complete User Deletion (`delete_user_completely.js`)

**Purpose:** Provides the most comprehensive solution for user deletion.

**What it does:**
- Deletes the user from Firebase Authentication
- Removes the user document from Firestore
- Deletes the record from the `deletedAccounts` collection
- Cleans up related user data in other collections (userAchievements, studentQuizzes, etc.)

**How to run:**
1. Double-click the `run_delete_user_completely.bat` file
2. Enter the email address when prompted
3. Wait for the script to complete

## Security Considerations

- These scripts require appropriate Firebase permissions
- The service account key file should be kept secure and not committed to version control
- Run these scripts in a controlled environment
- Consider backing up data before running destructive operations

## Maintaining Database Integrity

The `delete_all_users.js` script is designed to maintain database integrity by:

1. Using batched operations to ensure atomic updates
2. Handling pagination for large user sets
3. Properly revoking tokens before deletion
4. Cleaning up related collections to prevent orphaned data
5. Providing detailed logging and error handling

## Troubleshooting

If you encounter issues:

1. Check that the service account key has sufficient permissions
2. Verify that Node.js is installed and in your PATH
3. Ensure the Firebase project configuration is correct
4. Check the console output for specific error messages