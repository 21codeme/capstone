import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'jwt_service.dart';

class EmailService {
  // Send verification email to student with code using Firebase Cloud Function
  static Future<bool> sendStudentVerificationEmail({
    required String email,
    required String studentId,
    required String firstName,
    required String verificationCode,
  }) async {
    try {
      // Use the new sendRegistrationOtp function instead of the old sendOtpEmail
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendRegistrationOtp');
      
      final result = await callable.call({
        'email': email,
        'studentId': studentId,
        'firstName': firstName,
      });
      
      if (result.data['success'] == true) {
        print('OTP email sent successfully to $email');
        return true;
      } else {
        print('Failed to send OTP email: ${result.data['message']}');
        return false;
      }
    } catch (e) {
      print('Error sending verification email with Firebase Functions: $e');
      return false;
    }
  }

  // Send verification success confirmation (placeholder - can be implemented later)
  static Future<bool> sendVerificationSuccessEmail({
    required String email,
    required String firstName,
  }) async {
    try {
      print('Verification success email for $firstName ($email) - Placeholder implementation');
      // This function can be implemented later with a new Cloud Function if needed
      return true;
    } catch (e) {
      print('Error sending success email: $e');
      return false;
    }
  }

  // For development/testing - log email content instead of sending
  static Future<bool> logVerificationEmail({
    required String email,
    required String studentId,
    required String firstName,
    required String verificationCode,
  }) async {
    try {
      print('''
=== EMAIL VERIFICATION LOG ===
To: $email
Subject: Verify Your PathFit Student Account

Hello $firstName,

Your verification code is: $verificationCode

Please enter this 6-digit code in the PathFit app to verify your account.
This code will expire in 24 hours.
==============================
      ''');

      return true;
    } catch (e) {
      print('Error logging verification email: $e');
      return false;
    }
  }
}