import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../services/user_migration_service.dart';
import '../../firebase_options.dart';

// This script migrates user data from role string to isStudent boolean
// Run with: dart run lib/core/scripts/migrate_role_to_isStudent.dart

Future<void> main() async {
  try {
    // Initialize Firebase
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
    
    // Create migration service
    final migrationService = UserMigrationService();
    
    // Start migration
    print('🚀 Starting user role to isStudent migration...');
    final migrationResult = await migrationService.migrateUsers();
    
    // Print results
    print('\n📊 Migration Results:');
    print('  - Total users: ${migrationResult.totalUsers}');
    print('  - Successfully migrated: ${migrationResult.successCount}');
    print('  - Failed migrations: ${migrationResult.failureCount}');
    
    if (migrationResult.failureCount > 0) {
      print('\nFailed user IDs:');
      for (final userId in migrationResult.failedUserIds) {
        print('- $userId');
      }
    }
    
    // Verify migration
    print('\n🔍 Verifying migration...');
    final verificationResult = await migrationService.verifyMigration();
    
    if (verificationResult.isSuccessful) {
      print('\n✅ Migration verification successful!');
      print('  - Total users: ${verificationResult.sourceCount}');
      print('  - Users with isStudent field: ${verificationResult.targetCount}');
      
      // Finalize migration
      print('\n🔄 Finalizing migration...');
      final finalizeResult = await migrationService.finalizeMigration();
      
      if (finalizeResult.isSuccessful) {
        print('\n🎉 Migration completed successfully!');
      } else {
        print('\n⚠️ Migration finalization failed: ${finalizeResult.errorMessage}');
      }
    } else {
      print('\n⚠️ Migration verification failed!');
      print('  - Total users: ${verificationResult.sourceCount}');
      print('  - Users with isStudent field: ${verificationResult.targetCount}');
      print('  - Users missing isStudent field: ${verificationResult.missingUserIds.length}');
      
      if (verificationResult.missingUserIds.isNotEmpty) {
        print('\nUsers missing isStudent field:');
        for (final userId in verificationResult.missingUserIds.take(5)) {
          print('- $userId');
        }
        if (verificationResult.missingUserIds.length > 5) {
          print('  ... and ${verificationResult.missingUserIds.length - 5} more');
        }
      }
    }
  } catch (e) {
    print('\n❌ Migration failed: $e');
    exit(1);
  }
}