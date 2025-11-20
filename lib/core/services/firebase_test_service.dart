import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth_service.dart';

class FirebaseTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseAuthService _authService = FirebaseAuthService();

  // Test basic Firebase connection
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      print('🧪 Testing Firebase connection...');
      
      // Test 1: Firebase Auth connection
      final currentUser = _auth.currentUser;
      print('✅ Firebase Auth: ${currentUser?.uid ?? 'No user signed in'}');
      
      // Test 2: Firestore connection
      try {
        await _firestore.collection('test').doc('connection').get();
        print('✅ Firestore: Connection successful');
      } catch (e) {
        print('❌ Firestore: Connection failed - $e');
        return {
          'success': false,
          'auth': true,
          'firestore': false,
          'error': e.toString(),
          'message': 'Firestore connection failed. Check your security rules.',
        };
      }
      
      // Test 3: Create a test document
      try {
        await _firestore.collection('test').doc('connection').set({
          'timestamp': Timestamp.now(),
          'test': true,
        });
        print('✅ Firestore: Write test successful');
        
        // Clean up test document
        await _firestore.collection('test').doc('connection').delete();
        print('✅ Firestore: Cleanup successful');
        
      } catch (e) {
        print('❌ Firestore: Write test failed - $e');
        return {
          'success': false,
          'auth': true,
          'firestore': true,
          'write': false,
          'error': e.toString(),
          'message': 'Firestore write test failed. Check your security rules.',
        };
      }
      
      print('🎉 All Firebase tests passed!');
      return {
        'success': true,
        'auth': true,
        'firestore': true,
        'write': true,
        'message': 'Firebase connection is working perfectly!',
      };
      
    } catch (e) {
      print('❌ Firebase test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Firebase test failed. Check your configuration.',
      };
    }
  }

  // Test user registration flow - SAFE VERSION: only checks email status, never creates users
  static Future<Map<String, dynamic>> testUserRegistration(String email) async {
    try {
      print('🧪 Testing user registration flow for: $email');
      
      // Safe check: using the workaround method since fetchSignInMethodsForEmail is removed
      final methods = await _authService.fetchSignInMethodsForEmail(email.trim());
      
      return {
        'success': true,
        'registered': methods.isNotEmpty,
        'methods': methods,
        'message': methods.isNotEmpty
            ? 'Email already registered via ${methods.join(', ')}'
            : 'Email available',
      };
      
    } catch (e) {
      print('❌ User registration test failed: $e');
      return {
        'success': false,
        'message': 'Error checking email: $e',
        'error': e.toString(),
      };
    }
  }
}

