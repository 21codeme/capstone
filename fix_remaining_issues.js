#!/usr/bin/env node

/**
 * Fix Remaining UID Migration Issues
 * 
 * This script automatically fixes the remaining issues identified
 * by the verification script after the main migration.
 */

const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

class UIDFixer {
  constructor() {
    this.fixes = {
      migratedUsers: 0,
      updatedCollections: 0,
      cleanedOrphaned: 0,
      createdMissing: 0,
      errors: []
    };
  }

  async fixRemainingIssues() {
    console.log('🔧 Starting UID Migration Fixes...\n');

    try {
      await this.fixStudentIdBasedUsers();
      await this.fixRelatedCollections();
      await this.fixOrphanedDocuments();
      await this.fixMissingAuthUsers();
      
      this.generateFixReport();
    } catch (error) {
      console.error('❌ Fix process failed:', error);
      this.fixes.errors.push(error.message);
    }
  }

  async fixStudentIdBasedUsers() {
    console.log('🔄 Fixing studentId-based users...');
    
    try {
      const usersSnapshot = await db.collection('users').get();
      
      for (const doc of usersSnapshot.docs) {
        const data = doc.data();
        const docId = doc.id;
        
        // Check if this is a studentId-based document (not using UID as ID)
        if (data.studentId && !data.uid) {
          // Try to find the corresponding Auth user by email
          try {
            const authUser = await auth.getUserByEmail(data.email);
            
            // Create new UID-based document
            await db.collection('users').doc(authUser.uid).set({
              ...data,
              uid: authUser.uid,
              migrated: true,
              migrationDate: new Date().toISOString()
            });
            
            // Delete old studentId-based document
            await db.collection('users').doc(docId).delete();
            
            this.fixes.migratedUsers++;
            console.log(`✅ Migrated user: ${data.email} (${authUser.uid})`);
            
          } catch (authError) {
            console.warn(`⚠️ Could not find Auth user for: ${data.email}`);
          }
        }
      }

      console.log(`✅ Fixed ${this.fixes.migratedUsers} studentId-based users\n`);

    } catch (error) {
      console.error('❌ Error fixing studentId-based users:', error);
      this.fixes.errors.push(`StudentId users: ${error.message}`);
    }
  }

  async fixRelatedCollections() {
    console.log('🔗 Fixing related collections...');
    
    const collections = [
      'userAchievements',
      'studentQuizzes',
      'studentModules',
      'assignmentSubmissions',
      'courseEnrollments',
      'notifications',
      'quizAttempts'
    ];

    for (const collectionName of collections) {
      try {
        const snapshot = await db.collection(collectionName).get();
        let updated = 0;

        for (const doc of snapshot.docs) {
          const data = doc.data();
          
          if (data.studentId && !data.userId) {
            // Find user by studentId
            const userQuery = await db.collection('users')
              .where('studentId', '==', data.studentId)
              .limit(1)
              .get();
            
            if (!userQuery.empty) {
              const userDoc = userQuery.docs[0];
              const uid = userDoc.id;
              
              // Update document to use UID
              await db.collection(collectionName).doc(doc.id).update({
                userId: uid,
                studentId: data.studentId, // Keep for reference
                updatedAt: new Date().toISOString()
              });
              
              updated++;
            }
          } else if (data.userId && data.userId.startsWith('S')) {
            // This might be a studentId in the userId field
            const userQuery = await db.collection('users')
              .where('studentId', '==', data.userId)
              .limit(1)
              .get();
            
            if (!userQuery.empty) {
              const userDoc = userQuery.docs[0];
              const uid = userDoc.id;
              
              await db.collection(collectionName).doc(doc.id).update({
                userId: uid,
                updatedAt: new Date().toISOString()
              });
              
              updated++;
            }
          }
        }

        this.fixes.updatedCollections += updated;
        console.log(`✅ Updated ${updated} documents in ${collectionName}`);

      } catch (error) {
        console.error(`❌ Error fixing ${collectionName}:`, error);
        this.fixes.errors.push(`${collectionName}: ${error.message}`);
      }
    }

    console.log(`✅ Fixed ${this.fixes.updatedCollections} related collection documents\n`);
  }

