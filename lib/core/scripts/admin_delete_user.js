// Firebase Admin SDK script to delete a user from both Authentication and Firestore
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

// Email of the user to delete
const targetEmail = 'charlesmiembro24@gmail.com';

async function deleteUser() {
  try {
    console.log(`🔍 Searching for user with email: ${targetEmail}`);
    
    // Step 1: Find user in Firebase Auth by email
    const userRecord = await auth.getUserByEmail(targetEmail)
      .catch(error => {
        if (error.code === 'auth/user-not-found') {
          console.log(`❌ No user found with email: ${targetEmail} in Firebase Auth`);
          return null;
        }
        throw error;
      });
    
    if (!userRecord) {
      console.log('⚠️ Skipping Firebase Auth deletion as user was not found');
    } else {
      const uid = userRecord.uid;
      console.log(`✅ Found user with UID: ${uid} in Firebase Auth`);
      
      // Step 2: Delete user from Firebase Auth
      await auth.deleteUser(uid);
      console.log(`✅ User deleted from Firebase Auth`);
      
      // Step 3: Find and delete user document from Firestore
      const userDoc = await firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        console.log(`⚠️ No matching Firestore document found with UID: ${uid}`);
      } else {
        await firestore.collection('users').doc(uid).delete();
        console.log(`✅ User document deleted from Firestore`);
      }
      
      // Step 4: Also check for any documents with matching email
      const emailQuery = await firestore.collection('users')
        .where('email', '==', targetEmail)
        .get();
      
      if (emailQuery.empty) {
        console.log(`⚠️ No additional documents found with email: ${targetEmail}`);
      } else {
        console.log(`🔍 Found ${emailQuery.size} additional document(s) with matching email`);
        
        // Delete each matching document
        const batch = firestore.batch();
        emailQuery.forEach(doc => {
          console.log(`🗑️ Deleting document with ID: ${doc.id}`);
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`✅ Additional documents deleted from Firestore`);
      }
    }
    
    console.log('\n🎉 User cleanup process completed!');
    console.log(`✅ The user with email ${targetEmail} has been completely removed from Firebase`);
    
  } catch (error) {
    console.error('\n❌ Error during user deletion:', error);
    process.exit(1);
  }
}

deleteUser();