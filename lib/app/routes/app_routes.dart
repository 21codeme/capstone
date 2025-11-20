// This file contains route constants for the app

class AppRoutes {
  // Auth routes
  static const String splash = '/splash';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String studentSignup = '/student-signup';
  static const String instructorSignup = '/instructor-signup';
  static const String unifiedSignup = '/unified-signup';
  static const String forgotPassword = '/forgot-password';
  
  // Dashboard routes
  static const String studentDashboard = '/student-dashboard';
  static const String instructorDashboard = '/instructor-dashboard';
  static const String moduleList = '/modules';
  static const String moduleDetail = '/module-detail';

  static const String progress = '/progress';
  
  // Settings routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String profileSettings = '/profile-settings';
  static const String privacySecurity = '/privacy-security';
  
  // Student-specific routes
  static const String studentLibrary = '/student-library';
  static const String studentQuizView = '/student-quiz-view';
  
  // Instructor-specific routes
  static const String moduleUpload = '/module-upload';
  static const String quizCreate = '/quiz-create';
  static const String studentIndividualProgress = '/student-individual-progress';
  static const String gradeStudent = '/grade-student';
  static const String sectionStudents = '/section-students';
  static const String userMigration = '/user-migration';
}