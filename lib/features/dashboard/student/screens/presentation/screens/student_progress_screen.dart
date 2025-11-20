import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathfitcapstone/core/services/student_progress_service.dart';
import 'package:pathfitcapstone/core/services/firebase_auth_service.dart';
import 'package:pathfitcapstone/core/services/bmi_service.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:pathfitcapstone/core/widgets/loading_widgets.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  // Services
  final StudentProgressService _progressService = StudentProgressService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final BmiService _bmiService = BmiService();
  
  // Progress data
  double _gradeProgress = 0.0; // Start at 0%
  int _totalActivities = 0;
  int _completedActivities = 0;
  int _weeklyStreak = 0;
  
  // BMI progress data
  double _currentBMI = 0.0;
  double _bmiProgress = 0.0;
  bool _isLoadingBMI = true;
  
  // Quiz activities from studentScores
  List<Map<dynamic, dynamic>> _quizActivities = [];
  bool _isLoadingQuizActivities = false;
  
  // Real-time progress tracking
  final List<Map<String, dynamic>> _activityCompletions = []; // Store activity completions
  final double _targetGradeProgress = 100.0; // Target for semester end
  
  final int _totalMonths = 5; // 5 months in a semester
  int _currentMonth = 0; // Current month (0-4)
  double _semesterProgress = 0.0; // Semester-based progress
  
  @override
  void initState() {
    super.initState();
    // Initialize with current month based on semester timeline
    _currentMonth = DateTime.now().month - 8; // Assuming semester starts in August
    if (_currentMonth < 0 || _currentMonth >= _totalMonths) {
      _currentMonth = 0; // Default to first month if out of range
    }
    
    // Initialize progress
    
    // Load BMI data and progress
    _loadBMIProgress();
    
    // Load quiz activities from studentScores
    _loadQuizActivities();
  }
  
  void _loadProgressData() {
    // Start with zero progress - will be updated in real-time
    setState(() {
      _gradeProgress = 0.0; // Start at 0%
      _totalActivities = 0;
      _completedActivities = 0;
      _weeklyStreak = 0;
      _currentMonth = 0;
    });
  }

  /// Load BMI progress data from Firebase
  Future<void> _loadBMIProgress() async {
    try {
      setState(() {
        _isLoadingBMI = true;
      });

      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Calculate BMI progress using the same logic as dashboard
        const double targetBMI = 22.0; // Healthy target

        // Fetch current BMI
        final latestBmiDoc = await _bmiService.getLatestBmiData();
        final double currentBMI = (latestBmiDoc?['bmi'] as num?)?.toDouble() ?? 0.0;

        // Fetch history to get baseline (earliest record)
        final bmiHistory = await _bmiService.getBmiHistory();
        double baselineBMI = currentBMI;
        if (bmiHistory.isNotEmpty) {
          // getBmiHistory returns descending by timestamp, earliest is last
          final Map<dynamic, dynamic> earliest = bmiHistory.last;
          final double earliestBmi = (earliest['bmi'] as num?)?.toDouble() ?? currentBMI;
          baselineBMI = earliestBmi;
        }

        double bmiProgress = 0.0;
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

        if (mounted) {
          setState(() {
            _currentBMI = currentBMI;
            _bmiProgress = bmiProgress;
            _isLoadingBMI = false;
          });
        }
      } else {
        setState(() {
          _isLoadingBMI = false;
        });
      }
    } catch (e) {
      print('⚠️ Error loading BMI progress: $e');
      if (mounted) {
        setState(() {
          _isLoadingBMI = false;
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

        if (mounted) {
          setState(() {
            _quizActivities = activities;
            _isLoadingQuizActivities = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _quizActivities = [];
            _isLoadingQuizActivities = false;
          });
        }
      }
    } catch (e) {
      print('âŒ Error loading quiz activities: $e');
      if (mounted) {
        setState(() {
          _quizActivities = [];
          _isLoadingQuizActivities = false;
        });
      }
    }
  }

  /// Get color based on score percentage
  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return AppColors.successGreen;
    if (percentage >= 80) return AppColors.primaryBlue;
    if (percentage >= 70) return AppColors.warningOrange;
    return AppColors.errorRed;
  }

  /// Format date for display
  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
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

  /// Public method to update progress when an activity is completed
  /// Call this method from activity completion screens
  void onActivityCompleted({String? activityType, double? activityScore, int? maxScore}) {
    // Store activity completion data
    final activityData = {
      'type': activityType ?? 'general',
      'score': activityScore ?? 100.0,
      'maxScore': maxScore ?? 100.0,
      'percentage': activityScore != null && maxScore != null ? (activityScore / maxScore) * 100.0 : 100.0,
      'timestamp': DateTime.now(),
      'activityNumber': _completedActivities + 1,
    };
    
    _activityCompletions.add(activityData);
    
    setState(() {
      _completedActivities++;
      _totalActivities = _totalActivities == 0 ? 10 : _totalActivities;
      
      // Update weekly streak (simplified logic)
      if (_weeklyStreak < 7) {
        _weeklyStreak++;
      }
    });
    
    print('Activity completed: ${activityData['type']} - ${(activityData['percentage'] as double).toStringAsFixed(0)}%');
    print('Total Activities: $_completedActivities/$_totalActivities');
    print('New Grade Progress: ${_gradeProgress.toStringAsFixed(1)}%');
    
    // Show progress update notification
    _showProgressUpdate('Activity completed! +${(activityData['percentage'] as double).toStringAsFixed(0)}% to progress');
    
    // Reload quiz activities to reflect the new completion
    _loadQuizActivities();
  }
  

  

  
  /// Show progress update notification
  void _showProgressUpdate(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  

  

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                              AppColors.primaryBlue.withOpacity(0.2),
                          ),
                        ),
                        ),
                        // Progress Circle
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _gradeProgress / 100,
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
                            '${_gradeProgress.round()}%',
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
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            Text(
              'Completed Quiz Topics',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
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

                final completedIds = _quizActivities
                    .where((a) {
                      final p = (a['percentage'] is num) ? (a['percentage'] as num).toDouble() : 0.0;
                      return p >= 60.0;
                    })
                    .map((a) => a['quizId']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toSet();

                final movementQuizzes = [
                  {'id': 'intro_basic_movements_day1', 'label': 'Day 1'},
                  {'id': 'movement_relative_center_day2', 'label': 'Day 2'},
                  {'id': 'specialized_movements_day3', 'label': 'Day 3'},
                  {'id': 'anatomical_planes_day4', 'label': 'Day 4'},
                  {'id': 'movement_review_day5', 'label': 'Day 5'},
                  {'id': 'final_quiz_human_movement', 'label': 'Final'},
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
                    final String label = item['label'] as String;
                    return Container(
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
                            label,
                            style: AppTextStyles.textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (label == 'Understanding Movements') ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final q in movementQuizzes) ...[
                                  Builder(
                                    builder: (context) {
                                      final bool done = completedIds.contains(q['id']);
                                      final Color chipColor = done ? AppColors.successGreen : AppColors.divider;
                                      final Color textColor = done ? AppColors.successGreen : AppColors.textSecondary;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: done ? AppColors.successGreen.withOpacity(0.08) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: chipColor),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: textColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              q['label'] as String,
                                              style: AppTextStyles.textTheme.bodySmall?.copyWith(color: textColor),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ] else ...[
                            Text(
                              'No quizzes yet',
                              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),
            
            // Summary Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.check_circle,
                    value: '$_completedActivities',
                    label: 'Completed',
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.local_fire_department,
                    value: '$_weeklyStreak days',
                    label: 'Streak',
                    color: AppColors.warningOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.school,
                    value: '${_gradeProgress.round()}%',
                    label: 'Grade',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBMIMetricCard(
                    currentBMI: _currentBMI,
                    targetBMI: 22.0,
                    isLoading: _isLoadingBMI,
                    onTap: () => _showBMIDetails(context),
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
            
            // Quiz attempts from studentScores
            if (_isLoadingQuizActivities)
              Center(child: ModernLoadingWidget())
            else if (_quizActivities.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No quiz attempts yet',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete some quizzes to see your progress here',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ..._quizActivities.map((activity) {
                final double percentage = (activity['percentage'] ?? 0.0) as double;
                final double score = (activity['score'] ?? 0.0) as double;
                final double maxScore = (activity['maxScore'] ?? 0.0) as double;
                final String status = activity['status']?.toString() ?? 'submitted';
                final Color scoreColor = _getScoreColor(percentage);
                
                final dynamic completedAt = activity['completedAt'];
                DateTime? completedDate;
                if (completedAt is Timestamp) {
                  completedDate = completedAt.toDate();
                } else if (completedAt is String) {
                  completedDate = DateTime.tryParse(completedAt);
                }
                final String dateLabel = _formatDate(completedDate);

                return Column(
                  children: [
                    _buildActivityCard(
                      title: activity['title']?.toString() ?? 'Quiz',
                      status: status,
                      timestamp: dateLabel,
                      score: '${score.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)}',
                      percentage: '${percentage.round()}%',
                      icon: Icons.assignment,
                      statusColor: scoreColor,
                      onTap: () => _showActivityDetails(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
            
            const SizedBox(height: 32),
            
            // Recent Activities Section
            Text(
              'Recent Activities',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent learning activities from completions
            if (_activityCompletions.isEmpty)
              Text(
                'Complete some activities to see them here',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else ...[
              ..._activityCompletions.take(5).map((activity) {
                final double percentage = (activity['percentage'] ?? 100.0) as double;
                final Color scoreColor = _getScoreColor(percentage);
                
                return Column(
                  children: [
                    _buildActivityCard(
                      title: 'Activity ${activity['activityNumber']}',
                      status: 'Completed',
                      timestamp: _formatDate(activity['timestamp'] as DateTime?),
                      score: '${percentage.round()}%',
                      percentage: '${percentage.round()}%',
                      icon: Icons.check_circle,
                      statusColor: scoreColor,
                      onTap: () => _showActivityDetails(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
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
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBMIMetricCard({
    required double currentBMI,
    required double targetBMI,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    final String category = _getBMICategory(currentBMI);
    final Color categoryColor = _getBMICategoryColor(currentBMI);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_weight,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current BMI: ${isLoading ? '...' : (currentBMI > 0 ? currentBMI.toStringAsFixed(1) : '—')}',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLoading || currentBMI <= 0 ? AppColors.primaryBlue : categoryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLoading ? 'Loading' : category,
                    style: AppTextStyles.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current BMI',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? '...' : (currentBMI > 0 ? currentBMI.toStringAsFixed(1) : '—'),
                      style: AppTextStyles.textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target BMI',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      targetBMI.toStringAsFixed(1),
                      style: AppTextStyles.textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_bmiProgress.round()}%',
                      style: AppTextStyles.textTheme.titleLarge?.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String status,
    required String timestamp,
    required String score,
    required String percentage,
    required IconData icon,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: statusColor,
              size: 24,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Score: $score',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'â€¢',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Percentage: $percentage',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timestamp,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              status,
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showActivityDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This is a sample activity for demonstration purposes.'),
            const SizedBox(height: 8),
            const Text('In a real application, this would show detailed activity information.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi <= 0) return 'No data';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMICategoryColor(double bmi) {
    if (bmi <= 0) return AppColors.primaryBlue;
    if (bmi < 18.5) return AppColors.warningOrange;
    if (bmi < 25) return AppColors.successGreen;
    if (bmi < 30) return AppColors.warningOrange;
    return AppColors.errorRed;
  }

  void _showBMIDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.monitor_weight, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            const Text('BMI Progress Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentBMI > 0) ...[
              Text('Current BMI: ${_currentBMI.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              Text('Progress to Target: ${_bmiProgress.toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Target BMI: 22.0 (Healthy range)'),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _bmiProgress / 100,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                minHeight: 8,
              ),
            ] else ...[
              const Text('No BMI data available yet.'),
              const SizedBox(height: 8),
              const Text('Update your BMI in the BMI Tracking section to see your progress.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
