enum NotificationType { moduleAvailable, scoreUpdate, system, reminder }

enum EntityType { module, score, system }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType notificationType;
  final EntityType relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.relatedEntityType,
    this.relatedEntityId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      notificationType: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['notification_type'],
        orElse: () => NotificationType.system,
      ),
      relatedEntityType: EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['related_entity_type'],
        orElse: () => EntityType.system,
      ),
      relatedEntityId: json['related_entity_id'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': notificationType.toString().split('.').last,
      'related_entity_type': relatedEntityType.toString().split('.').last,
      'related_entity_id': relatedEntityId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? notificationType,
    EntityType? relatedEntityType,
    String? relatedEntityId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification{id: $id, title: $title, type: $notificationType, isRead: $isRead}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class NotificationPreferences {
  final String userId;
  final bool moduleNotifications;
  final bool scoreNotifications;
  final bool systemNotifications;
  final bool reminderNotifications;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;

  NotificationPreferences({
    required this.userId,
    required this.moduleNotifications,
    required this.scoreNotifications,
    required this.systemNotifications,
    required this.reminderNotifications,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.smsNotifications,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['user_id'],
      moduleNotifications: json['module_notifications'] ?? true,
      scoreNotifications: json['score_notifications'] ?? true,
      systemNotifications: json['system_notifications'] ?? true,
      reminderNotifications: json['reminder_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? false,
      smsNotifications: json['sms_notifications'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'module_notifications': moduleNotifications,
      'score_notifications': scoreNotifications,
      'system_notifications': systemNotifications,
      'reminder_notifications': reminderNotifications,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
    };
  }

  NotificationPreferences copyWith({
    String? userId,
    bool? moduleNotifications,
    bool? scoreNotifications,
    bool? systemNotifications,
    bool? reminderNotifications,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      moduleNotifications: moduleNotifications ?? this.moduleNotifications,
      scoreNotifications: scoreNotifications ?? this.scoreNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      reminderNotifications: reminderNotifications ?? this.reminderNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
    );
  }
}









