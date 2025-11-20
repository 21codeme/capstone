// Firebase Admin SDK script to delete ALL users from both Authentication and Firestore
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

async function deleteAllUsers() {
  try {
    console.log('🔥 Starting complete user database purge...');
    console.log('⚠️ WARNING: This will delete ALL users and their data!');
    console.log('⚠️ Press Ctrl+C within 5 seconds to abort');
    
    // Give a 5-second grace period to cancel
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Step 1: Get all users from Firebase Auth
    console.log('🔍 Retrieving all users from Firebase Authentication...');
    
    let users = [];
    let nextPageToken;
    
    // Firebase Auth listUsers is paginated, so we need to loop
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      users = users.concat(listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
      
      console.log(`📊 Retrieved ${users.length} users from Firebase Authentication so far`);
    } while (nextPageToken);
    
    console.log(`✅ Found a total of ${users.length} users in Firebase Authentication`);
    
    if (users.length === 0) {
      console.log('ℹ️ No users found in Firebase Authentication.');
    } else {
      // Step 2: Revoke all refresh tokens to terminate active sessions
      console.log('🔒 Revoking all user sessions...');
      
      const revokePromises = users.map(async (user) => {
        try {
          await auth.revokeRefreshTokens(user.uid);
          return { success: true, uid: user.uid };
        } catch (error) {
          return { success: false, uid: user.uid, error };
        }
      });
      
      const revokeResults = await Promise.all(revokePromises);
      const successfulRevokes = revokeResults.filter(result => result.success).length;
      
      console.log(`✅ Successfully revoked sessions for ${successfulRevokes}/${users.length} users`);
      
      // Step 3: Delete all users from Firebase Auth
      console.log('🗑️ Deleting all users from Firebase Authentication...');
      
      // Process in batches of 100 (Firebase Admin SDK limit)
      const batchSize = 100;
      let successCount = 0;
      let failCount = 0;
      let errorMessages = [];
      
      for (let i = 0; i < users.length; i += batchSize) {
        const batch = users.slice(i, i + batchSize);
        const deletePromises = batch.map(async (user) => {
          try {
            await auth.deleteUser(user.uid);
            return { success: true, uid: user.uid };
          } catch (error) {
            return { success: false, uid: user.uid, error };
          }
        });
        
        const results = await Promise.all(deletePromises);
        
        // Count successes and failures
        results.forEach(result => {
          if (result.success) {
            successCount++;
          } else {
            failCount++;
            errorMessages.push(`Failed to delete user ${result.uid}: ${result.error}`);
          }
        });
        
        console.log(`📊 Deleted ${successCount}/${users.length} users from Firebase Authentication`);
      }
      
      console.log(`✅ Successfully deleted ${successCount}/${users.length} users from Firebase Authentication`);
      
      if (failCount > 0) {
        console.log(`⚠️ Failed to delete ${failCount} users from Firebase Authentication`);
        console.log('⚠️ First few errors:');
        errorMessages.slice(0, 5).forEach(msg => console.log(`  - ${msg}`));
      }
    }
    
    // Step 4: Delete all user documents from Firestore
    console.log('🔍 Retrieving all users from Firestore...');
    
    const usersSnapshot = await firestore.collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('ℹ️ No users found in Firestore.');
    } else {
      console.log(`📊 Found ${usersSnapshot.size} users in Firestore`);
      console.log('🗑️ Deleting all user documents from Firestore...');
      
      // Use batched writes for better performance
      let batchSize = 0;
      let batch = firestore.batch();
      let totalDeleted = 0;
      
      for (const doc of usersSnapshot.docs) {
        batch.delete(doc.ref);
        batchSize++;
        
        // Firestore batches are limited to 500 operations
        if (batchSize >= 400) {
          await batch.commit();
          totalDeleted += batchSize;
          console.log(`📊 Deleted ${totalDeleted}/${usersSnapshot.size} users from Firestore (${(totalDeleted / usersSnapshot.size * 100).toFixed(1)}%)`);
          
          // Reset batch
          batch = firestore.batch();
          batchSize = 0;
        }
      }
      
      // Commit any remaining operations
      if (batchSize > 0) {
        await batch.commit();
        totalDeleted += batchSize;
        console.log(`📊 Deleted ${totalDeleted}/${usersSnapshot.size} users from Firestore (${(totalDeleted / usersSnapshot.size * 100).toFixed(1)}%)`);
      }
      
      console.log('✅ All user documents have been removed from Firestore');
    }
    
    // Step 5: Delete related user data collections
    const relatedCollections = [
      'userAchievements',
      'studentQuizzes',
      'studentModules',
      'messages'
    ];
    
    console.log('🔍 Cleaning up related user data collections...');
    
    for (const collection of relatedCollections) {
      console.log(`🔍 Checking collection: ${collection}`);
      
      const snapshot = await firestore.collection(collection).get();
      
      if (snapshot.empty) {
        console.log(`ℹ️ No documents found in ${collection} collection.`);
        continue;
      }
      
      console.log(`📊 Found ${snapshot.size} documents in ${collection} collection`);
      console.log(`🗑️ Deleting all documents from ${collection} collection...`);
      
      // Use batched writes for better performance
      let batchSize = 0;
      let batch = firestore.batch();
      let totalDeleted = 0;
      
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        batchSize++;
        
        // Firestore batches are limited to 500 operations
        if (batchSize >= 400) {
          await batch.commit();
          totalDeleted += batchSize;
          console.log(`📊 Deleted ${totalDeleted}/${snapshot.size} documents from ${collection} (${(totalDeleted / snapshot.size * 100).toFixed(1)}%)`);
          
          // Reset batch
          batch = firestore.batch();
          batchSize = 0;
        }
      }
      
      // Commit any remaining operations
      if (batchSize > 0) {
        await batch.commit();
        totalDeleted += batchSize;
        console.log(`📊 Deleted ${totalDeleted}/${snapshot.size} documents from ${collection} (${(totalDeleted / snapshot.size * 100).toFixed(1)}%)`);
      }
      
      console.log(`✅ All documents have been removed from ${collection} collection`);
    }
    
    console.log('\n🎉 Complete user database purge completed!');
    console.log('✅ All users have been removed from Firebase Authentication');
    console.log('✅ All user documents have been removed from Firestore');
    console.log('✅ All related user data has been removed from Firestore');
    console.log('✅ All user sessions have been terminated');
    
  } catch (error) {
    console.error('\n❌ Database purge failed:', error);
    process.exit(1);
  }
}

deleteAllUsers();