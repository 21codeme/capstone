// Firebase Admin SDK script to delete multiple users from both Authentication and Firestore
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

// List of emails to delete
const emailsToDelete = [
  'haxelon.zettu@gmail.com',
  'mockupfusion23@gmail.com',
  'sad@yopmail.com',
  'john@yopmail.com',
  'uptanwex@yahoo.com',
  'patutu@yopmail.com',
  'vf@gmail.com',
  'jkl@gmail.com'
];

async function deleteUserByEmail(email) {
  try {
    console.log(`\n🔍 Processing user with email: ${email}`);
    
    // Step 1: Find user in Firebase Auth by email
    const userRecord = await auth.getUserByEmail(email)
      .catch(error => {
        if (error.code === 'auth/user-not-found') {
          console.log(`❌ No user found with email: ${email} in Firebase Auth`);
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
        .where('email', '==', email)
        .get();
      
      if (emailQuery.empty) {
        console.log(`⚠️ No additional documents found with email: ${email}`);
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
    
    // Step 5: Delete from deletedAccounts collection if present
    const deletedAccountDoc = await firestore.collection('deletedAccounts').doc(email.toLowerCase()).get();
    
    if (deletedAccountDoc.exists) {
      await firestore.collection('deletedAccounts').doc(email.toLowerCase()).delete();
      console.log(`✅ Removed from deletedAccounts collection`);
    } else {
      console.log(`⚠️ No record found in deletedAccounts collection`);
    }
    
    console.log(`✅ User with email ${email} has been completely removed from Firebase`);
    return true;
    
  } catch (error) {
    console.error(`❌ Error deleting user ${email}:`, error);
    return false;
  }
}

async function deleteMultipleUsers() {
  console.log('🚀 Starting batch deletion of multiple users...');
  console.log(`📋 Total users to delete: ${emailsToDelete.length}`);
  console.log('======================================================');
  
  let successCount = 0;
  let failCount = 0;
  
  for (let i = 0; i < emailsToDelete.length; i++) {
    const email = emailsToDelete[i];
    console.log(`\n⏳ Processing user ${i+1}/${emailsToDelete.length}: ${email}`);
    
    const success = await deleteUserByEmail(email);
    if (success) {
      successCount++;
    } else {
      failCount++;
    }
  }
  
  console.log('\n======================================================');
  console.log('🎉 Batch deletion completed!');
  console.log(`✅ Successfully deleted: ${successCount}/${emailsToDelete.length} users`);
  if (failCount > 0) {
    console.log(`❌ Failed to delete: ${failCount}/${emailsToDelete.length} users`);
  }
}

deleteMultipleUsers();