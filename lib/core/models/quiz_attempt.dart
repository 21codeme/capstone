class StudentQuizAttempt {
  final String id;
  final String studentId;
  final String quizId;
  final String quizTitle;
  final double score;
  final double maxScore;
  final double percentage;
  final bool passed;
  final List<Map<dynamic, dynamic>> answers; // Simplified answers structure
  final int timeTakenMinutes;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final String status; // 'completed', 'in_progress', 'submitted'

  StudentQuizAttempt({
    required this.id,
    required this.studentId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.passed,
    required this.answers,
    required this.timeTakenMinutes,
    required this.submittedAt,
    this.updatedAt,
    required this.status,
  });

  StudentQuizAttempt copyWith({
    String? id,
    String? studentId,
    String? quizId,
    String? quizTitle,
    double? score,
    double? maxScore,
    double? percentage,
    bool? passed,
    List<Map<dynamic, dynamic>>? answers,
    int? timeTakenMinutes,
    DateTime? submittedAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return StudentQuizAttempt(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      passed: passed ?? this.passed,
      answers: answers ?? this.answers,
      timeTakenMinutes: timeTakenMinutes ?? this.timeTakenMinutes,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'score': score,
      'maxScore': maxScore,
      'percentage': percentage,
      'passed': passed,
      'answers': answers,
      'timeTakenMinutes': timeTakenMinutes,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
    };
  }

  factory StudentQuizAttempt.fromJson(Map<dynamic, dynamic> json) {
    return StudentQuizAttempt(
      id: json['id'],
      studentId: json['studentId'],
      quizId: json['quizId'],
      quizTitle: json['quizTitle'],
      score: json['score'].toDouble(),
      maxScore: json['maxScore'].toDouble(),
      percentage: json['percentage'].toDouble(),
      passed: json['passed'],
      answers: List<Map<dynamic, dynamic>>.from(json['answers']),
      timeTakenMinutes: json['timeTakenMinutes'],
      submittedAt: DateTime.parse(json['submittedAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      status: json['status'],
    );
  }
}
