import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Service for creating users with custom UIDs (student IDs)
/// This aligns with the Cloud Functions approach
class FirebaseAdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new user with Firebase Auth UID as the document ID
  /// This matches the Cloud Functions implementation
  Future<UserCredential?> createUserWithStudentId({
    required String email,
    required String password,
    required String displayName,
    required bool isStudent,
    String? firstName,
    String? middleName,
    String? lastName,
    int? age,
    String? gender,
    String? course,
    String? year,
    String? section,
    double? bmi,
  }) async {
    try {
      print('🔐 Creating Firebase Auth account...');

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create Firebase Auth account');
      }

      final userId = userCredential.user!.uid;
      print('✅ Firebase Auth account created successfully: $userId');

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);

      // Create Firestore document using the Firebase Auth UID as document ID
      final userData = <String, dynamic>{
        'uid': userId, // Use Firebase Auth UID as the primary identifier
        'email': email,
        'displayName': displayName.trim(),
        'isStudent': isStudent,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'profilePicture': '',
        'phoneNumber': '',
        'accountStatus': 'active',
        'emailVerified': false,
      };

      // Add optional fields
      if (firstName != null && firstName.trim().isNotEmpty) {
        userData['firstName'] = firstName.trim();
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        userData['lastName'] = lastName.trim();
      }
      if (middleName != null && middleName.trim().isNotEmpty) {
        userData['middleName'] = middleName.trim();
      }
      if (age != null && age > 0) {
        userData['age'] = age;
      }
      if (gender != null && gender.trim().isNotEmpty) {
        userData['gender'] = gender.trim();
      }
      if (course != null && course.trim().isNotEmpty) {
        userData['course'] = course.trim();
      }
      if (year != null && year.trim().isNotEmpty) {
        userData['year'] = year.trim();
      }
      if (section != null && section.trim().isNotEmpty) {
        userData['section'] = section.trim();
      }
      if (bmi != null && bmi > 0) {
        userData['bmi'] = bmi;
      }

      await _firestore.collection('users').doc(userId).set(userData);
      print('✅ User created with Firebase Auth UID as document ID: $userId');

      return userCredential;
    } catch (e) {
      print('❌ Error creating user with student ID: $e');
      rethrow;
    }
  }



  /// Get user by Firebase Auth UID (which is now the document ID)
  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting user by UID: $e');
      return null;
    }
  }

  /// Get Firebase Auth UID from email
  Future<String?> getUidByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id; // Document ID is the Firebase Auth UID
      }
      return null;
    } catch (e) {
      print('❌ Error getting UID by email: $e');
      return null;
    }
  }
}