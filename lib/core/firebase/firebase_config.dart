import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import '../../firebase_options.dart';

class FirebaseConfig {
  // Flag to track if pre-warming has been done
  static bool _preWarmed = false;
  
  // Flag to control connection limiting
  static bool _limitConnections = true;
  
  static Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized successfully');
        
        // Initialize Firebase App Check with debug provider for development
        // This prevents the "Too many attempts" error during development
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI'), // Test key from Google
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        
        // Add a small delay to ensure App Check is fully initialized
        await Future.delayed(const Duration(milliseconds: 500));
        print('✅ Firebase App Check initialized with debug providers');
      } else {
        print('✅ Firebase already initialized');
      }
      
      // Initialize Firestore with specific database
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Test Firestore connection (but don't fail if it doesn't work)
      try {
        await FirebaseFirestore.instance.collection('test').doc('connection').get();
        print('✅ Firestore connected successfully');
      } catch (e) {
        print('⚠️ Firestore connection test failed: $e');
        print('⚠️ This might be normal if the test collection doesn\'t exist');
        // Don't fail initialization if Firestore test fails
      }
      
      // Pre-warm connections if not already done
      if (!_preWarmed) {
        _preWarmConnections();
      }
      
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      // Don't rethrow - continue with existing Firebase instance
    }
  }
  
  // Pre-warm Firebase connections to improve performance
  static Future<void> _preWarmConnections() async {
    try {
      // Skip pre-warming if connection limiting is enabled
      if (_limitConnections) {
        print('⚠️ Connection limiting is enabled, skipping pre-warming');
        return;
      }
      
      print('🔥 Pre-warming Firebase connections...');
      
      // Pre-warm Firestore connection
      Future<void> preWarmFirestore() async {
        try {
          // Create a small batch operation to warm up the connection
          final batch = FirebaseFirestore.instance.batch();
          final tempDoc = FirebaseFirestore.instance.collection('_temp').doc('_prewarm');
          batch.set(tempDoc, {'timestamp': FieldValue.serverTimestamp()});
          batch.delete(tempDoc);
          await batch.commit();
          print('✅ Firestore connection pre-warmed');
        } catch (e) {
          // Ignore errors during pre-warming
          print('⚠️ Firestore pre-warming: $e');
        }
      }
      
      // Pre-warm Auth connection
      Future<void> preWarmAuth() async {
        try {
          // Just check the current user to warm up the connection
          final _ = FirebaseAuth.instance.currentUser;
          print('✅ Auth connection pre-warmed');
        } catch (e) {
          // Ignore errors during pre-warming
          print('⚠️ Auth pre-warming: $e');
        }
      }
      
      // Run pre-warming in parallel
      await Future.wait([
        preWarmFirestore(),
        preWarmAuth(),
      ]);
      
      _preWarmed = true;
      print('✅ Firebase connections pre-warmed successfully');
    } catch (e) {
      print('⚠️ Error during connection pre-warming: $e');
      // Don't fail if pre-warming fails
    }
  }

  // Get Firestore instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  // Get Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;
  
  // Get current user
  static User? get currentUser => auth.currentUser;
  
  // Get current user ID
  static String? get currentUserId => currentUser?.uid;
  
  // Set connection limiting
  static void setLimitConnections(bool limit) {
    _limitConnections = limit;
    print('${limit ? '🔒' : '🔓'} Firebase connection limiting ${limit ? 'enabled' : 'disabled'}');
    
    // If limiting is disabled and we haven't pre-warmed, do it now
    if (!limit && !_preWarmed) {
      _preWarmConnections();
    }
  }
  
  // Get connection limiting status
  static bool get limitConnections => _limitConnections;
  
  // Force App Check token refresh
  static Future<void> refreshAppCheckToken() async {
    try {
      print('🔄 Refreshing App Check token...');
      await FirebaseAppCheck.instance.getToken(true); // Force refresh
      print('✅ App Check token refreshed');
    } catch (e) {
      print('❌ Failed to refresh App Check token: $e');
      // Don't throw - this is a best-effort refresh
    }
  }
  
  // Check if App Check is properly initialized
  static Future<bool> isAppCheckInitialized() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return token != null;
    } catch (e) {
      print('❌ App Check initialization check failed: $e');
      return false;
    }
  }
}
