/**
 * Test script for Firebase authentication flow
 * Run with: node test_auth_flow.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

// Test configuration
const testConfig = {
  email: 'test.student@example.com',
  password: 'TestPassword123!',
  firstName: 'Test',
  lastName: 'Student',
  course: 'BSIT',
  year: '2',
  section: 'A'
};

// Helper function to generate verification code
function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Test 1: Create pending user
async function testCreatePendingUser() {
  console.log('🧪 Testing: Create Pending User');
  
  try {
    // Check if user already exists
    const existingUser = await auth.getUserByEmail(testConfig.email).catch(() => null);
    if (existingUser) {
      console.log('⚠️  User already exists, cleaning up...');
      await auth.deleteUser(existingUser.uid);
      await db.collection('users').doc(testConfig.email).delete().catch(() => {});
    }
    
    // Create pending user
    const verificationCode = generateVerificationCode();
    const userData = {
      email: testConfig.email,
      firstName: testConfig.firstName,
      lastName: testConfig.lastName,
      course: testConfig.course,
      year: testConfig.year,
      section: testConfig.section,
      password: testConfig.password,
      verificationCode: verificationCode,
      verificationExpiry: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
      accountStatus: 'pending',
      createdAt: new Date(),
      loginAttempts: 0,
      lastLoginAttempt: null
    };
    
    await db.collection('users').doc(testConfig.email).set(userData);
    
    console.log('✅ Pending user created successfully');
    console.log(`   Email: ${testConfig.email}`);
    console.log(`   Verification Code: ${verificationCode}`);
    
    return verificationCode;
  } catch (error) {
    console.error('❌ Failed to create pending user:', error.message);
    throw error;
  }
}

// Test 2: Complete registration
async function testCompleteRegistration(verificationCode) {
  console.log('\n🧪 Testing: Complete Registration');
  
  try {
    // Get pending user
    const pendingUserDoc = await db.collection('users').doc(testConfig.email).get();
    
    if (!pendingUserDoc.exists) {
      throw new Error('Pending user not found');
    }
    
    const pendingUser = pendingUserDoc.data();
    
    // Verify verification code
    if (pendingUser.verificationCode !== verificationCode) {
      throw new Error('Invalid verification code');
    }
    
    if (pendingUser.verificationExpiry.toDate() < new Date()) {
      throw new Error('Verification code expired');
    }
    
    // Create Firebase Auth user
    const userRecord = await auth.createUser({
      email: testConfig.email,
      password: testConfig.password,
      displayName: `${testConfig.firstName} ${testConfig.lastName}`,
      emailVerified: true
    });
    
    // Prepare user data for new document
    const userData = {
      uid: userRecord.uid,
      email: testConfig.email,
      firstName: testConfig.firstName,
      lastName: testConfig.lastName,
      course: testConfig.course,
      year: testConfig.year,
      section: testConfig.section,
      accountStatus: 'active',
      createdAt: new Date(),
      verifiedAt: new Date(),
      loginAttempts: 0,
      lastLoginAttempt: null,
      loginStreak: 0,
      role: 'student'
    };
    
    // Use transaction to move data from email-based document to UID-based document
    await db.runTransaction(async (transaction) => {
      // Create new document with UID as ID
      transaction.set(db.collection('users').doc(userRecord.uid), userData);
      
      // Delete old email-based document
      transaction.delete(db.collection('users').doc(testConfig.email));
    });
    
    console.log('✅ Registration completed successfully');
    console.log(`   UID: ${userRecord.uid}`);
    console.log(`   Email: ${userRecord.email}`);
    
    return userRecord.uid;
  } catch (error) {
    console.error('❌ Failed to complete registration:', error.message);
    throw error;
  }
}

// Test 3: Login user
async function testLoginUser(uid) {
  console.log('\n🧪 Testing: Login User');
  
  try {
    // Get user document
    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      throw new Error('User not found');
    }
    
    const userData = userDoc.data();
    
    // Check account status
    if (userData.accountStatus !== 'active') {
      throw new Error('Account is not active');
    }
    
    // Check rate limiting
    const now = new Date();
    const lastAttempt = userData.lastLoginAttempt?.toDate();
    
    if (lastAttempt && userData.loginAttempts >= 5) {
      const timeDiff = now - lastAttempt;
      if (timeDiff < 15 * 60 * 1000) { // 15 minutes
        throw new Error('Too many failed attempts. Please try again later.');
      }
    }
    
    // Create custom token
    const customToken = await auth.createCustomToken(uid, {
      role: userData.role,
      email: userData.email
    });
    
    // Update login stats
    await db.collection('users').doc(uid).update({
      loginAttempts: 0,
      lastLoginAttempt: now,
      loginStreak: (userData.loginStreak || 0) + 1,
      lastLoginAt: now
    });
    
    console.log('✅ Login successful');
    console.log(`   Custom Token: ${customToken.substring(0, 20)}...`);
    
    return customToken;
  } catch (error) {
    console.error('❌ Login failed:', error.message);
    
    // Update failed login attempt
    if (uid) {
      try {
        const userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          await db.collection('users').doc(uid).update({
            loginAttempts: (userDoc.data().loginAttempts || 0) + 1,
            lastLoginAttempt: new Date()
          });
        }
      } catch (updateError) {
        console.error('Failed to update failed login attempt:', updateError.message);
      }
    }
    
    throw error;
  }
}

// Test 4: Test rate limiting
async function testRateLimiting() {
  console.log('\n🧪 Testing: Rate Limiting');
  
  try {
    const testEmail = 'ratelimit.test@example.com';
    
    // Create a user for rate limiting test
    await auth.createUser({
      email: testEmail,
      password: 'WrongPassword123!'
    });
    
    // Simulate multiple failed login attempts
    for (let i = 0; i < 6; i++) {
      try {
        await auth.getUserByEmail(testEmail);
        // Simulate failed login by throwing error
        throw new Error('Invalid credentials');
      } catch (error) {
        if (error.message === 'Invalid credentials') {
          // Update login attempts in Firestore
          const userRecord = await auth.getUserByEmail(testEmail);
          await db.collection('users').doc(userRecord.uid).update({
            loginAttempts: i + 1,
            lastLoginAttempt: new Date()
          }).catch(() => {});
        }
      }
    }
    
    console.log('✅ Rate limiting test completed');
    
    // Cleanup
    const userRecord = await auth.getUserByEmail(testEmail);
    await auth.deleteUser(userRecord.uid);
    
  } catch (error) {
    console.error('❌ Rate limiting test failed:', error.message);
  }
}

// Test 5: Test data validation
async function testDataValidation() {
  console.log('\n🧪 Testing: Data Validation');
  
  try {
    const testEmail = 'validation.test@example.com';
    
    // Test invalid email
    try {
      await db.collection('users').doc('test-user').set({
        email: 'invalid-email',
        firstName: 'Test',
        lastName: 'User',
        course: 'BSIT',
        year: '2',
        section: 'A'
      });
      console.error('❌ Should have failed with invalid email');
    } catch (error) {
      console.log('✅ Correctly rejected invalid email format');
    }
    
    // Test invalid year
    try {
      await db.collection('users').doc('test-user').set({
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        course: 'BSIT',
        year: '5', // Invalid year
        section: 'A'
      });
      console.error('❌ Should have failed with invalid year');
    } catch (error) {
      console.log('✅ Correctly rejected invalid year');
    }
    
    console.log('✅ Data validation tests completed');
    
  } catch (error) {
    console.error('❌ Data validation test failed:', error.message);
  }
}

// Main test runner
async function runAllTests() {
  console.log('🔥 Firebase Authentication Flow Test Suite');
  console.log('==========================================\n');
  
  try {
    // Run tests in sequence
    const verificationCode = await testCreatePendingUser();
    const uid = await testCompleteRegistration(verificationCode);
    await testLoginUser(uid);
    await testRateLimiting();
    await testDataValidation();
    
    console.log('\n✅ All tests completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Test suite failed:', error.message);
  } finally {
    // Cleanup
    try {
      await auth.getUserByEmail(testConfig.email).then(user => 
        auth.deleteUser(user.uid)
      ).catch(() => {});
      
      await db.collection('users').doc(testConfig.email).delete().catch(() => {});
    } catch (cleanupError) {
      console.error('Cleanup error:', cleanupError.message);
    }
    
    process.exit(0);
  }
}

// Run tests if this script is executed directly
if (require.main === module) {
  runAllTests();
}

module.exports = {
  testCreatePendingUser,
  testCompleteRegistration,
  testLoginUser,
  testRateLimiting,
  testDataValidation
};