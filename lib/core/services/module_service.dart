import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';

class ModuleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _modulesCollection => _firestore.collection('modules');
  CollectionReference get _studentModulesCollection => _firestore.collection('studentModules');

  // Upload module to Firebase Storage and Firestore
  Future<Map<String, dynamic>> uploadModule({
    required File file,
    required String moduleTitle,
    required String category,
    String? description,
    String? videoUrl,
    DateTime? dueDate,
    String? sectionId,
    String? sectionName,
    String? yearLevel,
    String? course,
  }) async {
    try {
      print('🔄 Starting module upload...');
      print('📁 File path: ${file.path}');
      print('📄 Module title: $moduleTitle');
      print('🏷️ Category: $category');
      
      // Check if file exists
      if (!await file.exists()) {
        print('❌ File does not exist at path: ${file.path}');
        return {
          'success': false,
          'error': 'File not found',
          'message': 'Selected file does not exist',
        };
      }

      // Get file info
      final fileSize = await file.length();
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();
      
      print('✅ File selected: $fileName');
      print('📏 File size: $fileSize bytes');
      print('🔤 File extension: $fileExtension');
      
      // Validate file size (50MB limit)
      if (fileSize > 50 * 1024 * 1024) {
        print('❌ File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
        return {
          'success': false,
          'error': 'File too large',
          'message': 'File size must be less than 50MB',
        };
      }

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        return {
          'success': false,
          'error': 'User not authenticated',
          'message': 'Please log in to upload modules',
        };
      }

      // Force token refresh to get latest email verification status
      print('🔄 Refreshing authentication token...');
      await user.reload();
      await user.getIdToken(true); // Force refresh
      
      // Get updated user after refresh
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        print('❌ User lost after token refresh');
        return {
          'success': false,
          'error': 'Authentication lost',
          'message': 'Please log in again',
        };
      }

      print('✅ User authenticated: ${refreshedUser.email}');
      print('✅ User email verified: ${refreshedUser.emailVerified}');
      
      // Additional check: try to get user from Firestore to see verification status and determine role
      bool? isStudentRole;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(refreshedUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<dynamic, dynamic>;
          print('📋 Firestore user data: ${userData.toString()}');
          print('📧 Firestore email: ${userData['email']}');
          print('✅ Firestore email verified: ${userData['emailVerified'] ?? 'not set'}');
          if (userData.containsKey('isStudent')) {
            isStudentRole = userData['isStudent'] == true;
          } else if (userData.containsKey('role')) {
            final role = (userData['role'] as String?)?.toLowerCase();
            isStudentRole = role == 'student';
          }
          print('👤 Derived isStudent role: ${isStudentRole ?? 'unknown'}');
        }
      } catch (e) {
        print('⚠️ Could not check Firestore user data: $e');
      }
      
      // Enforce email verification only for students (instructors can upload regardless)
      final enforceEmailVerification = isStudentRole == true;
      if (enforceEmailVerification && !refreshedUser.emailVerified) {
        print('❌ Student email not verified in Firebase Auth');
        print('💡 Attempting to send verification email...');
        
        try {
          await refreshedUser.sendEmailVerification();
          print('📧 Verification email sent');
        } catch (e) {
          print('❌ Failed to send verification email: $e');
        }
        
        return {
          'success': false,
          'error': 'Email not verified',
          'message': 'Please verify your email before uploading modules. Check your inbox for a verification email.',
        };
      }
      

      final instructorId = refreshedUser.uid;
      // Prefer Firestore users.fullName; fallback to Auth displayName
      String instructorFullName = 'Unknown Instructor';
      try {
        final doc = await _firestore.collection('users').doc(instructorId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final fromDoc = (data['fullName'] as String?)?.trim();
          if (fromDoc != null && fromDoc.isNotEmpty) {
            instructorFullName = fromDoc;
          } else if ((refreshedUser.displayName ?? '').trim().isNotEmpty) {
            instructorFullName = refreshedUser.displayName!.trim();
          }
        } else if ((refreshedUser.displayName ?? '').trim().isNotEmpty) {
          instructorFullName = refreshedUser.displayName!.trim();
        }
      } catch (e) {
        print('⚠️ Could not read instructor fullName: $e');
        if ((refreshedUser.displayName ?? '').trim().isNotEmpty) {
          instructorFullName = refreshedUser.displayName!.trim();
        }
      }
      
      print('👤 Instructor ID: $instructorId');
      print('👤 Instructor Full Name: $instructorFullName');
      if (yearLevel != null) {
        print('🎓 Year Level: $yearLevel');
      }
      if (course != null) {
        print('🏫 Course: $course');
      }

      // Create storage reference
      final storageRef = _storage.ref().child('modules/$moduleTitle/$fileName');
      print('📦 Storage reference created: modules/$moduleTitle/$fileName');

      // Upload to Firebase Storage
      print('🚀 Starting Firebase Storage upload...');
      final uploadTask = storageRef.putFile(file);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      print('✅ File uploaded to Firebase Storage');
      
      // Get download URL
      final downloadURL = await snapshot.ref.getDownloadURL();
      print('🔗 Download URL generated: $downloadURL');

      // Create Firestore document
      print('📝 Creating Firestore document...');
      final moduleRef = await _modulesCollection.add({
        'title': moduleTitle,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileExtension': fileExtension,
        'instructorId': instructorId,
        'fullName': instructorFullName,
        'category': category, // Added category field
        'description': description ?? '',
        'videoUrl': videoUrl ?? '', // Video URL field
        'dueDate': dueDate?.toIso8601String(),
        'uploadDate': DateTime.now().toIso8601String(),
        'status': 'active',
        'downloads': 0,
        'views': 0,
        'sectionId': sectionId,
        'section': sectionName,
        'year': yearLevel,
        'course': course,
        'visibility': sectionId != null ? 'section' : 'all',
        // Store storage full path to support deletion later
        'filePath': snapshot.ref.fullPath,
        // Optional: store download URL on main doc too for consistency
        'downloadURL': downloadURL,
      });
      print('✅ Module document created: ${moduleRef.id}');

      // Distribute to matching students (course + year + section)
      final normalizedCourse = course?.trim();
      final normalizedYear = yearLevel?.trim();
      final normalizedSection = sectionName?.trim();
      final List<String> recipientUids = [];

      if (normalizedCourse != null && normalizedYear != null && normalizedSection != null) {
        print('🔍 Resolving recipients via users collection...');
        final usersQuery = await _firestore
            .collection('users')
            .where('isStudent', isEqualTo: true)
            .where('course', isEqualTo: normalizedCourse)
            .where('year', isEqualTo: normalizedYear)
            .where('section', isEqualTo: normalizedSection)
            .get();
        for (final doc in usersQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final uid = (data['uid'] as String?) ?? doc.id;
          recipientUids.add(uid);
        }
        print('👥 Matched ${recipientUids.length} recipients from users');
      } else {
        print('⚠️ Missing course/year/section; falling back to studentProgress');
        final progressQuery = await _firestore
            .collection('studentProgress')
            .where('section', isEqualTo: sectionName)
            .where('year', isEqualTo: yearLevel)
            .get();
        for (final doc in progressQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final uid = data['studentId'] as String?;
          if (uid != null) recipientUids.add(uid);
        }
        print('👥 Matched ${recipientUids.length} recipients from studentProgress');
      }

      // Write studentModules documents per recipient in batches
      int createdCount = 0;
      const batchSize = 400; // keep under Firestore 500 limit
      for (int i = 0; i < recipientUids.length; i += batchSize) {
        final chunk = recipientUids.sublist(i, (i + batchSize) > recipientUids.length ? recipientUids.length : (i + batchSize));
        final batch = _firestore.batch();
        for (final uid in chunk) {
          final ref = _studentModulesCollection.doc();
          batch.set(ref, {
            'moduleId': moduleRef.id,
            'title': moduleTitle,
            'fileName': fileName,
            'instructorId': instructorId,
            'fullName': instructorFullName,
            'category': category,
            'uploadDate': DateTime.now().toIso8601String(),
            'dueDate': dueDate?.toIso8601String(),
            'status': 'active',
            'downloadURL': downloadURL,
            'fileSize': fileSize,
            'fileExtension': fileExtension,
            'videoUrl': videoUrl ?? '', // Include video URL
            'sectionId': sectionId,
            'section': sectionName,
            'year': yearLevel,
            'course': course,
            'studentId': uid,
          });
        }
        await batch.commit();
        createdCount += chunk.length;
      }
      print('✅ Distributed module to $createdCount students');

      print('🎉 Module upload completed successfully!');
      return {
        'success': true,
        'moduleId': moduleRef.id,
        'downloadURL': downloadURL,
        'message': 'Module uploaded successfully',
      };
    } catch (e) {
      print('❌ Error during module upload: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error stack trace: ${StackTrace.current}');
      
      // Provide more specific error messages
      String errorMessage = 'Failed to upload module';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Check your Firebase rules.';
      } else if (e.toString().contains('unauthenticated')) {
        errorMessage = 'User not authenticated. Please log in again.';
      } else if (e.toString().contains('storage/unauthorized')) {
        errorMessage = 'Storage access denied. Check Firebase Storage rules.';
      } else if (e.toString().contains('firestore/permission-denied')) {
        errorMessage = 'Database access denied. Check Firestore rules.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else if (e.toString().contains('quota-exceeded')) {
        errorMessage = 'Storage quota exceeded. Contact administrator.';
      } else if (e.toString().contains('invalid-argument')) {
        errorMessage = 'Invalid file or data. Please check your input.';
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': errorMessage,
      };
    }
  }

  // Get all modules for students (legacy/global)
  Future<List<Map<dynamic, dynamic>>> getStudentModules() async {
    try {
      print('🔍 ModuleService: Starting getStudentModules()...');
      print('📡 Collection path: studentModules');
      
      QuerySnapshot snapshot;
      
      try {
        // Try with orderBy first (requires composite index)
        print('🔍 Attempting query with orderBy...');
        snapshot = await _studentModulesCollection
            .orderBy('uploadDate', descending: true)
            .orderBy('__name__', descending: true)
            .get();
        print('✅ Query with orderBy successful');
      } catch (indexError) {
        print('⚠️ OrderBy query failed (likely missing index): $indexError');
        print('🔄 Falling back to simple query without orderBy...');
        
        // Fallback: simple query without orderBy
        snapshot = await _studentModulesCollection.get();
        print('✅ Simple query successful');
      }

      print('📊 Raw documents found: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('❌ No documents found in studentModules collection');
        print('🔍 Checking if collection exists...');
        
        // Test if we can access the collection at all
        try {
          final testSnapshot = await _studentModulesCollection.limit(1).get();
          print('📊 Collection access test: ${testSnapshot.docs.length} docs');
        } catch (accessError) {
          print('❌ Collection access failed: $accessError');
        }
        
        return [];
      }

      final modules = snapshot.docs.map((doc) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      print('✅ Successfully processed ${modules.length} modules');
      
      // Sort manually if we used the fallback query
      if (modules.isNotEmpty) {
        try {
          modules.sort((a, b) {
            final aDate = a['uploadDate']?.toString() ?? '';
            final bDate = b['uploadDate']?.toString() ?? '';
            return bDate.compareTo(aDate); // Descending order
          });
          print('✅ Modules sorted by upload date');
        } catch (sortError) {
          print('⚠️ Could not sort modules: $sortError');
        }
        
        print('📋 Sample module structure:');
        final sample = modules.first;
        sample.forEach((key, value) {
          print('   $key: $value');
        });
      }

      return modules;
    } catch (e) {
      print('❌ Error getting student modules: $e');
      print('❌ Error type: ${e.runtimeType}');
      return [];
    }
  }

  // NEW: Get modules for a specific student (by UID), optional filters
  Future<List<Map<dynamic, dynamic>>> getStudentModulesForStudent(String studentUid, {String? sectionName, String? fileType}) async {
    try {
      print('🔍 ModuleService: getStudentModulesForStudent(uid=$studentUid, sectionName=$sectionName, fileType=$fileType)');
      Query query = _studentModulesCollection.where('studentId', isEqualTo: studentUid);
      if (sectionName != null && sectionName.isNotEmpty) {
        // Store under 'section' going forward
        query = query.where('section', isEqualTo: sectionName);
      }
      if (fileType != null && fileType.isNotEmpty && fileType.toLowerCase() != 'all types') {
        query = query.where('fileExtension', isEqualTo: fileType.toLowerCase());
      }

      QuerySnapshot snapshot;
      try {
        snapshot = await query.orderBy('uploadDate', descending: true).orderBy('__name__', descending: true).get();
      } catch (indexError) {
        print('⚠️ OrderBy failed, falling back without orderBy: $indexError');
        snapshot = await query.get();
      }

      // Map raw documents
      final rawModules = snapshot.docs.map((doc) {
        final data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter out modules whose storage object no longer exists
      final List<Map<dynamic, dynamic>> filtered = [];
      for (final m in rawModules) {
        final exists = await _moduleFileExists(m);
        if (exists) {
          filtered.add(m);
        } else {
          print('🧹 Skipping removed module (missing storage): title=${m['title']} fileName=${m['fileName']}');
        }
      }
      return filtered;
    } catch (e) {
      print('❌ Error getting modules for student: $e');
      return [];
    }
  }

  // Add: Get modules for a specific section by name
  Future<List<Map<dynamic, dynamic>>> getStudentModulesForSectionName(String sectionName) async {
    try {
      QuerySnapshot snapshot = await _studentModulesCollection
          .where('section', isEqualTo: sectionName)
          .orderBy('uploadDate', descending: true)
          .orderBy('__name__', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting section modules by name: $e');
      return [];
    }
  }

  // Get modules by instructor
  Future<List<Map<dynamic, dynamic>>> getInstructorModules(String instructorId) async {
    try {
      print('🔍 getInstructorModules: Fetching modules for instructor: $instructorId');

      // First try the main modules collection WITHOUT orderBy to avoid index requirements
      final modulesSnapshot = await _modulesCollection
          .where('instructorId', isEqualTo: instructorId)
          .get();

      print('✅ Found ${modulesSnapshot.docs.length} modules in "modules" collection');

      List<Map<dynamic, dynamic>> modules = modulesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // If no modules found in main collection, try studentModules as fallback (also without orderBy)
      if (modules.isEmpty) {
        print('⚠️ No modules found in "modules" collection, checking "studentModules"...');

        final studentModulesSnapshot = await _studentModulesCollection
            .where('instructorId', isEqualTo: instructorId)
            .get();

        print('✅ Found ${studentModulesSnapshot.docs.length} modules in "studentModules" collection');

        if (studentModulesSnapshot.docs.isNotEmpty) {
          // Deduplicate by moduleId to avoid showing the same module multiple times
          final uniqueModules = <String, Map<dynamic, dynamic>>{};

          for (var doc in studentModulesSnapshot.docs) {
            final data = doc.data() as Map<dynamic, dynamic>;
            final moduleId = data['moduleId'] ?? doc.id;

            if (!uniqueModules.containsKey(moduleId)) {
              data['id'] = doc.id;
              uniqueModules[moduleId] = data;
            }
          }

          modules = uniqueModules.values.toList();
          print('✅ Returning ${modules.length} unique modules from studentModules');
        }
      }

      // Sort modules by uploadDate descending in memory
      modules.sort((a, b) {
        final aDateStr = a['uploadDate']?.toString();
        final bDateStr = b['uploadDate']?.toString();
        final aDate = aDateStr != null ? DateTime.tryParse(aDateStr) : null;
        final bDate = bDateStr != null ? DateTime.tryParse(bDateStr) : null;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return modules;
    } catch (e) {
      print('❌ Error getting instructor modules: $e');
      return [];
    }
  }

  // Get module by ID
  Future<Map<dynamic, dynamic>?> getModuleById(String moduleId) async {
    try {
      DocumentSnapshot doc = await _modulesCollection.doc(moduleId).get();
      if (doc.exists) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting module by ID: $e');
      return null;
    }
  }

  // Update module views/downloads
  Future<void> updateModuleStats(String moduleId, {bool isDownload = false}) async {
    try {
      if (isDownload) {
        await _modulesCollection.doc(moduleId).update({
          'downloads': FieldValue.increment(1),
        });
      } else {
        await _modulesCollection.doc(moduleId).update({
          'views': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error updating module stats: $e');
    }
  }

  // Delete module
  Future<bool> deleteModule(String moduleId) async {
    try {
      // Get module data first
      DocumentSnapshot doc = await _modulesCollection.doc(moduleId).get();
      if (doc.exists) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        
        // Delete from Firebase Storage
        try {
          final String? filePath = data['filePath']?.toString();
          if (filePath != null && filePath.isNotEmpty) {
            await _storage.ref(filePath).delete();
            print('🗑️ Storage file deleted: $filePath');
          } else {
            print('⚠️ No filePath stored on module; skipping storage delete');
          }
        } catch (e) {
          print('⚠️ Error deleting file from storage (continuing): $e');
        }

        // Delete from Firestore
        await _modulesCollection.doc(moduleId).delete();
        print('🗑️ Module document deleted: $moduleId');
        
        // Delete from studentModules (best-effort, tolerate permission issues)
        try {
          QuerySnapshot studentModules = await _studentModulesCollection
              .where('moduleId', isEqualTo: moduleId)
              .get();
          for (var sDoc in studentModules.docs) {
            await sDoc.reference.delete();
          }
          print('🗑️ Deleted ${studentModules.docs.length} studentModules documents for module: $moduleId');
        } catch (e) {
          print('⚠️ Could not delete studentModules entries (rules?): $e');
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting module: $e');
      return false;
    }
  }

  // Search modules
  Future<List<Map<dynamic, dynamic>>> searchModules(String query) async {
    try {
      QuerySnapshot snapshot = await _studentModulesCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .get();

      return snapshot.docs.map((doc) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error searching modules: $e');
      return [];
    }
  }

  // Get modules by file type
  Future<List<Map<dynamic, dynamic>>> getModulesByType(String fileType) async {
    try {
      QuerySnapshot snapshot = await _studentModulesCollection
          .where('fileExtension', isEqualTo: fileType.toLowerCase())
          .orderBy('uploadDate', descending: true)
          .orderBy('__name__', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting modules by type: $e');
      return [];
    }
  }

  // NEW: Get modules by type for a specific student
  Future<List<Map<dynamic, dynamic>>> getStudentModulesByTypeForStudent(String studentUid, String fileType) async {
    try {
      Query query = _studentModulesCollection
          .where('studentId', isEqualTo: studentUid)
          .where('fileExtension', isEqualTo: fileType.toLowerCase());

      QuerySnapshot snapshot;
      try {
        snapshot = await query.orderBy('uploadDate', descending: true).orderBy('__name__', descending: true).get();
      } catch (indexError) {
        print('⚠️ OrderBy failed, falling back without orderBy: $indexError');
        snapshot = await query.get();
      }

      final rawModules = snapshot.docs.map((doc) {
        final data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      final List<Map<dynamic, dynamic>> filtered = [];
      for (final m in rawModules) {
        final exists = await _moduleFileExists(m);
        if (exists) {
          filtered.add(m);
        } else {
          print('🧹 Skipping removed module (missing storage): title=${m['title']} fileName=${m['fileName']}');
        }
      }
      return filtered;
    } catch (e) {
      print('Error getting modules by type for student: $e');
      return [];
    }
  }

  // Helper: check if the backing storage file exists for a module
  Future<bool> _moduleFileExists(Map<dynamic, dynamic> module) async {
    try {
      // Prefer downloadURL if present (exact reference), otherwise build path
      final String? downloadURL = module['downloadURL']?.toString();
      Reference ref;
      if (downloadURL != null && downloadURL.isNotEmpty) {
        ref = _storage.refFromURL(downloadURL);
      } else {
        final String? title = module['title']?.toString();
        final String? fileName = module['fileName']?.toString();
        if (title == null || title.isEmpty || fileName == null || fileName.isEmpty) {
          return false;
        }
        ref = _storage.ref().child('modules/$title/$fileName');
      }
      await ref.getMetadata();
      return true;
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        // Expected when file was removed from storage; treat as non-existent
        return false;
      }
      // Other errors (permissions, network) – be conservative and treat as non-existent
      print('⚠️ Error checking module file existence: $e');
      return false;
    }
  }

  // Get modules by category
  Future<List<Map<dynamic, dynamic>>> getModulesByCategory(String category) async {
    try {
      // TEMPORARY: Remove complex orderBy to avoid index requirement
      QuerySnapshot snapshot = await _studentModulesCollection
          .where('category', isEqualTo: category)
          .where('fileExtension', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .get(); // Removed orderBy temporarily

      return snapshot.docs.map((doc) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting modules by category: $e');
      return [];
    }
  }

  // Get module statistics by category
  Future<Map<String, dynamic>> getModuleStatsByCategory(String category) async {
    try {
      print('🔍 getModuleStatsByCategory: Querying for category "$category"');
      print('🔍 Collection path: studentModules');
      print('🔍 Query filters: category="$category", status="active"');
      
      // TEMPORARY: Remove complex orderBy to avoid index requirement
      QuerySnapshot snapshot = await _studentModulesCollection
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .get(); // Removed orderBy temporarily

      int totalModules = snapshot.docs.length;
      print('📊 Found $totalModules modules for category "$category"');
      
      // Debug: Show what documents were found
      if (totalModules > 0) {
        print('📋 Documents found:');
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<dynamic, dynamic>;
          print('   - ID: ${doc.id}');
          print('     Title: ${data['title']}');
          print('     Category: ${data['category']}');
          print('     Status: ${data['status']}');
          print('     Instructor: ${data['fullName'] ?? data['instructorName']}');
        }
      } else {
        print('❌ No documents found for category "$category"');
        print('🔍 Checking if collection exists and has any documents...');
        
        // Check if collection has any documents at all
        try {
          final allDocs = await _studentModulesCollection.limit(1).get();
          print('📊 Total documents in studentModules collection: ${allDocs.docs.length}');
          
          if (allDocs.docs.isNotEmpty) {
            final sampleDoc = allDocs.docs.first.data() as Map<dynamic, dynamic>;
            print('📋 Sample document structure:');
            sampleDoc.forEach((key, value) {
              print('     $key: $value');
            });
          }
        } catch (e) {
          print('❌ Error checking collection: $e');
        }
      }
      
      // Calculate progress based on completed modules (you can enhance this logic)
      double progress = totalModules > 0 ? 0.3 : 0.0; // Placeholder progress

      return {
        'totalModules': totalModules,
        'progress': progress,
        'category': category,
      };
    } catch (e) {
      print('❌ Error getting module stats for category "$category": $e');
      print('❌ Error type: ${e.runtimeType}');
      return {
        'totalModules': 0,
        'progress': 0.0,
        'category': category,
      };
    }
  }

  // Get all categories with their module counts
  Future<Map<String, Map<String, dynamic>>> getAllCategoriesStats() async {
    try {
      print('🔄 getAllCategoriesStats: Starting...');
      
      final categories = [
        'Understanding Movements',
        'Musculoskeletal Basis', 
        'Discrete Skills',
        'Throwing & Catching',
        'Serial Skills',
        'Continuous Skills',
      ];

      Map<String, Map<String, dynamic>> categoryStats = {};
      
      for (String category in categories) {
        print('🔍 Checking category: $category');
        final stats = await getModuleStatsByCategory(category);
        print('📊 Category $category: ${stats['totalModules']} modules');
        categoryStats[category] = stats;
      }

      print('✅ getAllCategoriesStats: Completed with ${categoryStats.length} categories');
      return categoryStats;
    } catch (e) {
      print('❌ Error getting all categories stats: $e');
      return {};
    }
  }

  // Test method to check if modules can be read
  Future<void> testModuleAccess() async {
    try {
      print('🧪 TESTING MODULE ACCESS...');
      
      // Test 1: Check if collection exists
      print('🔍 Test 1: Checking if studentModules collection exists...');
      final testSnapshot = await _studentModulesCollection.limit(1).get();
      print('✅ Collection exists with ${testSnapshot.docs.length} documents');
      
      if (testSnapshot.docs.isNotEmpty) {
        final sampleDoc = testSnapshot.docs.first.data() as Map<dynamic, dynamic>;
        print('📋 Sample document:');
        sampleDoc.forEach((key, value) {
          print('   $key: $value');
        });
      }
      
      // Test 2: Try to read all modules
      print('🔍 Test 2: Trying to read all modules...');
      final allModules = await _studentModulesCollection.get();
      print('✅ Successfully read ${allModules.docs.length} modules');
      
      // Test 3: Try to read by category
      print('🔍 Test 3: Trying to read modules by category...');
      final categoryModules = await _studentModulesCollection
          .where('category', isEqualTo: 'Understanding Movements')
          .get();
      print('✅ Found ${categoryModules.docs.length} modules in "Understanding Movements" category');
      
    } catch (e) {
      print('❌ TEST FAILED: $e');
      print('❌ Error type: ${e.runtimeType}');
    }
  }

  // DEBUG: Check instructor modules in both collections
  Future<Map<String, dynamic>> debugInstructorModules(String instructorId) async {
    try {
      print('🔍 DEBUG: Checking modules for instructor: $instructorId');
      
      // Check modules collection
      print('📁 Checking "modules" collection...');
      final modulesSnapshot = await _modulesCollection
          .where('instructorId', isEqualTo: instructorId)
          .get();
      print('✅ Found ${modulesSnapshot.docs.length} modules in "modules" collection');
      
      if (modulesSnapshot.docs.isNotEmpty) {
        print('📋 Modules collection documents:');
        for (var doc in modulesSnapshot.docs) {
          final data = doc.data() as Map<dynamic, dynamic>;
          print('   - ID: ${doc.id}, Title: ${data['title']}, UploadDate: ${data['uploadDate']}');
        }
      }
      
      // Check studentModules collection
      print('📁 Checking "studentModules" collection...');
      final studentModulesSnapshot = await _studentModulesCollection
          .where('instructorId', isEqualTo: instructorId)
          .get();
      print('✅ Found ${studentModulesSnapshot.docs.length} modules in "studentModules" collection');
      
      if (studentModulesSnapshot.docs.isNotEmpty) {
        print('📋 StudentModules collection documents:');
        for (var doc in studentModulesSnapshot.docs) {
          final data = doc.data() as Map<dynamic, dynamic>;
          print('   - ID: ${doc.id}, Title: ${data['title']}, UploadDate: ${data['uploadDate']}');
        }
      }
      
      return {
        'modulesCount': modulesSnapshot.docs.length,
        'studentModulesCount': studentModulesSnapshot.docs.length,
        'modulesData': modulesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<dynamic, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList(),
        'studentModulesData': studentModulesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<dynamic, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList(),
      };
    } catch (e) {
      print('❌ DEBUG ERROR: $e');
      return {
        'error': e.toString(),
        'modulesCount': 0,
        'studentModulesCount': 0,
        'modulesData': [],
        'studentModulesCount': [],
      };
    }
  }
}


