
import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/student_signup_screen.dart';
import '../../features/auth/presentation/screens/instructor_signup_screen.dart';
import '../../features/auth/presentation/screens/unified_signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/verification_success_screen.dart';
import '../../features/auth/presentation/screens/verification_code_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/student_dashboard_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/student_library_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/module_detail_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/student_progress_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/student_bmi_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/student_quiz_view_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/movement_topics_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/intro_basic_movements_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/movement_relative_center_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/specialized_movements_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/anatomical_planes_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/comprehensive_movement_review_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/final_quiz_assessment_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/musculoskeletal_basis_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/musculoskeletal_basis_intro_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/muscle_physiology_fiber_types_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/muscle_architecture_core_stability_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/muscle_contraction_landing_mechanics_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/movement_injuries_prevention_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/musculoskeletal_final_quiz_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/discrete_skills_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/discrete_skills_foundations_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/discrete_skills_classification_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/discrete_skills_mechanics_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/discrete_skills_striking_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/discrete_skills_advanced_rt_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/discrete_skills_final_quiz_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/throwing_catching_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/serial_skills_screen.dart';
import '../../features/dashboard/student/screens/presentation/screens/continuous_skills_screen.dart';
import '../../features/dashboard/instructor/instructor_dashboard_screen.dart';
import '../../features/dashboard/instructor/screens/student_individual_progress_screen.dart';
import '../../features/dashboard/instructor/screens/module_upload_screen.dart';
import '../../features/dashboard/instructor/screens/grade_student_screen.dart';
import '../../features/dashboard/instructor/screens/section_students_screen.dart';
import '../../features/settings/index.dart';
import '../../features/auth/presentation/widgets/role_guard.dart';
import '../../features/dashboard/instructor/screens/quiz_list_screen.dart';
import '../../features/dashboard/instructor/screens/quiz_type_editor_screen.dart';
import '../../features/dashboard/instructor/screens/quiz_create_screen.dart';
import '../../features/dashboard/instructor/screens/instructor_quiz_view_screen.dart';


class AppRouter {
  // Route names
  static const String splash = '/splash';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String studentSignup = '/student-signup';
  static const String instructorSignup = '/instructor-signup';
  static const String unifiedSignup = '/unified-signup';
  static const String forgotPassword = '/forgot-password';
  static const String studentDashboard = '/student-dashboard';
  static const String instructorDashboard = '/instructor-dashboard';
  static const String moduleList = '/modules';
  static const String moduleDetail = '/module-detail';
  static const String movementTopics = '/movement-topics';
  static const String introBasicMovements = '/intro-basic-movements';
  static const String movementRelativeCenter = '/movement-relative-center';
  static const String specializedMovements = '/specialized-movements';
  static const String anatomicalPlanes = '/anatomical-planes';
  static const String movementReview = '/movement-review';
  static const String finalQuiz = '/final-quiz';
  static const String musculoskeletalBasis = '/musculoskeletal-basis';
  static const String musculoIntro = '/musculo-intro';
  static const String musclePhysiology = '/muscle-physiology';
  static const String muscleArchitecture = '/muscle-architecture';
  static const String muscleContractionsLanding = '/muscle-contractions-landing';
  static const String movementInjuriesPrevention = '/movement-injuries-prevention';
  static const String musculoskeletalFinalQuiz = '/musculoskeletal-final-quiz';

  static const String progress = '/progress';
  static const String studentBmi = '/student-bmi';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String profileSettings = '/profile-settings';
  static const String privacySecurity = '/privacy-security';
  static const String studentLibrary = '/student-library';
  static const String moduleUpload = '/module-upload';
  static const String userMigration = '/user-migration';
  static const String emailVerification = '/verify-email';
  static const String verificationCode = '/verification-code';
  static const String verificationSuccess = '/verification-success';
  
