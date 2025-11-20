import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../firebase_options.dart';

Future<void> main() async {
  try {
    // Initialize Firebase
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
    
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    print('🚀 Starting users database cleanup...');
    
    // Get all users from Firestore
    final QuerySnapshot usersSnapshot = await firestore.collection('users').get();
    
    if (usersSnapshot.docs.isEmpty) {
      print('ℹ️ No users found in the database.');
      exit(0);
    }
    
    print('📊 Found ${usersSnapshot.docs.length} users in the database');
    print('🗑️ Deleting all user documents...');
    
    // Use batched writes for better performance
    int batchSize = 0;
    WriteBatch batch = firestore.batch();
    int totalDeleted = 0;
    
    for (var doc in usersSnapshot.docs) {
      batch.delete(doc.reference);
      batchSize++;
      
      // Firestore batches are limited to 500 operations
      if (batchSize >= 400) {
        await batch.commit();
        totalDeleted += batchSize;
        print('📊 Deleted $totalDeleted/${usersSnapshot.docs.length} users (${(totalDeleted / usersSnapshot.docs.length * 100).toStringAsFixed(1)}%)');
        
        // Reset batch
        batch = firestore.batch();
        batchSize = 0;
      }
    }
    
    // Commit any remaining operations
    if (batchSize > 0) {
      await batch.commit();
      totalDeleted += batchSize;
      print('📊 Deleted $totalDeleted/${usersSnapshot.docs.length} users (${(totalDeleted / usersSnapshot.docs.length * 100).toStringAsFixed(1)}%)');
    }
    
    print('\n🎉 Users database cleanup completed!');
    print('✅ All user documents have been removed from Firestore');
    print('⚠️ Note: Users still exist in Firebase Authentication');
    print('⚠️ To delete users from Authentication, use the Firebase Console or the admin script');
    
  } catch (e) {
    print('\n❌ Database cleanup failed: $e');
    exit(1);
  }
}