import 'package:cloud_firestore/cloud_firestore.dart';

class SectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new section
  Future<String> createSection({
    required String sectionName,
    required String instructorId,
    String? description,
    int? maxStudents,
    String? yearLevel,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('sections').add({
        'sectionName': sectionName,
        'instructorId': instructorId,
        'description': description ?? '',
        'maxStudents': maxStudents ?? 50,
        'currentStudents': 0,
        'yearLevel': yearLevel, // optional until data is fully migrated
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create section: $e');
    }
  }

  // Get sections by instructor
  Stream<QuerySnapshot> getSectionsByInstructor(String instructorId) {
    return _firestore
        .collection('sections')
        .where('instructorId', isEqualTo: instructorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get section by ID
  Future<DocumentSnapshot> getSectionById(String sectionId) {
    return _firestore.collection('sections').doc(sectionId).get();
  }

  // Enroll student in a section
  Future<void> enrollStudentInSection({
    required String studentId,
    required String sectionId,
    required String instructorId,
  }) async {
    try {
      // Check if section exists and belongs to instructor
      DocumentSnapshot sectionDoc = await getSectionById(sectionId);
      if (!sectionDoc.exists) {
        throw Exception('Section not found');
      }
      
      Map<dynamic, dynamic> sectionData = sectionDoc.data() as Map<dynamic, dynamic>;
      if (sectionData['instructorId'] != instructorId) {
        throw Exception('Unauthorized access to section');
      }

      // Check if student is already enrolled
      QuerySnapshot existingEnrollment = await _firestore
          .collection('sectionEnrollments')
          .where('studentId', isEqualTo: studentId)
          .where('sectionId', isEqualTo: sectionId)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        throw Exception('Student is already enrolled in this section');
      }

      // Create enrollment
      await _firestore.collection('sectionEnrollments').add({
        'studentId': studentId,
        'sectionId': sectionId,
        'instructorId': instructorId,
        'enrolledAt': Timestamp.now(),
        'status': 'active',
      });

      // Update section student count
      await sectionDoc.reference.update({
        'currentStudents': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      // Update student progress with section info
      await _updateStudentProgressSection(studentId, instructorId, sectionId);
    } catch (e) {
      throw Exception('Failed to enroll student: $e');
    }
  }

  // Remove student from section
  Future<void> removeStudentFromSection({
    required String studentId,
    required String sectionId,
    required String instructorId,
  }) async {
    try {
      // Check if section exists and belongs to instructor
      DocumentSnapshot sectionDoc = await getSectionById(sectionId);
      if (!sectionDoc.exists) {
        throw Exception('Section not found');
      }
      
      Map<dynamic, dynamic> sectionData = sectionDoc.data() as Map<dynamic, dynamic>;
      if (sectionData['instructorId'] != instructorId) {
        throw Exception('Unauthorized access to section');
      }

      // Find and remove enrollment
      QuerySnapshot enrollmentQuery = await _firestore
          .collection('sectionEnrollments')
          .where('studentId', isEqualTo: studentId)
          .where('sectionId', isEqualTo: sectionId)
          .get();

      if (enrollmentQuery.docs.isNotEmpty) {
        await enrollmentQuery.docs.first.reference.delete();
        
        // Update section student count
        await sectionDoc.reference.update({
          'currentStudents': FieldValue.increment(-1),
          'updatedAt': Timestamp.now(),
        });

        // Remove section info from student progress
        await _removeStudentProgressSection(studentId, instructorId);
      }
    } catch (e) {
      throw Exception('Failed to remove student: $e');
    }
  }

  // Get students in a section
  Future<List<Map<dynamic, dynamic>>> getStudentsInSection(String sectionId) async {
    try {
      QuerySnapshot enrollments = await _firestore
          .collection('sectionEnrollments')
          .where('sectionId', isEqualTo: sectionId)
          .where('status', isEqualTo: 'active')
          .get();

      List<Map<dynamic, dynamic>> students = [];
      
      for (DocumentSnapshot enrollment in enrollments.docs) {
        Map<dynamic, dynamic> enrollmentData = enrollment.data() as Map<dynamic, dynamic>;
        String studentId = enrollmentData['studentId'];
        
        // Get student details
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(studentId)
            .get();
        
        if (userDoc.exists) {
          Map<dynamic, dynamic> userData = userDoc.data() as Map<dynamic, dynamic>;
          students.add({
            'studentId': studentId,
            'studentName': userData['displayName'] ?? 'Unknown Student',
            'studentEmail': userData['email'] ?? 'No Email',
            'enrolledAt': enrollmentData['enrolledAt'],
          });
        }
      }
      
      return students;
    } catch (e) {
      throw Exception('Failed to get students in section: $e');
    }
  }

  // Get students organized by sections for an instructor
  Future<Map<String, List<Map<dynamic, dynamic>>>> getStudentsBySection(String instructorId) async {
    try {
      // Get all sections for this instructor
      QuerySnapshot sectionsQuery = await _firestore
          .collection('sections')
          .where('instructorId', isEqualTo: instructorId)
          .get();

      Map<String, List<Map<dynamic, dynamic>>> studentsBySection = {};
      
      for (DocumentSnapshot sectionDoc in sectionsQuery.docs) {
        Map<dynamic, dynamic> sectionData = sectionDoc.data() as Map<dynamic, dynamic>;
        String sectionName = sectionData['sectionName'];
        String sectionId = sectionDoc.id;
        
        // Get students in this section
        List<Map<dynamic, dynamic>> students = await getStudentsInSection(sectionId);
        
        if (students.isNotEmpty) {
          studentsBySection[sectionName] = students;
        }
      }
      
      return studentsBySection;
    } catch (e) {
      throw Exception('Failed to get students by section: $e');
    }
  }

  // Update student progress with section information
  Future<void> _updateStudentProgressSection(String studentId, String instructorId, String sectionId) async {
    try {
      // Get section name
      DocumentSnapshot sectionDoc = await getSectionById(sectionId);
      if (sectionDoc.exists) {
        Map<dynamic, dynamic> sectionData = sectionDoc.data() as Map<dynamic, dynamic>;
        String sectionName = sectionData['sectionName'];
        
        // Update student progress
        QuerySnapshot progressQuery = await _firestore
            .collection('studentProgress')
            .where('studentId', isEqualTo: studentId)
            .where('instructorId', isEqualTo: instructorId)
            .get();

        if (progressQuery.docs.isNotEmpty) {
          await progressQuery.docs.first.reference.update({
            'sectionId': sectionId,
            'sectionName': sectionName,
            'updatedAt': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      print('Failed to update student progress section: $e');
    }
  }

  // Remove section information from student progress
  Future<void> _removeStudentProgressSection(String studentId, String instructorId) async {
    try {
      QuerySnapshot progressQuery = await _firestore
          .collection('studentProgress')
          .where('studentId', isEqualTo: studentId)
          .where('instructorId', isEqualTo: instructorId)
          .get();

      if (progressQuery.docs.isNotEmpty) {
        await progressQuery.docs.first.reference.update({
          'sectionId': FieldValue.delete(),
          'sectionName': FieldValue.delete(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Failed to remove student progress section: $e');
    }
  }

  // Get section statistics
  Future<Map<dynamic, dynamic>> getSectionStatistics(String sectionId) async {
    try {
      DocumentSnapshot sectionDoc = await getSectionById(sectionId);
      if (!sectionDoc.exists) {
        return {
          'totalStudents': 0,
          'averageProgress': 0,
          'activeStudents': 0,
        };
      }

      Map<dynamic, dynamic> sectionData = sectionDoc.data() as Map<dynamic, dynamic>;
      int totalStudents = sectionData['currentStudents'] ?? 0;

      // Get student progress for this section
      QuerySnapshot progressQuery = await _firestore
          .collection('studentProgress')
          .where('sectionId', isEqualTo: sectionId)
          .get();

      if (progressQuery.docs.isEmpty) {
        return {
          'totalStudents': totalStudents,
          'averageProgress': 0,
          'activeStudents': 0,
        };
      }

      double totalProgress = 0;
      int activeStudents = 0;
      DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      for (DocumentSnapshot doc in progressQuery.docs) {
        Map<dynamic, dynamic> data = doc.data() as Map<dynamic, dynamic>;
        totalProgress += (data['averageProgress'] ?? 0);
        
        if (data['lastActivity'] != null &&
            (data['lastActivity'] as Timestamp).toDate().isAfter(thirtyDaysAgo)) {
          activeStudents++;
        }
      }

      double averageProgress = totalStudents > 0 ? totalProgress / totalStudents : 0;

      return {
        'totalStudents': totalStudents,
        'averageProgress': averageProgress,
        'activeStudents': activeStudents,
      };
    } catch (e) {
      throw Exception('Failed to get section statistics: $e');
    }
  }
}