  // Instructor-specific routes
  static const String studentIndividualProgress = '/student-individual-progress';
  static const String gradeStudent = '/grade-student';
  static const String sectionStudents = '/section-students';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name ?? '') {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case roleSelection:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case '/student-signup':
        return MaterialPageRoute(
          builder: (_) => const StudentSignupScreen(),
          settings: settings,
        );
      case '/instructor-signup':
        return MaterialPageRoute(
          builder: (_) => const InstructorSignupScreen(),
          settings: settings,
        );
      case '/unified-signup':
        final args = settings.arguments as Map<String, dynamic>?;
        final initialIsStudent = args?['initialIsStudent'] as bool?;
        return MaterialPageRoute(
          builder: (_) => UnifiedSignupScreen(initialIsStudent: initialIsStudent),
          settings: settings,
        );
      case emailVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        final token = args?['token'] as String?;
        if (token == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid verification link')),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(token: token),
          settings: settings,
        );
      case verificationSuccess:
        final args = settings.arguments as Map<String, dynamic>?;
        final token = args?['token'] as String?;
        if (token == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid verification link')),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => VerificationSuccessScreen(token: token),
          settings: settings,
        );
      case verificationCode:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String?;
        final userType = args?['userType'] as String?;
        
        if (email == null || userType == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Invalid verification parameters')),
            ),
            settings: settings,
          );
        }
        
        return MaterialPageRoute(
          builder: (_) => VerificationCodeScreen(
            email: email,
            userType: userType,
          ),
          settings: settings,
        );
      case '/student-dashboard':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student', // Uses isStudent=true internally
            child: StudentDashboardScreen(),
            fallbackRoute: '/login',
            loadingWidget: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verifying student access...'),
                  ],
                ),
              ),
            ),
          ),
          settings: settings,
        );
      case '/student-library':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student', // Uses isStudent=true internally
            fallbackRoute: '/login',
            child: StudentLibraryScreen(),
          ),
          settings: settings,
        );
      case '/module-detail':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student', // Uses isStudent=true internally
            fallbackRoute: '/login',
            child: ModuleDetailScreen(moduleTitle: 'Understanding Movements'),
          ),
          settings: settings,
        );
      case '/movement-topics':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MovementTopicsScreen(),
          ),
          settings: settings,
        );
      case '/discrete-skills':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: DiscreteSkillsScreen(),
          ),
          settings: settings,
        );
      case '/discrete-foundations':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: DiscreteSkillsFoundationsScreen(),
          ),
          settings: settings,
        );
      case '/discrete-classification':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: DiscreteSkillsClassificationScreen(),
          ),
          settings: settings,
        );
      case '/discrete-mechanics':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: DiscreteSkillsMechanicsScreen(),
          ),
          settings: settings,
        );
      case '/discrete-striking':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: DiscreteSkillsStrikingScreen(),
          ),
          settings: settings,
        );
      case '/discrete-advanced-rt':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: DiscreteSkillsAdvancedRtScreen(),
          ),
          settings: settings,
        );
      case '/discrete-final-quiz':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: DiscreteSkillsFinalQuizScreen(),
          ),
          settings: settings,
        );
      case '/throwing-catching':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: ThrowingCatchingScreen(),
          ),
          settings: settings,
        );
      case '/serial-skills':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: SerialSkillsScreen(),
          ),
          settings: settings,
        );
      case '/continuous-skills':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: ContinuousSkillsScreen(),
          ),
          settings: settings,
        );
      case '/musculoskeletal-basis':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MusculoskeletalBasisScreen(),
          ),
          settings: settings,
        );
      case '/musculo-intro':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MusculoskeletalBasisIntroScreen(),
          ),
          settings: settings,
        );
      case '/muscle-physiology':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MusclePhysiologyFiberTypesScreen(),
          ),
          settings: settings,
        );
      case '/muscle-architecture':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MuscleArchitectureCoreStabilityScreen(),
          ),
          settings: settings,
        );
      case '/muscle-contractions-landing':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MuscleContractionLandingMechanicsScreen(),
          ),
          settings: settings,
        );
      case '/movement-injuries-prevention':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MovementInjuriesPreventionScreen(),
          ),
          settings: settings,
        );
      case '/musculoskeletal-final-quiz':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MusculoskeletalFinalQuizScreen(),
          ),
          settings: settings,
        );
      case '/intro-basic-movements':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: IntroBasicMovementsScreen(),
          ),
          settings: settings,
        );
      case '/movement-relative-center':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: MovementRelativeCenterScreen(),
          ),
          settings: settings,
        );
      case '/specialized-movements':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: SpecializedMovementsScreen(),
          ),
          settings: settings,
        );
      case '/anatomical-planes':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: AnatomicalPlanesScreen(),
          ),
          settings: settings,
        );
      case '/movement-review':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: ComprehensiveMovementReviewScreen(),
          ),
          settings: settings,
        );
      case '/final-quiz':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: FinalQuizAssessmentScreen(),
          ),
          settings: settings,
        );
      case '/instructor-dashboard':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'instructor', // Uses isStudent=false internally
            child: InstructorDashboardScreen(),
            fallbackRoute: '/login',
            loadingWidget: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Verifying instructor access...'),
                  ],
                ),
              ),
            ),
          ),
          settings: settings,
        );
      
      case '/quiz':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'instructor',
            fallbackRoute: '/login',
            child: QuizListScreen(),
          ),
          settings: settings,
        );
      case '/quiz-create':
        final args = settings.arguments as Map<String, dynamic>?;
        final topic = (args?['topic'] as String?) ?? 'Topic';
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            requiredRole: 'instructor',
            fallbackRoute: '/login',
            child: QuizCreateScreen(topic: topic),
          ),
          settings: settings,
        );
      case '/quiz-type':
        final args = settings.arguments as Map<String, dynamic>?;
        final topic = (args?['topic'] as String?) ?? 'Topic';
        final type = (args?['type'] as String?) ?? 'type';
        final label = (args?['label'] as String?) ?? 'Quiz Type';
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            requiredRole: 'instructor',
            fallbackRoute: '/login',
            child: QuizTypeEditorScreen(topic: topic, type: type, label: label),
          ),
          settings: settings,
        );

      case '/instructor-quiz-view':
        final args = settings.arguments as Map<String, dynamic>?;
        final quizId = args?['quizId'] as String?;
        if (quizId == null || quizId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing quizId for instructor view')),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            requiredRole: 'instructor',
            fallbackRoute: '/login',
            child: InstructorQuizViewScreen(quizId: quizId),
          ),
          settings: settings,
        );
      
      // Instructor-specific routes
      case studentIndividualProgress:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => RoleGuard(
            requiredRole: 'instructor', // Uses isStudent=false internally
            fallbackRoute: '/login',
            child: StudentIndividualProgressScreen(
              studentId: args?['studentId'] ?? '',
              studentName: args?['studentName'] ?? 'Student',
              instructorId: args?['instructorId'] ?? '',
            ),
          ),
          settings: settings,
        );



      case gradeStudent:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            requiredRole: 'instructor',
            fallbackRoute: '/login',
            child: GradeStudentScreen(
              studentName: args?['studentName'] ?? 'Student',
              studentId: args?['studentId'] ?? 'ID',
              course: args?['course'] ?? 'Course',
            ),
          ),
          settings: settings,
        );

      case sectionStudents:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            requiredRole: 'instructor',
            fallbackRoute: '/login',
            child: SectionStudentsScreen(
              sectionId: args?['sectionId'] ?? '',
              sectionName: args?['sectionName'] ?? 'Section',
              courseName: args?['courseName'],
              yearLevel: args?['yearLevel'],
              section: args?['section'],
            ),
          ),
          settings: settings,
        );
      
      case '/modules':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: _PlaceholderScreen(title: 'Learning Modules'),
          ),
          settings: settings,
        );

      case '/progress':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: StudentProgressScreen(),
          ),
          settings: settings,
        );
      case '/student-bmi':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: StudentBmiScreen(),
          ),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'any', // Allow both students and instructors
            fallbackRoute: '/login',
            child: SettingsScreen(),
          ),
          settings: settings,
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'any', // Allow both students and instructors
            fallbackRoute: '/login',
            child: SettingsScreen(),
          ),
          settings: settings,
        );
      case '/profile-settings':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'any',
            fallbackRoute: '/login',
            child: ProfileSettingsScreen(),
          ),
          settings: settings,
        );
      case '/privacy-security':
        return MaterialPageRoute(
          builder: (_) => const RoleGuard(
            requiredRole: 'any',
            fallbackRoute: '/login',
            child: PrivacySecurityScreen(),
          ),
          settings: settings,
        );

      case moduleUpload:
        return MaterialPageRoute(
          builder: (context) => const RoleGuard(
            requiredRole: 'instructor',
            fallbackRoute: '/login',
            child: ModuleUploadScreen(),
          ),
          settings: settings,
        );
      case '/student-quiz-view':
        final args = settings.arguments as Map<String, dynamic>?;
        final quizId = args?['quizId'] as String?;
        if (quizId == null || quizId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing quizId for student view')),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => RoleGuard(
            requiredRole: 'student',
            fallbackRoute: '/login',
            child: StudentQuizViewScreen(quizId: quizId),
          ),
          settings: settings,
        );
      case AppRouter.userMigration:
        return MaterialPageRoute(
          builder: (context) => const UserMigrationScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const _PlaceholderScreen(title: 'Route not found'),
          settings: settings,
        );
    }
  }
}

// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const _PlaceholderScreen({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This screen is under construction',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
