import 'module.dart';
import 'user.dart';

class StudentDashboard {
  final String studentId;
  final String studentName;
  final String course;
  final int yearLevel;
  final String section;
  final List<Module> recentModules;
  final DashboardStats stats;
  final List<RecentActivity> recentActivities;

  StudentDashboard({
    required this.studentId,
    required this.studentName,
    required this.course,
    required this.yearLevel,
    required this.section,
    required this.recentModules,
    required this.stats,
    required this.recentActivities,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    return StudentDashboard(
      studentId: json['student_id'],
      studentName: json['student_name'],
      course: json['course'],
      yearLevel: json['year_level'],
      section: json['section'],
      recentModules: (json['recent_modules'] as List)
          .map((m) => Module.fromJson(m))
          .toList(),
      stats: DashboardStats.fromJson(json['stats']),
      recentActivities: (json['recent_activities'] as List)
          .map((a) => RecentActivity.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'course': course,
      'year_level': yearLevel,
      'section': section,
      'recent_modules': recentModules.map((m) => m.toJson()).toList(),
      'stats': stats.toJson(),
      'recent_activities': recentActivities.map((a) => a.toJson()).toList(),
    };
  }
}

class InstructorDashboard {
  final String instructorId;
  final String instructorName;
  final String department;
  final String specialization;
  final List<Module> recentModules;
  final List<Student> recentStudents;
  final DashboardStats stats;
  final List<RecentActivity> recentActivities;

  InstructorDashboard({
    required this.instructorId,
    required this.instructorName,
    required this.department,
    required this.specialization,
    required this.recentModules,
    required this.recentStudents,
    required this.stats,
    required this.recentActivities,
  });

  factory InstructorDashboard.fromJson(Map<String, dynamic> json) {
    return InstructorDashboard(
      instructorId: json['instructor_id'],
      instructorName: json['instructor_name'],
      department: json['department'],
      specialization: json['specialization'],
      recentModules: (json['recent_modules'] as List)
          .map((m) => Module.fromJson(m))
          .toList(),
      recentStudents: (json['recent_students'] as List)
          .map((s) => Student.fromJson(s))
          .toList(),
      stats: DashboardStats.fromJson(json['stats']),
      recentActivities: (json['recent_activities'] as List)
          .map((a) => RecentActivity.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'department': department,
      'specialization': specialization,
      'recent_modules': recentModules.map((m) => m.toJson()).toList(),
      'recent_students': recentStudents.map((s) => s.toJson()).toList(),
      'stats': stats.toJson(),
      'recent_activities': recentActivities.map((a) => a.toJson()).toList(),
    };
  }
}

class DashboardStats {
  final int totalModules;
  final int completedModules;
  final int thisWeekModules;
  final double overallProgress;

  DashboardStats({
    required this.totalModules,
    required this.completedModules,
    required this.thisWeekModules,
    required this.overallProgress,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalModules: json['total_modules'] ?? 0,
      completedModules: json['completed_modules'] ?? 0,
      thisWeekModules: json['this_week_modules'] ?? 0,
      overallProgress: (json['overall_progress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_modules': totalModules,
      'completed_modules': completedModules,
      'this_week_modules': thisWeekModules,
      'overall_progress': overallProgress,
    };
  }

  double get moduleCompletionRate => 
      totalModules > 0 ? (completedModules / totalModules) * 100 : 0.0;
}

class RecentActivity {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? relatedEntityId;
  final String? relatedEntityType;

  RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      relatedEntityId: json['related_entity_id'],
      relatedEntityType: json['related_entity_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
    };
  }
}

class DashboardAnalytics {
  final String userId;
  final String period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> metrics;

  DashboardAnalytics({
    required this.userId,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.metrics,
  });

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    return DashboardAnalytics(
      userId: json['user_id'],
      period: json['period'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      metrics: Map<String, dynamic>.from(json['metrics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'period': period,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'metrics': metrics,
    };
  }
}

class StudentProgress {
  final String studentId;
  final List<ModuleProgress> moduleProgress;
  final DashboardStats overallStats;
  final List<String> achievements;
  final DateTime lastUpdated;

  StudentProgress({
    required this.studentId,
    required this.moduleProgress,
    required this.overallStats,
    required this.achievements,
    required this.lastUpdated,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      studentId: json['student_id'],
      moduleProgress: (json['module_progress'] as List)
          .map((m) => ModuleProgress.fromJson(m))
          .toList(),
      overallStats: DashboardStats.fromJson(json['overall_stats']),
      achievements: List<String>.from(json['achievements'] ?? []),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'module_progress': moduleProgress.map((m) => m.toJson()).toList(),
      'overall_stats': overallStats.toJson(),
      'achievements': achievements,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class StudentAnalytics {
  final String studentId;
  final Map<String, double> weeklyProgress;
  final Map<String, double> monthlyProgress;
  final List<String> strengths;
  final List<String> areasForImprovement;
  final Map<String, int> timeSpentBySubject;
  final Map<String, double> performanceBySubject;

  StudentAnalytics({
    required this.studentId,
    required this.weeklyProgress,
    required this.monthlyProgress,
    required this.strengths,
    required this.areasForImprovement,
    required this.timeSpentBySubject,
    required this.performanceBySubject,
  });

  factory StudentAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentAnalytics(
      studentId: json['student_id'],
      weeklyProgress: Map<String, double>.from(json['weekly_progress']),
      monthlyProgress: Map<String, double>.from(json['monthly_progress']),
      strengths: List<String>.from(json['strengths'] ?? []),
      areasForImprovement: List<String>.from(json['areas_for_improvement'] ?? []),
      timeSpentBySubject: Map<String, int>.from(json['time_spent_by_subject']),
      performanceBySubject: Map<String, double>.from(json['performance_by_subject']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'weekly_progress': weeklyProgress,
      'monthly_progress': monthlyProgress,
      'strengths': strengths,
      'areas_for_improvement': areasForImprovement,
      'time_spent_by_subject': timeSpentBySubject,
      'performance_by_subject': performanceBySubject,
    };
  }
}

class ModuleAnalytics {
  final String moduleId;
  final String moduleTitle;
  final int totalStudents;
  final int completedStudents;
  final double averageCompletionTime;
  final double averageRating;
  final Map<String, int> progressDistribution;
  final List<String> topPerformers;
  final List<String> studentsNeedingHelp;

  ModuleAnalytics({
    required this.moduleId,
    required this.moduleTitle,
    required this.totalStudents,
    required this.completedStudents,
    required this.averageCompletionTime,
    required this.averageRating,
    required this.progressDistribution,
    required this.topPerformers,
    required this.studentsNeedingHelp,
  });

  factory ModuleAnalytics.fromJson(Map<String, dynamic> json) {
    return ModuleAnalytics(
      moduleId: json['module_id'],
      moduleTitle: json['module_title'],
      totalStudents: json['total_students'] ?? 0,
      completedStudents: json['completed_students'] ?? 0,
      averageCompletionTime: (json['average_completion_time'] ?? 0.0).toDouble(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      progressDistribution: Map<String, int>.from(json['progress_distribution'] ?? {}),
      topPerformers: List<String>.from(json['top_performers'] ?? []),
      studentsNeedingHelp: List<String>.from(json['students_needing_help'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'module_title': moduleTitle,
      'total_students': totalStudents,
      'completed_students': completedStudents,
      'average_completion_time': averageCompletionTime,
      'average_rating': averageRating,
      'progress_distribution': progressDistribution,
      'top_performers': topPerformers,
      'students_needing_help': studentsNeedingHelp,
    };
  }

  double get completionRate => 
      totalStudents > 0 ? (completedStudents / totalStudents) * 100 : 0.0;
}
