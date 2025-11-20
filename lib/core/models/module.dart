enum ContentType { video, document, interactive, mixed }
enum DifficultyLevel { beginner, intermediate, advanced }

class Module {
  final String id;
  final String instructorId;
  final String title;
  final String description;
  final ContentType contentType;
  final String contentUrl;
  final String? thumbnailUrl;
  final int? durationMinutes;
  final DifficultyLevel? difficultyLevel;
  final List<String> tags;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final double rating;

  Module({
    required this.id,
    required this.instructorId,
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentUrl,
    this.thumbnailUrl,
    this.durationMinutes,
    this.difficultyLevel,
    required this.tags,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.viewCount,
    required this.rating,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      instructorId: json['instructor_id'],
      title: json['title'],
      description: json['description'],
      contentType: ContentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['content_type'],
        orElse: () => ContentType.document,
      ),
      contentUrl: json['content_url'],
      thumbnailUrl: json['thumbnail_url'],
      durationMinutes: json['duration_minutes'],
      difficultyLevel: json['difficulty_level'] != null
          ? DifficultyLevel.values.firstWhere(
              (e) => e.toString().split('.').last == json['difficulty_level'],
              orElse: () => DifficultyLevel.beginner,
            )
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      isPublished: json['is_published'] ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      viewCount: json['view_count'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instructor_id': instructorId,
      'title': title,
      'description': description,
      'content_type': contentType.toString().split('.').last,
      'content_url': contentUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_minutes': durationMinutes,
      'difficulty_level': difficultyLevel?.toString().split('.').last,
      'tags': tags,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'view_count': viewCount,
      'rating': rating,
    };
  }

  Module copyWith({
    String? id,
    String? instructorId,
    String? title,
    String? description,
    ContentType? contentType,
    String? contentUrl,
    String? thumbnailUrl,
    int? durationMinutes,
    DifficultyLevel? difficultyLevel,
    List<String>? tags,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    double? rating,
  }) {
    return Module(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      contentUrl: contentUrl ?? this.contentUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      tags: tags ?? this.tags,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
    );
  }

  @override
  String toString() {
    return 'Module{id: $id, title: $title, contentType: $contentType}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Module &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ModuleUploadData {
  final String title;
  final String description;
  final ContentType contentType;
  final String contentUrl;
  final String? thumbnailUrl;
  final int? durationMinutes;
  final DifficultyLevel? difficultyLevel;
  final List<String> tags;

  ModuleUploadData({
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentUrl,
    this.thumbnailUrl,
    this.durationMinutes,
    this.difficultyLevel,
    required this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'content_type': contentType.toString().split('.').last,
      'content_url': contentUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_minutes': durationMinutes,
      'difficulty_level': difficultyLevel?.toString().split('.').last,
      'tags': tags,
    };
  }
}

class ModuleContent {
  final String id;
  final String moduleId;
  final int contentOrder;
  final ContentType contentType;
  final Map<String, dynamic> contentData;
  final int? durationSeconds;

  ModuleContent({
    required this.id,
    required this.moduleId,
    required this.contentOrder,
    required this.contentType,
    required this.contentData,
    this.durationSeconds,
  });

  factory ModuleContent.fromJson(Map<String, dynamic> json) {
    return ModuleContent(
      id: json['id'],
      moduleId: json['module_id'],
      contentOrder: json['content_order'],
      contentType: ContentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['content_type'],
        orElse: () => ContentType.document,
      ),
      contentData: Map<String, dynamic>.from(json['content_data']),
      durationSeconds: json['duration_seconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'content_order': contentOrder,
      'content_type': contentType.toString().split('.').last,
      'content_data': contentData,
      'duration_seconds': durationSeconds,
    };
  }
}

class ModuleProgress {
  final String studentId;
  final String moduleId;
  final double progressPercentage;
  final int timeSpentMinutes;
  final DateTime lastAccessed;
  final bool isCompleted;
  final DateTime? completedAt;

  ModuleProgress({
    required this.studentId,
    required this.moduleId,
    required this.progressPercentage,
    required this.timeSpentMinutes,
    required this.lastAccessed,
    required this.isCompleted,
    this.completedAt,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      studentId: json['student_id'],
      moduleId: json['module_id'],
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      timeSpentMinutes: json['time_spent_minutes'] ?? 0,
      lastAccessed: DateTime.parse(json['last_accessed']),
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'module_id': moduleId,
      'progress_percentage': progressPercentage,
      'time_spent_minutes': timeSpentMinutes,
      'last_accessed': lastAccessed.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}









