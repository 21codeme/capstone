import 'package:cloud_firestore/cloud_firestore.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a multiple-choice quiz targeted at a specific course/year/section.
  /// Returns a map with { success: bool, id?: String, error?: String }.
  Future<Map<String, dynamic>> createMultipleChoiceQuiz({
    required String instructorId,
    required String course,
    required String yearLevel,
    required String section,
    required String title,
    String? instructions,
    required int timeLimitMinutes,
    required int pointsPerQuestion,
    required bool shuffleQuestions,
    required bool shuffleOptions,
    required List<Map<String, dynamic>> questions,
    String? topic,
    String? type,
    String? label,
  }) async {
    try {
      final quizData = {
        'type': type ?? 'multiple_choice',
        'label': label ?? 'Multiple Choice',
        'topic': topic ?? '',
        'instructorId': instructorId,
        'course': course.trim(),
        'year': yearLevel.trim(),
        'section': section.trim().toUpperCase(), // Normalize to uppercase for consistent matching
        'title': title.trim(),
        'instructions': (instructions ?? '').trim(),
        'timeLimitMinutes': timeLimitMinutes,
        'pointsPerQuestion': pointsPerQuestion,
        'shuffleQuestions': shuffleQuestions,
        'shuffleOptions': shuffleOptions,
        'questions': questions,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'visibility': 'section',
        'status': 'active',
      };

      final ref = await _firestore.collection('quizzes').add(quizData);
      return {
        'success': true,
        'id': ref.id,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Creates a multiple-choice quiz in the new `courseQuizzes` collection
  /// targeted to a specific course/year/section. This is used to validate
  /// saving to the new database partition.
  Future<Map<String, dynamic>> createTargetedCourseQuiz({
    required String instructorId,
    required String course,
    required String yearLevel,
    required String section,
    required String title,
    String? instructions,
    required int timeLimitMinutes,
    required int pointsPerQuestion,
    required bool shuffleQuestions,
    required bool shuffleOptions,
    required List<Map<String, dynamic>> questions,
    String? topic,
    String? type,
    String? label,
    String? quizId,
    String? mediaFolder,
    DateTime? availableFrom,
    DateTime? availableUntil,
  }) async {
    try {
      final quizData = {
        'type': type ?? 'multiple_choice',
        'label': label ?? 'Multiple Choice',
        'topic': topic ?? '',
        'instructorId': instructorId,
        'course': course.trim(),
        'year': yearLevel.trim(),
        'section': section.trim().toUpperCase(), // Normalize to uppercase for consistent matching
        'title': title.trim(),
        'instructions': (instructions ?? '').trim(),
        'timeLimitMinutes': timeLimitMinutes,
        'pointsPerQuestion': pointsPerQuestion,
        'shuffleQuestions': shuffleQuestions,
        'shuffleOptions': shuffleOptions,
        'questions': questions,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'visibility': 'section',
        'status': 'active',
        if (mediaFolder != null) 'mediaFolder': mediaFolder,
        if (availableFrom != null) 'availableFrom': Timestamp.fromDate(availableFrom),
        if (availableUntil != null) 'availableUntil': Timestamp.fromDate(availableUntil),
      };

      if (quizId != null && quizId.isNotEmpty) {
        final docRef = _firestore.collection('courseQuizzes').doc(quizId);
        await docRef.set(quizData);
        return {
          'success': true,
          'id': quizId,
        };
      } else {
        final ref = await _firestore.collection('courseQuizzes').add(quizData);
        return {
          'success': true,
          'id': ref.id,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Submits a student quiz attempt summary to Firestore under `studentScores`.
  /// Returns a map with { success: bool, id?: String, error?: String }.
  Future<Map<String, dynamic>> submitStudentQuizAttempt({
    required String studentId,
    required String quizId,
    required String quizTitle,
    required double score,
    required double maxScore,
    required double percentage,
    required bool passed,
    required List<Map<String, dynamic>> answers,
    required int timeTakenMinutes,
    String status = 'submitted',
    // Additional student details for tracking in studentScores
    String? studentName,
    String? course,
    String? year,
    String? section,
  }) async {
    try {
      // Determine lock document ID to enforce single attempt per quiz per student
      final String lockDocId = '${studentId}_$quizId';

      // Check if the student has already answered this quiz
      final lockDocRef = _firestore.collection('studentScores').doc(lockDocId);
      final existingLock = await lockDocRef.get();
      if (existingLock.exists) {
        final data = existingLock.data() as Map<String, dynamic>;
        final bool hasAnswered = (data['hasAnswered'] as bool?) ?? false;
        if (hasAnswered) {
          return {
            'success': false,
            'error': 'You have already answered this quiz.',
          };
        }
      }

      // Write a score record into studentScores for analytics/tracking
      // Use deterministic doc ID to enforce one record per student per quiz
      // Also include detailed answers so instructors can view them
      final scoreRecord = {
        'studentId': studentId,
        if (studentName != null) 'studentName': studentName,
        if (course != null) 'course': course,
        if (year != null) 'year': year,
        if (section != null) 'section': section,
        'quizId': quizId,
        'quizTitle': quizTitle,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'passed': passed,
        'timeTakenMinutes': timeTakenMinutes,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': status,
        'hasAnswered': true,
        'answers': answers, // Save detailed answers here too for instructor review
      };

      try {
        print('💾 Saving to studentScores with answers...');
        print('   Document ID: $lockDocId');
        print('   Answers count: ${answers.length}');
        print('   Answers preview: ${answers.take(2).toList()}');
        
        await lockDocRef.set(scoreRecord, SetOptions(merge: true));
        
        // Verify it was saved with answers
        final verifyScoreDoc = await lockDocRef.get();
        if (verifyScoreDoc.exists) {
          final verifyData = verifyScoreDoc.data() as Map<String, dynamic>?;
          final savedAnswers = verifyData?['answers'];
          if (savedAnswers != null && savedAnswers is List) {
            print('✅ Successfully saved to studentScores with ${savedAnswers.length} answers');
          } else {
            print('❌ WARNING: Answers were not saved to studentScores!');
            print('   Saved data keys: ${verifyData?.keys.toList()}');
          }
        }
      } catch (e) {
        print('❌ Error saving to studentScores: $e');
        return {
          'success': false,
          'error': 'studentScores.set denied: ${e.toString()}',
        };
      }

      // Also save detailed attempt to quizAttempts for instructor review
      // This is critical for instructor to view student answers
      try {
        if (answers.isEmpty) {
          print('⚠️ Warning: No answers to save for quiz $quizId');
        }
        
        final attemptData = {
          'studentId': studentId,
          'quizId': quizId,
          'quizTitle': quizTitle,
          'score': score,
          'maxScore': maxScore,
          'percentage': percentage,
          'passed': passed,
          'answers': answers, // Detailed answers for review
          'timeTakenMinutes': timeTakenMinutes,
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': status,
        };
        
        print('💾 Attempting to save to quizAttempts...');
        print('   Student: $studentId');
        print('   Quiz: $quizId');
        print('   Title: $quizTitle');
        print('   Answers count: ${answers.length}');
        
        final attemptRef = await _firestore.collection('quizAttempts').add(attemptData);
        
        // Verify it was saved
        final verifyDoc = await attemptRef.get();
        if (verifyDoc.exists) {
          print('✅ Successfully saved quiz attempt to quizAttempts: ${attemptRef.id}');
          print('   Verified: Document exists in database');
        } else {
          print('❌ ERROR: Document was not saved! Attempt ID: ${attemptRef.id}');
        }
      } catch (e, stackTrace) {
        // Log error but don't fail the submission
        print('❌ CRITICAL: Failed to save to quizAttempts: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Stack trace: $stackTrace');
        print('   This means instructor will NOT be able to view detailed answers!');
      }

      return {
        'success': true,
        'id': lockDocId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> logQuizAttempt({
    required String studentId,
    required String quizId,
    required String quizTitle,
    required double score,
    required double maxScore,
    required double percentage,
    required bool passed,
    required int attemptNumber,
  }) async {
    try {
      final data = {
        'studentId': studentId,
        'quizId': quizId,
        'quizTitle': quizTitle,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'passed': passed,
        'attemptNumber': attemptNumber,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('quizAttempts').add(data);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}