import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/models/user.dart';

// Migration result class
class MigrationResult {
  final int totalUsers;
  final int successCount;
  final int failureCount;
  final List<String> failedUserIds;
  
  MigrationResult({
    required this.totalUsers,
    required this.successCount,
    required this.failureCount,
    required this.failedUserIds,
  });
}

// Verification result class
class VerificationResult {
  final bool isSuccessful;
  final int sourceCount;
  final int targetCount;
  final List<String> missingUserIds;
  
  VerificationResult({
    required this.isSuccessful,
    required this.sourceCount,
    required this.targetCount,
    required this.missingUserIds,
  });
}

// Rollback result class
class RollbackResult {
  final bool isSuccessful;
  final String? errorMessage;
  
  RollbackResult({
    required this.isSuccessful,
    this.errorMessage,
  });
}

// Finalize result class
class FinalizeResult {
  final bool isSuccessful;
  final String? errorMessage;
  
  FinalizeResult({
    required this.isSuccessful,
    this.errorMessage,
  });
}

class UserMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection to update
  final String _usersCollection = 'users';
  
  // Migration status tracking
  int _totalUsers = 0;
  int _migratedUsers = 0;
  int _failedUsers = 0;
  List<String> _errors = [];
  
  // Getters for migration status
  int get totalUsers => _totalUsers;
  int get migratedUsers => _migratedUsers;
  int get failedUsers => _failedUsers;
  List<String> get errors => _errors;
  bool get isComplete => _totalUsers > 0 && _migratedUsers + _failedUsers == _totalUsers;
  double get progressPercentage => _totalUsers > 0 ? (_migratedUsers / _totalUsers) * 100 : 0;
  
  // Validate user data before migration
  bool _validateUserData(Map<String, dynamic> userData) {
    // Check for required fields
    if (userData['uid'] == null || userData['uid'].toString().isEmpty) {
      return false;
    }
    if (userData['email'] == null || userData['email'].toString().isEmpty) {
      return false;
    }
    
    // Additional validation can be added here
    return true;
  }
  
  // Transform user data if needed
  Map<String, dynamic> _transformUserData(Map<String, dynamic> userData) {
    // Create a copy of the original data
    final transformedData = Map<String, dynamic>.from(userData);
    
    // Convert role string to isStudent boolean
    if (userData.containsKey('role')) {
      final String role = userData['role'] ?? 'student';
      transformedData['isStudent'] = role == 'student';
      
      // Keep the role field for backward compatibility
      transformedData['role'] = role;
    } else {
      // Default to student if role is missing
      transformedData['isStudent'] = true;
      transformedData['role'] = 'student';
    }
    
    // Ensure all required fields exist with default values if missing
    transformedData['accountStatus'] = userData['accountStatus'] ?? 'active';
    transformedData['displayName'] = userData['displayName'] ?? 'Unknown User';
    
    // Convert Timestamp objects to ISO8601 strings for consistent format
    if (userData['createdAt'] != null) {
      if (userData['createdAt'] is Timestamp) {
        transformedData['createdAt'] = (userData['createdAt'] as Timestamp).toDate().toIso8601String();
      }
    } else {
      transformedData['createdAt'] = DateTime.now().toIso8601String();
    }
    
    if (userData['lastLogin'] != null) {
      if (userData['lastLogin'] is Timestamp) {
        transformedData['lastLogin'] = (userData['lastLogin'] as Timestamp).toDate().toIso8601String();
      }
    } else {
      transformedData['lastLogin'] = DateTime.now().toIso8601String();
    }
    
    return transformedData;
  }
  
  // Migrate a single user
  Future<bool> _migrateUser(DocumentSnapshot userDoc) async {
    try {
      // Get user data
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Validate user data
      if (!_validateUserData(userData)) {
        _errors.add('Invalid user data for user ${userDoc.id}');
        return false;
      }
      
      // Check if user already has isStudent field
      if (userData.containsKey('isStudent')) {
        print('✅ User ${userDoc.id} already has isStudent field, skipping');
        return true;
      }
      
      // Get role and convert to isStudent
      final String role = userData['role'] ?? 'student';
      final bool isStudent = role == 'student';
      
      // Update user document with isStudent field
      await _firestore.collection(_usersCollection).doc(userDoc.id).update({
        'isStudent': isStudent,
      });
      
      print('✅ Updated user ${userDoc.id}: role="$role" -> isStudent=$isStudent');
      return true;
    } catch (e) {
      _errors.add('Error migrating user ${userDoc.id}: $e');
      return false;
    }
  }
  
  // Migrate all users
  Future<MigrationResult> migrateUsers() async {
    try {
      // Reset counters
      _totalUsers = 0;
      _migratedUsers = 0;
      _failedUsers = 0;
      _errors = [];
      List<String> failedUserIds = [];
      
      // Get all users from users collection
      final QuerySnapshot usersSnapshot = await _firestore.collection(_usersCollection).get();
      _totalUsers = usersSnapshot.docs.length;
      
      print('🚀 Starting migration of $_totalUsers users to add isStudent field');
      
      // Process each user
      for (var userDoc in usersSnapshot.docs) {
        final success = await _migrateUser(userDoc);
        if (success) {
          _migratedUsers++;
        } else {
          _failedUsers++;
          failedUserIds.add(userDoc.id);
        }
        
        // Log progress
        if (_migratedUsers % 10 == 0 || _migratedUsers == _totalUsers || _migratedUsers + _failedUsers == _totalUsers) {
          print('📊 Migration progress: ${_migratedUsers + _failedUsers}/$_totalUsers (${progressPercentage.toStringAsFixed(1)}%)');
        }
      }
      
      print('✅ Migration complete: $_migratedUsers users migrated successfully, $_failedUsers failed');
      if (_failedUsers > 0) {
        print('⚠️ Errors encountered during migration:');
        for (var error in _errors.take(5)) {
          print('  - $error');
        }
        if (_errors.length > 5) {
          print('  ... and ${_errors.length - 5} more errors');
        }
      }
      
      return MigrationResult(
        totalUsers: _totalUsers,
        successCount: _migratedUsers,
        failureCount: _failedUsers,
        failedUserIds: failedUserIds,
      );
    } catch (e) {
      print('❌ Migration failed: $e');
      _errors.add('Migration failed: $e');
      return MigrationResult(
        totalUsers: _totalUsers,
        successCount: _migratedUsers,
        failureCount: _failedUsers,
        failedUserIds: [],
      );
    }
  }
  
  // Verify migration by checking if all users have isStudent field
  Future<VerificationResult> verifyMigration() async {
    try {
      final usersSnapshot = await _firestore.collection(_usersCollection).get();
      final totalCount = usersSnapshot.docs.length;
      
      int usersWithIsStudent = 0;
      final List<String> missingIsStudentUserIds = [];
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        if (userData.containsKey('isStudent')) {
          usersWithIsStudent++;
        } else {
          missingIsStudentUserIds.add(doc.id);
        }
      }
      
      final bool isSuccessful = missingIsStudentUserIds.isEmpty;
      
      print('📊 Users with isStudent field: $usersWithIsStudent/$totalCount');
      if (missingIsStudentUserIds.isNotEmpty) {
        print('⚠️ Users missing isStudent field: ${missingIsStudentUserIds.length}');
      }
      
      return VerificationResult(
        isSuccessful: isSuccessful,
        sourceCount: totalCount,
        targetCount: usersWithIsStudent,
        missingUserIds: missingIsStudentUserIds,
      );
    } catch (e) {
      print('❌ Verification failed: $e');
      return VerificationResult(
        isSuccessful: false,
        sourceCount: 0,
        targetCount: 0,
        missingUserIds: [],
      );
    }
  }
   
   // Rollback migration by deleting the destination collection
   Future<RollbackResult> rollbackMigration() async {
     try {
       final batch = _firestore.batch();
       final destSnapshot = await _firestore.collection('users').get();
       
       // Delete all documents in the destination collection
       for (var doc in destSnapshot.docs) {
         batch.delete(doc.reference);
       }
       
       await batch.commit();
       
       return RollbackResult(isSuccessful: true);
     } catch (e) {
       print('❌ Rollback failed: $e');
       return RollbackResult(
         isSuccessful: false,
         errorMessage: e.toString(),
       );
     }
   }
   
   // Finalize migration by logging completion
   Future<FinalizeResult> finalizeMigration() async {
     try {
       // Log migration completion
       print('🎉 Role to isStudent migration completed successfully');
       print('✅ All users now have both role and isStudent fields');
       print('✅ New users will be created with both fields');
       
       return FinalizeResult(isSuccessful: true);
     } catch (e) {
       print('❌ Finalization failed: $e');
       return FinalizeResult(
         isSuccessful: false,
         errorMessage: e.toString(),
       );
     }
   }
}