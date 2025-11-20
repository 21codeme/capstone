

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const { onSchedule } = require('firebase-functions/v2/scheduler');

// Initialize Firebase Admin SDK
try {
  admin.initializeApp();
  console.log('Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('Failed to initialize Firebase Admin SDK:', error);
  throw error;
}

// Initialize Nodemailer transporter with your Gmail credentials
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'mockupfusion23@gmail.com',
    pass: 'ehhysovktyckpsyl',
  },
});

/**
 * Cloud Function to send OTP email for student registration using Nodemailer
 */
exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  console.log('Raw data received:', data);
  console.log('Data type:', typeof data);
  console.log('Data keys:', Object.keys(data || {}));
  
  // For Firebase callable functions, the actual user data is in data.data
  const actualData = data.data || {};
  console.log('Actual data:', actualData);
  
  const { email, otp, verificationCode } = actualData;
  
  console.log('Extracted email:', email);
  console.log('Extracted otp:', otp);
  console.log('Extracted verificationCode:', verificationCode);
  
  // Handle both 'otp' and 'verificationCode' parameter names for backward compatibility
  const code = otp || verificationCode;
  
  console.log('Final code:', code);
  
  if (!email || !code) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email and OTP are required.'
    );
  }

  try {
    // Email configuration
    const mailOptions = {
      from: 'PathFit <mockupfusion23@gmail.com>',
      to: email,
      subject: 'PathFit - Your Verification Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 28px;">PathFit</h1>
            <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">Your Fitness Journey Starts Here</p>
          </div>
          
          <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-top: 20px;">
            <h2 style="color: #333; margin-top: 0;">Email Verification</h2>
            <p style="color: #666; font-size: 16px; line-height: 1.6;">
              Thank you for registering with PathFit! Please use the verification code below to complete your registration.
            </p>
            
            <div style="background: white; border: 2px solid #667eea; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
              <p style="color: #666; margin: 0 0 10px 0; font-size: 14px;">Your verification code:</p>
              <div style="font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                ${code}
              </div>
            </div>
            
            <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0;">
              <p style="color: #856404; margin: 0; font-size: 14px;">
                <strong>Important:</strong> This code will expire in 10 minutes for security purposes.
              </p>
            </div>
            
            <p style="color: #666; font-size: 14px; margin-top: 20px;">
              If you didn't request this verification, please ignore this email.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 12px;">
            <p>© 2024 PathFit. All rights reserved.</p>
          </div>
        </div>
      `
    };

    // Send email using Nodemailer
    await transporter.sendMail(mailOptions);
    console.log(`OTP email sent successfully to: ${email}`);
    
    return { success: true, message: 'OTP email sent successfully' };
  } catch (error) {
    console.error('Error sending OTP email with Nodemailer:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send OTP email. Please try again later.'
    );
  }
});

/**
 * Cloud Function to send OTP email for registration verification
 * Generates a 6-digit OTP code and sends it to the user's email
 */
exports.sendRegistrationOtp = functions.https.onCall(async (data, context) => {
  try {
    // Extract data from the request - for callable functions, data is wrapped in a data property
    const requestData = data?.data || data;
    const email = requestData?.email;
    const firstName = requestData?.firstName;
    const lastName = requestData?.lastName;
    
    console.log('Registration OTP request received for:', email);
    console.log('Request data:', JSON.stringify(requestData));
    console.log('Email value:', email);
    console.log('First name value:', firstName);
    console.log('Last name value:', lastName);
    
    // Validate required fields
    if (!email) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email is required for OTP verification'
      );
    }
    
    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }
    
    // Generate 6-digit OTP code
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    console.log('Generated OTP:', otp);
    
    // Create email content with professional design
    const mailOptions = {
      from: 'PathFit <mockupfusion23@gmail.com>',
      to: email,
      subject: 'PathFit - Complete Your Registration',
      html: `
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #ffffff;">
          <!-- Header -->
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; border-radius: 15px 15px 0 0; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 32px; font-weight: 700; letter-spacing: 1px;">PathFit</h1>
            <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9; font-weight: 300;">Your Fitness Journey Starts Here</p>
          </div>
          
          <!-- Main Content -->
          <div style="background: #f8f9fa; padding: 40px; border-radius: 0 0 15px 15px; border: 1px solid #e9ecef;">
            <h2 style="color: #2c3e50; margin: 0 0 20px 0; font-size: 24px; font-weight: 600;">Welcome to PathFit!</h2>
            
            <p style="color: #5a6c7d; font-size: 16px; line-height: 1.6; margin-bottom: 25px;">
              ${firstName ? `Hi ${firstName},` : 'Hi there,'} Welcome to PathFit! We're excited to have you join our fitness community. 
              To complete your registration and verify your email address, please use the verification code below.
            </p>
            
            <!-- OTP Code Box -->
            <div style="background: white; border: 3px solid #667eea; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
              <p style="color: #6c757d; margin: 0 0 15px 0; font-size: 14px; font-weight: 500; text-transform: uppercase; letter-spacing: 1px;">Your Verification Code</p>
              <div style="font-size: 36px; font-weight: 700; color: #667eea; letter-spacing: 10px; font-family: 'Courier New', monospace; margin: 20px 0;">
                ${otp}
              </div>
              <p style="color: #6c757d; margin: 15px 0 0 0; font-size: 12px;">Enter this code in the app to verify your email</p>
            </div>
            
            <!-- Security Notice -->
            <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 20px; margin: 25px 0;">
              <p style="color: #856404; margin: 0; font-size: 14px; font-weight: 500;">
                <strong>⏰ Important:</strong> This verification code will expire in 10 minutes for security purposes.
              </p>
            </div>
            
            <!-- Next Steps -->
            <div style="background: #e8f5e8; border: 1px solid #c3e6c3; border-radius: 8px; padding: 20px; margin: 25px 0;">
              <h3 style="color: #155724; margin: 0 0 10px 0; font-size: 16px; font-weight: 600;">What's Next?</h3>
              <ul style="color: #155724; margin: 0; padding-left: 20px; font-size: 14px;">
                <li>Enter the verification code in the app</li>
                <li>Complete your profile setup</li>
                <li>Start your fitness journey with PathFit!</li>
              </ul>
            </div>
            
            <p style="color: #6c757d; font-size: 14px; margin-top: 25px; line-height: 1.5;">
              If you didn't request this verification or if you have any questions, please contact our support team or simply ignore this email.
            </p>
          </div>
          
          <!-- Footer -->
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 12px; padding: 0 20px;">
            <p style="margin: 0;">© 2024 PathFit. All rights reserved.</p>
            <p style="margin: 5px 0 0 0;">This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      `
    };

    // Send email using Nodemailer
    await transporter.sendMail(mailOptions);
    console.log(`✅ Registration OTP sent successfully to: ${email}`);
    
    return { 
      success: true, 
      message: 'Registration OTP sent successfully',
      otp: otp, // Return OTP for testing purposes (remove in production)
      expiry: Date.now() + (10 * 60 * 1000) // 10 minutes from now
    };
    
  } catch (error) {
    console.error('❌ Error sending registration OTP:', error);
    
    if (error.code && error.code.startsWith('functions/')) {
      throw error; // Re-throw Firebase errors
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send registration OTP. Please try again later.'
    );
  }
});

/**
 * Cloud Function to handle user login with rate limiting and security features
 */
exports.loginUser = functions.https.onCall(async (data, context) => {
  try {
    const { email, password } = data;

    if (!email || !password) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and password are required'
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    const firestore = admin.firestore();
    
    // Use transaction for atomic operations
    return await firestore.runTransaction(async (transaction) => {
      // Find user by email
      const userQuery = await transaction.get(
        firestore
          .collection('users')
          .where('email', '==', email.toLowerCase().trim())
          .limit(1)
      );

      if (userQuery.empty) {
        throw new functions.https.HttpsError(
          'not-found',
          'Invalid email or password'
        );
      }

      const userDoc = userQuery.docs[0];
      const userData = userDoc.data();

      // Check account status
      if (userData.accountStatus === 'pending') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Account not verified. Please check your email for verification code.'
        );
      }

      if (userData.accountStatus !== 'active') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Account is not active. Please contact support.'
        );
      }

      // Check for account lockout (5 failed attempts in 15 minutes)
      const now = admin.firestore.Timestamp.now();
      const fifteenMinutesAgo = admin.firestore.Timestamp.fromDate(
        new Date(now.toDate().getTime() - 15 * 60 * 1000)
      );

      if (userData.loginAttempts >= 5 && 
          userData.lastLoginAttempt && 
          userData.lastLoginAttempt.toDate() > fifteenMinutesAgo.toDate()) {
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'Account temporarily locked due to too many failed login attempts. Please try again in 15 minutes.'
        );
      }

      // Verify password
      if (userData.password !== password) {
        // Increment failed login attempts
        const newAttempts = (userData.loginAttempts || 0) + 1;
        transaction.update(userDoc.ref, {
          loginAttempts: newAttempts,
          lastLoginAttempt: now,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid email or password'
        );
      }

      // Reset login attempts on successful login
      const loginData = {
        lastLogin: now,
        totalLogins: (userData.totalLogins || 0) + 1,
        loginAttempts: 0,
        lastLoginAttempt: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Calculate login streak
      if (userData.lastLogin) {
        const lastLoginDate = userData.lastLogin.toDate();
        const today = new Date();
        const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);
        
        // Reset streak if more than 1 day gap
        if (lastLoginDate < yesterday) {
          loginData.loginStreak = 1;
        } else if (lastLoginDate.toDateString() !== today.toDateString()) {
          loginData.loginStreak = (userData.loginStreak || 0) + 1;
        }
      } else {
        loginData.loginStreak = 1;
      }

      transaction.update(userDoc.ref, loginData);

      // Create custom token for Firebase Auth
      const customToken = await admin.auth().createCustomToken(userData.uid);

      return { 
        success: true,
        customToken: customToken,
        user: {
          uid: userData.uid,
          email: userData.email,
          displayName: `${userData.firstName} ${userData.lastName}`,
          course: userData.course,
          year: userData.year,
          section: userData.section,
          loginStreak: loginData.loginStreak,
          totalLogins: loginData.totalLogins
        },
        message: 'Login successful'
      };
    });

  } catch (error) {
    console.error('Error during user login:', error);
    
    // Re-throw HttpsError as-is, wrap other errors
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to login. Please try again later.'
    );
  }
});

/**
 * Cloud Function to resend verification email
 * Enhanced with rate limiting and error handling
 */
exports.resendVerificationEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email } = data;

    if (!email) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email is required'
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    const firestore = admin.firestore();
    
    // Use transaction for atomic operations
    return await firestore.runTransaction(async (transaction) => {
      // Find pending user
      const pendingUserQuery = await transaction.get(
        firestore
          .collection('users')
          .where('email', '==', email.toLowerCase().trim())
          .where('accountStatus', '==', 'pending')
          .limit(1)
      );

      if (pendingUserQuery.empty) {
        throw new functions.https.HttpsError(
          'not-found',
          'No pending registration found for this email'
        );
      }

      const userDoc = pendingUserQuery.docs[0];
      const userData = userDoc.data();

      // Check if user has exceeded resend limit (max 3 resends per hour)
      const now = admin.firestore.Timestamp.now();
      const oneHourAgo = admin.firestore.Timestamp.fromDate(
        new Date(now.toDate().getTime() - 60 * 60 * 1000)
      );

      if (userData.resendCount && userData.resendCount >= 3 && 
          userData.lastResendTime && userData.lastResendTime.toDate() > oneHourAgo.toDate()) {
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'Too many resend attempts. Please try again later.'
        );
      }

      // Generate new verification code
      const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
      const verificationExpiry = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours from now
      );

      // Update user document with new verification data
      const updateData = {
        verificationCode,
        verificationExpiry,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastResendTime: now,
        resendCount: (userData.resendCount || 0) + 1
      };

      transaction.update(userDoc.ref, updateData);

      // Send verification email (outside transaction)
      setImmediate(async () => {
        try {
          const mailOptions = {
            from: functions.config().gmail.user,
            to: email,
            subject: 'Resend: Verify Your PathFit Account',
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px; text-align: center; color: white;">
                  <h1 style="margin: 0; font-size: 28px;">PathFit Verification</h1>
                  <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">New verification code for your account</p>
                </div>
                
                <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-top: 20px;">
                  <h2 style="color: #333; margin-top: 0;">Hello ${userData.firstName}!</h2>
                  <p style="color: #666; font-size: 16px; line-height: 1.6;">
                    Here's your new verification code to complete your PathFit registration:
                  </p>
                  
                  <div style="background: white; border: 2px solid #667eea; border-radius: 10px; padding: 20px; margin: 20px 0; text-align: center;">
                    <h3 style="color: #667eea; margin-top: 0;">Your Verification Code</h3>
                    <div style="font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; margin: 10px 0;">${verificationCode}</div>
                  </div>
                  
                  <p style="color: #666; font-size: 14px;">
                    <strong>Important:</strong> This code expires in 24 hours. Please enter this 6-digit code in the PathFit app to verify your account.
                  </p>
                  
                  <p style="color: #999; font-size: 12px; margin-top: 20px;">
                    If you didn't request this code, you can safely ignore this email.
                  </p>
                </div>
              </div>
            `,
          };

          const transporter = getTransporter();
          await transporter.sendMail(mailOptions);
          console.log(`Verification email resent to: ${email}`);
        } catch (emailError) {
          console.error('Failed to send verification email:', emailError);
          // Don't fail the transaction if email fails
        }
      });

      return { 
        success: true, 
        message: 'Verification email sent successfully',
        email: email
      };
    });

  } catch (error) {
    console.error('Error resending verification email:', error);
    
    // Re-throw HttpsError as-is, wrap other errors
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to resend verification email. Please try again later.'
    );
  }
});

