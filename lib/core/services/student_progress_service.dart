import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<double> calculateOverallProgress(String studentId) async {
    try {
      print('🔄 Calculating overall progress for student: $studentId');
      
      QuerySnapshot<Map<String, dynamic>> scoresQuery;
      try {
        scoresQuery = await _firestore
            .collection('studentScores')
            .where('studentId', isEqualTo: studentId)
            .where('hasAnswered', isEqualTo: true)
            .get();
      } catch (e) {
        print('⚠️ Fallback query for studentScores due to index: $e');
        scoresQuery = await _firestore
            .collection('studentScores')
            .where('studentId', isEqualTo: studentId)
            .get();
      }

      print('📊 Found ${scoresQuery.docs.length} total score documents');

      if (scoresQuery.docs.isEmpty) {
        print('⚠️ No score documents found for student');
        return 0.0;
      }

      double totalPercentage = 0.0;
      int includedCount = 0;

      final dayRegex = RegExp(r"_day[1-5]$", caseSensitive: false);
      for (final doc in scoresQuery.docs) {
        final data = doc.data();
        final String quizId = (data['quizId'] as String?) ?? '';
        final bool hasAnswered = (data['hasAnswered'] as bool?) ?? false;
        
        print('📝 Processing quiz: $quizId, hasAnswered: $hasAnswered');
        
        if (!hasAnswered) {
          print('⏭️ Skipping - not answered');
          continue;
        }

        final bool isMini = dayRegex.hasMatch(quizId);
        final bool isFinal = quizId.toLowerCase().contains('final_quiz');
        
        print('🔍 Quiz patterns - isMini: $isMini, isFinal: $isFinal');
        
        if (!isMini && !isFinal) {
          print('⏭️ Skipping - not a learning topic quiz');
          continue; // skip non-topic quizzes
        }

        double percentage;
        if (data['percentage'] is num) {
          percentage = (data['percentage'] as num).toDouble();
        } else {
          final double score = (data['score'] is num) ? (data['score'] as num).toDouble() : 0.0;
          final double maxScore = (data['maxScore'] is num) ? (data['maxScore'] as num).toDouble() : 0.0;
          percentage = maxScore > 0 ? (score / maxScore) * 100.0 : 0.0;
        }

        print('✅ Including quiz: $quizId with percentage: $percentage%');
        totalPercentage += percentage;
        includedCount++;
      }

      print('📈 Total included quizzes: $includedCount');
      print('📊 Total percentage sum: $totalPercentage');

      if (includedCount == 0) {
        print('⚠️ No learning topic quizzes found');
        return 0.0;
      }
      
      final avgPercent = totalPercentage / includedCount; // 0..100
      final result = (avgPercent / 100.0).clamp(0.0, 1.0);
      
      print('🎯 Final progress calculation: $result (${avgPercent.toStringAsFixed(2)}%)');
      return result;
    } catch (e) {
      print('❌ Error calculating overall progress from quizzes: $e');
      return 0.0;
    }
  }

  /// Get module-based progress data for the student
  Future<Map<String, dynamic>> getModuleProgressData(String studentId) async {
    try {
      // Get all module progress for the student
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .orderBy('lastAccessed', descending: true)
        .get();

      if (progressQuery.docs.isEmpty) {
        return {
          'totalModules': 0,
          'averageProgress': 0.0,
          'totalActivities': 0,
          'recentModules': [],
        };
      }

      List<Map<String, dynamic>> recentModules = [];
      Map<String, List<double>> subjectProgress = {};
      double totalProgress = 0;
      int totalModules = progressQuery.docs.length;

      for (var doc in progressQuery.docs) {
        final data = doc.data();
        String moduleId = data['moduleId'] ?? '';
        String moduleTitle = data['moduleTitle'] ?? 'Unknown Module';
        String subject = data['subject'] ?? 'General';
        double progress = (data['progressPercentage'] ?? 0.0) as double;
        totalProgress += progress;

        // Add to recent modules (last 10)
        if (recentModules.length < 10) {
          recentModules.add({
            'moduleTitle': moduleTitle,
            'subject': subject,
            'progress': progress,
            'lastAccessed': data['lastAccessed'],
            'moduleId': moduleId,
          });
        }

        // Group by subject for progress tracking
        if (!subjectProgress.containsKey(subject)) {
          subjectProgress[subject] = [];
        }
        subjectProgress[subject]!.add(progress);
      }

      // Calculate subject averages
      Map<String, double> subjectAverages = {};
      subjectProgress.forEach((subject, progressList) {
        double average = progressList.reduce((a, b) => a + b) / progressList.length;
        subjectAverages[subject] = average;
      });

      double averageProgress = totalProgress / totalModules;

      return {
        'totalModules': totalModules,
        'averageProgress': averageProgress,
        'totalActivities': totalModules,
        'recentModules': recentModules,
        'subjectProgress': subjectAverages,
      };
    } catch (e) {
      print('❌ Error getting module progress data: $e');
      return {
        'totalModules': 0,
        'averageProgress': 0.0,
        'totalActivities': 0,
        'recentModules': [],
        'subjectProgress': {},
      };
    }
  }

  /// Get weekly streak based on module access
  static Future<int> getWeeklyStreak(String studentId) async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(Duration(days: 7));

      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .where('lastAccessed', isGreaterThan: oneWeekAgo.toIso8601String())
        .get();

      // Count unique days with module access
      Set<String> uniqueDays = {};
      for (var doc in progressQuery.docs) {
        final data = doc.data();
        final lastAccessed = DateTime.parse(data['lastAccessed']);
        final dayKey = '${lastAccessed.year}-${lastAccessed.month}-${lastAccessed.day}';
        uniqueDays.add(dayKey);
      }

      return uniqueDays.length;
    } catch (e) {
      print('❌ Error getting weekly streak: $e');
      return 0;
    }
  }

  /// Get recent activities for the student
  static Future<List<Map<String, dynamic>>> getRecentActivities(String studentId) async {
    try {
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .orderBy('lastAccessed', descending: true)
        .limit(10)
        .get();

      List<Map<String, dynamic>> activities = [];
      for (var doc in progressQuery.docs) {
        final data = doc.data();
        activities.add({
          'type': 'module_accessed',
          'title': data['moduleTitle'] ?? 'Module Accessed',
          'description': 'Progress: ${data['progressPercentage']?.toStringAsFixed(1)}%',
          'timestamp': data['lastAccessed'],
          'progress': data['progressPercentage'],
        });
      }

      return activities;
    } catch (e) {
      print('❌ Error getting recent activities: $e');
      return [];
    }
  }

  /// Convert progress to points based on completion
  static int convertProgressToPoints(double progressPercentage) {
    if (progressPercentage >= 100) return 100;
    if (progressPercentage >= 90) return 90;
    if (progressPercentage >= 80) return 80;
    if (progressPercentage >= 70) return 70;
    if (progressPercentage >= 60) return 60;
    if (progressPercentage >= 50) return 50;
    if (progressPercentage >= 40) return 40;
    if (progressPercentage >= 30) return 30;
    if (progressPercentage >= 20) return 20;
    if (progressPercentage >= 10) return 10;
    return 0;
  }

  /// Get comprehensive student progress data
  static Future<Map<String, dynamic>> getStudentProgressData(String studentId) async {
    try {
      // Get all module progress for the student
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .orderBy('lastAccessed', descending: true)
        .get();

      if (progressQuery.docs.isEmpty) {
        return {
          'totalModules': 0,
          'averageProgress': 0.0,
          'totalPoints': 0,
          'weeklyStreak': 0,
          'recentActivities': [],
        };
      }

      double totalProgress = 0;
      int totalPoints = 0;
      int totalModules = progressQuery.docs.length;

      for (var doc in progressQuery.docs) {
        final data = doc.data();
        final progress = (data['progressPercentage'] ?? 0.0) as double;
        totalProgress += progress;
        totalPoints += convertProgressToPoints(progress);
      }

      double averageProgress = totalProgress / totalModules;
      int weeklyStreak = await getWeeklyStreak(studentId);
      List<Map<String, dynamic>> recentActivities = await getRecentActivities(studentId);

      return {
        'totalModules': totalModules,
        'averageProgress': averageProgress,
        'totalPoints': totalPoints,
        'weeklyStreak': weeklyStreak,
        'recentActivities': recentActivities,
      };
    } catch (e) {
      print('❌ Error getting student progress data: $e');
      return {
        'totalModules': 0,
        'averageProgress': 0.0,
        'totalPoints': 0,
        'weeklyStreak': 0,
        'recentActivities': [],
      };
    }
  }

  /// Get student module activities with progress
  Future<List<Map<dynamic, dynamic>>> getStudentModuleActivities(String studentId, String instructorId) async {
    try {
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .orderBy('lastAccessed', descending: true)
        .limit(20)
        .get();

      List<Map<dynamic, dynamic>> activities = [];
      for (var doc in progressQuery.docs) {
        final data = doc.data();
        activities.add({
          'type': 'module',
          'moduleId': data['moduleId'] ?? '',
          'title': data['moduleTitle'] ?? 'Unknown Module',
          'progress': data['progressPercentage'] ?? 0.0,
          'lastAccessed': data['lastAccessed'],
          'timeSpent': data['timeSpentMinutes'] ?? 0,
          'completed': (data['progressPercentage'] ?? 0.0) >= 100.0,
        });
      }

      return activities;
    } catch (e) {
      print('❌ Error getting student module activities: $e');
      return [];
    }
  }

  /// Get instructor's student progress overview
  static Future<List<Map<String, dynamic>>> getInstructorStudentProgress(String instructorId) async {
    try {
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .orderBy('lastAccessed', descending: true)
        .get();

      Map<String, List<double>> studentProgress = {};
      
      for (var doc in progressQuery.docs) {
        final data = doc.data();
        final studentId = data['studentId'] ?? '';
        final progress = (data['progressPercentage'] ?? 0.0) as double;
        
        if (!studentProgress.containsKey(studentId)) {
          studentProgress[studentId] = [];
        }
        studentProgress[studentId]!.add(progress);
      }

      List<Map<String, dynamic>> progressData = [];
      studentProgress.forEach((studentId, progressList) {
        double averageProgress = progressList.reduce((a, b) => a + b) / progressList.length;
        progressData.add({
          'studentId': studentId,
          'averageProgress': averageProgress,
          'totalModules': progressList.length,
          'lastActivity': DateTime.now().toIso8601String(),
        });
      });

      return progressData;
    } catch (e) {
      print('❌ Error getting instructor student progress: $e');
      return [];
    }
  }

  /// Add module activity to student progress
  Future<void> addModuleActivity({
    required String studentId,
    required String instructorId,
    required String moduleId,
    required String moduleTitle,
    required double progressPercentage,
    required int timeSpentMinutes,
  }) async {
    try {
      // This method is called when a module is accessed
      // The progress is automatically calculated in getModuleProgressData
      print('✅ Module activity added: $moduleTitle - Progress: $progressPercentage%');
    } catch (e) {
      print('❌ Error adding module activity: $e');
    }
  }

  /// Get student quiz attempts for Activity Progress
  /// Returns latest attempts with title and score details
  Future<List<Map<dynamic, dynamic>>> getStudentLearningActivities(
    String studentId,
    String instructorId,
  ) async {
    try {
      print('🔍 Fetching learning activities for studentId: $studentId');
      // Fetch summarized quiz records from studentScores (one per quiz per student)
      QuerySnapshot<Map<String, dynamic>> attemptsQuery;
      try {
        attemptsQuery = await _firestore
            .collection('studentScores')
            .where('studentId', isEqualTo: studentId)
            .where('hasAnswered', isEqualTo: true)
            .orderBy('submittedAt', descending: true)
            .limit(10)
            .get();
        print('📊 Found ${attemptsQuery.docs.length} quiz attempts (indexed query)');
      } catch (indexError) {
        // If composite index for (studentId, hasAnswered, submittedAt) is missing, fall back
        print('⚠️ Indexed query failed, falling back without orderBy: $indexError');
        attemptsQuery = await _firestore
            .collection('studentScores')
            .where('studentId', isEqualTo: studentId)
            .where('hasAnswered', isEqualTo: true)
            .get();
        print('📊 Found ${attemptsQuery.docs.length} quiz attempts (fallback query)');
      }

      final activities = attemptsQuery.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        final double score = (data['score'] ?? 0).toDouble();
        final double maxScore = (data['maxScore'] ?? 0).toDouble();
        final double percentage = (data['percentage'] != null)
            ? (data['percentage'] as num).toDouble()
            : (maxScore > 0 ? (score / maxScore) * 100 : 0.0);
        
        print('📝 Processing quiz: ${data['quizTitle']} - Score: $score/$maxScore ($percentage%)');
        
        return {
          'id': doc.id,
          'quizId': data['quizId'] ?? '',
          'title': data['quizTitle'] ?? 'Quiz',
          'type': 'Quiz',
          'percentage': percentage,
          'score': score,
          'maxScore': maxScore,
          'status': data['status'] ?? 'submitted',
          'completedAt': data['submittedAt'] ?? data['updatedAt'],
          'timeTaken': data['timeTakenMinutes'] ?? 0,
        };
      }).toList();
      
      // If we used the fallback (no orderBy), sort client-side by completedAt desc and cap to 10
      activities.sort((a, b) {
        final aTs = a['completedAt'];
        final bTs = b['completedAt'];
        // Both are Firestore Timestamps or null; handle nulls last
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        try {
          final aMillis = (aTs is Timestamp) ? aTs.millisecondsSinceEpoch : 0;
          final bMillis = (bTs is Timestamp) ? bTs.millisecondsSinceEpoch : 0;
          return bMillis.compareTo(aMillis);
        } catch (_) {
          return 0;
        }
      });
      if (activities.length > 10) {
        activities.removeRange(10, activities.length);
      }
      
      print('✅ Returning ${activities.length} learning activities');
      return activities;
    } catch (e) {
      print('❌ Error getting student quiz attempts: $e');
      return [];
    }
  }

  /// Get student performance trends (replaces quiz performance trends)
  Future<List<Map<String, dynamic>>> getStudentPerformanceTrends(
    String studentId,
    String instructorId,
  ) async {
    try {
      // Get module progress over time to show performance trends
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .orderBy('lastAccessed', descending: false)
        .get();

      return progressQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'date': data['lastAccessed'],
          'progress': data['progressPercentage'] ?? 0.0,
          'moduleTitle': data['moduleTitle'] ?? 'Module',
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting student performance trends: $e');
      return [];
    }
  }

  /// Count completed task activities for a student (from studentScores)
  /// Counts documents where the student has answered/submitted
  Future<int> getCompletedTaskActivityCount(String studentId) async {
    try {
      final query = await _firestore
          .collection('studentScores')
          .where('studentId', isEqualTo: studentId)
          .where('hasAnswered', isEqualTo: true)
          .get();

      return query.docs.length;
    } catch (e) {
      print('❌ Error counting completed task activities: $e');
      return 0;
    }
  }

  /// Get progress status based on percentage
  String getProgressStatus(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Good';
    if (percentage >= 50) return 'Average';
    if (percentage >= 25) return 'Needs Improvement';
    return 'Poor';
  }

  /// Get progress color based on percentage
  int getProgressColor(double percentage) {
    if (percentage >= 90) return 0xFF4CAF50; // Green
    if (percentage >= 75) return 0xFF8BC34A; // Light Green
    if (percentage >= 50) return 0xFFFFC107; // Amber
    if (percentage >= 25) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Get progress data for a student
  Future<Map<dynamic, dynamic>> getProgressData(String studentId) async {
    try {
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .get();

      if (progressQuery.docs.isEmpty) {
        return {
          'totalActivities': 0,
          'completedActivities': 0,
          'progressPercentage': 0.0,
        };
      }

      int totalActivities = progressQuery.docs.length;
      int completedActivities = progressQuery.docs
          .where((doc) => (doc.data()['progressPercentage'] ?? 0.0) >= 100.0)
          .length;
      
      double averageProgress = progressQuery.docs
          .map((doc) => (doc.data()['progressPercentage'] ?? 0.0) as double)
          .reduce((a, b) => a + b) / totalActivities;

      return {
        'totalActivities': totalActivities,
        'completedActivities': completedActivities,
        'progressPercentage': averageProgress,
      };
    } catch (e) {
      print('❌ Error getting progress data: $e');
      return {
        'totalActivities': 0,
        'completedActivities': 0,
        'progressPercentage': 0.0,
      };
    }
  }

  /// Get student progress summary for instructor view
  Future<Map<String, dynamic>> getStudentProgressSummary(String studentId, String instructorId) async {
    try {
      final progressQuery = await _firestore
        .collection('moduleProgress')
        .where('studentId', isEqualTo: studentId)
        .where('instructorId', isEqualTo: instructorId)
        .get();

      if (progressQuery.docs.isEmpty) {
        return {
          'totalModules': 0,
          'completedModules': 0,
          'totalQuizzes': 0,
          'completedQuizzes': 0,
          'averageScore': 0.0,
          'progressPercentage': 0.0,
        };
      }

      int totalModules = progressQuery.docs.length;
      int completedModules = progressQuery.docs
          .where((doc) => (doc.data()['progressPercentage'] ?? 0.0) >= 100.0)
          .length;
      
      double averageProgress = progressQuery.docs
          .map((doc) => (doc.data()['progressPercentage'] ?? 0.0) as double)
          .reduce((a, b) => a + b) / totalModules;

      return {
        'totalModules': totalModules,
        'completedModules': completedModules,
        'totalQuizzes': totalModules, // Using modules as quiz equivalent
        'completedQuizzes': completedModules,
        'averageScore': averageProgress,
        'progressPercentage': averageProgress,
      };
    } catch (e) {
      print('❌ Error getting student progress summary: $e');
      return {
        'totalModules': 0,
        'completedModules': 0,
        'totalQuizzes': 0,
        'completedQuizzes': 0,
        'averageScore': 0.0,
        'progressPercentage': 0.0,
      };
    }
  }
}
