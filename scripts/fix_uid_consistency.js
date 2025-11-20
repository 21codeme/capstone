const admin = require('firebase-admin');
const serviceAccount = require('../pathfit-capstone-firebase-adminsdk.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://pathfit-capstone-515e3.firebaseio.com'
});

const db = admin.firestore();
const auth = admin.auth();

async function fixUidConsistency() {
  console.log('🔧 Starting UID consistency fix...');
  
  try {
    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 Found ${usersSnapshot.docs.length} users in Firestore`);
    
    const fixes = [];
    const conflicts = [];
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const firestoreStudentId = doc.id;
      const firestoreUid = userData.uid;
      const email = userData.email;
      
      console.log(`🔍 Checking user: ${email}`);
      console.log(`   Firestore doc ID: ${firestoreStudentId}`);
      console.log(`   Firestore UID: ${firestoreUid}`);
      
      try {
        // Get Firebase Auth user by email
        const authUser = await auth.getUserByEmail(email);
        const authUid = authUser.uid;
        
        console.log(`   Firebase Auth UID: ${authUid}`);
        
        // Check if there's a mismatch
        if (firestoreUid !== authUid || firestoreStudentId !== authUid) {
          console.log(`   ❌ UID mismatch detected!`);
          
          // Check if the student ID is already used as a document ID
          const studentIdDoc = await db.collection('users').doc(firestoreStudentId).get();
          
          if (studentIdDoc.exists) {
            fixes.push({
              email,
              firestoreStudentId,
              firestoreUid,
              authUid,
              action: 'update_firestore_uid'
            });
          } else {
            conflicts.push({
              email,
              firestoreStudentId,
              firestoreUid,
              authUid,
              action: 'needs_manual_review'
            });
          }
        } else {
          console.log(`   ✅ UIDs are consistent`);
        }
      } catch (error) {
        console.log(`   ⚠️ Error getting auth user: ${error.message}`);
        conflicts.push({
          email,
          firestoreStudentId,
          firestoreUid,
          authUid: null,
          action: 'auth_user_not_found',
          error: error.message
        });
      }
    }
    
    console.log('\n📋 Summary:');
    console.log(`   Fixes needed: ${fixes.length}`);
    console.log(`   Manual review needed: ${conflicts.length}`);
    
    // Apply fixes for consistent cases
    if (fixes.length > 0) {
      console.log('\n🔧 Applying fixes...');
      
      for (const fix of fixes) {
        try {
          // Update Firestore document to use student ID as UID
          await db.collection('users').doc(fix.firestoreStudentId).update({
            uid: fix.firestoreStudentId
          });
          
          console.log(`   ✅ Fixed UID for ${fix.email}`);
        } catch (error) {
          console.log(`   ❌ Failed to fix ${fix.email}: ${error.message}`);
        }
      }
    }
    
    // Report conflicts
    if (conflicts.length > 0) {
      console.log('\n⚠️ Manual review needed for:');
      conflicts.forEach(conflict => {
        console.log(`   - ${conflict.email}: ${conflict.action}`);
      });
    }
    
    console.log('\n✅ UID consistency fix completed');
    
  } catch (error) {
    console.error('❌ Error during UID consistency fix:', error);
  }
}

// Run the fix
fixUidConsistency().then(() => {
  console.log('🏁 Process completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Process failed:', error);
  process.exit(1);
});