exports.resendVerificationCode = functions.https.onCall(async (data, context) => {
  try {
    // Handle both direct calls and HTTP calls for UID and email
    const uid = data.uid || data.data?.uid || '';
    const email = (data.email || data.data?.email || '').toLowerCase().trim();
    
    if (!uid && !email) {
      throw new functions.https.HttpsError('invalid-argument', 'Either UID or email is required');
    }

    const firestore = admin.firestore();
    let userDoc, userRef;

    if (uid) {
      // If UID is provided, use it directly (more efficient)
      userRef = firestore.collection('users').doc(uid);
      userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found with this UID');
      }
    } else {
      // If only email is provided, find the user document by email field
      const userQuery = await firestore.collection('users').where('email', '==', email).get();
      
      if (userQuery.empty) {
        throw new functions.https.HttpsError('not-found', 'User not found with this email');
      }

      // Get the first (and should be only) user document
      userDoc = userQuery.docs[0];
      userRef = userDoc.ref;
    }

    // Get the email from the document if not provided
    const userEmail = email || userDoc.data().email;

    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    const verificationExpiry = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000)
    );

    // Update the existing user document
    await userRef.update({
      verificationCode,
      verificationExpiry,
      accountStatus: 'pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send code via email
    const mailOptions = {
      from: 'PathFit <mockupfusion23@gmail.com>',
      to: userEmail,
      subject: 'PathFit - Verification Code',
      html: `
        <p>Hello,</p>
        <p>Your PathFit verification code is:</p>
        <h2>${verificationCode}</h2>
        <p>This code expires in 10 minutes.</p>
      `,
    };
    await transporter.sendMail(mailOptions);

    console.log(`✅ Verification code updated for user: ${userDoc.id} (${userEmail})`);
    return { 
      success: true, 
      message: 'Verification code sent successfully.',
      uid: userDoc.id,
      email: userEmail,
      verificationCode: verificationCode
    };
  } catch (error) {
    console.error('❌ resendVerificationCode failed:', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to resend verification code');
  }
});


