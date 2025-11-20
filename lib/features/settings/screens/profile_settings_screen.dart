import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/data/models/user.dart';
import '../../../core/services/profile_picture_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'JS';
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    return 'JS';
  }
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  File? _selectedImageFile;
  bool _isUpdatingProfile = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty text, will be populated in didChangeDependencies
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get user data from auth provider and populate controllers
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUserModel;
    
    if (user != null) {
      // Use fullName from Firestore, or construct from individual fields
      String fullName = user.fullName ?? '';
      
      // If fullName is empty, construct from firstName and lastName
      if (fullName.isEmpty) {
        final firstName = user.firstName ?? '';
        final lastName = user.lastName ?? '';
        
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          fullName = '$firstName $lastName'.trim();
        } else if (firstName.isNotEmpty) {
          fullName = firstName;
        } else if (lastName.isNotEmpty) {
          fullName = lastName;
        }
      }
      
      _fullNameController.text = fullName;
      _emailController.text = user.email;
      _bioController.text = '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Handle profile picture selection
  Future<void> _selectProfilePicture() async {
    try {
      final File? selectedImage = await _profilePictureService.showImagePickerDialog(context);
      
      if (selectedImage != null) {
        setState(() {
          _selectedImageFile = selectedImage;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture selected! Tap Save to update.'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting profile picture: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Simple test method for direct image picking
  Future<void> _testDirectImagePicker(ImageSource source) async {
    try {
      File? selectedImage;
      if (source == ImageSource.gallery) {
        selectedImage = await _profilePictureService.pickImageFromGallery();
      } else if (source == ImageSource.camera) {
        selectedImage = await _profilePictureService.takePhotoWithCamera();
      }
      
      if (selectedImage != null) {
        setState(() {
          _selectedImageFile = selectedImage;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected from ${source.name}! Tap Save to update.'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No image selected from ${source.name}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error with ${source.name}: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Get profile picture widget
  Widget _getProfilePicture(UserModel? user) {
    if (_selectedImageFile != null) {
      // Show selected image
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_selectedImageFile!),
        backgroundColor: AppColors.primaryBlue,
      );
    } else if (user?.profilePicture != null && user!.profilePicture.isNotEmpty) {
      // Show existing profile picture
      try {
        // Try to decode as base64 first
        if (user.profilePicture.startsWith('data:image') || user.profilePicture.length > 100) {
          // This is likely a base64 image
          final imageWidget = _profilePictureService.base64ToImage(user.profilePicture);
          if (imageWidget != null) {
            return CircleAvatar(
              radius: 60,
              backgroundImage: imageWidget.image as ImageProvider?,
              backgroundColor: AppColors.primaryBlue,
            );
          }
        } else {
          // This might be a file path
          final file = File(user.profilePicture);
          if (file.existsSync()) {
            return CircleAvatar(
              radius: 60,
              backgroundImage: FileImage(file),
              backgroundColor: AppColors.primaryBlue,
            );
          }
        }
      } catch (e) {
        // Fallback to initials if there's an error
      }
    }
    
    // Fallback to initials
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppColors.primaryBlue,
      child: Text(
        _getInitials(user?.fullName) ?? 'JS',
        style: AppTextStyles.textTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdatingProfile = true;
      });
      
      try {
        final authProvider = context.read<AuthProvider>();
        final currentUser = authProvider.currentUserModel;
        
        if (currentUser != null) {
          String? updatedProfilePicture = currentUser.profilePicture;
          
          // Handle profile picture update
          if (_selectedImageFile != null) {
            // Convert image to base64 for storage
            updatedProfilePicture = await _profilePictureService.imageToBase64(_selectedImageFile!);
            
            if (updatedProfilePicture == null) {
              throw Exception('Failed to process profile picture');
            }
          }
          
          // Create updated user data
          final updatedUserData = {
            'displayName': _fullNameController.text.trim(),
            'profilePicture': updatedProfilePicture,
          };
          
          // Update profile
          final success = await authProvider.updateProfile(updatedUserData);
          
          if (success && mounted) {
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
            
            // Clear selected image file
            setState(() {
              _selectedImageFile = null;
            });
            
            // Navigate back to dashboard
            Navigator.pop(context);
          } else {
            throw Exception('Failed to update profile');
          }
        }
      } catch (e) {
        debugPrint('Error updating profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUpdatingProfile = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUserModel;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Check if we can go back to instructor dashboard
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If no previous route, navigate based on user role
              if (user?.isStudent == true) {
                Navigator.pushNamedAndRemoveUntil(context, '/student-dashboard', (route) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/instructor-dashboard', (route) => false);
              }
            }
          },
        ),
        title: Text(
          'Profile Settings',
          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isUpdatingProfile ? null : _saveProfile,
            child: _isUpdatingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      _getProfilePicture(user),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _selectProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Change Photo Button
                  TextButton(
                    onPressed: _selectProfilePicture,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Change Photo',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  

                ],
              ),
            ),
            
            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Personal Information Section
                    _FormSection(
                      title: 'Personal Information',
                      children: [
                        _FormField(
                          label: 'Full Name',
                          controller: _fullNameController,
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _FormField(
                          label: 'Email',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Bio Section
                    _FormSection(
                      title: 'Bio',
                      children: [
                        _FormField(
                          label: 'About Me',
                          controller: _bioController,
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bio is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Section Content
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Input Field
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20,
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
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
