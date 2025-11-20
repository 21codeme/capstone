import 'dart:math';
import 'dart:async';
import '../models/api_response.dart';
import '../models/user.dart';
import '../models/module.dart';
import '../models/notification.dart';
import '../models/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockBackendService {
  static final MockBackendService _instance = MockBackendService._internal();
  factory MockBackendService() => _instance;
  MockBackendService._internal();

  // Mock data storage
  final List<User> _users = [];
  final List<Module> _modules = [];
  final List<AppNotification> _notifications = [];

  // Real-time update streams
  final StreamController<List<AppNotification>> _notificationUpdateController = StreamController<List<AppNotification>>.broadcast();

  // Getters for real-time streams
  Stream<List<AppNotification>> get notificationUpdates => _notificationUpdateController.stream;

  // Initialize mock data
  void initializeMockData() {
    _createMockUsers();
    _createMockModules();
    _createMockNotifications();
  }

  // Ensure mock data is initialized (call this before any operations)
  void ensureMockDataInitialized() {
    if (_users.isEmpty) {
      print('🔧 Initializing mock data...');
      initializeMockData();
      print('✅ Mock data initialized with ${_notifications.length} notifications');
    } else {
      print('📊 Mock data already initialized: ${_notifications.length} notifications');
    }
  }

  // Real-time update methods
  void _notifyNotificationUpdates() {
    _notificationUpdateController.add(_notifications);
    print('📡 Notified notification updates: ${_notifications.length} notifications');
  }

  void _createMockUsers() {
    _users.clear();
    
    // Create mock students
    for (int i = 1; i <= 10; i++) {
      _users.add(Student(
        id: 'student_$i',
        email: 'student$i@example.com',
        firstName: 'Student',
        lastName: 'Number $i',
        createdAt: DateTime.now().subtract(Duration(days: 30 + i)),
        updatedAt: DateTime.now().subtract(Duration(days: i)),
        isActive: true,
        emailVerified: true,
        studentId: 'STU${i.toString().padLeft(3, '0')}',
        course: 'Computer Science',
        yearLevel: (i % 4) + 1,
        section: 'A',
        enrollmentDate: DateTime.now().subtract(Duration(days: 365)),
        academicStatus: 'active',
      ));
    }

    // Create mock instructors
    for (int i = 1; i <= 5; i++) {
      _users.add(Instructor(
        id: 'instructor_$i',
        email: 'instructor$i@example.com',
        firstName: 'Instructor',
        lastName: 'Number $i',
        createdAt: DateTime.now().subtract(Duration(days: 100 + i)),
        updatedAt: DateTime.now().subtract(Duration(days: i)),
        isActive: true,
        emailVerified: true,
        instructorId: 'INS${i.toString().padLeft(3, '0')}',
        department: 'Computer Science',
        specialization: 'Software Engineering',
        qualifications: ['PhD', 'MSc'],
        hireDate: DateTime.now().subtract(Duration(days: 1000)),
        status: 'active',
      ));
    }
  }

  void _createMockModules() {
    _modules.clear();
    
    final instructorIds = _users
        .where((u) => u.userType == UserType.instructor)
        .map((u) => u.id)
        .toList();

    for (int i = 1; i <= 15; i++) {
      _modules.add(Module(
        id: 'module_$i',
        instructorId: instructorIds[i % instructorIds.length],
        title: 'Module $i: ${_getModuleTitle(i)}',
        description: 'This is a comprehensive module covering ${_getModuleTitle(i).toLowerCase()}.',
        contentType: ContentType.values[i % ContentType.values.length],
        contentUrl: 'https://example.com/module$i.pdf',
        thumbnailUrl: 'https://example.com/thumb$i.jpg',
        durationMinutes: 45 + (i * 5),
        difficultyLevel: DifficultyLevel.values[i % DifficultyLevel.values.length],
        tags: ['tag${i}_1', 'tag${i}_2'],
        isPublished: i <= 10,
        publishedAt: i <= 10 ? DateTime.now().subtract(Duration(days: i * 2)) : null,
        createdAt: DateTime.now().subtract(Duration(days: i * 3)),
        updatedAt: DateTime.now().subtract(Duration(days: i)),
        viewCount: Random().nextInt(1000),
        rating: 3.5 + (Random().nextDouble() * 1.5),
      ));
    }
  }

  String _getModuleTitle(int index) {
    final titles = [
      'Introduction to Programming',
      'Data Structures and Algorithms',
      'Database Management Systems',
      'Web Development Fundamentals',
      'Mobile App Development',
      'Machine Learning Basics',
      'Software Engineering Principles',
      'Computer Networks',
      'Operating Systems',
      'Cybersecurity Fundamentals',
      'Cloud Computing',
      'Artificial Intelligence',
      'Data Science',
      'Blockchain Technology',
      'Internet of Things',
    ];
    return titles[index % titles.length];
  }



  void _createMockNotifications() {
    _notifications.clear();
    
    final studentIds = _users
        .where((u) => u.userType == UserType.student)
        .map((u) => u.id)
        .toList();

    for (int i = 1; i <= 25; i++) {
      _notifications.add(AppNotification(
        id: 'notification_$i',
        userId: studentIds[i % studentIds.length],
        title: _getNotificationTitle(i),
        message: _getNotificationMessage(i),
        notificationType: NotificationType.values[i % NotificationType.values.length],
        relatedEntityType: EntityType.values[i % EntityType.values.length],
        relatedEntityId: i % 2 == 0 ? 'entity_$i' : null,
        isRead: i % 3 == 0,
        readAt: i % 3 == 0 ? DateTime.now().subtract(Duration(hours: i)) : null,
        createdAt: DateTime.now().subtract(Duration(hours: i * 2)),
      ));
    }
    _notifyNotificationUpdates();
  }

  String _getNotificationTitle(int index) {
    final titles = [
      'New Module Available',
      'Score Updated',
      'System Maintenance',
      'Reminder: Complete Module',
      'Module Completed',
      'Achievement Unlocked',
      'Weekly Progress Report',
      'Course Update',
    ];
    return titles[index % titles.length];
  }

  String _getNotificationMessage(int index) {
    final messages = [
      'A new module has been added to your course.',
      'Your module score has been updated.',
      'System maintenance scheduled for tonight.',
      'Don\'t forget to complete your assigned module.',
      'Congratulations! You completed a module.',
      'You earned a new achievement badge.',
      'Your weekly progress report is ready.',
      'Your course has been updated with new content.',
    ];
    return messages[index % messages.length];
  }



  // Mock API methods
  Future<ApiResponse<AuthResponse>> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    final user = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );

    return ApiResponse.success(
      data: AuthResponse(
        user: user,
        accessToken: 'mock_token_${user.id}',
        refreshToken: 'mock_refresh_${user.id}',
        expiresAt: DateTime.now().add(Duration(hours: 24)),
      ),
      message: 'Login successful',
    );
  }

  Future<ApiResponse<AuthResponse>> register(UserRegistrationData data) async {
    await Future.delayed(Duration(milliseconds: 800));
    
    final newUser = data.userType == UserType.student
        ? Student(
            id: 'user_${_users.length + 1}',
            email: data.email,
            firstName: data.firstName,
            lastName: data.lastName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
            emailVerified: false,
            studentId: 'STU${(_users.length + 1).toString().padLeft(3, '0')}',
            course: 'Computer Science',
            yearLevel: 1,
            section: 'A',
            enrollmentDate: DateTime.now(),
            academicStatus: 'active',
          )
        : Instructor(
            id: 'user_${_users.length + 1}',
            email: data.email,
            firstName: data.firstName,
            lastName: data.lastName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
            emailVerified: false,
            instructorId: 'INS${(_users.length + 1).toString().padLeft(3, '0')}',
            department: 'Computer Science',
            specialization: 'Software Engineering',
            qualifications: ['MSc'],
            hireDate: DateTime.now(),
            status: 'active',
          );

    _users.add(newUser);

    return ApiResponse.success(
      data: AuthResponse(
        user: newUser,
        accessToken: 'mock_token_${newUser.id}',
        refreshToken: 'mock_refresh_${newUser.id}',
        expiresAt: DateTime.now().add(Duration(hours: 24)),
      ),
      message: 'Registration successful',
    );
  }

  Future<ApiResponse<StudentDashboard>> getStudentDashboard(String studentId) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    final student = _users.firstWhere(
      (u) => u.id == studentId && u.userType == UserType.student,
      orElse: () => throw Exception('Student not found'),
    ) as Student;

    final recentModules = _modules.take(5).toList();
    
    final stats = DashboardStats(
      totalModules: _modules.length,
      completedModules: Random().nextInt(_modules.length),
      thisWeekModules: Random().nextInt(5),
      overallProgress: 85.0 + Random().nextDouble() * 10,
    );

    final recentActivities = [
      RecentActivity(
        id: 'activity_1',
        type: 'module_completed',
        title: 'Module Completed',
        description: 'You completed Module 1: Introduction to Programming',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        relatedEntityId: 'module_1',
        relatedEntityType: 'module',
      ),
      RecentActivity(
        id: 'activity_2',
        type: 'module_completed',
        title: 'Module Completed',
        description: 'You completed Module 2: Data Structures',
        timestamp: DateTime.now().subtract(Duration(hours: 4)),
        relatedEntityId: 'module_2',
        relatedEntityType: 'module',
      ),
    ];

    return ApiResponse.success(
      data: StudentDashboard(
        studentId: studentId,
        studentName: student.fullName,
        course: student.course,
        yearLevel: student.yearLevel,
        section: student.section,
        recentModules: recentModules,
        stats: stats,
        recentActivities: recentActivities,
      ),
      message: 'Dashboard data retrieved successfully',
    );
  }

  Future<ApiResponse<InstructorDashboard>> getInstructorDashboard(String instructorId) async {
    await Future.delayed(Duration(milliseconds: 600));
    
    final instructor = _users.firstWhere(
      (u) => u.id == instructorId && u.userType == UserType.instructor,
      orElse: () => throw Exception('Instructor not found'),
    ) as Instructor;

    final recentModules = _modules.where((m) => m.instructorId == instructorId).take(5).toList();
    final recentStudents = _users.where((u) => u.userType == UserType.student).take(5).cast<Student>().toList();

    final stats = DashboardStats(
      totalModules: _modules.where((m) => m.instructorId == instructorId).length,
      completedModules: Random().nextInt(10),
      thisWeekModules: Random().nextInt(3),
      overallProgress: 75.0 + Random().nextDouble() * 20,
    );

    final recentActivities = [
      RecentActivity(
        id: 'activity_1',
        type: 'module_uploaded',
        title: 'Module Uploaded',
        description: 'You uploaded a new module: Advanced Programming',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        relatedEntityId: 'module_new',
        relatedEntityType: 'module',
      ),
      RecentActivity(
        id: 'activity_2',
        type: 'module_uploaded',
        title: 'Module Uploaded',
        description: 'You uploaded a new module: Database Design',
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
        relatedEntityId: 'module_new_2',
        relatedEntityType: 'module',
      ),
    ];

    return ApiResponse.success(
      data: InstructorDashboard(
        instructorId: instructorId,
        instructorName: instructor.fullName,
        department: instructor.department,
        specialization: instructor.specialization,
        recentModules: recentModules,
        recentStudents: recentStudents,
        stats: stats,
        recentActivities: recentActivities,
      ),
      message: 'Dashboard data retrieved successfully',
    );
  }

  Future<ApiResponse<List<Module>>> getStudentLibrary(String studentId) async {
    await Future.delayed(Duration(milliseconds: 400));
    
    final publishedModules = _modules.where((m) => m.isPublished).toList();
    
    return ApiResponse.success(
      data: publishedModules,
      message: 'Library data retrieved successfully',
    );
  }

  Future<ApiResponse<List<AppNotification>>> getNotifications() async {
    await Future.delayed(Duration(milliseconds: 300));
    
    // Ensure mock data is initialized
    ensureMockDataInitialized();
    
    print('Getting notifications');
    print('Found ${_notifications.length} notifications');
    _notifications.take(5).forEach((n) => print('- ${n.title} (${n.notificationType})'));
    
    return ApiResponse.success(
      data: _notifications,
      message: 'Notifications retrieved successfully',
    );
  }

  Future<ApiResponse<StudentProgress>> getStudentProgress(String studentId) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    final moduleProgress = _modules.take(3).map((module) => ModuleProgress(
      studentId: studentId,
      moduleId: module.id,
      progressPercentage: Random().nextDouble() * 100,
      timeSpentMinutes: Random().nextInt(120),
      lastAccessed: DateTime.now().subtract(Duration(hours: Random().nextInt(72))),
      isCompleted: Random().nextBool(),
      completedAt: Random().nextBool() 
          ? DateTime.now().subtract(Duration(hours: Random().nextInt(48)))
          : null,
    )).toList();
    
    final overallStats = DashboardStats(
      totalModules: _modules.length,
      completedModules: moduleProgress.where((p) => p.progressPercentage >= 100).length,
      thisWeekModules: Random().nextInt(5),
      overallProgress: moduleProgress.isNotEmpty 
          ? moduleProgress.map((p) => p.progressPercentage).reduce((a, b) => a + b) / moduleProgress.length
          : 0.0,
    );

    final achievements = [
      'First Module Completed',
      'Module Master',
      'Consistent Learner',
      'Perfect Progress',
      'Early Bird',
    ];

    return ApiResponse.success(
      data: StudentProgress(
        studentId: studentId,
        moduleProgress: moduleProgress,
        overallStats: overallStats,
        achievements: achievements.take(Random().nextInt(3) + 1).toList(),
        lastUpdated: DateTime.now(),
      ),
      message: 'Progress data retrieved successfully',
    );
  }

  // Utility method to get mock service
  static MockBackendService get instance => _instance;
}
