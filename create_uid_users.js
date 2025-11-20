const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createUIDUsers() {
  try {
    console.log('🔍 Creating UID-based users from existing data...\n');

    // Get unique student IDs from studentQuizzes
    const studentQuizzesSnapshot = await db.collection('studentQuizzes').get();
    const studentIds = new Set();
    
    studentQuizzesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.studentId) {
        studentIds.add(data.studentId);
      }
    });

    // Get unique student IDs from studentModules
    const studentModulesSnapshot = await db.collection('studentModules').get();
    studentModulesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.studentId) {
        studentIds.add(data.studentId);
      }
    });

    console.log(`📊 Found ${studentIds.size} unique student IDs in collections`);

    // Create users for each student ID
    const createdUsers = [];
    const errors = [];

    for (const studentId of studentIds) {
      try {
        // Create a Firebase Auth user
        const email = `student.${studentId}@pathfit.edu`;
        let userRecord;

        try {
          userRecord = await admin.auth().getUserByEmail(email);
          console.log(`✅ User already exists: ${email}`);
        } catch (error) {
          if (error.code === 'auth/user-not-found') {
            userRecord = await admin.auth().createUser({
              email: email,
              password: 'TempPass123!', // Temporary password
              displayName: `Student ${studentId}`,
              emailVerified: false,
              disabled: false
            });
            console.log(`✅ Created auth user: ${email} (${userRecord.uid})`);
          } else {
            throw error;
          }
        }

        // Create Firestore user document
        const userData = {
          uid: userRecord.uid,
          email: email,
          studentId: studentId,
          firstName: `Student`,
          lastName: studentId,
          course: 'BSIT',
          year: '4',
          section: 'A',
          role: 'student',
          accountStatus: 'active',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('users').doc(userRecord.uid).set(userData);
        console.log(`✅ Created Firestore document: ${userRecord.uid}`);

        createdUsers.push({
          studentId,
          uid: userRecord.uid,
          email: email
        });

      } catch (error) {
        console.error(`❌ Error creating user for ${studentId}:`, error.message);
        errors.push({ studentId, error: error.message });
      }
    }

    console.log('\n📊 Migration Summary:');
    console.log('====================');
    console.log(`Total students: ${studentIds.size}`);
    console.log(`Successfully created: ${createdUsers.length}`);
    console.log(`Errors: ${errors.length}`);

    if (createdUsers.length > 0) {
      console.log('\n✅ Created Users:');
      createdUsers.forEach(user => {
        console.log(`   ${user.studentId} -> ${user.uid}`);
      });
    }

    if (errors.length > 0) {
      console.log('\n❌ Errors:');
      errors.forEach(error => {
        console.log(`   ${error.studentId}: ${error.error}`);
      });
    }

    // Update related collections to use UID instead of studentId
    console.log('\n🔄 Updating related collections to use UID...');
    
    for (const user of createdUsers) {
      try {
        // Update studentQuizzes
        const quizzesSnapshot = await db.collection('studentQuizzes')
          .where('studentId', '==', user.studentId)
          .get();
        
        const batch = db.batch();
        quizzesSnapshot.forEach(doc => {
          batch.update(doc.ref, {
            studentId: user.uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });

        // Update studentModules
        const modulesSnapshot = await db.collection('studentModules')
          .where('studentId', '==', user.studentId)
          .get();
        
        modulesSnapshot.forEach(doc => {
          batch.update(doc.ref, {
            studentId: user.uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });

        await batch.commit();
        console.log(`✅ Updated references for ${user.studentId} -> ${user.uid}`);

      } catch (error) {
        console.error(`❌ Error updating references for ${user.studentId}:`, error.message);
      }
    }

    console.log('\n🎉 UID migration completed successfully!');
    console.log('📄 Summary saved to uid_migration_summary.json');

    // Save summary
    const summary = {
      timestamp: new Date().toISOString(),
      totalStudents: studentIds.size,
      createdUsers: createdUsers.length,
      errors: errors.length,
      createdUsersList: createdUsers,
      errorsList: errors
    };

    require('fs').writeFileSync('uid_migration_summary.json', JSON.stringify(summary, null, 2));

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

createUIDUsers();