/**
 * Cloud Function to complete student registration after OTP verification
 * Enhanced with proper transaction support and error handling
 */
exports.completeStudentRegistration = functions.https.onCall(async (data, context) => {
  try {
    const { code, email } = data;

    if (!code || !email) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: code and email are required'
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    const firestore = admin.firestore();
    
    // Use transaction for atomic operations
    return await firestore.runTransaction(async (transaction) => {
      // Find pending user in users collection with verification data
      const pendingUserQuery = await transaction.get(
        firestore
          .collection('users')
          .where('email', '==', email.toLowerCase().trim())
          .where('accountStatus', '==', 'pending')
          .where('verificationCode', '==', code)
          .where('verificationExpiry', '>', admin.firestore.FieldValue.serverTimestamp())
          .limit(1)
      );

      if (pendingUserQuery.empty) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid or expired verification code'
        );
      }

      const userDoc = pendingUserQuery.docs[0];
      const userData = userDoc.data();
      
      // Check if email already exists in active users
      const existingUserQuery = await transaction.get(
        firestore
          .collection('users')
          .where('email', '==', email.toLowerCase().trim())
          .where('accountStatus', '==', 'active')
          .limit(1)
      );
      
      if (!existingUserQuery.empty) {
        throw new functions.https.HttpsError(
          'already-exists',
          'Email already registered with an active account'
        );
      }

      // Create Firebase Auth user with auto-generated UID
      let userRecord;
      try {
        console.log('Creating Firebase Auth user with email:', email.toLowerCase().trim());
        console.log('Display name will be:', `${userData.firstName.trim()} ${userData.lastName.trim()}`);
        
        userRecord = await admin.auth().createUser({
          email: email.toLowerCase().trim(),
          password: userData.password,
          displayName: `${userData.firstName.trim()} ${userData.lastName.trim()}`,
          emailVerified: true
        });
        
        console.log('Firebase Auth user created successfully:', userRecord.uid);
        
      } catch (error) {
        console.error('Firebase Auth creation error details:', error);
        console.error('Error type:', typeof error);
        console.error('Error message:', error.message);
        console.error('Error code:', error.code);
        console.error('Error stack:', error.stack);
        
        // Check for specific PigeonUserDetails error
        if (error.message && error.message.includes('PigeonUserDetails')) {
          console.error('PigeonUserDetails error detected - this is likely a Firebase Auth configuration issue');
          throw new functions.https.HttpsError(
            'internal',
            'Firebase Auth configuration error. Please check your Firebase project settings and ensure Authentication is properly configured.'
          );
        }
        
        if (error.code === 'auth/email-already-exists') {
          throw new functions.https.HttpsError(
            'already-exists',
            'Email already registered'
          );
        } else if (error.code === 'auth/invalid-email') {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid email format'
          );
        } else if (error.code === 'auth/weak-password') {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Password is too weak'
          );
        } else if (error.code === 'auth/configuration-exists') {
          throw new functions.https.HttpsError(
            'internal',
            'Firebase Auth configuration error. Please check your Firebase project settings.'
          );
        }
        
        // For any other unknown errors, provide a generic message
        throw new functions.https.HttpsError(
          'internal',
          'Failed to create user account. Please try again later or contact support.'
        );
      }

      // Prepare user data for new document
      const newUserData = {
        ...userData,
        uid: userRecord.uid,
        email: email.toLowerCase().trim(),
        accountStatus: 'active',
        emailVerified: true,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        lastLogin: null,
        loginStreak: 0,
        totalLogins: 0,
        // Remove sensitive data
        verificationCode: admin.firestore.FieldValue.delete(),
        verificationExpiry: admin.firestore.FieldValue.delete(),
        password: admin.firestore.FieldValue.delete()
      };

      // Create new document with UID as ID
      transaction.set(
        firestore.collection('users').doc(userRecord.uid),
        newUserData
      );
      
      // Delete the old pending document
      transaction.delete(userDoc.ref);

      // Send welcome email (outside transaction)
      setImmediate(async () => {
        try {
          const welcomeMailOptions = {
            from: functions.config().gmail.user,
            to: email,
            subject: 'Welcome to PathFit - Account Created Successfully!',
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px; text-align: center; color: white;">
                  <h1 style="margin: 0; font-size: 28px;">Welcome to PathFit!</h1>
                  <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">Your account has been created successfully</p>
                </div>
                
                <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-top: 20px;">
                  <h2 style="color: #333; margin-top: 0;">Hello ${userData.firstName}!</h2>
                  <p style="color: #666; font-size: 16px; line-height: 1.6;">
                    Welcome to PathFit! Your account has been successfully created and verified. You can now log in to your account and start your fitness journey.
                  </p>
                  
                  <div style="background: white; border: 1px solid #ddd; border-radius: 8px; padding: 20px; margin: 20px 0;">
                    <h3 style="color: #667eea; margin-top: 0;">Account Details:</h3>
                    <p style="margin: 5px 0; color: #666;"><strong>Email:</strong> ${email}</p>
                    <p style="margin: 5px 0; color: #666;"><strong>User ID:</strong> ${userRecord.uid}</p>
                    <p style="margin: 5px 0; color: #666;"><strong>Course:</strong> ${userData.course} ${userData.year}-${userData.section}</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="#" style="background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">Log In Now</a>
                  </div>
                </div>
              </div>
            `,
          };

          const transporter = getTransporter();
          await transporter.sendMail(welcomeMailOptions);
          console.log(`Welcome email sent to: ${email}`);
        } catch (emailError) {
          console.error('Failed to send welcome email:', emailError);
          // Don't fail the transaction if email fails
        }
      });

      // Create custom token for immediate login
      const customToken = await admin.auth().createCustomToken(userRecord.uid);
      
      console.log('Registration completed successfully for user:', userRecord.uid);
      
      // Ensure we return a proper object, not an array
      const response = { 
        success: true, 
        uid: userRecord.uid,
        customToken: customToken,
        message: 'Registration completed successfully!',
        email: email,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };
      
      console.log('Returning response:', response);
      return response;
    });

  } catch (error) {
    console.error('Error completing student registration:', error);
    
    // Re-throw HttpsError as-is, wrap other errors
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to complete registration. Please try again later.'
    );
  }
});

/**
 * Cloud Function to create a pending user and send verification email
 * Enhanced with proper validation and error handling
 * Now includes server-side 6-digit code generation and email sending
 */
exports.createPendingUser = functions.https.onCall(async (data, context) => {
  try {
    const {
      email,
      password,
      firstName,
      middleName,
      lastName,
      age,
      gender,
      course,
      year,
      section,
      height,
      weight,
      BMI,
      BMI_result
    } = data;

    // Validate required fields
    if (!email || !password || !firstName || !lastName) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields for user registration'
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    // Validate password strength
    if (password.length < 6) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Password must be at least 6 characters long'
      );
    }

    // Validate names
    if (firstName.length < 1 || lastName.length < 1) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'First name and last name are required'
      );
    }

    // Validate course and year
    const validYears = ['1', '2', '3', '4'];
    if (!validYears.includes(year.toString())) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid year. Must be 1, 2, 3, or 4'
      );
    }

    const firestore = admin.firestore();
    let verificationCode;
    let userDoc;
    
    // Use transaction for atomic operations
    const result = await firestore.runTransaction(async (transaction) => {
      // Check if email already exists (case-insensitive)
      const existingUserQuery = await transaction.get(
        firestore
          .collection('users')
          .where('email', '==', email.toLowerCase().trim())
          .limit(1)
      );

      if (!existingUserQuery.empty) {
        const existingUser = existingUserQuery.docs[0].data();
        if (existingUser.accountStatus === 'active') {
          throw new functions.https.HttpsError(
            'already-exists',
            'Email already registered with an active account'
          );
        } else if (existingUser.accountStatus === 'pending') {
          throw new functions.https.HttpsError(
            'already-exists',
            'Registration already in progress. Please check your email for verification code'
          );
        }
      }

      // Generate verification code on server side
      verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
      const expiryTime = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 15 * 60 * 1000) // 15 minutes
      );

      // Create user document with all data and pending status
      userDoc = {
        email: email.toLowerCase().trim(),
        firstName: firstName.trim(),
        middleName: middleName ? middleName.trim() : '',
        lastName: lastName.trim(),
        fullName: `${firstName.trim()} ${middleName ? middleName.trim() + ' ' : ''}${lastName.trim()}`.trim(),
        age: age,
        gender: gender,
        course: course,
        year: year,
        section: section,
        height: height,
        weight: weight,
        BMI: BMI,
        BMI_result: BMI_result,
        password: password, // Will be removed after verification
        isStudent: true,
        role: 'student',
        accountStatus: 'pending',
        emailVerified: false,
        verificationCode: verificationCode,
        verificationExpiry: expiryTime,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        profileCompleted: true,
        isActive: false, // Will be activated after verification
        lastLogin: null,
        loginStreak: 0,
        totalLogins: 0,
        loginAttempts: 0,
        lastLoginAttempt: null,
        preferences: {
          theme: 'light',
          notifications: true,
          language: 'en'
        }
      };

      // Use email as document ID for consistency
      transaction.set(
        firestore.collection('users').doc(email.toLowerCase().trim()),
        userDoc
      );

      return {
        email: email.toLowerCase().trim(),
        verificationCode,
        verificationExpiry: expiryTime
      };
    });

    // Send verification email using Nodemailer after successful transaction
    try {
      const mailOptions = {
        from: 'PathFit <mockupfusion23@gmail.com>',
        to: email.toLowerCase().trim(),
        subject: 'PathFit - Your Verification Code',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px; text-align: center; color: white;">
              <h1 style="margin: 0; font-size: 28px;">PathFit</h1>
              <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">Your Fitness Journey Starts Here</p>
            </div>
            
            <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-top: 20px;">
              <h2 style="color: #333; margin-top: 0;">Email Verification</h2>
              <p style="color: #666; font-size: 16px; line-height: 1.6;">
                Thank you for registering with PathFit! Please use the verification code below to complete your registration.
              </p>
              
              <div style="background: white; border: 2px solid #667eea; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
                <p style="color: #666; margin: 0 0 10px 0; font-size: 14px;">Your verification code:</p>
                <div style="font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                  ${verificationCode}
                </div>
              </div>
              
              <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0;">
                <p style="color: #856404; margin: 0; font-size: 14px;">
                  <strong>Important:</strong> This code will expire in 15 minutes for security purposes.
                </p>
              </div>
              
              <p style="color: #666; font-size: 14px; margin-top: 20px;">
                If you didn't request this verification, please ignore this email.
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px; color: #999; font-size: 12px;">
              <p>© 2024 PathFit. All rights reserved.</p>
            </div>
          </div>
        `
      };

      // Send email using Nodemailer
      await transporter.sendMail(mailOptions);
      console.log(`Verification email sent successfully to: ${email}`);
      
      return { 
        success: true, 
        email: email.toLowerCase().trim(),
        message: 'Registration successful! Verification email sent.',
        studentId: email.toLowerCase().trim()
      };
      
    } catch (emailError) {
      console.error('Error sending verification email:', emailError);
      // If email sending fails, we should still return success but log the error
      // The user can request a new verification code later
      return { 
        success: true, 
        email: email.toLowerCase().trim(),
        message: 'Registration successful! However, verification email could not be sent. Please request a new verification code.',
        studentId: email.toLowerCase().trim(),
        emailError: true
      };
    }

  } catch (error) {
    console.error('Error creating pending user:', error);
    
    // Re-throw HttpsError as-is, wrap other errors
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create user registration. Please try again later.'
    );
  }
});

