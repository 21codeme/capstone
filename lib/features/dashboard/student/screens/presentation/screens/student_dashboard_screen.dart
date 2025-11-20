import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show ScrollDirection;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathfitcapstone/features/dashboard/student/screens/presentation/screens/widgets/student_quiz_list_tile.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../../features/auth/data/models/user.dart';
import '../../../../../../core/services/mock_backend_service.dart';
import '../../../../../../core/models/dashboard.dart';
import '../../../../../../core/models/module.dart';
import '../../../../../../core/services/profile_picture_service.dart';
import '../../../../../../core/services/module_service.dart'; // Added ModuleService
import 'dart:io';
import 'dart:async';
import '../../../../../../core/services/student_progress_service.dart';
import '../../../../../../core/services/firebase_auth_service.dart';
import '../../../../../../core/services/bmi_service.dart';
import '../../../../../../core/services/file_download_service.dart';
import '../../../../../../core/widgets/loading_widgets.dart';
import '../../../../../../core/utils/name_formatter.dart';
import 'student_bmi_screen.dart';
import 'module_viewer_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;
  StudentDashboard? _dashboard;
  bool _isLoading = true;
  String? _error;
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final ScrollController _scrollController = ScrollController();
  final ModuleService _moduleService = ModuleService(); // Added ModuleService
  final StudentProgressService _progressService = StudentProgressService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final BmiService _bmiService = BmiService();
  final FileDownloadService _downloadService = FileDownloadService();

  // Swipe-up refresh state
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  static const double _refreshOverscrollThreshold = 80.0; // make gesture harder

  
  // Module-related state variables
  Map<String, Map<String, dynamic>> _categoryStats = {};
  bool _isLoadingModules = false;
  
  // Classroom-related state variables
  List<Map<dynamic, dynamic>> _classroomModules = [];
  List<Map<dynamic, dynamic>> _filteredModules = [];
  String _selectedModuleFilter = 'All types';
String _selectedFileType = 'All';
final List<String> _fileTypes = ['All', 'PDF', 'DOC', 'DOCX', 'PPT', 'PPTX'];

