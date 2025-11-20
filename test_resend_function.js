const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./pathfit-capstone-515e3-firebase-adminsdk-ixhqr-e8b8b8b8b8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'pathfit-capstone-515e3'
});

async function testResendFunction() {
  try {
    console.log('🧪 Testing resendVerificationCode function...');
    
    // Call the function directly
    const functions = admin.functions();
    const callable = functions.httpsCallable('resendVerificationCode');
    
    const result = await callable({
      email: 'test@example.com'
    });
    
    console.log('✅ Function result:', result);
    
  } catch (error) {
    console.error('❌ Error calling function:', error);
  }
}

testResendFunction();