/**
 * Cloud Function to delete a user account and all associated data
 * This function handles comprehensive data cleanup across Firestore collections
 * and removes the user from Firebase Authentication
 */
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  // Security check - user must be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  try {
    // Get the user ID from the authenticated context
    const uid = context.auth.uid;
    
    // Log the deletion request
    console.log(`🔄 [DELETE] Starting account deletion process for UID: ${uid}`);
    
    // Get Firestore and Auth references
    const firestore = admin.firestore();
    const auth = admin.auth();
    
    // Step 1: Get user data before deletion (for cleanup and reference)
    const userDoc = await firestore.collection('users').doc(uid).get();
    let userEmail = null;
    
    if (!userDoc.exists) {
      console.log('⚠️ [DELETE] User document not found in Firestore');
      // Continue with deletion of Auth account
    } else {
      const userData = userDoc.data();
      userEmail = userData.email;
      console.log(`✅ [DELETE] Found user data for cleanup: ${userEmail || 'unknown email'}`);
      
      // Create a blacklist record to prevent re-registration with same email
      if (userEmail) {
        await firestore.collection('deletedAccounts').doc(userEmail.toLowerCase()).set({
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
          formerUid: uid,
        });
        console.log('✅ [DELETE] Created deleted account record to prevent re-registration');
      }
      
      // Step 2: Delete user document from Firestore
      await firestore.collection('users').doc(uid).delete();
      console.log('✅ [DELETE] User document deleted from Firestore');
      
      // Delete BMI data
      await firestore.collection('bmi_records').doc(uid).delete();
      console.log('✅ [DELETE] BMI data deleted from Firestore');
    }
    
    // Step 3: Delete all user-related data (batch operations)
    // Using multiple batches for comprehensive cleanup
    console.log('🔄 [DELETE] Starting comprehensive data cleanup...');
    
    // List of all collections that might contain user data
    const userRelatedCollections = [
      // Core user data
      { collection: 'userAchievements', field: 'userId' },
      { collection: 'studentQuizzes', field: 'userId' },
      { collection: 'studentModules', field: 'userId' },
      
      // BMI data
      { collection: 'bmi_records', field: 'userId' },
      { collection: 'bmi_records', field: 'uid' }, // Alternative field name
      
      // Communication data
      { collection: 'messages', field: 'senderId' },
      { collection: 'messages', field: 'recipientId' },
      { collection: 'conversations', field: `participants.${uid}`, exists: true },
      
      // Assignment data
      { collection: 'assignmentSubmissions', field: 'userId' },
      
      // Any other collections with user references
      { collection: 'enrollments', field: 'userId' },
      { collection: 'userPreferences', field: 'userId' },
      { collection: 'userActivity', field: 'userId' },
      { collection: 'workouts', field: 'userId' },
      { collection: 'goals', field: 'userId' },
      { collection: 'healthMetrics', field: 'userId' },
      { collection: 'achievements', field: 'userId' },
      { collection: 'notifications', field: 'userId' },
    ];
    
    // Process each collection
    for (const collectionInfo of userRelatedCollections) {
      const collectionName = collectionInfo.collection;
      const fieldName = collectionInfo.field;
      const checkExists = collectionInfo.exists || false;
      
      console.log(`🔍 [DELETE] Checking collection: ${collectionName} for field: ${fieldName}`);
      
      let querySnapshot;
      if (checkExists) {
        // For fields that need to check existence (like map fields)
        querySnapshot = await firestore.collection(collectionName)
          .where(fieldName, '!=', null)
          .get();
      } else {
        // For regular equality checks
        querySnapshot = await firestore.collection(collectionName)
          .where(fieldName, '==', uid)
          .get();
      }
      
      if (querySnapshot.empty) {
        console.log(`ℹ️ [DELETE] No documents found in ${collectionName}`);
        continue;
      }
      
      console.log(`🗑️ [DELETE] Deleting ${querySnapshot.size} documents from ${collectionName}`);
      
      // Use batched writes for efficiency (Firestore limits batches to 500 operations)
      let batch = firestore.batch();
      let batchCount = 0;
      let totalDeleted = 0;
      
      for (const doc of querySnapshot.docs) {
        batch.delete(doc.ref);
        batchCount++;
        
        // Commit batch when it reaches the limit
        if (batchCount >= 400) {
          await batch.commit();
          totalDeleted += batchCount;
          console.log(`✅ [DELETE] Deleted ${totalDeleted}/${querySnapshot.size} documents from ${collectionName}`);
          
          // Reset batch
          batch = firestore.batch();
          batchCount = 0;
        }
      }
      
      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
        totalDeleted += batchCount;
        console.log(`✅ [DELETE] Deleted ${totalDeleted}/${querySnapshot.size} documents from ${collectionName}`);
      }
    }
    
    console.log('✅ [DELETE] All user-related data deleted from Firestore');
    
    // Step 4: Delete user from Firebase Authentication
    await auth.deleteUser(uid);
    console.log('✅ [DELETE] User deleted from Firebase Authentication');
    
    console.log('✅ [DELETE] Account deletion completed successfully');
    console.log('🔒 [DELETE] All user data has been permanently removed');
    
    return { success: true, message: 'Account successfully deleted' };
  } catch (error) {
    console.error('❌ [DELETE] Error deleting user account:', error);
    throw new functions.https.HttpsError('internal', `Error deleting account: ${error.message}`);
  }
});

