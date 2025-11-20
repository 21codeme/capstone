const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://pathfit-capstone-515e3.firebaseio.com',
  storageBucket: 'pathfit-capstone-515e3.firebasestorage.app'
});

const auth = admin.auth();
const firestore = admin.firestore();
const storage = admin.storage();

async function deleteAllUsers() {
  console.log('Starting deletion of all user accounts...');
  
  try {
    // Step 1: List all users
    console.log('Fetching all users...');
    const userList = [];
    let nextPageToken;
    
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      userList.push(...listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log(`Found ${userList.length} users to delete`);

    if (userList.length === 0) {
      console.log('No users found to delete.');
      return;
    }

    // Step 2: Delete user data from Firestore
    console.log('Deleting user data from Firestore...');
    const batch = firestore.batch();
    
    for (const user of userList) {
      const uid = user.uid;
      
      // Delete user document from users collection
      const userDoc = firestore.collection('users').doc(uid);
      batch.delete(userDoc);
      
      // Delete user-specific subcollections and documents
      const collections = ['workouts', 'goals', 'healthMetrics', 'achievements', 'notifications'];
      
      for (const collection of collections) {
        const userCollection = firestore.collection(collection).doc(uid);
        batch.delete(userCollection);
        
        // Delete subcollections if they exist
        const subcollections = ['sessions', 'exercises', 'progress', 'logs'];
        for (const sub of subcollections) {
          const subDoc = firestore.collection(collection).doc(uid).collection(sub).doc('data');
          batch.delete(subDoc);
        }
      }
    }

    await batch.commit();
    console.log('Firestore user data deleted successfully');

    // Step 3: Delete user profile images from Storage
    console.log('Deleting user profile images from Storage...');
    const bucket = storage.bucket();
    
    for (const user of userList) {
      try {
        const profileImagePath = `profile_images/${user.uid}`;
        await bucket.file(profileImagePath).delete();
        console.log(`Deleted profile image for user: ${user.uid}`);
      } catch (error) {
        // Image might not exist, continue
        console.log(`No profile image found for user: ${user.uid}`);
      }
    }

    // Step 4: Delete all users from Firebase Auth
    console.log('Deleting users from Firebase Authentication...');
    const uids = userList.map(user => user.uid);
    
    // Firebase Auth has a limit of 1000 users per delete operation
    const chunkSize = 1000;
    for (let i = 0; i < uids.length; i += chunkSize) {
      const chunk = uids.slice(i, i + chunkSize);
      await auth.deleteUsers(chunk);
      console.log(`Deleted ${chunk.length} users`);
    }

    console.log('All user accounts and associated data have been deleted successfully!');
    console.log(`Total users deleted: ${userList.length}`);

  } catch (error) {
    console.error('Error during deletion process:', error);
    throw error;
  }
}

// Run the deletion
if (require.main === module) {
  deleteAllUsers()
    .then(() => {
      console.log('Deletion process completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Deletion failed:', error);
      process.exit(1);
    });
}

module.exports = { deleteAllUsers };