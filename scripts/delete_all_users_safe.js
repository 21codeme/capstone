const admin = require('firebase-admin');
const readline = require('readline');

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

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askQuestion(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function listAllUsers() {
  console.log('Fetching all users...');
  const userList = [];
  let nextPageToken;
  
  do {
    const listUsersResult = await auth.listUsers(1000, nextPageToken);
    userList.push(...listUsersResult.users);
    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);

  return userList;
}

async function previewDeletion() {
  const users = await listAllUsers();
  
  console.log('\n=== USERS TO BE DELETED ===');
  console.log(`Total users found: ${users.length}\n`);
  
  if (users.length === 0) {
    console.log('No users found.');
    return [];
  }

  // Show first 10 users as preview
  const previewUsers = users.slice(0, 10);
  previewUsers.forEach((user, index) => {
    console.log(`${index + 1}. UID: ${user.uid}`);
    console.log(`   Email: ${user.email || 'No email'}`);
    console.log(`   Display Name: ${user.displayName || 'No display name'}`);
    console.log(`   Created: ${new Date(user.metadata.creationTime).toLocaleDateString()}`);
    console.log('');
  });

  if (users.length > 10) {
    console.log(`... and ${users.length - 10} more users`);
  }

  return users;
}

async function deleteAllUsers() {
  try {
    // Step 1: Preview users to be deleted
    const users = await previewDeletion();
    
    if (users.length === 0) {
      rl.close();
      return;
    }

    // Step 2: Get confirmation
    console.log('\n⚠️  WARNING: This will permanently delete all user accounts and their data!');
    console.log('This includes:');
    console.log('- All Firebase Authentication accounts');
    console.log('- All user data in Firestore');
    console.log('- All user profile images in Storage');
    console.log('- All workout data, goals, achievements, etc.');
    
    const confirmation = await askQuestion('\nType "DELETE ALL USERS" to confirm: ');
    
    if (confirmation !== 'DELETE ALL USERS') {
      console.log('Deletion cancelled.');
      rl.close();
      return;
    }

    const doubleConfirm = await askQuestion('Type your project ID (pathfit-capstone-515e3) to confirm: ');
    
    if (doubleConfirm !== 'pathfit-capstone-515e3') {
      console.log('Deletion cancelled.');
      rl.close();
      return;
    }

    console.log('\n🗑️  Starting deletion process...\n');

    // Step 3: Delete user data from Firestore
    console.log('Deleting user data from Firestore...');
    const batch = firestore.batch();
    
    for (const user of users) {
      const uid = user.uid;
      
      // Delete user document from users collection
      const userDoc = firestore.collection('users').doc(uid);
      batch.delete(userDoc);
      
      // Delete user-specific collections
      const collections = ['workouts', 'goals', 'healthMetrics', 'achievements', 'notifications'];
      
      for (const collection of collections) {
        const userCollection = firestore.collection(collection).doc(uid);
        batch.delete(userCollection);
        
        // Delete subcollections
        const subcollections = ['sessions', 'exercises', 'progress', 'logs'];
        for (const sub of subcollections) {
          const subDoc = firestore.collection(collection).doc(uid).collection(sub).doc('data');
          batch.delete(subDoc);
        }
      }
    }

    await batch.commit();
    console.log('✅ Firestore user data deleted successfully');

    // Step 4: Delete user profile images from Storage
    console.log('Deleting user profile images from Storage...');
    const bucket = storage.bucket();
    let storageDeletions = 0;
    
    for (const user of users) {
      try {
        const profileImagePath = `profile_images/${user.uid}`;
        await bucket.file(profileImagePath).delete();
        storageDeletions++;
      } catch (error) {
        // Image might not exist, continue
      }
    }
    console.log(`✅ Deleted ${storageDeletions} profile images`);

    // Step 5: Delete all users from Firebase Auth
    console.log('Deleting users from Firebase Authentication...');
    const uids = users.map(user => user.uid);
    
    // Firebase Auth has a limit of 1000 users per delete operation
    const chunkSize = 1000;
    for (let i = 0; i < uids.length; i += chunkSize) {
      const chunk = uids.slice(i, i + chunkSize);
      await auth.deleteUsers(chunk);
      console.log(`✅ Deleted ${chunk.length} users`);
    }

    console.log('\n🎉 All user accounts and associated data have been deleted successfully!');
    console.log(`Total users deleted: ${users.length}`);

  } catch (error) {
    console.error('❌ Error during deletion process:', error);
  } finally {
    rl.close();
  }
}

// Run the safe deletion
if (require.main === module) {
  deleteAllUsers()
    .then(() => {
      process.exit(0);
    })
    .catch((error) => {
      console.error('Deletion failed:', error);
      process.exit(1);
    });
}

module.exports = { deleteAllUsers };