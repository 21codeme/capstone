import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/retry_helper.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register a new user with enhanced security and validation
  Future<UserCredential?> registerUser({
    required String email,
    required String password,
    required String displayName,
    required bool isStudent, // Changed from role to boolean isStudent
    String? lastName,
    int? age,
    String? gender,
    String? course,
    String? year,
    String? section,
  }) async {
    UserCredential? userCredential;
    
    try {
      // Normalize email
      final normalizedEmail = email.toLowerCase().trim();
      print('ðŸš€ [REGISTRATION] Starting user registration for: $normalizedEmail');
      
      // Check if user already exists
      final userExists = await this.userExists(normalizedEmail);
      if (userExists) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        );
      }
      
      // Validate password format
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters',
        );
      }
      
      // Enforce isStudent based on the registration path
      // This ensures the isStudent value is correctly set regardless of what was passed
      // Get the current route to determine which signup screen was used
      final currentRoute = StackTrace.current.toString();
      
      // Override the isStudent parameter based on which signup screen was used
      if (currentRoute.contains('instructor_signup_screen.dart')) {
        print('ðŸ“ Enforcing instructor type (isStudent=false) based on registration path');
        isStudent = false;
      } else if (currentRoute.contains('student_signup_screen.dart')) {
        print('ðŸ“ Enforcing student type (isStudent=true) based on registration path');
        isStudent = true;
      } else {
        print('ðŸ“ Using provided isStudent value: $isStudent');
      }
      
      // Step 1: Create Firebase Auth account
      print('ðŸ” Creating Firebase Auth account...');
      
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to create Firebase Auth account');
      }
      
      final userId = userCredential.user!.uid;
      print('âœ… Firebase Auth account created successfully: $userId');
      
      // Step 2: Update display name in Firebase Auth
      try {
        await userCredential.user!.updateDisplayName(displayName);
        print('âœ… Display name updated in Firebase Auth');
      } catch (e) {
        print('âš ï¸ Warning: Could not update display name in Firebase Auth: $e');
      }
      
      // Step 3: Prepare user data for Firestore
      final userData = <String, dynamic>{
        'uid': userId,
        'email': normalizedEmail,
        'displayName': displayName.trim(),
        'isStudent': isStudent,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'profilePicture': '',
        'phoneNumber': '',
        'accountStatus': 'active', // New field for account status
        'emailVerified': false,
      };
      
      // Add optional fields
      if (lastName != null && lastName.trim().isNotEmpty) {
        userData['lastName'] = lastName.trim();
      }
      if (age != null && age > 0) {
        userData['age'] = age;
      }
      if (gender != null && gender.trim().isNotEmpty) {
        userData['gender'] = gender.trim();
      }

      print('âœ… User data prepared, saving to Firestore...');

      // Step 4: Save user data to Firestore using student ID as document ID
      try {
        // Ensure userData is properly formatted
        final sanitizedUserData = <String, dynamic>{};
        for (final entry in userData.entries) {
          if (entry.value != null) {
            sanitizedUserData[entry.key] = entry.value;
          }
        }
        
        print('ðŸ“„ Sanitized user data: $sanitizedUserData');
        // Use Firebase Auth UID as document ID for proper sync
        final uid = userCredential.user!.uid;
        await _firestore.collection('users').doc(uid).set(sanitizedUserData);
        print('âœ… User data saved to Firestore successfully with UID: $uid');
      } catch (firestoreError) {
        print('âŒ Error saving to Firestore: $firestoreError');
        print('âŒ Firestore error type: ${firestoreError.runtimeType}');
        
        // Throw error for any Firestore save failure
        throw Exception('Failed to save user data to Firestore: $firestoreError');
      }
      
      print('ðŸŽ‰ User registration completed successfully!');
      return userCredential;

    } on FirebaseAuthException catch (e) {
      print('âŒ Firebase Auth Error during registration: ${e.code} - ${e.message}');
      
      // Cleanup: Delete Firebase Auth account if it was created
      if (userCredential != null && userCredential.user != null) {
        try {
          print('ðŸ§¹ Cleaning up: Deleting Firebase Auth account...');
          await userCredential.user!.delete();
          print('âœ… Firebase Auth account deleted successfully');
        } catch (deleteError) {
          print('âŒ Error deleting Firebase Auth account: $deleteError');
        }
      }
      
      rethrow;
    } catch (e) {
      print('âŒ Error during registration: $e');
      print('âŒ Error type: ${e.runtimeType}');
      print('âŒ Error details: ${e.toString()}');
      
      // Cleanup: Delete Firebase Auth account if it was created
      if (userCredential != null && userCredential.user != null) {
        try {
          print('ðŸ§¹ Cleaning up: Deleting Firebase Auth account...');
          await userCredential.user!.delete();
          print('âœ… Firebase Auth account deleted successfully');
        } catch (deleteError) {
          print('âŒ Error deleting Firebase Auth account: $deleteError');
        }
      }
      
      rethrow;
    }
  }

  /// Get the correct document ID for a user
  /// Uses Firebase Auth UID as document ID for proper sync
  Future<String?> getDocumentIdForUser(String uid, String email) async {
    try {
      // Always use Firebase Auth UID as document ID for consistency
      return uid;
    } catch (e) {
      print('âŒ Error getting document ID: $e');
      return uid;
    }
  }

  // Sign in user with account status check and deleted account verification
  // Sign in user with email and password using student ID lookups
  Future<UserCredential> signInUser({
    required String email,
    required String password,
    int maxRetries = 3,
  }) async {
    try {
      print('ðŸ” [AUTH] Starting sign in process for: $email');
      
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Sign in failed: User credential is null');
      }

      // Use Firebase Auth UID for document lookup
      final uid = userCredential.user!.uid;

      // Check if user document exists in Firestore using UID
      try {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          // Check account status
          final accountStatus = userData['accountStatus'] as String?;
          if (accountStatus == 'pending') {
            // Sign out the user immediately
            await _auth.signOut();
            throw Exception('Account not verified. Please check your email for verification code.');
          }
          
          if (accountStatus == 'inactive') {
            // Sign out the user immediately
            await _auth.signOut();
            throw Exception('Your account is inactive. Please contact support.');
          }
          
          if (accountStatus != 'active') {
            // Sign out the user immediately
            await _auth.signOut();
            throw Exception('Account is not active. Please contact support.');
          }
          
          // Update last login time using UID
          await _firestore.collection('users').doc(uid).update({
            'lastLogin': Timestamp.now(),
          });
          print('âœ… User document found and last login updated for UID: $uid');
        } else {
          // Create user document if it doesn't exist (for existing auth users)
          await _firestore.collection('users').doc(uid).set({
            'uid': uid,
            'email': email,
            'accountStatus': 'active',
            'emailVerified': userCredential.user!.emailVerified,
            'createdAt': Timestamp.now(),
            'lastLogin': Timestamp.now(),
            'role': 'student',
            'isNewUser': true,
          });
          print('âœ… Created new user document for UID: $uid');
        }
      } catch (firestoreError) {
        print('âš ï¸ Error handling Firestore operations: $firestoreError');
        throw Exception('Error accessing user data: $firestoreError');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('âŒ Firebase Auth Error during sign in: ${e.code} - ${e.message}');
      
      // Provide more user-friendly error messages
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email address.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled. Please contact support.');
      } else {
        throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Secure sign out that terminates all active connections
  Future<void> signOut() async {
    try {
      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Update user's online status in Firestore if needed
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        try {
          await _firestore.collection('users').doc(currentUser.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
            'isOnline': false
          });
        } catch (e) {
          print('âš ï¸ Could not update user online status: $e');
        }
      }
      
      print('âœ… User signed out successfully');
    } catch (e) {
      print('âŒ Error signing out: $e');
      throw Exception('Sign out failed: $e');
    }
  }
  
  // Clear all persistent data and cached credentials
  Future<void> clearPersistentData() async {
    try {
      // Force token refresh to invalidate existing tokens
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        try {
          await currentUser.getIdToken(true);
        } catch (e) {
          print('âš ï¸ Error refreshing token: $e');
        }
      }
      
      // Clear shared preferences data
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Clear all auth-related preferences
        await prefs.remove('user_uid');
        await prefs.remove('user_email');
        await prefs.remove('last_login');
        await prefs.remove('auth_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_role');
        await prefs.remove('user_settings');
        
        // For complete security, you can clear all preferences
        // Uncomment the line below to clear everything
        // await prefs.clear();
        
        print('âœ… Shared preferences cleared successfully');
      } catch (e) {
        print('âš ï¸ Error clearing shared preferences: $e');
      }
      
      // Sign out again to ensure token invalidation
      try {
        await _auth.signOut();
      } catch (e) {
        print('âš ï¸ Secondary sign out during cleanup: $e');
      }
      
      print('âœ… Persistent data cleared successfully');
    } catch (e) {
      print('âŒ Error clearing persistent data: $e');
      throw Exception('Failed to clear persistent data: $e');
    }
  }

  // Get user data from Firestore with enhanced error handling
  // Get user data from Firestore using UID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      print('ðŸ” Getting user data for UID: $uid');
      
      // Use UID for direct document lookup
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        print('âœ… User data retrieved successfully by UID: ${data?['email']}');
        
        // Ensure we return a Map, not a List
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          Map<dynamic, dynamic> dynamicMap = data as Map<dynamic, dynamic>;
          final convertedData = Map<String, dynamic>.fromEntries(
            dynamicMap.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
          );
          print('âœ… Successfully converted data to Map<String, dynamic>');
          return convertedData;
        } else {
          print('âŒ Cannot convert data to Map: ${data.runtimeType}');
          return null;
        }
      } else {
        print('âš ï¸ User document not found for UID: $uid');
        return null;
      }
    } catch (e) {
      print('âŒ Error getting user data: $e');
      return null;
    }
  }

  // Get user isStudent status from Firestore using UID
  Future<bool> getUserIsStudent(String uid) async {
    try {
      print('ðŸ” Getting user isStudent status for UID: $uid');
      
      // Use UID for direct document lookup
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        
        // First check if the new isStudent field exists
        if (data?.containsKey('isStudent') == true) {
          final isStudent = data?['isStudent'] as bool?;
          if (isStudent != null) {
            print('âœ… User isStudent status retrieved by UID: $isStudent');
            return isStudent;
          }
        }
        
        // If isStudent doesn't exist, check for legacy role field
        final role = data?['role'] as String?;
        if (role != null && role.isNotEmpty) {
          // Convert legacy role to isStudent boolean
          final isStudent = role == 'student';
          print('âœ… Converted legacy role ($role) to isStudent: $isStudent');
          
          // Update the document with the new isStudent field
          try {
            await _firestore.collection('users').doc(uid).update({
              'isStudent': isStudent,
            });
            print('âœ… Updated user document with isStudent: $isStudent');
          } catch (updateError) {
            print('âš ï¸ Could not update user document: $updateError');
          }
          
          return isStudent;
        }
        
        print('âœ… User found but no role specified, defaulting to student');
        return true; // Default to student if no role specified
      } else {
        print('âš ï¸ User document not found for UID: $uid');
      }
      
      print('âš ï¸ User document not found, using default isStudent: true');
      return true; // Default to student
    } catch (e) {
      print('âŒ Error getting user isStudent status: $e');
      return true; // Default to student on error
    }
  }
  
  // Legacy method for backward compatibility
  Future<String?> getUserRole(String uid) async {
    final isStudent = await getUserIsStudent(uid);
    return isStudent ? 'student' : 'instructor';
  }

  // Check if user exists with improved method
  Future<bool> userExists(String email) async {
    try {
      // Normalize email to lowercase and trim
      final normalizedEmail = email.toLowerCase().trim();
      print('ðŸ” Checking if user exists for email: $normalizedEmail');
      
      // Check if user exists using a workaround since fetchSignInMethodsForEmail is removed in Firebase Auth 6.0.2
      try {
        // Try to sign in with an invalid password to check if the email exists
        // This will throw an error, but the error code will tell us if the email exists
        await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: 'invalid-password-for-checking-only',
        );
        // If we get here, the user somehow signed in with our invalid password (shouldn't happen)
        return true;
      } on FirebaseAuthException catch (authError) {
        // If error code is 'wrong-password', the email exists but password is wrong
        // If error code is 'user-not-found', the email doesn't exist
        final exists = authError.code == 'wrong-password';
        
        print(exists 
          ? 'âœ… User exists in Firebase Auth (wrong-password error)' 
          : 'âœ… User does not exist in Firebase Auth (${authError.code})');
        
        return exists;
      }
      
    } on FirebaseAuthException catch (e) {
      print('âŒ Firebase Auth Error checking if user exists: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('âŒ Error checking if user exists: $e');
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update user profile with validation using UID
  Future<bool> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('ðŸ”„ [PROFILE] Updating user profile for UID: $uid');
      
      // Validate critical fields if they're being updated
      if (data.containsKey('role') && 
          data['role'] != 'student' && 
          data['role'] != 'instructor') {
        throw Exception('Invalid role: must be either student or instructor');
      }
      
      if (data.containsKey('accountStatus') && 
          data['accountStatus'] != 'active' && 
          data['accountStatus'] != 'inactive') {
        throw Exception('Invalid account status: must be either active or inactive');
      }
      
      // Update Firestore document using UID
      await _firestore.collection('users').doc(uid).update(data);
      print('âœ… [PROFILE] User profile updated successfully for UID: $uid');
      return true;
      
    } catch (e) {
      print('âŒ [PROFILE] Error updating user profile: $e');
      return false;
    }
  }

  // Update user data in Firestore (alias for updateUserProfile)
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      return updateUserProfile(uid: uid, data: data);
    } catch (e) {
      print('âŒ Error in updateUserData: $e');
      return false;
    }
  }

  // Note: getStudentIdByUid method removed - using UID directly now
  
  // Update account status (activate/deactivate account)
  Future<bool> updateAccountStatus(String uid, bool isActive) async {
    try {
      print('ðŸ”„ [ACCOUNT] Updating account status for UID: $uid to ${isActive ? 'active' : 'inactive'}');
      
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': isActive ? 'active' : 'inactive',
      });
      
      print('âœ… [ACCOUNT] Account status updated successfully');
      return true;
    } catch (e) {
      print('âŒ [ACCOUNT] Error updating account status: $e');
      return false;
    }
  }
  
  // Delete account functionality removed
  
  // Get all users with a specific role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      print('ðŸ” Getting users with role: $role');
      
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      
      final users = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      
      print('âœ… Found ${users.length} users with role: $role');
      return users;
    } catch (e) {
      print('âŒ Error getting users by role: $e');
      return [];
    }
  }
  
  // This method is already defined above, so we're removing the duplicate
  
  // Fetch sign-in methods for email (workaround since fetchSignInMethodsForEmail is removed in Firebase Auth 6.0.2)
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      print('ðŸ” Checking sign-in methods for email: $email');
      
      // First check if email exists in Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        print('âœ… Email exists (found in Firestore)');
        return ['password']; // Indicate the user exists
      }
      
      // Try to sign in with an invalid password to check if the email exists
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: 'invalid-password-for-checking-only',
        );
        // If we get here, the user somehow signed in with our invalid password (shouldn't happen)
        return ['password'];
      } on FirebaseAuthException catch (authError) {
        // If error code is 'wrong-password', the email exists but password is wrong
        if (authError.code == 'wrong-password') {
          print('âœ… Email exists (wrong-password error)');
          return ['password']; // Indicate the user exists with password auth
        } else if (authError.code == 'invalid-credential' || authError.code == 'user-not-found') {
          // Now we're more confident the user doesn't exist
          print('âœ… Email does not exist (${authError.code})');
          return [];
        } else {
          // For other error codes, we can't be sure, so check Firestore
          print('âš ï¸ Uncertain auth error: ${authError.code}');
          return []; // Default to not existing
        }
      }
    } catch (e) {
      print('âŒ Error checking email existence: $e');
      return [];
    }
  }
  
  // Delete account functionality removed
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('ðŸ” Signing in user with email: $email');
      
      final userCredential = await RetryHelper.executeWithRetry<UserCredential>(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
        maxRetries: 3,
        initialDelayMs: 300,
        maxDelayMs: 3000,
        shouldRetry: (error) {
          // Custom retry logic for sign-in specific errors
          if (error is FirebaseAuthException) {
            // Retry network-related errors
            if (error.code == 'network-request-failed') return true;
            // Retry if we get the PigeonUserDetails error
            if (error.toString().contains('PigeonUserDetails')) return true;
            // Don't retry authentication errors
            if (error.code == 'wrong-password' || 
                error.code == 'user-not-found' || 
                error.code == 'user-disabled' ||
                error.code == 'invalid-credential') {
              return false;
            }
            // Don't retry App Check related errors
            if (error.code == 'app-check-failed' ||
                error.toString().contains('App Check')) {
              return false;
            }
          }
          // Use default retry logic for other errors
          return RetryHelper.defaultShouldRetry(error);
        },
      );
      print('âœ… User signed in successfully: ${userCredential.user!.uid}');
      return userCredential;
    } catch (e) {
      print('âŒ Error signing in user: $e');
      rethrow;
    }
  }
  
  // Update user document
  Future<bool> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      print('ðŸ“ Updating user document for UID: $uid');
      await _firestore.collection('users').doc(uid).update(data);
      print('âœ… User document updated successfully');
      return true;
    } catch (e) {
      print('âŒ Error updating user document: $e');
      return false;
    }
  }
  
  // Create user document with student ID as document ID
  Future<bool> createUserDocument(
    String uid,
    String email,
    String displayName,
    bool isStudent, {
    String? firstName,
    String? middleName,
    String? lastName,
    int? age,
    String? gender,
    String? course,
    String? year,
    String? section,
    double? bmi,
  }) async {
    try {
      print('ðŸ“ Creating user document for UID: $uid');
      
      // Create a map with non-null values only
      final userData = <String, dynamic>{
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'isStudent': isStudent,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'accountStatus': 'active',
      };
      
      // Only add optional fields if they are not null
      if (firstName != null) userData['firstName'] = firstName;
      if (middleName != null) userData['middleName'] = middleName;
      if (lastName != null) userData['lastName'] = lastName;
      if (age != null) userData['age'] = age;
      if (gender != null) userData['gender'] = gender;
      if (course != null) userData['course'] = course;
      if (year != null) userData['year'] = year;
      if (section != null) userData['section'] = section;
      if (bmi != null) userData['bmi'] = bmi;
      
      await _firestore.collection('users').doc(uid).set(userData);
      print('âœ… User document created successfully with UID: $uid');
      return true;
    } catch (e) {
      print('âŒ Error creating user document: $e');
      return false;
    }
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('ðŸ“§ Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('âœ… Password reset email sent successfully');
    } catch (e) {
      print('âŒ Error sending password reset email: $e');
      rethrow;
    }
  }

  // Fetch sign-in methods for email
  Future<List<String>> fetchSignInMethods(String email) async {
    try {
      print('ðŸ” Fetching sign-in methods for email: $email');
      // Use our workaround method instead of the removed fetchSignInMethodsForEmail
      final methods = await fetchSignInMethodsForEmail(email.trim());
      print('âœ… Found sign-in methods: $methods');
      return methods;
    } catch (e) {
      print('âŒ Error fetching sign-in methods: $e');
      rethrow;
    }
  }


  
  // Update user display name
  Future<bool> updateUserDisplayName({required User user, required String displayName}) async {
    try {
      print('ðŸ‘¤ Updating user display name for UID: ${user.uid}');
      await user.updateDisplayName(displayName);
      print('âœ… User display name updated successfully');
      return true;
    } catch (e) {
      print('âŒ Error updating user display name: $e');
      return false;
    }
  }
  
  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      print('ðŸ‘¤ Creating user with email: $email');
      final userCredential = await RetryHelper.executeWithRetry<UserCredential>(
        () => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
        maxRetries: 3,
        initialDelayMs: 300,
        maxDelayMs: 3000,
        shouldRetry: (error) {
          // Custom retry logic for registration specific errors
          if (error is FirebaseAuthException) {
            // Retry network-related errors
            if (error.code == 'network-request-failed') return true;
            // Don't retry validation errors
            if (error.code == 'email-already-in-use' || 
                error.code == 'invalid-email' || 
                error.code == 'weak-password') {
              return false;
            }
          }
          // Use default retry logic for other errors
          return RetryHelper.defaultShouldRetry(error);
        },
      );
      print('âœ… User created successfully: ${userCredential.user!.uid}');
      return userCredential;
    } catch (e) {
      print('âŒ Error creating user: $e');
      rethrow;
    }
  }
  
  // Delete account functionality removed

  // Get student ID by email address
  Future<String?> getStudentIdByEmail(String email) async {
    try {
      print('ðŸ” Getting student ID for email: $email');
      
      final normalizedEmail = email.toLowerCase().trim();
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final studentId = data['studentId'] as String? ?? query.docs.first.id;
        print('âœ… Found student ID: $studentId for email: $email');
        return studentId;
      }
      
      print('âš ï¸ No student ID found for email: $email');
      return null;
    } catch (e) {
      print('âŒ Error getting student ID by email: $e');
      return null;
    }
  }

  // Get current user's student ID
  Future<String?> getCurrentStudentId() async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return null;
      
      // Try to get student ID from email
      return await getStudentIdByEmail(authUser.email!);
    } catch (e) {
      print('âŒ Error getting current student ID: $e');
      return null;
    }
  }
}
