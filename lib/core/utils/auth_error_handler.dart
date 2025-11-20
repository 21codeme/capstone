import 'package:firebase_auth/firebase_auth.dart';

/// A utility class that provides standardized error handling for Firebase authentication errors.
class AuthErrorHandler {
  /// Converts Firebase authentication exceptions into user-friendly error messages.
  /// 
  /// Parameters:
  /// - [error]: The error object to process
  /// - [context]: Optional context string to include in logs
  /// 
  /// Returns a user-friendly error message.
  static String getErrorMessage(dynamic error, [String? context]) {
    final logPrefix = context != null ? '[$context]' : '';
    
    // Handle FirebaseAuthException
    if (error is FirebaseAuthException) {
      print('$logPrefix Firebase Auth Error: ${error.code} - ${error.message}');
      
      switch (error.code) {
        // Authentication errors
        case 'user-not-found':
          return 'No account found with this email. Please check your email or sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or reset your password.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'invalid-email':
          return 'Invalid email format. Please enter a valid email address.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in or use a different email.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        
        // Network errors
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'too-many-requests':
          return 'Too many unsuccessful login attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please contact support.';
        
        // Default case
        default:
          return 'Authentication error: ${error.message ?? error.code}';
      }
    }
    
    // Handle specific error strings
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('pigeonuserdetails')) {
      print('$logPrefix PigeonUserDetails error detected');
      return 'Temporary authentication error. Please try again.';
    }
    
    if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('permanently deleted')) {
      return 'This account has been permanently deleted. Please register a new account.';
    }
    
    if (errorString.contains('inactive')) {
      return 'Your account is inactive. Please contact support.';
    }
    
    // Log unknown errors
    print('$logPrefix Unhandled auth error: $error');
    return 'An unexpected error occurred. Please try again later.';
  }
  
  /// Determines if an error is a network-related error that might be temporary
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseAuthException && error.code == 'network-request-failed') {
      return true;
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('timeout') || 
           errorString.contains('connection') ||
           errorString.contains('unavailable');
  }
  
  /// Determines if an error is a temporary error that might resolve on retry
  static bool isTemporaryError(dynamic error) {
    if (isNetworkError(error)) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('pigeonuserdetails') || 
           errorString.contains('internal') ||
           errorString.contains('temporarily') ||
           errorString.contains('resource-exhausted');
  }
  
  /// Determines if an error is a permanent error that won't resolve on retry
  static bool isPermanentError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'user-disabled':
        case 'invalid-email':
        case 'email-already-in-use':
        case 'weak-password':
        case 'account-exists-with-different-credential':
        case 'operation-not-allowed':
          return true;
        default:
          return false;
      }
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permanently deleted') || 
           errorString.contains('inactive') ||
           errorString.contains('permission-denied') ||
           errorString.contains('unauthenticated');
  }
}