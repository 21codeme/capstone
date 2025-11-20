// Simple test to call the resendVerificationCode function via HTTP
const https = require('https');

async function testResendVerificationCode() {
  console.log('🧪 Testing resendVerificationCode function via HTTP...');
  
  // Test UID - you can change this to test different users
  const testUID = 'GhmQUlkXLYNf13qRIETSTaPDCfg2';
  
  const data = JSON.stringify({
    data: {
      uid: testUID,
      email: 'belly@yopmail.com',
      verificationCode: '123456' // This will be overwritten by the function
    }
  });
  
  const options = {
    hostname: 'us-central1-pathfit-capstone-515e3.cloudfunctions.net',
    path: '/resendVerificationCode',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };
  
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        console.log('📥 Response status:', res.statusCode);
        console.log('📥 Response data:', responseData);
        resolve(responseData);
      });
    });
    
    req.on('error', (error) => {
      console.error('❌ Request error:', error);
      reject(error);
    });
    
    console.log('📤 Sending request with data:', data);
    req.write(data);
    req.end();
  });
}

// Run the test
testResendVerificationCode()
  .then(() => {
    console.log('🏁 Test completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Test failed:', error);
    process.exit(1);
  });