  async fixOrphanedDocuments() {
    console.log('👻 Cleaning up orphaned documents...');
    
    try {
      const usersSnapshot = await db.collection('users').get();
      const authUsers = await auth.listUsers();
      
      const authUids = new Set(authUsers.users.map(user => user.uid));
      const firestoreUids = new Set(usersSnapshot.docs.map(doc => doc.id));

      // Clean up Firestore documents without Auth users
      for (const firestoreUid of firestoreUids) {
        if (!authUids.has(firestoreUid)) {
          // Check if this is a legitimate orphaned document
          const userDoc = await db.collection('users').doc(firestoreUid).get();
          const userData = userDoc.data();
          
          if (userData && userData.email) {
            try {
              await auth.getUserByEmail(userData.email);
              // User exists, might be UID mismatch - skip
              continue;
            } catch (e) {
              // User doesn't exist, safe to delete
              await db.collection('users').doc(firestoreUid).delete();
              this.fixes.cleanedOrphaned++;
              console.log(`🗑️ Cleaned orphaned document: ${firestoreUid}`);
            }
          }
        }
      }

      console.log(`✅ Cleaned ${this.fixes.cleanedOrphaned} orphaned documents\n`);

    } catch (error) {
      console.error('❌ Error cleaning orphaned documents:', error);
      this.fixes.errors.push(`Orphaned docs: ${error.message}`);
    }
  }

  async fixMissingAuthUsers() {
    console.log('🔗 Creating missing Firestore documents for Auth users...');
    
    try {
      const authUsers = await auth.listUsers();
      
      for (const authUser of authUsers.users) {
        const userDoc = await db.collection('users').doc(authUser.uid).get();
        
        if (!userDoc.exists) {
          // Create basic user document
          await db.collection('users').doc(authUser.uid).set({
            uid: authUser.uid,
            email: authUser.email,
            displayName: authUser.displayName || '',
            photoURL: authUser.photoURL || '',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            isActive: true,
            autoCreated: true
          });
          
          this.fixes.createdMissing++;
          console.log(`✅ Created missing document for: ${authUser.email}`);
        }
      }

      console.log(`✅ Created ${this.fixes.createdMissing} missing documents\n`);

    } catch (error) {
      console.error('❌ Error creating missing documents:', error);
      this.fixes.errors.push(`Missing docs: ${error.message}`);
    }
  }

  generateFixReport() {
    console.log('📊 FIX REPORT');
    console.log('=============');

    console.log(`✅ Migrated Users: ${this.fixes.migratedUsers}`);
    console.log(`✅ Updated Collections: ${this.fixes.updatedCollections}`);
    console.log(`✅ Cleaned Orphaned: ${this.fixes.cleanedOrphaned}`);
    console.log(`✅ Created Missing: ${this.fixes.createdMissing}`);
    console.log(`❌ Errors: ${this.fixes.errors.length}\n`);

    if (this.fixes.errors.length > 0) {
      console.log('❌ Errors Encountered:');
      this.fixes.errors.forEach(error => console.log(`  - ${error}`));
      console.log();
    }

    // Save fix report
    const reportPath = './fix_report.json';
    fs.writeFileSync(reportPath, JSON.stringify(this.fixes, null, 2));
    console.log(`📄 Fix report saved to: ${reportPath}\n`);

    if (this.fixes.errors.length === 0) {
      console.log('🎉 All fixes completed successfully!');
      console.log('✅ Your UID migration is now complete.\n');
    } else {
      console.log('⚠️ Some fixes encountered errors.');
      console.log('🛠️ Please review the errors above.\n');
    }
  }
}

// Run fixes if called directly
if (require.main === module) {
  const fixer = new UIDFixer();
  fixer.fixRemainingIssues()
    .then(() => {
      console.log('✅ Fix process complete!');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Fix process failed:', error);
      process.exit(1);
    });
}

module.exports = UIDFixer;