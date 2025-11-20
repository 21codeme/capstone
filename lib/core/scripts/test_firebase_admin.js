// Test script to verify Firebase Admin SDK configuration

const admin = require('firebase-admin');
let serviceAccount;

try {
  serviceAccount = require('../../../firebase-admin-key.json');
  console.log('✅ Successfully loaded service account key');
} catch (error) {
  console.error('❌ Failed to load service account key:', error.message);
  console.log('\n⚠️ Make sure you have placed the firebase-admin-key.json file in the project root directory.');
  console.log('⚠️ See firebase-admin-key-setup.md for instructions on how to obtain this file.');
  process.exit(1);
}

try {
  // Initialize the app with a service account
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Successfully initialized Firebase Admin SDK');
  
  // Get references to Auth and Firestore
  const auth = admin.auth();
  const firestore = admin.firestore();
  
  console.log('✅ Successfully created Auth and Firestore references');
  console.log('\n🎉 Firebase Admin SDK is properly configured!');
  console.log('\n✅ You can now run the delete_all_users.js script to delete all users.');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
  process.exit(1);
}