/**
 * Cloud Function to sync Firebase Auth user with Firestore on login
 * Ensures Firestore document exists for authenticated user and returns user data
 */
exports.syncAuthUserWithFirestore = functions.https.onCall(async (data, context) => {
  // Security check - user must be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  try {
    const uid = context.auth.uid;
    const email = context.auth.token.email || '';
    const displayName = context.auth.token.name || '';
    
    console.log(`🔄 [SYNC] Syncing Auth user with Firestore: ${uid}`);
    
    const firestore = admin.firestore();
    const userRef = firestore.collection('users').doc(uid);
    
    // Check if user document exists
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      console.log(`⚠️ [SYNC] User document not found, creating new document for: ${uid}`);
      
      // Create new user document with basic info from Auth
      const newUserDoc = {
        uid: uid,
        email: email,
        displayName: displayName,
        accountStatus: 'active',
        emailVerified: context.auth.token.email_verified || false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        // Default values for new users
        firstName: '',
        lastName: '',
        course: '',
        year: '',
        section: '',
        role: 'student',
        profilePicture: '',
        isNewUser: true
      };
      
      await userRef.set(newUserDoc);
      console.log(`✅ [SYNC] Created new user document for: ${uid}`);
      
      return {
        success: true,
        userData: newUserDoc,
        isNewUser: true,
        message: 'New user document created'
      };
    }
    
    // User document exists, update last login
    const userData = userDoc.data();
    await userRef.update({
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`✅ [SYNC] Successfully synced user: ${uid}`);
    
    return {
      success: true,
      userData: userData,
      isNewUser: false,
      message: 'User synced successfully'
    };
    
  } catch (error) {
    console.error('❌ [SYNC] Error syncing user:', error);
    throw new functions.https.HttpsError('internal', `Error syncing user: ${error.message}`);
  }
});

