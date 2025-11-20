/**
 * Migration Script: Student ID → UID Consistency
 * This script helps migrate existing data from studentId-based to UID-based system
 */

const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Initialize Firebase Admin (use service account)
const serviceAccount = require('./firebase-admin-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = getFirestore();
const auth = getAuth();

class UidMigration {
  constructor() {
    this.migrationLog = [];
    this.errors = [];
  }

  async migrateAllUsers() {
    console.log('🚀 Starting UID migration...\n');
    
    try {
      // Get all users from Firestore
      console.log('📊 Fetching all users from Firestore...');
      const usersSnapshot = await db.collection('users').get();
      
      console.log(`📋 Found ${usersSnapshot.size} users to process\n`);
      
      for (const userDoc of usersSnapshot.docs) {
        await this.migrateUser(userDoc);
      }
      
      // Print summary
      this.printSummary();
      
    } catch (error) {
      console.error('❌ Migration failed:', error);
      this.errors.push({ type: 'general', error: error.message });
    }
  }

  async migrateUser(userDoc) {
    const userData = userDoc.data();
    const docId = userDoc.id;
    
    console.log(`🔄 Processing user: ${userData.email || 'unknown'} (Doc ID: ${docId})`);
    
    try {
      // Find corresponding Auth user
      let authUser = null;
      
      if (userData.email) {
        try {
          authUser = await auth.getUserByEmail(userData.email);
          console.log(`✅ Found Auth user: ${authUser.uid}`);
        } catch (error) {
          console.log(`⚠️ No Auth user found for email: ${userData.email}`);
        }
      }
      
      if (!authUser && userData.uid) {
        try {
          authUser = await auth.getUser(userData.uid);
          console.log(`✅ Found Auth user by UID: ${authUser.uid}`);
        } catch (error) {
          console.log(`⚠️ No Auth user found for UID: ${userData.uid}`);
        }
      }
      
      if (!authUser) {
        console.log(`❌ Skipping - no Auth user found`);
        this.migrationLog.push({
          email: userData.email,
          docId: docId,
          status: 'skipped_no_auth',
          reason: 'No corresponding Auth user found'
        });
        return;
      }
      
      const uid = authUser.uid;
      
      // Check if document already uses UID as ID
      if (docId === uid) {
        console.log(`✅ Document already uses UID as ID`);
        
        // Ensure uid field is set
        if (!userData.uid) {
          await db.collection('users').doc(uid).update({
            uid: uid
          });
          console.log(`✅ Added UID field to document`);
        }
        
        this.migrationLog.push({
          email: userData.email,
          docId: docId,
          uid: uid,
          status: 'already_correct'
        });
        return;
      }
      
      // Migrate user document
      await this.migrateUserDocument(userDoc, uid, userData);
      
      // Migrate related collections
      await this.migrateRelatedCollections(docId, uid);
      
      console.log(`✅ Successfully migrated user: ${userData.email}`);
      
    } catch (error) {
      console.error(`❌ Error migrating user ${userData.email}:`, error);
      this.errors.push({
        email: userData.email,
        docId: docId,
        error: error.message
      });
    }
  }

  async migrateUserDocument(userDoc, uid, userData) {
    const docId = userDoc.id;
    
    console.log(`📄 Migrating user document...`);
    
    // Ensure uid field is set
    const updatedData = {
      ...userData,
      uid: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // Create new document with UID as ID
    await db.collection('users').doc(uid).set(updatedData);
    
    // Delete old document
    await userDoc.ref.delete();
    
    console.log(`✅ Migrated user document from ${docId} to ${uid}`);
    
    this.migrationLog.push({
      email: userData.email,
      oldDocId: docId,
      newDocId: uid,
      status: 'migrated'
    });
  }

  async migrateRelatedCollections(oldDocId, uid) {
    console.log(`🔄 Migrating related collections...`);
    
    const collectionsToMigrate = [
      { collection: 'userAchievements', field: 'userId' },
      { collection: 'studentQuizzes', field: 'studentId' },
      { collection: 'studentModules', field: 'studentId' },
      { collection: 'messages', field: 'senderId' },
      { collection: 'messages', field: 'recipientId' },
      { collection: 'assignmentSubmissions', field: 'studentId' },
      { collection: 'enrollments', field: 'userId' },
      { collection: 'userPreferences', field: 'userId' },
      { collection: 'userActivity', field: 'userId' }
    ];
    
    let totalMigrated = 0;
    
    for (const collectionInfo of collectionsToMigrate) {
      const { collection, field } = collectionInfo;
      
      try {
        const querySnapshot = await db.collection(collection)
          .where(field, '==', oldDocId)
          .get();
        
        if (querySnapshot.empty) {
          continue;
        }
        
        console.log(`📊 Found ${querySnapshot.size} documents in ${collection}`);
        
        const batch = db.batch();
        
        for (const doc of querySnapshot.docs) {
          batch.update(doc.ref, {
            [field]: uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          totalMigrated++;
        }
        
        await batch.commit();
        console.log(`✅ Migrated ${querySnapshot.size} documents in ${collection}`);
        
      } catch (error) {
        console.error(`❌ Error migrating ${collection}:`, error);
        this.errors.push({
          collection: collection,
          oldId: oldDocId,
          newId: uid,
          error: error.message
        });
      }
    }
    
    console.log(`✅ Total documents migrated: ${totalMigrated}`);
  }

  printSummary() {
    console.log('\n📊 Migration Summary:');
    console.log('====================');
    
    const summary = {
      total: this.migrationLog.length,
      migrated: this.migrationLog.filter(x => x.status === 'migrated').length,
      alreadyCorrect: this.migrationLog.filter(x => x.status === 'already_correct').length,
      skipped: this.migrationLog.filter(x => x.status === 'skipped_no_auth').length,
      errors: this.errors.length
    };
    
    console.log(`Total users processed: ${summary.total}`);
    console.log(`Successfully migrated: ${summary.migrated}`);
    console.log(`Already correct: ${summary.alreadyCorrect}`);
    console.log(`Skipped (no auth): ${summary.skipped}`);
    console.log(`Errors: ${summary.errors}`);
    
    if (this.errors.length > 0) {
      console.log('\n❌ Errors:');
      this.errors.forEach(error => {
        console.log(`- ${error.email || error.collection}: ${error.error}`);
      });
    }
    
    console.log('\n✅ Migration completed!');
  }
}

// Run migration if called directly
if (require.main === module) {
  const migration = new UidMigration();
  migration.migrateAllUsers()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Migration script error:', error);
      process.exit(1);
    });
}

module.exports = { UidMigration };