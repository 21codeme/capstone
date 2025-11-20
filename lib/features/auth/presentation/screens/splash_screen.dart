import 'package:flutter/material.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/loading_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/firebase/firebase_config.dart';
import '../providers/auth_provider.dart' as app_auth;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Start Firebase initialization immediately but wait for animation to complete
    Future.delayed(const Duration(seconds: 2), () {
      _initializeAndCheckAuth();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndCheckAuth() async {
    try {
      print('🔄 Initializing Firebase and AuthProvider...');
      
      // Set loading state for animation
      setState(() {
        _isInitializing = true;
      });
      
      // Initialize Firebase first with pre-warming
      await FirebaseConfig.initialize();
      
      // Initialize AuthProvider
      final authProvider = context.read<app_auth.AuthProvider>();
      
      // Use a timeout to ensure we don't get stuck in initialization
      bool initializeComplete = false;
      
      // Start initialization with parallel operations
      Future<void> initializeFuture = Future.wait([
        // Initialize auth provider
        authProvider.initialize(),
        // Add a small delay to ensure animations complete smoothly
        Future.delayed(const Duration(milliseconds: 500)),
      ]);
      
      // Set up a timeout
      Future<void> timeoutFuture = Future.delayed(const Duration(seconds: 5), () {
        if (!initializeComplete) {
          print('⚠️ Auth initialization timeout reached');
        }
      });
      
      // Wait for initialization or timeout
      await Future.any([initializeFuture, timeoutFuture]);
      initializeComplete = true;
      
      print('✅ AuthProvider initialized, checking authentication state...');
      
      // Check if user is authenticated with Firebase
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        print('✅ User is authenticated: ${currentUser.uid}');
        
        // User is authenticated, enforce role-based access control
        final isUserStudent = authProvider.isStudent;
        final userRole = isUserStudent ? 'student' : 'instructor';
        
        print('✅ User role from provider: $userRole (isStudent: $isUserStudent)');
        
        if (isUserStudent) {
          // Verify student role access
          final hasStudentAccess = await authProvider.enforceRoleAccess('student');
          if (hasStudentAccess) {
            print('🔄 Student role verified, navigating to student dashboard');
            Navigator.pushReplacementNamed(context, '/student-dashboard');
          } else {
            print('⚠️ Student role verification failed, redirecting to login');
            await authProvider.resetAppState(context); // Force sign out and reset app state for security
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          }
        } else {
          // Verify instructor role access
          final hasInstructorAccess = await authProvider.enforceRoleAccess('instructor');
          if (hasInstructorAccess) {
            print('🔄 Instructor role verified, navigating to instructor dashboard');
            Navigator.pushReplacementNamed(context, '/instructor-dashboard');
          } else {
            print('⚠️ Instructor role verification failed, redirecting to login');
            await authProvider.resetAppState(context); // Force sign out and reset app state for security
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          }
        }
      } else {
        print('❌ No user authenticated, going to login');
        // No user authenticated, go to login
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      print('❌ Error checking authentication: $e');
      // On error, go to login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } finally {
      // Ensure loading state is updated even if there's an error
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isInitializing,
      progressColor: AppColors.primaryBlue,
      opacity: 0.7,
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Logo Circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 60,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App Name
                    Text(
                      'PathFit',
                      style: AppTextStyles.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tagline
                    Text(
                      'Your Path to Fitness Excellence',
                      style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    const LoadingDots(
                      color: Colors.white,
                      size: 12,
                    ),
                    

                  ],
                ),
              ),
            );
          },
        ),
      ),
    ));
  }
}
