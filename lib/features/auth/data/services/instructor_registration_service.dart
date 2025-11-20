import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/utils/name_formatter.dart';

class InstructorRegistrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _usersCollection = 'users';

  /// Create a pending instructor account that requires email verification
  Future<Map<String, dynamic>> createPendingInstructorAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String middleName,
    required int age,
    required String gender,
    List<String>? assignedYearSectionCourses,
    String? department,
    String? position,
    String? employeeId,
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

      final normalizedEmail = email.toLowerCase().trim();

      // Check if email already exists
      final emailExists = await _checkEmailExists(normalizedEmail);

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

      // Create pending user in unified users collection
      final pendingUserData = <String, dynamic>{
        'uid': userId, // Store Firebase Auth UID
        'email': normalizedEmail,
        'isStudent': false,
        'role': 'instructor',
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
      // removed legacy assignedCourses field
      if (assignedYearSectionCourses != null && assignedYearSectionCourses.isNotEmpty) {
        pendingUserData['assignedYearSectionCourses'] = assignedYearSectionCourses;
      }
      if (department != null && department.isNotEmpty && department != 'Select department') pendingUserData['department'] = department;
      if (position != null && position.isNotEmpty && position != 'Select position') pendingUserData['position'] = position;
      if (employeeId != null && employeeId.isNotEmpty) pendingUserData['employeeId'] = employeeId;

      // Legacy year-level/section fields removed; use assignedYearSectionCourses exclusively.

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
        'instructorId': userId, // Adding instructorId for consistency
        'message': 'Verification email sent. Please check your email to complete registration.',
      };
    } catch (e) {
      print('Error creating pending instructor: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if email already exists in the system
  Future<bool> _checkEmailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  /// Verify instructor email with code using direct Firestore approach
  Future<Map<String, dynamic>> verifyInstructorEmailWithCode({
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
        'message': 'Email verified successfully',
        'instructorId': userDoc.id, // Return Firebase Auth UID
      };
    } catch (e) {
      print('Error verifying instructor email: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}