# Firebase Admin SDK Key Setup

## Getting Your Service Account Key

To use the `delete_all_users.js` script, you need to obtain a Firebase Admin SDK service account key. Follow these steps:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (pathfit-capstone-515e3)
3. Click the gear icon (⚙️) next to "Project Overview" to open Project settings
4. Go to the "Service accounts" tab
5. Click "Generate new private key" button
6. Save the downloaded JSON file as `firebase-admin-key.json` in the root directory of your project

## File Structure

The service account key file should be placed in the following location:

```
D:\capstone\pathfitcapstone\firebase-admin-key.json
```

## Security Warning

⚠️ **IMPORTANT**: The service account key grants administrative access to your Firebase project. Keep it secure and never commit it to version control.

## Troubleshooting

If you encounter errors when running the script:

1. Verify that the service account key file is correctly named and placed in the project root
2. Ensure Node.js is installed on your system
3. Check that the service account has the necessary permissions in your Firebase project
4. If you get a "permission denied" error, make sure your service account has the "Firebase Admin" role