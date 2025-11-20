const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateToUIDOnly() {
  try {
    console.log('🔄 Updating users to use UID only...\n');

    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    const updates = []
    const errors = [];

    console.log(`📊 Found ${usersSnapshot.size} users to update`);

    for (const doc of usersSnapshot.docs) {
      try {
        const userData = doc.data();
        const uid = doc.id; // Document ID is already the UID

        console.log(`📝 Processing user: ${uid}`);

        // Update user document to remove studentId and use UID as primary identifier
        const updatedData = {
          uid: uid, // Keep UID as primary identifier
          email: userData.email,
          firstName: userData.firstName || 'Student',
          lastName: userData.lastName || uid.substring(0, 8), // Use part of UID if no last name
          course: userData.course || 'BSIT',
          year: userData.year || '4',
          section: userData.section || 'A',
          role: userData.role || 'student',
          accountStatus: userData.accountStatus || 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Remove studentId field
        await db.collection('users').doc(uid).set(updatedData, { merge: false });
        
        console.log(`✅ Updated user ${uid} - removed studentId`);
        updates.push({ uid, email: userData.email });

      } catch (error) {
        console.error(`❌ Error updating user ${doc.id}:`, error.message);
        errors.push({ uid: doc.id, error: error.message });
      }
    }

    console.log('\n📊 Update Summary:');
    console.log('==================');
    console.log(`Total users processed: ${usersSnapshot.size}`);
    console.log(`Successfully updated: ${updates.length}`);
    console.log(`Errors: ${errors.length}`);

    if (updates.length > 0) {
      console.log('\n✅ Updated Users:');
      updates.forEach(user => {
        console.log(`   ${user.uid} (${user.email})`);
      });
    }

    if (errors.length > 0) {
      console.log('\n❌ Errors:');
      errors.forEach(error => {
        console.log(`   ${error.uid}: ${error.error}`);
      });
    }

    console.log('\n🎉 UID-only update completed successfully!');

    // Save summary
    const summary = {
      timestamp: new Date().toISOString(),
      totalUsers: usersSnapshot.size,
      successfullyUpdated: updates.length,
      errors: errors.length,
      updatedUsers: updates,
      errorsList: errors
    };

    require('fs').writeFileSync('uid_only_update_summary.json', JSON.stringify(summary, null, 2));

  } catch (error) {
    console.error('❌ Update failed:', error);
    process.exit(1);
  }
}

updateToUIDOnly();