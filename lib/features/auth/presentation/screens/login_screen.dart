import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/firebase/firebase_config.dart'; // Added this import
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'student_signup_screen.dart';
import 'instructor_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isStudent = true; // Default to student
  bool _obscurePassword = true;
  bool _hasError = false; // Track error state
  bool _isLoading = false; // Track loading state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // We still track error state internally but don't show visual feedback
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    
    if (!_formKey.currentState!.validate()) return;

    print('🔐 LoginScreen: Starting sign in process...');
    print('📧 Email: ${_emailController.text.trim()}');
    print('🔑 Role: ${_isStudent ? 'student' : 'instructor'}');

    final authProvider = context.read<AuthProvider>();
    
    // Show loading state
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signing in...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    try {
      // Ensure App Check is properly initialized
      await FirebaseConfig.refreshAppCheckToken();
      
      // Attempt to sign in - RetryHelper will handle retries automatically
      final success = await authProvider.signInUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Handle the result
      _handleSignInResult(success, authProvider);
    } catch (e) {
      print('🔐 LoginScreen: Sign-in attempt failed: $e');
      
      // Check if this is an App Check related error
      if (e.toString().contains('App Check') || 
          e.toString().contains('app-check-failed')) {
        print('🔐 LoginScreen: App Check error detected, attempting refresh...');
        
        // Try to refresh App Check token and retry
        try {
          await FirebaseConfig.refreshAppCheckToken();
          
          // Retry the sign-in attempt
          final success = await authProvider.signInUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          _handleSignInResult(success, authProvider);
          return;
        } catch (retryError) {
          print('🔐 LoginScreen: Retry after App Check refresh also failed');
        }
      }
      
      // Get user-friendly error message using the AuthErrorHandler
      final errorMessage = AuthErrorHandler.getErrorMessage(e, 'Login');
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: AuthErrorHandler.isNetworkError(e) ? 
              SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _signIn(),
              ) : null,
          ),
        );
      }
      
      // Update error state
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
  
  void _handleSignInResult(bool success, AuthProvider authProvider) {
    // Update loading and error states
    setState(() {
      _isLoading = false;
      _hasError = !success;
    });

    print('🔐 LoginScreen: Sign in result: $success');
    print('🔐 LoginScreen: User data available: ${authProvider.currentUserModel != null}');
    print('🔐 LoginScreen: User role: ${authProvider.currentUserModel?.isStudent == true ? 'Student' : 'Instructor'}');
    
    // Force navigation if user data is available, regardless of success flag
    if (authProvider.currentUserModel != null && mounted) {
      print('🔐 LoginScreen: User data available, proceeding with navigation');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Navigate based on role
      if (authProvider.isInstructor) {
        print('🔐 LoginScreen: Navigating to instructor dashboard');
        Navigator.pushReplacementNamed(context, '/instructor-dashboard');
      } else {
        print('🔐 LoginScreen: Navigating to student dashboard');
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      }
    } else if (success && mounted) {
      print('🔐 LoginScreen: Success flag is true but no user data, attempting navigation anyway');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Navigate based on role
      if (authProvider.isInstructor) {
        print('🔐 LoginScreen: Navigating to instructor dashboard');
        Navigator.pushReplacementNamed(context, '/instructor-dashboard');
      } else {
        print('🔐 LoginScreen: Navigating to student dashboard');
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      }
    } else {
      print('🔐 LoginScreen: Sign in failed or user not mounted');
      
      // No visual error feedback as per requirements
      // Error is still tracked in authProvider.error but not displayed
    }
  }



  void _navigateToSignUp() {
    if (!_isStudent) {
      // Navigate to instructor signup with isStudent=false
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InstructorSignupScreen(),
        ),
      );
    } else {
      // Navigate to student signup with isStudent=true
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StudentSignupScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        statusMessage: 'Signing in...',
        progressColor: AppColors.primaryBlue,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: 40),
                
                // App Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Welcome Text
                Text(
                  'Welcome Back!',
                  style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Sign in to continue your fitness journey',
                  style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Role Selection
                Text(
                  'Select your role',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleButton(
                        'student',
                        'Student',
                        Icons.school,
                        _isStudent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleButton(
                        'instructor',
                        'Instructor',
                        Icons.fitness_center,
                        !_isStudent,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: _hasError ? Colors.red : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : Colors.grey.shade400,
                        width: _hasError ? 2.0 : 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : AppColors.primaryBlue,
                        width: 2.0,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _hasError ? Colors.red : null,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: _hasError ? Colors.red : null,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: _hasError ? Colors.red.shade300 : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : Colors.grey.shade400,
                        width: _hasError ? 2.0 : 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : AppColors.primaryBlue,
                        width: 2.0,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _hasError ? Colors.red : null,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Sign In Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Forgot Password
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToSignUp,
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Spacer at the bottom for better layout
                const SizedBox(height: 16),
                
                const SizedBox(height: 16),
                
                // Error Handling (no visual display)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.error != null) {
                      // Highlight input fields with error
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Add red border to input fields
                        setState(() {
                          // This will trigger a rebuild with error styling
                        });
                      });
                      
                      // Return empty widget instead of error container
                      // Error handling logic is preserved but no visual feedback
                      return const SizedBox.shrink();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildRoleButton(String role, String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isStudent = (role == 'student');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
