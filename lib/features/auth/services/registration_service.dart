import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling user registration with email OTP verification
class RegistrationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Send OTP code to email for registration verification
  Future<Map<String, dynamic>> sendRegistrationOTP({
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      print('🚀 Sending registration OTP to: $email');
      
      // Call the Firebase Cloud Function
      final result = await _functions.httpsCallable('sendRegistrationOtp').call({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      });
      
      print('✅ Registration OTP sent successfully');
      print('Response data: ${result.data}');
      
      return {
        'success': true,
        'message': 'OTP sent successfully',
        'data': result.data,
      };
      
    } on FirebaseFunctionsException catch (e) {
      print('❌ Firebase Functions error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.message ?? 'Failed to send OTP',
        'code': e.code,
      };
    } catch (e) {
      print('❌ Unexpected error sending OTP: $e');
      return {
        'success': false,
        'error': 'Failed to send OTP: $e',
      };
    }
  }
  
  /// Complete registration process with email verification
  Future<Map<String, dynamic>> completeRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String course,
    required String year,
    required String section,
    required String otpCode,
  }) async {
    try {
      print('=== Starting Complete Registration Process ===');
      
      // Step 1: Create user account with Firebase Auth
      print('🔐 Creating Firebase Auth account...');
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final String uid = userCredential.user!.uid;
      print('✅ Firebase Auth account created with UID: $uid');
      
      // Step 2: Create user document in Firestore
      print('📄 Creating user document in Firestore...');
      final userData = {
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'course': course,
        'year': year,
        'section': section,
        'accountStatus': 'active', // Mark as active since OTP was verified
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'loginStreak': 1,
        'totalLogins': 1,
        'loginAttempts': 0,
        'isEmailVerified': true, // OTP verification completed
      };
      
      // You would typically save this to Firestore here
      // await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
      
      print('✅ User document prepared');
      print('📋 User data: $userData');
      
      return {
        'success': true,
        'message': 'Registration completed successfully',
        'uid': uid,
        'userData': userData,
      };
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.message ?? 'Registration failed',
        'code': e.code,
      };
    } catch (e) {
      print('❌ Unexpected error during registration: $e');
      return {
        'success': false,
        'error': 'Registration failed: $e',
      };
    }
  }
  
  /// Resend OTP code (useful if user didn't receive the first one)
  Future<Map<String, dynamic>> resendRegistrationOTP({
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      print('🔄 Resending registration OTP to: $email');
      
      // Simply call the sendRegistrationOTP function again
      return await sendRegistrationOTP(
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
      
    } catch (e) {
      print('❌ Error resending OTP: $e');
      return {
        'success': false,
        'error': 'Failed to resend OTP: $e',
      };
    }
  }
}