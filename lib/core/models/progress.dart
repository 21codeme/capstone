class StudentProgress {
  final String id;
  final String studentId;
  final String moduleId;
  final String moduleTitle;
  final double completionPercentage;
  final int totalQuizzes;
  final int completedQuizzes;
  final double averageScore;
  final DateTime lastAccessed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StudentProgress({
    required this.id,
    required this.studentId,
    required this.moduleId,
    required this.moduleTitle,
    required this.completionPercentage,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.averageScore,
    required this.lastAccessed,
    required this.createdAt,
    this.updatedAt,
  });

  StudentProgress copyWith({
    String? id,
    String? studentId,
    String? moduleId,
    String? moduleTitle,
    double? completionPercentage,
    int? totalQuizzes,
    int? completedQuizzes,
    double? averageScore,
    DateTime? lastAccessed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProgress(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      averageScore: averageScore ?? this.averageScore,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'completionPercentage': completionPercentage,
      'totalQuizzes': totalQuizzes,
      'completedQuizzes': completedQuizzes,
      'averageScore': averageScore,
      'lastAccessed': lastAccessed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      id: json['id'],
      studentId: json['studentId'],
      moduleId: json['moduleId'],
      moduleTitle: json['moduleTitle'],
      completionPercentage: json['completionPercentage'].toDouble(),
      totalQuizzes: json['totalQuizzes'],
      completedQuizzes: json['completedQuizzes'],
      averageScore: json['averageScore'].toDouble(),
      lastAccessed: DateTime.parse(json['lastAccessed']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}