/**
 * Cloud Function to automatically delete unverified accounts after 10 minutes
 * This function runs periodically to clean up accounts that were created but never verified
 */
exports.autoDeleteUnverifiedAccounts = onSchedule('every 5 minutes', async (event) => {
  console.log('🧹 [AUTO-DELETE] Starting automatic cleanup of unverified accounts');
  
  try {
    const firestore = admin.firestore();
    const auth = admin.auth(); // Initialize auth from admin SDK
    const now = admin.firestore.Timestamp.now();
    const tenMinutesAgo = new admin.firestore.Timestamp(now.seconds - 600, now.nanoseconds); // 10 minutes ago
    
    // Query for unverified accounts created more than 10 minutes ago
    const unverifiedUsersQuery = await firestore.collection('users')
      .where('emailVerified', '==', false)
      .where('createdAt', '<=', tenMinutesAgo)
      .where('accountStatus', '==', 'pending')
      .limit(100) // Process in batches to avoid timeout
      .get();
    
    console.log(`🔍 [AUTO-DELETE] Found ${unverifiedUsersQuery.size} unverified accounts to delete`);
    
    let deletedCount = 0;
    let errorCount = 0;
    
    for (const userDoc of unverifiedUsersQuery.docs) {
      const userData = userDoc.data();
      const uid = userData.uid;
      const email = userData.email;
      
      console.log(`🗑️ [AUTO-DELETE] Processing deletion for user: ${email} (${uid})`);
      
      try {
        // Check if user exists in Firebase Auth
        try {
          await auth.getUser(uid);
          // User exists in Auth, delete from Auth first
          await auth.deleteUser(uid);
          console.log(`✅ [AUTO-DELETE] Deleted user from Firebase Auth: ${uid}`);
        } catch (authError) {
          if (authError.code === 'auth/user-not-found') {
            console.log(`ℹ️ [AUTO-DELETE] User not found in Firebase Auth (may already be deleted): ${uid}`);
          } else {
            console.error(`❌ [AUTO-DELETE] Error deleting from Firebase Auth: ${authError.message}`);
            throw authError;
          }
        }
        
        // Delete user document from Firestore
        await firestore.collection('users').doc(uid).delete();
        console.log(`✅ [AUTO-DELETE] Deleted user document from Firestore: ${uid}`);
        
        // Delete any related data (similar to deleteUserAccount function)
        await deleteUserRelatedData(uid);
        
        // Create a record of the auto-deletion for audit purposes
        await firestore.collection('autoDeletions').add({
          uid: uid,
          email: email,
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
          reason: 'unverified_account_timeout',
          deletionType: 'automatic'
        });
        
        deletedCount++;
        console.log(`✅ [AUTO-DELETE] Successfully auto-deleted unverified account: ${email}`);
        
      } catch (error) {
        errorCount++;
        console.error(`❌ [AUTO-DELETE] Error deleting unverified account ${email}: ${error.message}`);
      }
    }
    
    console.log(`🧹 [AUTO-DELETE] Auto-deletion completed: ${deletedCount} deleted, ${errorCount} errors`);
    return { deletedCount, errorCount };
    
  } catch (error) {
    console.error('❌ [AUTO-DELETE] Error in auto-deletion process:', error);
    throw new Error(`Auto-deletion failed: ${error.message}`);
  }
});

