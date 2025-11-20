# User Deletion Guide for PathFit

## Overview

This guide explains how to use the various user deletion scripts we've created to solve the "email already registered" issue after account deletion and manage user accounts.

## The Problem

When a user deletes their account through the app:
1. Their Firestore data is deleted
2. Their email is added to a `deletedAccounts` collection
3. The Firebase Authentication record may remain

This prevents users from re-registering with the same email address.

## Solution Options

We've created several scripts to address this issue:

### 1. Delete Deleted Account Record (`delete_deleted_accounts.js`)

**Purpose**: Removes an email from the `deletedAccounts` collection to allow re-registration.

**How to use**:
1. Ensure you have the Firebase Admin SDK key in the project root
2. Run `run_delete_deleted_accounts.bat`
3. Enter the email address when prompted

### 2. Complete User Deletion (`delete_user_completely.js`)

**Purpose**: Performs a complete user deletion, removing:
- Firebase Authentication record
- All Firestore data
- Entry from `deletedAccounts` collection

**How to use**:
1. Ensure you have the Firebase Admin SDK key in the project root
2. Run `run_delete_user_completely.bat`
3. Enter the email address when prompted

### 3. Admin Delete User (`admin_delete_user.js`)

**Purpose**: Deletes a user from Firebase Authentication and Firestore.

**How to use**:
1. Ensure you have the Firebase Admin SDK key in the project root
2. Run `run_admin_delete_user.bat`
3. Enter the email address when prompted

## Setting Up Firebase Admin SDK

### 1. Install Dependencies

Before using the scripts, install the required dependencies by running:

```
install_admin_dependencies.bat
```

This will install the Firebase Admin SDK and other necessary packages.

### 2. Get Service Account Key

To use these scripts, you need a Firebase Admin SDK service account key:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon (⚙️) next to "Project Overview" to open Project settings
4. Go to the "Service accounts" tab
5. Click "Generate new private key" button
6. Save the downloaded JSON file as `firebase-admin-key.json` in the root directory of your project

### 4. List All User Emails (`list_all_emails.js`)

**Purpose**: Lists all user emails from Firebase Authentication, Firestore, and the deletedAccounts collection.

**How to use**:
1. Ensure you have the Firebase Admin SDK key in the project root
2. Run `run_list_all_emails.bat`
3. View the list of all emails in the console

### 5. Delete Multiple Users (`delete_multiple_users.js`)

**Purpose**: Deletes multiple users in batch mode from Firebase Authentication, Firestore, and the deletedAccounts collection.

**How to use**:
1. Ensure you have the Firebase Admin SDK key in the project root
2. Edit the script to include the email addresses you want to delete in the `emailsToDelete` array
3. Run `run_delete_multiple_users.bat`
4. Confirm the deletion when prompted

## Recommended Approach

For most cases, use the **Complete User Deletion** script as it handles all aspects of user deletion. If you only need to allow a specific email to re-register, use the **Delete Deleted Account Record** script. To get an overview of all registered emails, use the **List All User Emails** script. If you need to delete multiple users at once, use the **Delete Multiple Users** script.

## Troubleshooting

If you encounter errors:

1. Verify that the service account key file is correctly named and placed in the project root
2. Ensure Node.js is installed on your system
3. Check that the service account has the necessary permissions in your Firebase project
4. If you get a "permission denied" error, make sure your service account has the "Firebase Admin" role