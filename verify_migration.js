#!/usr/bin/env node

/**
 * Migration Verification Script
 * 
 * This script verifies that the UID-based migration was successful
 * and identifies any remaining issues that need to be addressed.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

class MigrationVerifier {
  constructor() {
    this.results = {
      totalUsers: 0,
      uidBasedUsers: 0,
      studentIdBasedUsers: 0,
      orphanedDocuments: 0,
      missingAuthUsers: 0,
      relatedCollectionIssues: 0,
      errors: []
    };
  }

  async verifyMigration() {
    console.log('🔍 Starting UID Migration Verification...\n');

    try {
      await this.verifyUserDocuments();
      await this.verifyRelatedCollections();
      await this.checkOrphanedDocuments();
      await this.verifyAuthSync();
      
      this.generateReport();
    } catch (error) {
      console.error('❌ Verification failed:', error);
      this.results.errors.push(error.message);
    }

    return this.results;
  }

  async verifyUserDocuments() {
    console.log('📋 Verifying user documents...');
    
    try {
      const usersSnapshot = await db.collection('users').get();
      this.results.totalUsers = usersSnapshot.size;

      for (const doc of usersSnapshot.docs) {
        const data = doc.data();
        const docId = doc.id;
        
        // Check if document uses UID as ID
        if (data.uid && data.uid === docId) {
          this.results.uidBasedUsers++;
        } else {
          this.results.studentIdBasedUsers++;
          
          // Check if this might be a studentId-based document
          if (data.studentId && !data.uid) {
            console.warn(`⚠️ Student ID-based document found: ${docId}`);
          }
        }
      }

      console.log(`✅ Found ${this.results.uidBasedUsers} UID-based users`);
      console.log(`⚠️ Found ${this.results.studentIdBasedUsers} non-UID-based documents\n`);

    } catch (error) {
      console.error('❌ Error verifying user documents:', error);
      this.results.errors.push(`User documents verification: ${error.message}`);
    }
  }

  async verifyRelatedCollections() {
    console.log('🔗 Verifying related collections...');
    
    const relatedCollections = [
      'userAchievements',
      'studentQuizzes',
      'studentModules',
      'assignmentSubmissions',
      'courseEnrollments',
      'notifications',
      'quizAttempts'
    ];

    for (const collectionName of relatedCollections) {
      try {
        const snapshot = await db.collection(collectionName).get();
        let uidReferences = 0;
        let studentIdReferences = 0;
        let missingReferences = 0;

        for (const doc of snapshot.docs) {
          const data = doc.data();
          
          if (data.userId && data.userId.startsWith('S')) {
            // This looks like a student ID reference
            studentIdReferences++;
            this.results.relatedCollectionIssues++;
          } else if (data.userId && !data.userId.startsWith('S')) {
            // This looks like a UID reference
            uidReferences++;
          } else if (!data.userId && data.studentId) {
            // Old format using studentId field
            studentIdReferences++;
            this.results.relatedCollectionIssues++;
          } else if (!data.userId) {
            missingReferences++;
          }
        }

        console.log(`📊 ${collectionName}:`);
        console.log(`   UID references: ${uidReferences}`);
        console.log(`   Student ID references: ${studentIdReferences}`);
        console.log(`   Missing references: ${missingReferences}\n`);

      } catch (error) {
        console.error(`❌ Error verifying ${collectionName}:`, error);
        this.results.errors.push(`${collectionName}: ${error.message}`);
      }
    }
  }

  async checkOrphanedDocuments() {
    console.log('👻 Checking for orphaned documents...');
    
    try {
      const usersSnapshot = await db.collection('users').get();
      const authUsers = await auth.listUsers();
      
      const authUids = new Set(authUsers.users.map(user => user.uid));
      const firestoreUids = new Set(usersSnapshot.docs.map(doc => doc.id));

      // Check for Firestore documents without Auth users
      for (const firestoreUid of firestoreUids) {
        if (!authUids.has(firestoreUid)) {
          console.warn(`⚠️ Orphaned Firestore document: ${firestoreUid}`);
          this.results.orphanedDocuments++;
        }
      }

      // Check for Auth users without Firestore documents
      for (const authUid of authUids) {
        if (!firestoreUids.has(authUid)) {
          console.warn(`⚠️ Missing Firestore document for Auth user: ${authUid}`);
          this.results.missingAuthUsers++;
        }
      }

      console.log(`✅ Found ${this.results.orphanedDocuments} orphaned documents`);
      console.log(`✅ Found ${this.results.missingAuthUsers} missing Firestore documents\n`);

    } catch (error) {
      console.error('❌ Error checking orphaned documents:', error);
      this.results.errors.push(`Orphaned documents: ${error.message}`);
    }
  }

  async verifyAuthSync() {
    console.log('🔐 Verifying Auth-Firestore synchronization...');
    
    try {
      const authUsers = await auth.listUsers();
      let syncIssues = 0;

      for (const authUser of authUsers.users) {
        const userDoc = await db.collection('users').doc(authUser.uid).get();
        
        if (!userDoc.exists) {
          console.warn(`⚠️ Missing Firestore document for Auth user: ${authUser.uid}`);
          syncIssues++;
          continue;
        }

        const userData = userDoc.data();
        
        // Verify email matches
        if (userData.email !== authUser.email) {
          console.warn(`⚠️ Email mismatch for ${authUser.uid}: Firestore(${userData.email}) vs Auth(${authUser.email})`);
          syncIssues++;
        }

        // Verify UID matches
        if (userData.uid !== authUser.uid) {
          console.warn(`⚠️ UID mismatch for ${authUser.uid}`);
          syncIssues++;
        }
      }

      console.log(`✅ Found ${syncIssues} synchronization issues\n`);

    } catch (error) {
      console.error('❌ Error verifying Auth sync:', error);
      this.results.errors.push(`Auth sync: ${error.message}`);
    }
  }

  generateReport() {
    console.log('📊 MIGRATION VERIFICATION REPORT');
    console.log('==================================\n');

    console.log('📈 Summary:');
    console.log(`Total Users: ${this.results.totalUsers}`);
    console.log(`UID-based Users: ${this.results.uidBasedUsers}`);
    console.log(`Student ID-based Users: ${this.results.studentIdBasedUsers}`);
    console.log(`Orphaned Documents: ${this.results.orphanedDocuments}`);
    console.log(`Missing Auth Users: ${this.results.missingAuthUsers}`);
    console.log(`Related Collection Issues: ${this.results.relatedCollectionIssues}`);
    console.log(`Errors: ${this.results.errors.length}\n`);

    // Generate migration success percentage
    const successRate = this.results.totalUsers > 0 
      ? Math.round((this.results.uidBasedUsers / this.results.totalUsers) * 100)
      : 0;

    console.log(`🎯 Migration Success Rate: ${successRate}%\n`);

    if (this.results.errors.length > 0) {
      console.log('❌ Errors Encountered:');
      this.results.errors.forEach(error => console.log(`  - ${error}`));
      console.log();
    }

    // Save detailed report
    const reportPath = path.join(__dirname, 'migration_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(this.results, null, 2));
    console.log(`📄 Detailed report saved to: ${reportPath}\n`);

    // Provide recommendations
    this.provideRecommendations();
  }

  provideRecommendations() {
    console.log('💡 RECOMMENDATIONS:');
    console.log('==================\n');

    if (this.results.studentIdBasedUsers > 0) {
      console.log('1. 🔄 Re-run migration script for remaining studentId-based users');
      console.log('   Command: node migrate_to_uid.js\n');
    }

    if (this.results.relatedCollectionIssues > 0) {
      console.log('2. 🔧 Update related collections to use UID references');
      console.log('   - Run collection-specific migration scripts');
      console.log('   - Verify all foreign key references are updated\n');
    }

    if (this.results.orphanedDocuments > 0) {
      console.log('3. 🧹 Clean up orphaned Firestore documents');
      console.log('   - Review orphaned documents manually');
      console.log('   - Delete or merge as appropriate\n');
    }

    if (this.results.missingAuthUsers > 0) {
      console.log('4. 🔗 Create missing Firestore documents for Auth users');
      console.log('   - Sync Auth users with Firestore');
      console.log('   - Ensure all Auth users have corresponding documents\n');
    }

    if (this.results.errors.length > 0) {
      console.log('5. ❌ Address all errors before proceeding');
      console.log('   - Review error logs');
      console.log('   - Fix underlying issues\n');
    }

    if (this.results.uidBasedUsers === this.results.totalUsers && this.results.errors.length === 0) {
      console.log('✅ Migration appears to be 100% successful!');
      console.log('🎉 You can proceed with confidence.\n');
    } else {
      console.log('⚠️ Migration needs additional attention.');
      console.log('🛠️ Please address the recommendations above.\n');
    }
  }
}

// Run verification if called directly
if (require.main === module) {
  const verifier = new MigrationVerifier();
  verifier.verifyMigration()
    .then(() => {
      console.log('✅ Verification complete!');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Verification failed:', error);
      process.exit(1);
    });
}

module.exports = MigrationVerifier;