/**
 * Scheduled cleanup: permanently delete quizzes whose availability window has ended.
 *
 * Behavior:
 * - Looks for `courseQuizzes` with `availableUntil` <= now.
 * - Deletes those quiz documents so they no longer appear to any students.
 * - Student attempts and scores remain intact (`quizAttempts`, `studentScores`, `quizzes_records`).
 *
 * Note:
 * - Uses Admin SDK; Firestore security rules are bypassed for this maintenance task.
 * - Runs frequently to catch expirations promptly. Adjust the schedule as desired.
 */
exports.autoDeleteExpiredQuizzes = onSchedule('every 2 minutes', async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  try {
    const snapshot = await db
      .collection('courseQuizzes')
      .where('availableUntil', '<=', now)
      .get();

    if (snapshot.empty) {
      console.log('[autoDeleteExpiredQuizzes] No expired quizzes to delete.');
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`[autoDeleteExpiredQuizzes] Deleted ${snapshot.size} expired quizzes.`);
  } catch (error) {
    console.error('[autoDeleteExpiredQuizzes] Failed to delete expired quizzes:', error);
  }
});

/**
 * Helper function to delete all user-related data from various collections
 * This is reused from the deleteUserAccount function logic
 */
async function deleteUserRelatedData(uid) {
  const firestore = admin.firestore();
  
  // List of all collections that might contain user data
  const userRelatedCollections = [
    { collection: 'userAchievements', field: 'userId' },
    { collection: 'studentQuizzes', field: 'studentId' },
    { collection: 'studentModules', field: 'studentId' },
    { collection: 'bmi_records', field: 'userId' },
    { collection: 'bmi_records', field: 'uid' },
    { collection: 'messages', field: 'senderId' },
    { collection: 'messages', field: 'recipientId' },
    { collection: 'assignmentSubmissions', field: 'studentId' },
    { collection: 'enrollments', field: 'userId' },
    { collection: 'userPreferences', field: 'userId' },
    { collection: 'userActivity', field: 'userId' },
    { collection: 'workouts', field: 'userId' },
    { collection: 'goals', field: 'userId' },
    { collection: 'healthMetrics', field: 'userId' },
    { collection: 'achievements', field: 'userId' },
    { collection: 'notifications', field: 'userId' },
    { collection: 'pendingUsers', field: 'uid' },
    { collection: 'verificationCodes', field: 'email' }
  ];
  
  // Process each collection
  for (const collectionInfo of userRelatedCollections) {
    const { collection, field } = collectionInfo;
    
    try {
      const querySnapshot = await firestore.collection(collection)
        .where(field, '==', uid)
        .get();
      
      if (querySnapshot.empty) {
        continue;
      }
      
      console.log(`🗑️ [AUTO-DELETE] Deleting ${querySnapshot.size} documents from ${collection}`);
      
      // Use batched writes for efficiency
      let batch = firestore.batch();
      let batchCount = 0;
      let totalDeleted = 0;
      
      for (const doc of querySnapshot.docs) {
        batch.delete(doc.ref);
        batchCount++;
        
        // Commit batch when it reaches the limit
        if (batchCount >= 400) {
          await batch.commit();
          totalDeleted += batchCount;
          batch = firestore.batch();
          batchCount = 0;
        }
      }
      
      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
        totalDeleted += batchCount;
      }
      
      console.log(`✅ [AUTO-DELETE] Deleted ${totalDeleted} documents from ${collection}`);
      
    } catch (error) {
      console.error(`❌ [AUTO-DELETE] Error deleting from ${collection}: ${error.message}`);
    }
  }
}

