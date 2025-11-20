import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/widgets/multi_select_widget.dart';
import '../providers/auth_provider.dart';
import '../../data/services/instructor_registration_service.dart';

class InstructorSignupScreen extends StatefulWidget {
  const InstructorSignupScreen({super.key});

  @override
  State<InstructorSignupScreen> createState() => _InstructorSignupScreenState();
}

class _InstructorSignupScreenState extends State<InstructorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal Information controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  
  // Contact Information controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // State
  String _selectedGender = 'Select gender';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<String> _selectedSections = [];
  List<String> _selectedYearLevels = [];
  List<String> _selectedCourses = [];
  
  // New guided assignment selections
  String _currentYearLevel = 'Select year level';
  String _currentSection = 'Select section';
  String _currentCourse = 'Select course';
  final List<Map<String, String>> _assignmentCombos = [];
  final List<String> _assignmentLabels = [];

  // Select-option lists for guided flow
  final List<String> _sectionSelectOptions = const [
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

  final List<String> _yearLevelSelectOptions = const [
    'Select year level',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  final List<String> _courseSelectOptions = const [
    'Select course',
    'BS Computer Science',
    'BS Information Technology',
    'BS Information Systems',
    'BS Computer Engineering',
    'BS Data Science',
    'BS Cybersecurity',
    'BS Software Engineering',
  ];
  
  final List<String> _genderOptions = const [
    'Select gender',
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> _sectionOptions = const [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
  ];

  final List<String> _yearLevelOptions = const [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  final List<String> _courseOptions = const [
    'Computer Science 101',
    'Data Structures and Algorithms',
    'Database Management Systems',
    'Web Development',
    'Mobile App Development',
    'Software Engineering',
    'Computer Networks',
    'Operating Systems',
    'Artificial Intelligence',
    'Machine Learning',
    'Cybersecurity',
    'Human-Computer Interaction',
  ];

  @override
  void initState() {
    super.initState();
    // Clear any existing errors when entering signup screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.clearError();
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
    // Comprehensive form validation before any Firebase calls
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation checks
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
    final age = int.tryParse(_ageController.text);
    if (age == null || age < 18 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid age between 18 and 100'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Validate gender selection
    if (_selectedGender == 'Select gender') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Validate password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Validate password length
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Validate at least one guided assignment
    if (_assignmentCombos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one year-section-course assignment'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // All validation passed - proceed with registration
    try {
      // Build combined assignment strings from guided combos
      final assignedYearSectionCourses = _assignmentCombos
          .map((c)=>'${c['yearLevel']} ${c['section']} | ${c['course']}')
          .toSet()
          .toList();

      final instructorService = InstructorRegistrationService();
      final result = await instructorService.createPendingInstructorAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        assignedYearSectionCourses: assignedYearSectionCourses,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to verification screen
          Navigator.pushReplacementNamed(
            context,
            '/verification-code',
            arguments: {
              'email': _emailController.text.trim(),
              'userType': 'instructor',
            },
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Registration failed'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // Test Firebase connection for debugging
  Future<void> _testFirebaseConnection() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.testFirebaseConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Test completed'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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

              // First Name
              _buildInputField(
                controller: _firstNameController,
                label: 'First Name',
                hintText: 'John',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Middle Name
              _buildInputField(
                controller: _middleNameController,
                label: 'Middle Name',
                hintText: 'Michael',
                prefixIcon: Icons.person,
                validator: (value) {
                  return null; // Middle name is optional
                },
              ),

              const SizedBox(height: 16),

              // Last Name
              _buildInputField(
                controller: _lastNameController,
                label: 'Last Name',
                hintText: 'Doe',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Age
              _buildInputField(
                controller: _ageController,
                label: 'Age',
                hintText: 'Enter your age',
                prefixIcon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) {
                    return 'Please enter a valid age between 18 and 100';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Gender
              Text(
                'Gender',
                style: AppTextStyles.textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
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

              const SizedBox(height: 16),

              // Teaching Assignments
              Text(
                'Teaching Assignments',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Year Level',
                value: _currentYearLevel,
                items: _yearLevelSelectOptions,
                onChanged: (value) => setState(() => _currentYearLevel = value ?? 'Select year level'),
                validator: (value) {
                  if (value == null || value == 'Select year level') {
                    return 'Please select a year level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Section',
                value: _currentSection,
                items: _sectionSelectOptions,
                onChanged: (value) => setState(() => _currentSection = value ?? 'Select section'),
                validator: (value) {
                  if (value == null || value == 'Select section') {
                    return 'Please select a section';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Course',
                value: _currentCourse,
                items: _courseSelectOptions,
                onChanged: (value) => setState(() => _currentCourse = value ?? 'Select course'),
                validator: (value) {
                  if (value == null || value == 'Select course') {
                    return 'Please select a course';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final valid = _currentYearLevel != 'Select year level' &&
                                    _currentSection != 'Select section' &&
                                    _currentCourse != 'Select course';
                      if (!valid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select year, section, and course before adding'),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                        return;
                      }
                      final label = '$_currentYearLevel $_currentSection | $_currentCourse';
                      final exists = _assignmentLabels.contains(label);
                      if (!exists) {
                        setState(() {
                          _assignmentCombos.add({
                            'yearLevel': _currentYearLevel,
                            'section': _currentSection,
                            'course': _currentCourse,
                          });
                          _assignmentLabels.add(label);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Assignment',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add multiple combinations as needed.',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_assignmentLabels.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _assignmentLabels.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    return Chip(
                      label: Text(label),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () {
                        setState(() {
                          _assignmentLabels.removeAt(idx);
                          _assignmentCombos.removeAt(idx);
                        });
                      },
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),
              
              // Contact Information
              Text(
                'Contact Information',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Email Address
              _buildInputField(
                controller: _emailController,
                label: 'Email Address',
                hintText: 'example@gmail.com',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              // Text(
              //   'Please use a Gmail address',
              //   style: AppTextStyles.textTheme.bodySmall?.copyWith(
              //     color: AppColors.textSecondary,
              //   ),
              // ),

              const SizedBox(height: 16),

              // Password
              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Enter your password',
                isVisible: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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

              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                isVisible: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
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
                child: Consumer<AuthProvider>(
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

              const SizedBox(height: 24),

              // Error Display - Only show when there's an actual error
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.error != null && authProvider.error!.isNotEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        authProvider.error!,
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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
    required IconData prefixIcon,
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
            prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
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
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(Icons.lock, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
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
}
