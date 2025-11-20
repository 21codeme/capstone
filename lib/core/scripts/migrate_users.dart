import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../services/user_migration_service.dart';
import '../../firebase_options.dart';

// This script migrates user data from the old collection to the new collection
// Run with: dart run lib/core/scripts/migrate_users.dart

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
    print('🚀 Starting user migration...');
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
      print('  - Source collection count: ${verificationResult.sourceCount}');
      print('  - Target collection count: ${verificationResult.targetCount}');
    } else {
      print('\n⚠️ Migration verification failed!');
      print('  - Source collection count: ${verificationResult.sourceCount}');
      print('  - Target collection count: ${verificationResult.targetCount}');
      print('  - Missing user IDs: ${verificationResult.missingUserIds.join(', ')}');
      
      // Ask if user wants to rollback
      print('\n❓ Would you like to rollback the migration? (y/n)');
      final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
      
      if (response == 'y') {
        print('\n🔄 Rolling back migration...');
        final rollbackResult = await migrationService.rollbackMigration();
        if (rollbackResult.isSuccessful) {
          print('✅ Rollback completed successfully.');
        } else {
          print('❌ Rollback failed. Please check the database manually.');
        }
      }
    }
    
    // Finalize migration if successful and user confirms
    if (verificationResult.isSuccessful) {
      print('\nWould you like to finalize the migration? This will update all references to use the new collection. (y/n)');
      final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
      
      if (response == 'y') {
        print('\nFinalizing migration...');
        final finalizeResult = await migrationService.finalizeMigration();
        
        if (finalizeResult.isSuccessful) {
          print('Migration finalized successfully.');
        } else {
          print('Finalization failed: ${finalizeResult.errorMessage}');
        }
      }
    }
    
    print('\n🏁 Migration process completed');
  } catch (e) {
    print('\n❌ Error during migration: $e');
  }
}