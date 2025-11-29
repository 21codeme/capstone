
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../providers/auth_provider.dart' as app;
import '../../data/services/student_registration_service.dart';
import '../../../../core/services/firebase_test_service.dart';
import '../../../../core/utils/name_formatter.dart';

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});

  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // State
  String _selectedGender = 'Select gender';
  String _selectedCourse = 'Select course';
  String _selectedYear = 'Select year';
  String _selectedSection = 'Select section';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _signingUp = false;

  // Options
  final List<String> _genderOptions = const [
    'Select gender',
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> _courseOptions = const [
    'Select course',
    'BS Information Technology',
    'BS Midwifery',
  ];

  final List<String> _yearOptions = const [
    'Select year',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  final List<String> _sectionOptions = const [
    'Select section',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
  ];

  @override
  void initState() {
    super.initState();
    // Clear any existing errors when entering signup screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<app.AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }



  Future<void> _signUp() async {
    if (_signingUp) return; // local guard
    FocusScope.of(context).unfocus();

    // Comprehensive form validation
    if (!_formKey.currentState!.validate()) return;

    // Additional required checks
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Validate age
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 13 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid age between 13 and 100'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Validate selects
    if (_selectedGender == 'Select gender') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    if (_selectedCourse == 'Select course') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your course'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    if (_selectedYear == 'Select year') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your year level'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }





    final email = _emailController.text.trim();

    // Pre-check sign-in methods via AuthProvider to avoid direct Firebase import conflicts
    try {
      final auth = context.read<app.AuthProvider>();
      final status = await auth.checkEmailStatus(email);
      final exists = (status['exists'] as bool?) ?? false;
      final methods = (status['methods'] as List?)?.cast<String>() ?? const <String>[];

      if (exists) {
        if (methods.contains('password')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This email is already registered. Try signing in instead.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        } else if (methods.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This email is registered via ${methods.join(', ')}. Use that to sign in or link your email.',
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This email is already registered.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not verify email: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // All validation passed - proceed with registration
    _signingUp = true;
    final registrationService = StudentRegistrationService();
    
    try {
      // Create a map with non-null values and proper type handling
      final studentData = <String, dynamic>{
        'email': email,
        'password': _passwordController.text,
        'displayName': _buildDisplayName(),
      };
      
      // Only add fields with proper null checks
      final firstName = _firstNameController.text.trim();
      if (firstName.isNotEmpty) studentData['firstName'] = firstName;
      
      final middleName = _middleNameController.text.trim();
      if (middleName.isNotEmpty) studentData['middleName'] = middleName;
      
      final lastName = _lastNameController.text.trim();
      if (lastName.isNotEmpty) studentData['lastName'] = lastName;
      
      final age = int.tryParse(_ageController.text.trim());
      if (age != null) studentData['age'] = age;
      
      if (_selectedGender != 'Select gender') studentData['gender'] = _selectedGender;
      if (_selectedCourse != 'Select course') studentData['course'] = _selectedCourse;
      if (_selectedYear != 'Select year') studentData['year'] = _selectedYear;
      if (_selectedSection != 'Select section') studentData['section'] = _selectedSection;
      


      final result = await registrationService.createPendingStudentAccount(
        email: email,
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 18,
        gender: _selectedGender,
        course: _selectedCourse,
        year: _selectedYear,
        section: _selectedSection != 'Select section' ? _selectedSection : '',

      );
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        // Get studentId from either studentId or uid field
        final studentId = result['studentId'] as String? ?? result['uid'] as String;
        Navigator.pushReplacementNamed(
          context, 
          '/verification-code',
          arguments: {
            'email': email,
            'userType': 'student',
            'studentId': studentId,
          }
        );
      } else {
        final msg = result['error'] as String? ?? 'Registration failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      setState(() {
        _signingUp = false;
      });
    }
  }

  // Optional: quick connectivity test
  Future<void> _testFirebaseConnection() async {
    try {
      final testResult = await FirebaseTestService.testFirebaseConnection();
      if (!mounted) return;
      if ((testResult['success'] as bool?) ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${testResult['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${testResult['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Firebase test failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
        centerTitle: true,
        // Optional debug action:
        // actions: [IconButton(onPressed: _testFirebaseConnection, icon: const Icon(Icons.bug_report, color: AppColors.textPrimary))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Subtitle
              Center(
                child: Column(
                  children: [
                    Text(
                      'Sign Up',
                      style: AppTextStyles.textTheme.headlineLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account',
                      style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information
              Text(
                'Personal Information',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildInputField(
                controller: _firstNameController,
                label: 'First Name',
                hintText: 'John',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildInputField(
                controller: _middleNameController,
                label: 'Middle Name',
                hintText: 'Michael',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your middle name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildInputField(
                controller: _lastNameController,
                label: 'Last Name',
                hintText: 'Doe',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildInputField(
                controller: _ageController,
                label: 'Age',
                hintText: 'Enter your age',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 100) {
                    return 'Please enter a valid age between 13 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Gender',
                value: _selectedGender,
                items: _genderOptions,
                onChanged: (value) => setState(() => _selectedGender = value!),
                validator: (value) {
                  if (value == null || value == 'Select gender') {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Academic Information
              Text(
                'Academic Information',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Course',
                value: _selectedCourse,
                items: _courseOptions,
                onChanged: (value) => setState(() => _selectedCourse = value!),
                validator: (value) {
                  if (value == null || value == 'Select course') {
                    return 'Please select your course';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Year',
                      value: _selectedYear,
                      items: _yearOptions,
                      onChanged: (value) => setState(() => _selectedYear = value!),
                      validator: (value) {
                        if (value == null || value == 'Select year') {
                          return 'Please select your year';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Section',
                      value: _selectedSection,
                      items: _sectionOptions,
                      onChanged: (value) => setState(() => _selectedSection = value!),
                      validator: (value) {
                        if (value == null || value == 'Select section') {
                          return 'Please select your section';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact Information
              Text(
                'Contact Information',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildInputField(
                controller: _emailController,
                label: 'Gmail Address',
                hintText: 'example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Password
              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Enter your password',
                isVisible: !_obscurePassword ? true : false,
                onToggleVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                isVisible: !_obscureConfirmPassword ? true : false,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Consumer<app.AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
                          : Text(
                              'Create Account',
                              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Terms and Privacy Policy
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'By creating an account, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error handling is done via SnackBar instead of red error display
              // We're intentionally not showing errors here to improve user experience
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.errorRed),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: item.startsWith('Select')
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.errorRed),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final obscure = !isVisible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: const Icon(Icons.lock, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.errorRed),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  // BMI display field removed

  /// Builds a display name from first, middle, and last names.
  /// Middle names are formatted as initials (e.g., "Charles Simon" -> "C. S.")
  String _buildDisplayName() {
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      return 'Student';
    }

    var displayName = NameFormatter.buildDisplayName(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
    );
    
    if (displayName.length > 256) {
      displayName = displayName.substring(0, 256).trim();
    }
    if (displayName.isEmpty) displayName = 'Student';
    return displayName;
  }
}