/**
 * Cloud Function to create/update Firestore user document after Auth registration
 * Used for manual registration flow without OTP
 */
exports.createUserInFirestore = functions.https.onCall(async (data, context) => {
  // Security check - user must be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  try {
    const uid = context.auth.uid;
    const { firstName, lastName, course, year, section } = data;
    
    console.log(`📝 [CREATE] Creating user document for: ${uid}`);
    
    // Validate required fields
    if (!firstName || !lastName || !course || !year || !section) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: firstName, lastName, course, year, section'
      );
    }
    
    const firestore = admin.firestore();
    const userRef = firestore.collection('users').doc(uid);
    
    // Check if email already exists (UID is unique identifier now)
    
    const userDoc = {
      uid: uid,
      email: context.auth.token.email || '',
      firstName: firstName,
      lastName: lastName,
      displayName: `${firstName} ${lastName}`,
      course: course,
      year: year,
      section: section,
      accountStatus: 'active',
      emailVerified: context.auth.token.email_verified || false,
      role: 'student',
      profilePicture: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isNewUser: false
    };
    
    await userRef.set(userDoc, { merge: true });
    
    console.log(`✅ [CREATE] User document created for: ${uid}`);
    
    return {
      success: true,
      userData: userDoc,
      message: 'User document created successfully'
    };
    
  } catch (error) {
    console.error('❌ [CREATE] Error creating user document:', error);
    throw new functions.https.HttpsError('internal', `Error creating user: ${error.message}`);
  }
});