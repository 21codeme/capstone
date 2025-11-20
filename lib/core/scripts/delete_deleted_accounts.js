// Firebase Admin SDK script to delete entries from the deletedAccounts collection
// This script requires Node.js and the Firebase Admin SDK

const admin = require('firebase-admin');
const serviceAccount = require('../../../firebase-admin-key.json'); // Path to your service account key
const readline = require('readline');

// Initialize the app with a service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Get reference to Firestore
const firestore = admin.firestore();

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function deleteDeletedAccountRecord() {
  try {
    // Prompt for email address
    const targetEmail = await new Promise(resolve => {
      rl.question('Enter the email address to remove from deletedAccounts: ', (answer) => {
        resolve(answer.trim().toLowerCase());
      });
    });
    
    console.log(`🔍 Searching for deleted account record with email: ${targetEmail}`);
    
    // Check if the email exists in deletedAccounts collection
    const docRef = firestore.collection('deletedAccounts').doc(targetEmail);
    const docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      console.log(`❌ No record found for email: ${targetEmail} in deletedAccounts collection`);
    } else {
      // Delete the document
      await docRef.delete();
      console.log(`✅ Successfully removed ${targetEmail} from deletedAccounts collection`);
      console.log('✅ This email can now be used for new registrations');
    }
    
    console.log('\n🎉 Operation completed!');
    rl.close();
    
  } catch (error) {
    console.error('\n❌ Error during operation:', error);
    rl.close();
    process.exit(1);
  }
}

deleteDeletedAccountRecord();