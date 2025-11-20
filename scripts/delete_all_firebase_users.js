const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./pathfit-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://pathfit-capstone-515e3.firebaseio.com'
});

async function deleteAllUsers() {
  try {
    console.log('🗑️ Starting Firebase Auth user deletion...');
    
    // List all users
    const userList = await admin.auth().listUsers(1000);
    
    if (userList.users.length === 0) {
      console.log('✅ No users found to delete');
      return;
    }
    
    console.log(`📊 Found ${userList.users.length} users to delete`);
    
    // Delete all users
    const uids = userList.users.map(user => user.uid);
    
    if (uids.length > 0) {
      await admin.auth().deleteUsers(uids);
      console.log(`✅ Successfully deleted ${uids.length} users`);
    }
    
    // List users again to confirm deletion
    const remainingUsers = await admin.auth().listUsers(1000);
    console.log(`📋 Remaining users: ${remainingUsers.users.length}`);
    
    console.log('🎉 All Firebase Auth users deleted successfully!');
    
  } catch (error) {
    console.error('❌ Error deleting users:', error);
    process.exit(1);
  }
}

deleteAllUsers();