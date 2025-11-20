import 'dart:developer' as developer;

class EmailService {
  static Future<void> logVerificationEmail({
    required String email,
    required String studentId,
    required String firstName,
    required String verificationUrl,
  }) async {
    developer.log('''
    📧 VERIFICATION EMAIL LOG
    To: $email
    Student ID: $studentId
    Name: $firstName
    Verification URL: $verificationUrl
    ''', name: 'EmailService');
  }

  static Future<void> sendVerificationSuccessEmail({
    required String email,
    required String firstName,
  }) async {
    developer.log('''
    📧 WELCOME EMAIL LOG
    To: $email
    Name: $firstName
    Message: Welcome to PathFit! Your account has been verified.
    ''', name: 'EmailService');
  }

  static Future<void> sendPasswordResetEmail({
    required String email,
    required String resetUrl,
  }) async {
    developer.log('''
    📧 PASSWORD RESET EMAIL LOG
    To: $email
    Reset URL: $resetUrl
    ''', name: 'EmailService');
  }

  static Future<void> sendWelcomeEmail({
    required String email,
    required String firstName,
  }) async {
    developer.log('''
    📧 WELCOME EMAIL LOG
    To: $email
    Name: $firstName
    Message: Welcome to PathFit!
    ''', name: 'EmailService');
  }
}