import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show ScrollDirection;
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:pathfitcapstone/core/services/student_progress_service.dart';
import 'package:pathfitcapstone/core/services/firebase_auth_service.dart';
import 'package:pathfitcapstone/core/services/section_service.dart';
import 'package:pathfitcapstone/core/services/module_service.dart';
import 'package:pathfitcapstone/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() => _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  final StudentProgressService _progressService = StudentProgressService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final SectionService _sectionService = SectionService();
  final ModuleService _moduleService = ModuleService();

  bool _isLoading = true;
  int _selectedIndex = 0; // For bottom navigation
  UserModel? _instructorData;
  List<Map<String, dynamic>> _instructorSections = [];

  // Swipe-up refresh state
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;
  static const double _refreshOverscrollThreshold = 80.0; // make gesture harder

  // Real dashboard data computed from Firestore
  Map<dynamic, dynamic> _dashboardData = {
    'activeStudents': 0,
    'averageScore': 0,
    'missed': 0,
    'classProgress': 0,
    'moduleProgress': 0,
    'recentModules': [
      {'name': 'Nutrition Basics', 'completion': 90, 'score': 82},
      {'name': 'Exercise Physiology', 'completion': 100, 'score': 75},
      {'name': 'Health Assessment', 'completion': 85, 'score': 88},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 2));

      // Get current instructor data
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userData = await _authService.getUserData(currentUser.uid);
        if (userData != null) {
          _instructorData = UserModel.fromMap(userData);
          
          // Load instructor's assigned sections
          await _loadInstructorSections();
          
          // Update overall dashboard metrics with real data
          await _updateDashboardMetrics();
        } else {
          throw Exception('Failed to load user data');
        }
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInstructorSections() async {
    try {
      List<Map<String, dynamic>> sections = [];
      
      // Prefer combined assignments: year-level + section + course
      final combos = _instructorData?.assignedYearSectionCourses;
      if (combos != null && combos.isNotEmpty) {
        final seen = <String>{};
        for (final entry in combos) {
          final raw = entry.trim();
          if (raw.isEmpty) continue;
          // Expected format: "<Year Level> <Section> | <Course>"
          final parts = raw.split('|');
          if (parts.length != 2) continue;
          final left = parts[0].trim(); // e.g., "3rd Year A"
          final course = parts[1].trim(); // e.g., "BS Computer Science"

          // Parse year level and section from left side
          final match = RegExp(r'^(.*)\s([A-H])$').firstMatch(left);
          String yearLevel;
          String sectionName;
          if (match != null) {
            yearLevel = match.group(1)!.trim();
            sectionName = match.group(2)!.trim();
          } else {
            // Fallback: last token as section, preceding as year level
            final tokens = left.split(' ');
            sectionName = tokens.isNotEmpty ? tokens.last.trim() : '';
            yearLevel = tokens.length > 1
                ? tokens.sublist(0, tokens.length - 1).join(' ').trim()
                : left;
          }

          final combinedName = '$course - $yearLevel $sectionName';
          if (!seen.add(combinedName)) continue; // de-duplicate

          // Get real student count and average grade for this section
          final sectionData = await _getRealSectionData(course, yearLevel, sectionName);

          sections.add({
            'type': 'combined',
            'name': combinedName,
            'course': course,
            'yearLevel': yearLevel,
            'section': sectionName,
            'students': sectionData['studentCount'],
            'averageGrade': sectionData['averageGrade'],
          });
        }
      } else {
        // No legacy fallback: leave empty so UI prompts assignment
      }
      
      _instructorSections = sections;
    } catch (e) {
      print('Error loading instructor sections: $e');
      _instructorSections = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sections: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _updateDashboardMetrics() async {
    try {
      int totalActiveStudents = 0;
      double totalAverageScore = 0.0;
      int sectionsWithStudents = 0;
      
      // Calculate totals from all sections
      for (final section in _instructorSections) {
        final studentCount = section['students'] is int
            ? section['students'] as int
            : int.tryParse(section['students'].toString()) ?? 0;
        final dynamic avgRaw = section['averageGrade'];
        final double averageGrade = avgRaw is num
            ? avgRaw.toDouble()
            : double.tryParse(avgRaw.toString()) ?? 0.0;
        
        totalActiveStudents += studentCount;
        if (studentCount > 0) {
          totalAverageScore += averageGrade;
          sectionsWithStudents++;
        }
      }
      
      // Calculate overall average
      double overallAverageScore = sectionsWithStudents > 0 
          ? totalAverageScore / sectionsWithStudents 
          : 78.0; // Default fallback
      
      // Update dashboard data with real metrics
      setState(() {
        _dashboardData['activeStudents'] = totalActiveStudents;
        _dashboardData['averageScore'] = overallAverageScore.round();
        _dashboardData['missed'] = totalActiveStudents > 0 ? (totalActiveStudents * 0.15).round() : 6; // Estimate 15% missed
        _dashboardData['classProgress'] = overallAverageScore.round();
        _dashboardData['moduleProgress'] = overallAverageScore.round();
      });
    } catch (e) {
      print('Error updating dashboard metrics: $e');
      // Keep default values if calculation fails
    }
  }

  Future<Map<String, dynamic>> _getRealSectionData(String course, String yearLevel, String sectionName) async {
    try {
      // Query users collection for students matching course, year, and section
      final firestore = FirebaseFirestore.instance;
      
      Query query = firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('course', isEqualTo: course)
          .where('year', isEqualTo: yearLevel)
          .where('section', isEqualTo: sectionName);
      
      final querySnapshot = await query.get();
      
      int studentCount = querySnapshot.docs.length;
      double totalAverageGrade = 0.0;
      int studentsWithGrades = 0;
      
      // Calculate average grade from student progress
      for (final userDoc in querySnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String studentId = userDoc.id;
        
        try {
          // Get student progress data for average grade calculation
          final progress = await StudentProgressService.getStudentProgressData(studentId);
          final double averageProgress = (progress['averageProgress'] ?? 0.0) as double;
          
          if (averageProgress > 0) {
            totalAverageGrade += averageProgress;
            studentsWithGrades++;
          }
        } catch (_) {
          // Skip students without progress data
        }
      }
      
      double averageGrade = studentsWithGrades > 0 
          ? totalAverageGrade / studentsWithGrades 
          : 75.0; // Default if no students have grades
      
      return {
        'studentCount': studentCount,
        'averageGrade': averageGrade.round(),
      };
    } catch (e) {
      print('Error getting real section data: $e');
      // Return default values if query fails
      return {
        'studentCount': 0,
        'averageGrade': 75,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
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
              child: _buildDashboardContent(),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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

      await _loadDashboardData();
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

  Widget _buildDashboardContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Class Performance Overview
            _buildClassPerformanceOverview(),
            const SizedBox(height: 24),
            
            // Class Progress
            _buildClassProgress(),
            const SizedBox(height: 24),
            
            // Recent Modules Uploaded
            _buildRecentModulesUploaded(),
            const SizedBox(height: 24),
            // Your Quizzes (titles only)
            _buildInstructorQuizList(),
            const SizedBox(height: 24),
            
                          // Grading Performance
            _buildGradingPerformance(),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructor Dashboard',
          style: AppTextStyles.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Class Performance Overview',
          style: AppTextStyles.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildClassPerformanceOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildPerformanceCard(
            icon: Icons.school,
            value: _dashboardData['activeStudents'].toString(),
            label: 'Total Students',
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 16),
        // Removed Average Score card as requested
        Expanded(
          child: _buildPerformanceCard(
            icon: Icons.flag,
            value: _dashboardData['missed'].toString(),
            label: 'Missed',
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
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
    );
  }

  Widget _buildClassProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'Class Progress',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular Progress
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: _dashboardData['classProgress'] / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${_dashboardData['classProgress']}%',
                        style: AppTextStyles.textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Progress Bars
              Expanded(
                child: Column(
                  children: [
                    _buildProgressBar(
                      label: 'Module Completion',
                      percentage: _dashboardData['moduleProgress'],
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressBar(
                      label: 'Module Progress',
                      percentage: _dashboardData['moduleProgress'],
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.divider,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildRecentModulesUploaded() {
    final currentUser = _authService.currentUser;
    
    if (currentUser == null) {
      return Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sign in to see your uploaded modules.',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // Debug: Check both collections for instructor modules
    _moduleService.debugInstructorModules(currentUser.uid);
    
    return FutureBuilder<List<Map<dynamic, dynamic>>>(
      future: _moduleService.getInstructorModules(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.errorRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load modules.',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.errorRed),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
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
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final modules = snapshot.data!;
        
        if (modules.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
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
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'No modules uploaded yet',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        // Take only the 5 most recent modules
        final recentModules = modules.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(20),
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
              Text(
                'Recent Modules Uploaded',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...recentModules.map((module) => _buildModuleUploadItem(module)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleUploadItem(Map<dynamic, dynamic> module) {
    final title = module['title'] ?? 'Untitled Module';
    final fileName = module['fileName'] ?? 'Unknown File';
    final uploadDate = module['uploadDate'] != null 
        ? DateTime.tryParse(module['uploadDate'])
        : null;
    final section = module['section'] ?? 'No Section';
    final category = module['category'] ?? 'Uncategorized';
    
    String formattedDate = 'Unknown Date';
    if (uploadDate != null) {
      formattedDate = '${uploadDate.day}/${uploadDate.month}/${uploadDate.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 12),
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
                    '$section • $category',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Uploaded: $formattedDate',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Delete module',
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRed,
                  ),
                  onPressed: () => _confirmDeleteModule(module),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteModule(Map<dynamic, dynamic> module) async {
    final moduleTitle = (module['title'] ?? module['fileName'] ?? 'this module').toString();
    // Prefer moduleId if present (from studentModules fallback), else use id (modules doc id)
    final dynamic rawId = module['moduleId'] ?? module['id'];
    final String? moduleId = rawId?.toString();

    if (moduleId == null || moduleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to delete: missing module ID'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Module'),
              content: Text(
                'Are you sure you want to delete "$moduleTitle"? This will remove the file from storage and delete the module record. This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting module...')),
    );

    final success = await _moduleService.deleteModule(moduleId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "$moduleTitle" successfully.')),
      );
      // Trigger a refresh of the list
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete module. Please try again.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Widget _buildGradingPerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'Grading Performance',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_instructorSections.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No sections or year levels assigned',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact your administrator to get assigned to sections and year levels',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._instructorSections.map((section) => 
              _buildSectionItem(section),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructorQuizList() {
    final currentUser = _authService.currentUser;
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'Your Quizzes',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (currentUser == null) ...[
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sign in to see your quizzes.',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ] else ...[
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('courseQuizzes')
                  .where('instructorId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load quizzes. ',
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
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Icon(Icons.quiz_outlined, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'No quizzes created yet',
                            style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = (data['title'] as String?)?.trim();
                    final topic = (data['topic'] as String?)?.trim();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/instructor-quiz-view',
                            arguments: {'quizId': doc.id},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.quiz_outlined, color: AppColors.primaryBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title?.isNotEmpty == true ? title! : '(Untitled quiz)',
                                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    if (topic != null && topic.isNotEmpty)
                                      Text(
                                        topic,
                                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionItem(Map<dynamic, dynamic> section) {
    // Determine display properties based on section type
    IconData iconData;
    Color iconColor;
    String displayName;
    
    switch (section['type']) {
      case 'combined':
        iconData = Icons.school;
        iconColor = AppColors.primaryBlue;
        displayName = section['name']; // Already formatted as "Computer Science - 3rd Year Section A"
        break;
      case 'course_year_only':
        iconData = Icons.book;
        iconColor = AppColors.primaryBlue;
        displayName = section['name']; // Already formatted as "Computer Science - 3rd Year"
        break;
      case 'course_only':
        iconData = Icons.subject;
        iconColor = AppColors.successGreen;
        displayName = section['name']; // Course name only
        break;
      case 'year_level_only':
        iconData = Icons.school;
        iconColor = AppColors.successGreen;
        displayName = section['name'];
        break;
      case 'section_only':
        iconData = Icons.people;
        iconColor = AppColors.primaryBlue;
        displayName = 'Section ${section['name']}';
        break;
      default:
        iconData = Icons.class_;
        iconColor = AppColors.textSecondary;
        displayName = section['name'];
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${section['students']} students • Avg: ${section['averageGrade']}%',
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/section-students',
                arguments: {
                  'sectionName': section['name'],
                  'courseName': section['course'], // Pass course information
                  'yearLevel': section['yearLevel'],
                  'section': section['section'],
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'View',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Handle navigation
          switch (index) {
            case 0: // Home
              break;
            case 1: // Modules
              Navigator.pushNamed(context, '/module-upload');
              break;
            case 2: // Quiz
              Navigator.pushNamed(context, '/quiz');
              break;
            case 3: // Settings
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.textTheme.bodySmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Modules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