// Section filter state
List<String> _studentSections = [];
String _selectedSectionName = 'All sections';
bool _isLoadingSections = false;
  final Map<String, bool> _downloadingModules = {};
  
  // Progress-related state variables
  double _overallProgress = 0.0;
  Map<String, dynamic> _progressData = {};
  bool _isLoadingProgress = true;
  double _bmiProgress = 0.0;
  double _currentBMI = 0.0;

  // Quiz activity (studentScores) state
  List<Map<dynamic, dynamic>> _quizActivities = [];
  bool _isLoadingQuizActivities = false;
  int _completedTaskActivities = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadModuleStats();
    _loadProgress();
    _loadQuizActivities();
    _loadClassroomModules();
    
    // Test module access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testModuleAccess();
      // Check if user has BMI data after dashboard loads
      _checkBmiData();
    });
  }

  // Test method to check module access
  Future<void> _testModuleAccess() async {
    try {
      await _moduleService.testModuleAccess();
    } catch (e) {
      print('âŒ Error testing module access: $e');
    }
  }

  /// Check if user has BMI data and show floating message if missing
  Future<void> _checkBmiData() async {
    try {
      final hasBmiData = await _bmiService.hasBmiData();
      final canUpdateResult = await _bmiService.canUpdateBMI();
      
      if (!hasBmiData && mounted) {
        // Show floating message to update BMI
        _showBmiUpdateMessage();
      } else if (hasBmiData && !canUpdateResult['canUpdate'] && mounted) {
        // Show message if BMI was recently updated and cannot be updated again
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(canUpdateResult['reason'] ?? 'BMI cannot be updated at this time'),
            backgroundColor: AppColors.warningOrange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('âŒ Error checking BMI data: $e');
    }
  }

  /// Show floating message to update BMI
  void _showBmiUpdateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please update your BMI information to track your fitness progress!'),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Update BMI',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to BMI screen
            Navigator.pushNamed(context, '/student-bmi');
          },
        ),
      ),
    );
  }

  /// Get appropriate icon for subject/module type
  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'movement':
        return Icons.directions_run;
      case 'nutrition':
        return Icons.restaurant;
      case 'assessment':
        return Icons.assessment;
      case 'module':
        return Icons.book;
      default:
        return Icons.school;
    }
  }

  /// Get time ago string from date
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get color based on score
  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.successGreen;
    if (score >= 80) return AppColors.primaryBlue;
    if (score >= 70) return AppColors.warningOrange;
    if (score >= 60) return AppColors.warningOrange;
    return AppColors.errorRed;
  }

  /// Load student progress data
  Future<void> _loadProgress() async {
    try {
      setState(() {
        _isLoadingProgress = true;
      });

      final currentUser = _authService.currentUser;
      print('👤 Current user from auth service: ${currentUser?.uid}');
      if (currentUser != null) {
        print('🔄 Loading progress for user: ${currentUser.uid}');
        // Calculate overall progress
        final overallProgress = await StudentProgressService.calculateOverallProgress(currentUser.uid);
        print('📊 Overall progress calculated: $overallProgress');
        
        // Get detailed progress data
        final progressData = await _progressService.getProgressData(currentUser.uid);
        
        // Get weekly streak
        final weeklyStreak = await StudentProgressService.getWeeklyStreak(currentUser.uid);

        // Compute BMI progress per user using baseline from history
        double bmiProgress = 0.0;
        double currentBMI = 0.0; // Initialize currentBMI variable
        try {
          const double targetBMI = 22.0; // Healthy target

          // Fetch current BMI
          final latestBmiDoc = await _bmiService.getLatestBmiData();
          currentBMI = (latestBmiDoc?['bmi'] as num?)?.toDouble() ?? 0.0;

          // Fetch history to get baseline (earliest record)
          final bmiHistory = await _bmiService.getBmiHistory();
          double baselineBMI = currentBMI;
          if (bmiHistory.isNotEmpty) {
            // getBmiHistory returns descending by timestamp, earliest is last
            final Map<dynamic, dynamic> earliest = bmiHistory.last;
            final double earliestBmi = (earliest['bmi'] as num?)?.toDouble() ?? currentBMI;
            baselineBMI = earliestBmi;
          }

          if (currentBMI > 0) {
            final double baselineDistance = (baselineBMI - targetBMI).abs();
            final double currentDistance = (currentBMI - targetBMI).abs();
            double progressPercent;

            if (baselineDistance <= 0.0) {
              // Baseline already at target
              progressPercent = currentDistance <= 0.0 ? 100.0 : 0.0;
            } else {
              progressPercent = ((baselineDistance - currentDistance) / baselineDistance) * 100.0;
            }

            bmiProgress = progressPercent.clamp(0.0, 100.0);
          }
        } catch (e) {
          print('⚠️ Error computing BMI progress: $e');
        }
        
        // Combine all data
        final combinedProgressData = Map<String, dynamic>.from({
          ...progressData,
          'weeklyStreak': weeklyStreak,
        });
        
        if (mounted) {
          print('🔄 Setting progress in state: $overallProgress');
          setState(() {
            _overallProgress = overallProgress;
            _progressData = combinedProgressData;
            _isLoadingProgress = false;
            _bmiProgress = bmiProgress;
            _currentBMI = currentBMI;
          });
          print('✅ Progress state updated to: $_overallProgress');
        }
      } else {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      print('âŒ Error loading progress: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  /// Load recent quiz attempts from studentScores for Activity Progress
  Future<void> _loadQuizActivities() async {
    try {
      setState(() {
        _isLoadingQuizActivities = true;
      });

      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final activities = await _progressService.getStudentLearningActivities(
          currentUser.uid,
          '',
        );
        // Count all completed task activities (across studentScores)
        final completedCount = await _progressService.getCompletedTaskActivityCount(
          currentUser.uid,
        );

        if (mounted) {
          setState(() {
            _quizActivities = activities;
            _completedTaskActivities = completedCount;
            _isLoadingQuizActivities = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _quizActivities = [];
            _completedTaskActivities = 0;
            _isLoadingQuizActivities = false;
          });
        }
      }
    } catch (e) {
      print('âŒ Error loading quiz activities: $e');
      if (mounted) {
        setState(() {
          _quizActivities = [];
          _completedTaskActivities = 0;
          _isLoadingQuizActivities = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }





  /// Load module statistics for all categories
  Future<void> _loadModuleStats() async {
    setState(() {
      _isLoadingModules = true;
    });

    try {
      print('ðŸ”„ Loading module statistics...');
      final stats = await _moduleService.getAllCategoriesStats();
      
      if (mounted) {
        setState(() {
          _categoryStats = stats;
          _isLoadingModules = false;
        });
        print('âœ… Module stats loaded: ${stats.length} categories');
      }
    } catch (e) {
      print('âŒ Error loading module stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingModules = false;
        });
      }
    }
  }

  /// Get profile picture widget for student
  String _getInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) return 'AJ';
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    return 'AJ';
  }

  Widget _getStudentProfilePicture(UserModel? user) {
    if (user?.profilePicture != null && user!.profilePicture.isNotEmpty) {
      try {
        // Try to decode as base64 first
        if (user.profilePicture.startsWith('data:image') || user.profilePicture.length > 100) {
          // This is likely a base64 image
          final imageWidget = _profilePictureService.base64ToImage(user.profilePicture);
          if (imageWidget != null) {
            return CircleAvatar(
              radius: 30,
              backgroundImage: imageWidget.image as ImageProvider?,
              backgroundColor: AppColors.primaryBlue,
            );
          }
        } else {
          // This might be a file path
          final file = File(user.profilePicture);
          if (file.existsSync()) {
            return CircleAvatar(
              radius: 30,
              backgroundImage: FileImage(file),
              backgroundColor: AppColors.primaryBlue,
            );
          }
        }
      } catch (e) {
        // Fallback to initials if there's an error
        debugPrint('Error loading student profile picture: $e');
      }
    }
    
    // Fallback to initials
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.primaryBlue,
      child: Text(
                      _getInitials(user?.fullName) ?? 'AJ',
        style: AppTextStyles.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load dashboard data (don't reinitialize mock data - it overwrites user content)
      final response = await MockBackendService.instance.getStudentDashboard('student_1');
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _dashboard = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Fitness Education';
      case 1:
        return 'Classroom';
      case 2:
        return 'Progress';
      case 3:
        return 'BMI';
      case 4:
        return 'Profile';
      default:
        return 'Fitness Education';
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_currentIndex) {
      case 0:
        return [];
      case 1:
        return [];
      case 4:
        return [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ];
      default:
        return [];
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Dashboard',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for modules, materials, or topics...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Search',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Dashboard',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Type',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text('Modules'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: Text('Materials'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: Text('Topics'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: Text('Progress'),
                  selected: true,
                  onSelected: (selected) {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Difficulty Level',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text('Beginner'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: Text('Intermediate'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: Text('Advanced'),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Filters applied successfully!'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              'Apply Filters',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildClassroomContent();
      case 2:
        return _buildProgressContent();
      case 3:
        // Embed BMI screen content while keeping bottom navigation visible
        return const StudentBmiScreen();
      case 4:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final user = context.watch<AuthProvider>().currentUserModel;
    
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Row(
            children: [
              // Profile Picture with Upload Button
              Stack(
                children: [
                  _getStudentProfilePicture(user),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      user?.fullName ?? 'Alex Johnson',
                      style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ready to continue your fitness journey?',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          

          // Move "Your Quizzes" under Today's Progress (from Classroom)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final course = authProvider.currentUserModel?.course;
              final year = authProvider.currentUserModel?.year;
              final section = authProvider.currentUserModel?.section;

              if (course == null || year == null || section == null ||
                  course.isEmpty || year.isEmpty || section.isEmpty) {
                return const SizedBox.shrink();
              }

              final query = FirebaseFirestore.instance
                  .collection('courseQuizzes')
                  .where('course', isEqualTo: course)
                  .where('year', isEqualTo: year)
                  .where('section', isEqualTo: section);

              return Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Quizzes',
                          style: AppTextStyles.textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: query.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.errorRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Failed to load quizzes',
                                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.errorRed),
                                ),
                              ),
                            ],
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        // Filter by availability window on client to avoid index requirements
                        final now = DateTime.now();
                        final availableDocs = docs.where((d) {
                          final data = d.data();
                          final fromTs = data['availableFrom'] as Timestamp?;
                          final untilTs = data['availableUntil'] as Timestamp?;
                          if (fromTs != null && now.isBefore(fromTs.toDate())) return false;
                          if (untilTs != null && now.isAfter(untilTs.toDate())) return false;
                          return true;
                        }).toList();
                        if (availableDocs.isEmpty) {
                          return Row(
                            children: [
                              Icon(Icons.quiz_outlined, size: 32, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No available quizzes right now',
                                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            for (final doc in availableDocs) ...[
                              StudentQuizListTile(
                                title: (doc.data()['title'] as String?) ?? 'Quiz',
                                subtitle: ((doc.data()['topic'] as String?)?.isNotEmpty == true)
                                    ? (doc.data()['topic'] as String)
                                    : ((doc.data()['label'] as String?) ?? ''),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/student-quiz-view',
                                    arguments: {'quizId': doc.id},
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Boilerplate topic grid (student home)
          Text(
            'Learning Topics',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a topic to explore.',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final topics = [
                {
                  'label': 'Understanding Movements',
                  'icon': Icons.directions_run,
                  'color': AppColors.primaryBlue,
                },
                {
                  'label': 'Musculoskeletal Basis',
                  'icon': Icons.healing,
                  'color': AppColors.secondaryBlue,
                },
                {
                  'label': 'Discrete Skills',
                  'icon': Icons.sports_handball,
                  'color': AppColors.successGreen,
                },
                {
                  'label': 'Throwing & Catching',
                  'icon': Icons.sports_baseball,
                  'color': AppColors.warningOrange,
                },
                {
                  'label': 'Serial Skills',
                  'icon': Icons.timeline,
                  'color': AppColors.darkBlue,
                },
                {
                  'label': 'Continuous Skills',
                  'icon': Icons.loop,
                  'color': AppColors.accentBlue,
                },
              ];

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final item = topics[index];
                  final Color color = item['color'] as Color;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final label = item['label'] as String;
                      if (label == 'Understanding Movements') {
                        Navigator.pushNamed(context, '/movement-topics');
                      } else if (label == 'Musculoskeletal Basis') {
                        Navigator.pushNamed(context, '/musculoskeletal-basis');
                      } else if (label == 'Discrete Skills') {
                        Navigator.pushNamed(context, '/discrete-skills');
                      } else if (label == 'Throwing & Catching') {
                        Navigator.pushNamed(context, '/throwing-catching');
                      } else if (label == 'Serial Skills') {
                        Navigator.pushNamed(context, '/serial-skills');
                      } else if (label == 'Continuous Skills') {
                        Navigator.pushNamed(context, '/continuous-skills');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$label coming soon')),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['label'] as String,
                            style: AppTextStyles.textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Explore ${item['label']}.',
                            style: AppTextStyles.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildClassroomContent() {
    final user = context.watch<AuthProvider>().currentUserModel;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Your Classroom Section
          Text(
            'Your Classroom',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalized based on your enrolled section and year level',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Academic Information Cards
          Row(
            children: [
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return _buildAcademicInfoCard(
                      icon: Icons.class_,
                      iconColor: AppColors.primaryBlue,
                      title: 'Section',
                      value: authProvider.currentUserModel?.section ?? 'Not Set',
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return _buildAcademicInfoCard(
                      icon: Icons.star,
                      iconColor: AppColors.successGreen,
                      title: 'Year Level',
                      value: authProvider.currentUserModel?.year ?? 'Not Set',
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Course Card
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return _buildAcademicInfoCard(
                icon: Icons.school,
                iconColor: AppColors.warningOrange,
                title: 'Course',
                value: authProvider.currentUserModel?.course ?? 'Not Set',
                isFullWidth: true,
              );
            },
          ),
          
          const SizedBox(height: 24),

          // (Moved) Your Quizzes section has been relocated to Home under Today's Progress

          const SizedBox(height: 32),

          // Check if user is a student before showing modules
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isStudent) {
                // Don't show modules for non-students
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modules Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Modules',
                        style: AppTextStyles.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_filteredModules.length} modules',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Lazy-load student sections once on first build
                  Builder(
                    builder: (context) {
                      if (_studentSections.isEmpty && !_isLoadingSections) {
                        _isLoadingSections = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          try {
                            final authProvider = context.read<AuthProvider>();
                            final uid = authProvider.currentUser?.uid;
                            if (uid != null) {
                              final snapshot = await FirebaseFirestore.instance
                                  .collection('studentProgress')
                                  .where('studentId', isEqualTo: uid)
                                  .get();
                              final sections = snapshot.docs
                                  .map((d) => ((d.data()['section'] as String?) ?? (d.data()['sectionName'] as String?) ?? '').trim())
                                  .where((s) => s.isNotEmpty)
                                  .toSet()
                                  .toList();
                              setState(() {
                                _studentSections = sections;
                                _isLoadingSections = false;
                                final defaultSection = authProvider.currentUserModel?.section;
                                if (defaultSection != null && defaultSection.isNotEmpty && sections.contains(defaultSection)) {
                                  _selectedSectionName = defaultSection;
                                }
                              });
                            } else {
                              setState(() => _isLoadingSections = false);
                            }
                          } catch (e) {
                            setState(() => _isLoadingSections = false);
                          }
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 12),

                  // Section Filter Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.group, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: (_studentSections.isEmpty && !_isLoadingSections)
                                  ? null
                                  : _selectedSectionName,
                              hint: Text(
                                _isLoadingSections ? 'Loading sectionsâ€¦' : 'Select section',
                                style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: 'All sections',
                                  child: Text('All sections'),
                                ),
                                ..._studentSections.map((s) => DropdownMenuItem<String>(
                                      value: s,
                                      child: Text(s),
                                    ))
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  _selectedSectionName = val;
                                });
                                _loadClassroomModules();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // File Type Filter Buttons
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fileTypes.length,
                      itemBuilder: (context, index) {
                        final fileType = _fileTypes[index];
                        final isSelected = _selectedFileType == fileType;
                        
                        return Padding(
                          padding: EdgeInsets.only(right: index < _fileTypes.length - 1 ? 8 : 0),
                          child: FilterChip(
                            label: Text(fileType),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFileType = fileType;
                                _filterModulesByFileType();
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryBlue,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Modules List with Sticky Scroll Container
                  Container(
                    height: 400, // Fixed height for sticky scroll
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isLoadingModules
                        ? const Center(
                            child: ModernLoadingWidget(),
                          )
                        : _classroomModules.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.library_books_outlined,
                                      size: 64,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No modules available',
                                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Check back later for new learning materials',
                                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredModules.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.filter_list_off,
                                          size: 64,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No ${_selectedFileType.toLowerCase()} files found',
                                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try selecting a different file type',
                                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _filteredModules.length,
                                    itemBuilder: (context, index) {
                                      final module = _filteredModules[index];
                                      return _buildModuleListItem(module);
                                    },
                                  ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildProgressContent() {
    final user = context.watch<AuthProvider>().currentUserModel;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Overall Progress Section
          Center(
            child: Column(
              children: [
                // Circular Progress Indicator
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      // Background Circle
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      // Progress Circle
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _isLoadingProgress ? 0.0 : _overallProgress,
                          strokeWidth: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      // Center Text
                      Center(
                        child: Text(
                          _isLoadingProgress 
                              ? '...' 
                              : '${(_overallProgress * 100).round()}%',
                          style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Overall Progress',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Summary Metrics
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.school,
                  value: _isLoadingQuizActivities ? '...' : '$_completedTaskActivities',
                  label: 'Task Completed',
                  color: AppColors.successGreen,
                  onTap: () => _showMetricDetail(context, 'Task Completed', '$_completedTaskActivities', 'Total task activities you\'ve completed'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  icon: Icons.monitor_weight,
                  value: _isLoadingProgress ? '...' : (_currentBMI > 0 ? _currentBMI.toStringAsFixed(1) : '—'),
                  label: 'Current BMI',
                  color: AppColors.warningOrange,
                  onTap: () => _showMetricDetail(context, 'Current BMI', _currentBMI > 0 ? _currentBMI.toStringAsFixed(1) : 'No data', 'Your current Body Mass Index'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Activity Progress Section
          Text(
            'Recent Activities',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Dynamic subject progress based on quiz types
          if (_progressData['subjectProgress'] != null && _progressData['subjectProgress'] is Map) ...[
            ...(_progressData['subjectProgress'] as Map<dynamic, dynamic>).entries.map((entry) {
              final subject = entry.key.toString();
              final progress = entry.value is num ? (entry.value as num).toDouble() : 0.0;
              final status = _progressService.getProgressStatus(progress * 100);
              final color = Color(_progressService.getProgressColor(progress * 100));
              
              return Column(
                children: [
                  _SubjectProgressCard(
                    subject: subject,
                    progress: progress,
                    status: status,
                    icon: _getSubjectIcon(subject),
                    color: color,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],

          // Quiz attempts from studentScores
          if (_isLoadingQuizActivities)
            const ModernLoadingWidget()
          else if (_quizActivities.isEmpty)
            Text(
              'No quiz attempts yet',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            ..._quizActivities.map((activity) {
              final double percentage = (activity['percentage'] ?? 0.0) as double;
              final Color scoreColor = _getScoreColor(percentage);
              final dynamic completedAt = activity['completedAt'];
              DateTime? completedDate;
              if (completedAt is Timestamp) {
                completedDate = completedAt.toDate();
              } else if (completedAt is String) {
                completedDate = DateTime.tryParse(completedAt);
              }
              final String dateLabel = completedDate != null
                  ? _getTimeAgo(completedDate)
                  : 'Recently';

              return Column(
                children: [
                  _ActivityCard(
                    title: activity['title']?.toString() ?? 'Quiz',
                    date: dateLabel,
                    score: '${percentage.round()}%',
                    icon: Icons.assignment,
                    color: scoreColor,
                    onTap: () => _showActivityDetail(
                      context,
                      activity['title']?.toString() ?? 'Quiz',
                      '${percentage.toStringAsFixed(1)}%',
                      completedDate?.toLocal().toString() ?? 'N/A',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
          
          // Removed static "Module Progress" card under Recent Activities to declutter progress page.
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    // Automatically navigate to settings page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/settings');
    });
    
    // Return a loading placeholder while navigation happens
    return const Center(
      child: ModernLoadingWidget(),
    );
  }





  void _showMaterialDetail(BuildContext context, Map<String, dynamic> material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          material['title'] as String,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Type: ${material['type']}',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${material['duration']}',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${material['progress'] * 100}%',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Start Learning',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetail(BuildContext context, String title, String score, String date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Date: $date',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecommendedDetail(BuildContext context, String title, String level, String duration, int questionCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level: $level',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: $duration',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Questions: $questionCount',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Start Learning',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricDetail(BuildContext context, String title, String value, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Value: $value',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Description: $description',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _currentIndex == 3
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                _getAppBarTitle(),
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: _getAppBarActions(),
            ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (_isRefreshing) return false;
          try {
            if (notification is OverscrollNotification) {
              // Trigger only on significant overscroll beyond bounds
              if (notification.overscroll.abs() > _refreshOverscrollThreshold) {
                _onSwipeUpRefresh();
              }
            }
          } catch (_) {}
          return false;
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Handle navigation based on index
          switch (index) {
            case 0: // Home - already on dashboard
              setState(() {
                _currentIndex = index;
              });
              break;
            case 1: // Classroom
              setState(() {
                _currentIndex = index;
              });
              break;
            case 2: // Progress
              setState(() {
                _currentIndex = index;
              });
              break;
            case 3: // BMI - render within dashboard to keep bottom nav
              setState(() {
                _currentIndex = index;
              });
              break;
            case 4: // Profile - Navigate to Profile screen
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Classroom',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: 'BMI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _onSwipeUpRefresh() async {
    if (_isRefreshing) return;
    final now = DateTime.now();
    if (_lastRefreshTime != null && now.difference(_lastRefreshTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastRefreshTime = now;

    setState(() {
      _isRefreshing = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing content...')),
    );

    try {
      await FirebaseFirestore.instance.disableNetwork();
      await Future.delayed(const Duration(milliseconds: 300));
      await FirebaseFirestore.instance.enableNetwork();

      await Future.wait([
        _loadDashboard(),
        _loadModuleStats(),
        _loadProgress(),
        _loadQuizActivities(),
        _loadClassroomModules(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildModuleCard(Module module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.book,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.description,
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${module.durationMinutes ?? 0} min',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.warningOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      module.rating.toStringAsFixed(1),
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => _showModuleDetails(module),
          ),
        ],
      ),
    );
  }



  Widget _buildActivityCard(RecentActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(activity.timestamp),
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'module_completed':
        return Icons.check_circle;
      case 'module_uploaded':
        return Icons.upload;
      case 'module_accessed':
        return Icons.visibility;
      case 'progress_updated':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  String _formatDate(dynamic date) {
    DateTime dateTime;
    
    if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return 'Invalid date';
      }
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Invalid date';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showModuleDetails(Module module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(module.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(module.description),
            const SizedBox(height: 16),
            Text('Duration: ${module.durationMinutes ?? 0} minutes'),
            Text('Difficulty: ${module.difficultyLevel?.toString().split('.').last ?? 'Not specified'}'),
            Text('Rating: ${module.rating.toStringAsFixed(1)}/5.0'),
            Text('Views: ${module.viewCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to module content
            },
            child: const Text('Start Module'),
          ),
        ],
      ),
    );
  }



  /// Upload profile picture from dashboard
  Future<void> _uploadProfilePicture() async {
    try {
      debugPrint('Student Dashboard: Starting profile picture upload...');
      
      final File? selectedImage = await _profilePictureService.showImagePickerDialog(context);
      
      if (selectedImage != null) {
        debugPrint('Student Dashboard: Image selected: ${selectedImage.path}');
        
        // Convert to base64
        final String? base64Image = await _profilePictureService.imageToBase64(selectedImage);
        
        if (base64Image != null) {
          // Update user profile
          final authProvider = context.read<AuthProvider>();
          final currentUser = authProvider.currentUserModel;
          
          if (currentUser != null) {
            final updatedUser = currentUser.copyWith(
              profilePicture: base64Image,
              lastLogin: DateTime.now(),
            );
            
            final success = await authProvider.updateProfileWithUserModel(updatedUser);
            
            if (success && mounted) {
              setState(() {
                // Trigger rebuild to show new image
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture updated successfully!'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            } else {
              throw Exception('Failed to update profile picture');
            }
          }
        } else {
          throw Exception('Failed to process image');
        }
      }
    } catch (e) {
      debugPrint('Student Dashboard: Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Navigate to module category screen
  void _navigateToModuleCategory(String category) {
    Navigator.pushNamed(
      context, 
      '/module-category',
      arguments: {
        'category': category,
        'categoryStats': _categoryStats[category],
      },
    );
  }

  // Helper method for building information rows in classroom content
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for building schedule items
  Widget _buildScheduleItem({
    required String day,
    required String time,
    required String subject,
    required String room,
  }) {
    return Row(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            day.substring(0, 3).toUpperCase(),
            style: AppTextStyles.textTheme.bodySmall?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: AppTextStyles.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    room,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build academic info cards
  Widget _buildAcademicInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build classroom module cards
  Widget _buildClassroomModuleCard(Map<dynamic, dynamic> module) {
    final String fileExtension = module['fileExtension']?.toString().toUpperCase() ?? 'FILE';
    final String title = module['title']?.toString() ?? 'Untitled Module';
    final String instructorName = (module['fullName'] ?? module['instructorName'] ?? 'Unknown Instructor').toString();
    final String category = module['category']?.toString() ?? 'General';
    
    Color getFileTypeColor(String extension) {
      switch (extension.toLowerCase()) {
        case 'pdf':
          return Colors.red;
        case 'doc':
        case 'docx':
          return Colors.blue;
        case 'ppt':
        case 'pptx':
          return Colors.orange;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'image':
          return Colors.green;
        default:
          return AppColors.primaryBlue;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: getFileTypeColor(fileExtension).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                fileExtension,
                style: TextStyle(
                  color: getFileTypeColor(fileExtension),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Module info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$category â€¢ by $instructorName',
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () {
                  // Handle view action
                  _viewModule(module);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'View',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Handle download action
                  _downloadModule(module);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Download',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build module list items with the new design
  Widget _buildModuleListItem(Map<dynamic, dynamic> module) {
    final String fileExtension = module['fileExtension']?.toString().toUpperCase() ?? 'FILE';
    final String title = module['title']?.toString() ?? 'Untitled Module';
    final String instructorName = (module['fullName'] ?? module['instructorName'] ?? 'Unknown Instructor').toString();
    final String category = module['category']?.toString() ?? 'General';
    
    Color getFileTypeColor(String extension) {
      switch (extension.toLowerCase()) {
        case 'pdf':
          return Colors.red;
        case 'doc':
        case 'docx':
          return Colors.blue;
        case 'ppt':
        case 'pptx':
          return Colors.orange;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'image':
          return Colors.green;
        default:
          return AppColors.primaryBlue;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File type icon with extension
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: getFileTypeColor(fileExtension).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                fileExtension,
                style: TextStyle(
                  color: getFileTypeColor(fileExtension),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Module info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$category â€¢ by $instructorName',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // View button
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: () {
                    _viewModule(module);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Download button
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _downloadingModules[module['id']] == true 
                      ? Colors.grey 
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: _downloadingModules[module['id']] == true 
                      ? null 
                      : () {
                          _downloadModule(module);
                        },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _downloadingModules[module['id']] == true
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to load classroom modules
  Future<void> _loadClassroomModules() async {
    print('ðŸ”„ Starting to load classroom modules...');
    print('ðŸ” Selected filter: $_selectedModuleFilter');
    
    setState(() {
      _isLoadingModules = true;
    });

    try {
      List<Map<dynamic, dynamic>> modules;
      
      print('ðŸ“¡ Fetching modules from Firebase...');
// NEW: Fetch modules per authenticated student UID
final String? uid = _authService.currentUser?.uid;
if (uid == null) {
  print('âš ï¸ No authenticated user UID found; returning empty module list');
  modules = [];
} else if (_selectedSectionName != 'All sections') {
  print('ðŸ” Filtering by section for student: section=$_selectedSectionName uid=$uid');
  modules = await _moduleService.getStudentModulesForStudent(uid, sectionName: _selectedSectionName);
} else if (_selectedModuleFilter == 'All types') {
  print('ðŸ” Fetching all types for student uid=$uid...');
  modules = await _moduleService.getStudentModulesForStudent(uid);
} else {
  print('ðŸ” Fetching by file type for student: type=$_selectedModuleFilter uid=$uid');
  modules = await _moduleService.getStudentModulesByTypeForStudent(uid, _selectedModuleFilter);
}

      print('âœ… Modules fetched successfully!');
      print('ðŸ“Š Number of modules found: ${modules.length}');
      
      if (modules.isNotEmpty) {
        print('ðŸ“‹ Sample module data:');
        final sampleModule = modules.first;
        sampleModule.forEach((key, value) {
          print('   $key: $value');
        });
      } else {
        print('âŒ No modules found in the collection');
        print('ðŸ” This could mean:');
        print('   1. The studentModules collection is empty');
        print('   2. Firebase rules are blocking access');
        print('   3. The user is not authenticated properly');
        print('   4. Network connectivity issues');
      }

      setState(() {
        _classroomModules = modules;
        _isLoadingModules = false;
      });
      
      // Apply current file type filter
      _filterModulesByFileType();
      
      print('ðŸŽ¯ UI updated with ${modules.length} modules');
    } catch (e) {
      setState(() {
        _isLoadingModules = false;
      });
      print('âŒ Error loading classroom modules: $e');
      print('âŒ Error type: ${e.runtimeType}');
      print('âŒ Stack trace: ${StackTrace.current}');
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load modules: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Method to filter modules by file type
  void _filterModulesByFileType() {
    if (_selectedFileType == 'All') {
      _filteredModules = List.from(_classroomModules);
    } else {
      _filteredModules = _classroomModules.where((module) {
        final fileExtension = module['fileExtension']?.toString().toUpperCase() ?? '';
        final fileName = module['fileName']?.toString().toLowerCase() ?? '';
        
        // Check both file extension and file name for file type
        switch (_selectedFileType) {
          case 'PDF':
            return fileExtension == 'PDF' || fileName.endsWith('.pdf');
          case 'DOC':
          case 'DOCX':
            return fileExtension == 'DOC' || fileExtension == 'DOCX' || 
                   fileName.endsWith('.doc') || fileName.endsWith('.docx');
          case 'PPT':
          case 'PPTX':
            return fileExtension == 'PPT' || fileExtension == 'PPTX' || 
                   fileName.endsWith('.ppt') || fileName.endsWith('.pptx');
          default:
            return true;
        }
      }).toList();
    }
    
    print('ðŸ” Filtered modules: ${_filteredModules.length} out of ${_classroomModules.length} total modules');
  }

  // Method to view a module
  void _viewModule(Map<dynamic, dynamic> module) {
    // Update module views
    if (module['id'] != null) {
      _moduleService.updateModuleStats(module['id'], isDownload: false);
    }
    
    // Navigate to module viewer screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleViewerScreen(module: module),
      ),
    );
  }

  // Method to download a module
  Future<void> _downloadModule(Map<dynamic, dynamic> module) async {
    final moduleId = module['id'] ?? '';
    if (_downloadingModules[moduleId] == true) return; // Prevent multiple downloads
    
    setState(() {
      _downloadingModules[moduleId] = true;
    });

    try {
      // Show downloading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ðŸ“¥ Downloading ${module['title'] ?? 'module'}...'),
          backgroundColor: AppColors.primaryBlue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Get file path from module
      final fileName = module['fileName'] ?? '';
      final moduleTitle = module['title'] ?? 'module';
      final filePath = 'modules/$moduleTitle/$fileName';

      // Guard: ensure file still exists in storage before attempting download
      final exists = await _downloadService.fileExists(filePath);
      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This module file was removed and is no longer available.'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      print('ðŸ”„ Downloading file: $filePath');

      // Download the file
      final result = await _downloadService.downloadFile(
        filePath: filePath,
        fileName: fileName,
        customFileName: '${moduleTitle}_$fileName',
        context: context, // Pass context for permission dialog
      );

      if (result.success && result.file != null) {
        // Update module downloads stats
        if (module['id'] != null) {
          _moduleService.updateModuleStats(module['id'], isDownload: true);
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âœ… Downloaded successfully! File size: ${result.formattedFileSize}'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                await _downloadService.openFile(result.file!);
              },
            ),
          ),
        );

        // Ask if user wants to open the file
        _showOpenFileDialog(result.file!, module['title'] ?? 'module');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âŒ Download failed: ${result.error}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('âŒ Error downloading module: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('âŒ Download error: $e'),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _downloadingModules[moduleId] = false;
      });
    }
  }

  void _showOpenFileDialog(File file, String moduleTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File Downloaded Successfully!'),
        content: Text('Would you like to open "$moduleTitle" now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadService.openFile(file);
            },
            child: Text('Open Now'),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double progress;
  final int moduleCount;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.progress,
    required this.moduleCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive sizing based on available space
            final isSmallScreen = constraints.maxHeight < 120;
            final iconSize = isSmallScreen ? 40.0 : 50.0;
            final iconIconSize = isSmallScreen ? 20.0 : 24.0;
            final spacing = isSmallScreen ? 8.0 : 12.0;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: iconIconSize,
                  ),
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    'Modules: $moduleCount',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive sizing based on available space
            final isSmallScreen = constraints.maxHeight < 100;
            final iconSize = isSmallScreen ? 32.0 : 40.0;
            final iconIconSize = isSmallScreen ? 16.0 : 20.0;
            final spacing = isSmallScreen ? 6.0 : 8.0;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: iconIconSize,
                  ),
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ProgressMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final String title;
  final String type;
  final String duration;
  final double progress;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MaterialCard({
    required this.title,
    required this.type,
    required this.duration,
    required this.progress,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type,
                          style: AppTextStyles.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int itemCount;
  final Color color;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.collections_bookmark,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$itemCount items',
              style: AppTextStyles.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





class _ActivityCard extends StatelessWidget {
  final String title;
  final String date;
  final String score;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActivityCard({
    required this.title,
    required this.date,
    required this.score,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              score,
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final String subject;
  final double progress;
  final String status;
  final IconData icon;
  final Color color;

  const _SubjectProgressCard({
    required this.subject,
    required this.progress,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final String title;
  final String level;
  final String duration;
  final int questionCount;
  final String imageUrl;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.title,
    required this.level,
    required this.duration,
    required this.questionCount,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 30,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$level â€¢ $duration â€¢ $questionCount Questions',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
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
