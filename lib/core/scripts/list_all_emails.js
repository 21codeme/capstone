// Firebase Admin SDK script to list all user emails
// This script requires Node.js and the Firebase Admin SDK

const admin = require('firebase-admin');
const serviceAccount = require('../../../firebase-admin-key.json'); // Path to your service account key

// Initialize the app with a service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Get references to Auth and Firestore
const auth = admin.auth();
const firestore = admin.firestore();

async function listAllEmails() {
  try {
    console.log('🔍 Retrieving all user emails from Firebase...');
    console.log('======================================================');
    
    // Get users from Firebase Authentication
    console.log('\n📋 Users from Firebase Authentication:');
    console.log('------------------------------------------------------');
    
    let authUsers = [];
    let nextPageToken;
    
    // Firebase Auth only returns up to 1000 users at a time, so we need to paginate
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      authUsers = authUsers.concat(listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    
    // Print all emails from Auth
    authUsers.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email} (UID: ${user.uid})`);
    });
    
    console.log(`\n✅ Total users in Firebase Authentication: ${authUsers.length}`);
    
    // Get users from Firestore
    console.log('\n📋 Users from Firestore:');
    console.log('------------------------------------------------------');
    
    const usersSnapshot = await firestore.collection('users').get();
    const firestoreUsers = usersSnapshot.docs;
    
    // Print all emails from Firestore
    firestoreUsers.forEach((doc, index) => {
      const userData = doc.data();
      console.log(`${index + 1}. ${userData.email || 'No email'} (UID: ${doc.id})`);
    });
    
    console.log(`\n✅ Total users in Firestore: ${firestoreUsers.length}`);
    
    // Get deleted accounts
    console.log('\n📋 Deleted Accounts:');
    console.log('------------------------------------------------------');
    
    const deletedAccountsSnapshot = await firestore.collection('deletedAccounts').get();
    const deletedAccounts = deletedAccountsSnapshot.docs;
    
    // Print all deleted account emails
    deletedAccounts.forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. ${doc.id} (Deleted at: ${data.deletedAt ? data.deletedAt.toDate().toLocaleString() : 'Unknown'})`);
    });
    
    console.log(`\n✅ Total deleted accounts: ${deletedAccounts.length}`);
    
    console.log('\n======================================================');
    console.log('🎉 Email listing completed!');
    
  } catch (error) {
    console.error('\n❌ Error retrieving user emails:', error);
    process.exit(1);
  }
}

listAllEmails();