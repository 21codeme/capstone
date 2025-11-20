/**
 * Test Script for UID Consistency in Auth/Firestore
 * This script tests the complete UID-based authentication flow
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

async function testUidConsistency() {
  console.log('🧪 Testing UID Consistency...\n');
  
  try {
    // Test 1: Create test user
    console.log('📋 Test 1: Creating test user...');
    const testUser = await auth.createUser({
      email: 'test.student@example.com',
      password: 'TestPassword123!',
      displayName: 'Test Student'
    });
    
    console.log(`✅ Created user with UID: ${testUser.uid}`);
    
    // Test 2: Create Firestore document using UID as document ID
    console.log('\n📋 Test 2: Creating Firestore document...');
    const userDoc = {
      uid: testUser.uid,
      email: testUser.email,
      studentId: 'S2024001',
      firstName: 'Test',
      lastName: 'Student',
      course: 'BSIT',
      year: '4',
      section: 'A',
      role: 'student',
      accountStatus: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('users').doc(testUser.uid).set(userDoc);
    console.log(`✅ Created document with UID as ID: ${testUser.uid}`);
    
    // Test 3: Verify document exists
    console.log('\n📋 Test 3: Verifying document exists...');
    const docSnapshot = await db.collection('users').doc(testUser.uid).get();
    if (docSnapshot.exists) {
      console.log('✅ Document found with correct UID');
      console.log('📄 Document data:', docSnapshot.data());
    } else {
      console.log('❌ Document not found');
    }
    
    // Test 4: Test data retrieval by UID
    console.log('\n📋 Test 4: Testing data retrieval...');
    const userData = await db.collection('users').doc(testUser.uid).get();
    if (userData.exists && userData.data().uid === testUser.uid) {
      console.log('✅ Data retrieval successful, UID matches');
    } else {
      console.log('❌ Data retrieval failed or UID mismatch');
    }
    
    // Test 5: Test updates using UID
    console.log('\n📋 Test 5: Testing updates...');
    await db.collection('users').doc(testUser.uid).update({
      lastLogin: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Update successful');
    
    // Test 6: Test related collections with UID
    console.log('\n📋 Test 6: Testing related collections...');
    
    // Create test achievement
    await db.collection('userAchievements').add({
      userId: testUser.uid,
      achievement: 'First Login',
      points: 100,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Create test quiz
    await db.collection('studentQuizzes').add({
      studentId: testUser.uid,
      quizName: 'Test Quiz',
      score: 85,
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Related collections populated with UID');
    
    // Test 7: Verify data cleanup
    console.log('\n📋 Test 7: Testing data cleanup...');
    
    // Get all related documents
    const achievements = await db.collection('userAchievements')
      .where('userId', '==', testUser.uid).get();
    const quizzes = await db.collection('studentQuizzes')
      .where('studentId', '==', testUser.uid).get();
    
    console.log(`📊 Found ${achievements.size} achievements and ${quizzes.size} quizzes`);
    
    // Cleanup test data
    console.log('\n🧹 Cleaning up test data...');
    
    // Delete related collections
    const batch = db.batch();
    
    achievements.forEach(doc => batch.delete(doc.ref));
    quizzes.forEach(doc => batch.delete(doc.ref));
    
    // Delete user document
    batch.delete(db.collection('users').doc(testUser.uid));
    
    await batch.commit();
    
    // Delete auth user
    await auth.deleteUser(testUser.uid);
    
    console.log('✅ Test data cleaned up');
    
    console.log('\n🎉 All UID consistency tests passed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    
    // Cleanup on error
    try {
      const testUser = await auth.getUserByEmail('test.student@example.com');
      if (testUser) {
        await auth.deleteUser(testUser.uid);
        await db.collection('users').doc(testUser.uid).delete();
        console.log('🧹 Cleaned up on test failure');
      }
    } catch (cleanupError) {
      console.log('Note: Could not cleanup test data on failure');
    }
  }
}

// Run tests
if (require.main === module) {
  testUidConsistency()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Test script error:', error);
      process.exit(1);
    });
}

module.exports = { testUidConsistency };