// Firebase Admin SDK script to completely delete a user from Authentication, Firestore, and deletedAccounts
// This script requires Node.js and the Firebase Admin SDK

const admin = require('firebase-admin');
const serviceAccount = require('../../../firebase-admin-key.json'); // Path to your service account key
const readline = require('readline');

// Initialize the app with a service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Get references to Auth and Firestore
const auth = admin.auth();
const firestore = admin.firestore();

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function deleteUserCompletely() {
  try {
    // Prompt for email address
    const targetEmail = await new Promise(resolve => {
      rl.question('Enter the email address to completely delete: ', (answer) => {
        resolve(answer.trim());
      });
    });
    
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
    
    // Step 5: Delete from deletedAccounts collection
    const deletedAccountRef = firestore.collection('deletedAccounts').doc(targetEmail.toLowerCase());
    const deletedAccountDoc = await deletedAccountRef.get();
    
    if (!deletedAccountDoc.exists) {
      console.log(`⚠️ No record found in deletedAccounts collection for: ${targetEmail}`);
    } else {
      await deletedAccountRef.delete();
      console.log(`✅ Record removed from deletedAccounts collection`);
    }
    
    // Step 6: Clean up related collections
    console.log('🔄 Cleaning up related user data...');
    
    // List of collections that might contain user data
    const userRelatedCollections = [
      'userAchievements',
      'studentQuizzes',
      'studentModules',
      'messages',
      'notifications',
      'userProgress',
      'userSettings'
    ];
    
    // Process each collection
    for (const collection of userRelatedCollections) {
      try {
        // Look for documents where userId field matches the user's UID
        if (userRecord) {
          const relatedDocs = await firestore.collection(collection)
            .where('userId', '==', userRecord.uid)
            .get();
          
          if (!relatedDocs.empty) {
            console.log(`🔍 Found ${relatedDocs.size} documents in ${collection} collection`);
            
            // Delete each document
            const batch = firestore.batch();
            relatedDocs.forEach(doc => {
              batch.delete(doc.ref);
            });
            
            await batch.commit();
            console.log(`✅ Deleted ${relatedDocs.size} documents from ${collection} collection`);
          }
        }
        
        // Also look for documents where email field matches
        const emailRelatedDocs = await firestore.collection(collection)
          .where('email', '==', targetEmail)
          .get();
        
        if (!emailRelatedDocs.empty) {
          console.log(`🔍 Found ${emailRelatedDocs.size} documents by email in ${collection} collection`);
          
          // Delete each document
          const batch = firestore.batch();
          emailRelatedDocs.forEach(doc => {
            batch.delete(doc.ref);
          });
          
          await batch.commit();
          console.log(`✅ Deleted ${emailRelatedDocs.size} documents from ${collection} collection`);
        }
      } catch (error) {
        // Log error but continue with other collections
        console.log(`⚠️ Error processing ${collection} collection: ${error.message}`);
      }
    }
    
    console.log('\n🎉 User cleanup process completed!');
    console.log(`✅ The user with email ${targetEmail} has been completely removed from Firebase`);
    console.log('✅ The email address can now be used for new registrations');
    
    rl.close();
    
  } catch (error) {
    console.error('\n❌ Error during user deletion:', error);
    rl.close();
    process.exit(1);
  }
}

deleteUserCompletely();