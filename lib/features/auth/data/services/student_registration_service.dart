import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/user.dart';
import '../../../../core/utils/name_formatter.dart';

class StudentRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Unified users collection - no more separate pending_students or verification_codes
  static const String _usersCollection = 'users';

  /// Create pending user with all data stored in users collection
  Future<Map<String, dynamic>> createPendingStudentAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String middleName,
    required int age,
    required String gender,
    required String course,
    required String year,
    required String section,
    double? bmi,
    double? height,
    double? weight,
    String? bmiResult,
  }) async {
    try {
      // Validate required parameters
      if (email.isEmpty) {
        return {
          'success': false,
          'error': 'Email is required',
        };
      }

      if (password.isEmpty || password.length < 6) {
        return {
          'success': false,
          'error': 'Password must be at least 6 characters',
        };
      }

      if (age <= 0 || age > 120) {
        return {
          'success': false,
          'error': 'Please enter a valid age',
        };
      }

      // Only validate height if provided
      if (height != null && (height <= 0 || height > 300)) {
        return {
          'success': false,
          'error': 'Please enter a valid height',
        };
      }

      // Only validate weight if provided
      if (weight != null && (weight <= 0 || weight > 500)) {
        return {
          'success': false,
          'error': 'Please enter a valid weight',
        };
      }

      // Only validate BMI if provided
      if (bmi != null && (bmi <= 0 || bmi > 100)) {
        return {
          'success': false,
          'error': 'Please calculate a valid BMI',
        };
      }

      final normalizedEmail = email.toLowerCase().trim();

      // Check if email already exists
      final emailExists = await checkEmailExists(normalizedEmail);

      if (emailExists) {
        throw Exception('Email address is already registered');
      }

      // Create Firebase Auth user first to get the UID
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } catch (e) {
        return {
          'success': false,
          'error': 'Failed to create Firebase Auth user: ${e.toString()}',
        };
      }

      final userId = userCredential.user!.uid;

      // Create pending user in unified users collection with proper null handling
      final pendingUserData = <String, dynamic>{
        'uid': userId, // Store Firebase Auth UID
        'email': normalizedEmail,
        'isStudent': true,
        'role': 'student',
        'accountStatus': 'pending',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profileCompleted': true,
        'isActive': false,
        'lastLogin': null,
        'loginStreak': 0,
        'totalLogins': 0,
        'preferences': {
          'theme': 'light',
          'notifications': true,
          'language': 'en'
        }
      };
      
      // Only add non-null values with proper string handling
      if (firstName.isNotEmpty) {
        pendingUserData['firstName'] = firstName.trim();
      }
      
      if (lastName.isNotEmpty) {
        pendingUserData['lastName'] = lastName.trim();
      }
      
      if (middleName.isNotEmpty) {
        pendingUserData['middleName'] = middleName.trim();
      }
      
      // Build fullName with formatted middle name (initials only for display)
      final displayName = NameFormatter.buildDisplayName(
        firstName: firstName.trim(),
        middleName: middleName.trim(),
        lastName: lastName.trim(),
      );
      
      if (displayName.isNotEmpty) {
        pendingUserData['fullName'] = displayName;
      }
      
      if (age > 0) pendingUserData['age'] = age;
      if (gender.isNotEmpty && gender != 'Select gender') pendingUserData['gender'] = gender;
      if (course.isNotEmpty && course != 'Select course') pendingUserData['course'] = course;
      if (year.isNotEmpty && year != 'Select year') pendingUserData['year'] = year;
      if (section.isNotEmpty) pendingUserData['section'] = section;
      if (height != null && height > 0) pendingUserData['height'] = height;
      if (weight != null && weight > 0) pendingUserData['weight'] = weight;
      if (bmi != null && bmi > 0) pendingUserData['bmi'] = bmi;
      if (bmiResult != null && bmiResult.isNotEmpty && bmiResult != 'Your BMI will appear here') {
        pendingUserData['bmiResult'] = bmiResult;
      }

      // Store in users collection with Firebase Auth UID as document ID
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(pendingUserData);

      // Use new Nodemailer-based OTP function instead of old verification code system
      try {
        final result = await FirebaseFunctions.instance
            .httpsCallable('sendRegistrationOtp')
            .call({
          'email': normalizedEmail,
          'firstName': firstName,
          'lastName': lastName,
        });

        if (result.data['success'] == true) {
          print('✅ Registration OTP sent successfully to $normalizedEmail');
          // Store the OTP and expiry in the user document for verification
          await _firestore.collection(_usersCollection).doc(userId).update({
            'verificationCode': result.data['otp'], // Store for verification
            'verificationExpiry': DateTime.fromMillisecondsSinceEpoch(result.data['expiry']),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception('Failed to send OTP: ${result.data['message']}');
        }
      } catch (e) {
        print('❌ Error sending registration OTP: $e');
        throw Exception('Failed to send registration OTP: ${e.toString()}');
      }

      return {
        'success': true,
        'uid': userId,
        'studentId': userId, // Adding studentId for backward compatibility
        'message': 'Verification email sent. Please check your email to complete registration.',
      };
    } catch (e) {
      print('Error creating pending user: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Verify email with code using direct Firestore approach
  Future<Map<String, dynamic>> verifyStudentEmailWithCode({
    required String email,
    required String code,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Find user by email and pending status
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .where('accountStatus', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {
          'success': false,
          'error': 'No pending user found with this email',
        };
      }

      final userDoc = query.docs.first;
      final userData = userDoc.data();

      // Check if code matches and hasn't expired
      final storedCode = userData['verificationCode']?.toString();
      final expiry = userData['verificationExpiry']?.toDate();

      if (storedCode == null || expiry == null) {
        return {
          'success': false,
          'error': 'No verification code found',
        };
      }

      if (storedCode != code) {
        return {
          'success': false,
          'error': 'Invalid verification code',
        };
      }

      if (DateTime.now().isAfter(expiry)) {
        return {
          'success': false,
          'error': 'Verification code has expired',
        };
      }

      // Update user document to mark as verified
      await userDoc.reference.update({
        'accountStatus': 'active',
        'emailVerified': true,
        'verificationCode': FieldValue.delete(),
        'verificationExpiry': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'uid': userDoc.id, // Return Firebase Auth UID
        'message': 'Email verified successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to verify email: ${e.toString()}',
      };
    }
  }

  /// Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final query = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get pending user data
  Future<Map<String, dynamic>?> getPendingUser(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final query = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .where('accountStatus', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting pending user: $e');
      return null;
    }
  }

  /// Get student data by email
  Future<Map<String, dynamic>?> getStudentByEmail(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final query = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return query.docs.first.data();
    } catch (e) {
      return null;
    }
  }

  /// Resend verification email using new server-side function
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Use the new resendVerificationCode function that handles everything server-side
      final result = await FirebaseFunctions.instance
          .httpsCallable('resendVerificationCode')
          .call({
        'email': normalizedEmail,
      });

      if (result.data['success'] == true) {
        print('✅ Verification code resent successfully to $normalizedEmail');
        return {
          'success': true,
          'message': 'Verification email resent successfully',
        };
      } else {
        throw Exception('Failed to resend verification code: ${result.data['message']}');
      }
    } catch (e) {
      print('❌ Error resending verification email: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }



  /// Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    return !(await checkEmailExists(email));
  }

  /// Clean up expired pending users (maintenance)
  Future<void> cleanupExpiredPendingUsers() async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('accountStatus', isEqualTo: 'pending')
          .where('verificationExpiry', isLessThan: FieldValue.serverTimestamp())
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error cleaning up expired users: $e');
    }
  }

  /// Legacy: Verify student email using JWT token (deprecated)
  Future<Map<String, dynamic>> verifyStudentEmail(String token) async {
    return {
      'success': false,
      'error': 'JWT verification is deprecated. Please use verification codes.',
    };
  }

  /// Create pending student from signup data (compatibility method)
  Future<Map<String, dynamic>> createPendingStudent(Map<String, dynamic> studentData) async {
    return await createPendingStudentAccount(
      email: studentData['email'],
      password: studentData['password'],
      firstName: studentData['firstName'],
      lastName: studentData['lastName'],
      middleName: studentData['middleName'] ?? '',
      age: studentData['age'],
      gender: studentData['gender'],
      course: studentData['course'],
      year: studentData['year'],
      section: studentData['section'],
      bmi: studentData['bmi'],
      height: studentData['height'],
      weight: studentData['weight'],
      bmiResult: studentData['bmiResult'],
    );
  }
}