import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:pathfitcapstone/core/services/student_progress_service.dart';
import 'instructor_quiz_review_screen.dart';

class GradeStudentScreen extends StatefulWidget {
  final String studentName;
  final String studentId;
  final String course;
  
  const GradeStudentScreen({
    super.key, 
    required this.studentName,
    required this.studentId,
    required this.course,
  });

  @override
  State<GradeStudentScreen> createState() => _GradeStudentScreenState();
}

class _GradeStudentScreenState extends State<GradeStudentScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _pointsEarnedController = TextEditingController();
  final TextEditingController _totalPointsController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // Real student scores data
  List<Map<dynamic, dynamic>> _activities = [];
  bool _isLoadingActivities = true;

  Map<dynamic, dynamic> _gradeStats = {};
  bool _isLoadingStats = true;

  List<Map<dynamic, dynamic>> _recentActivity = [];
  bool _isLoadingRecentActivity = true;

  @override
  void initState() {
    super.initState();
    _pointsEarnedController.text = '85';
    _totalPointsController.text = '100';
    _loadStudentScores();
    _calculateGradeStats();
    _loadRecentActivity();
  }

  Future<void> _loadStudentScores() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Query studentScores collection for this specific student
      final querySnapshot = await firestore
          .collection('studentScores')
          .where('studentId', isEqualTo: widget.studentId)
          .where('course', isEqualTo: widget.course)
          .orderBy('submittedAt', descending: true)
          .get();

      List<Map<dynamic, dynamic>> activities = [];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Format the activity data to match the expected structure
        activities.add({
          'title': data['quizTitle'] ?? 'Quiz Activity',
          'date': _formatDate(data['submittedAt']),
          'score': data['score'] ?? 0,
          'total': data['maxScore'] ?? 100,
          'status': _getStatusText(data['status'], data['passed']),
          'statusColor': _getStatusColor(data['status'], data['passed']),
          'quizId': data['quizId'],
          'percentage': data['percentage'] ?? 0,
          'timeTakenMinutes': data['timeTakenMinutes'] ?? 0,
        });
      }

      setState(() {
        _activities = activities;
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('❌ Error loading student scores: $e');
      setState(() {
        _isLoadingActivities = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else {
      return 'Unknown Date';
    }
    
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getStatusText(String? status, bool? passed) {
    if (status == 'submitted') return 'Submitted';
    if (status == 'pending') return 'Pending';
    if (passed == true) return 'Passed';
    if (passed == false) return 'Failed';
    return 'Pending';
  }

  Color _getStatusColor(String? status, bool? passed) {
    if (status == 'submitted') return Colors.green;
    if (passed == true) return Colors.green;
    if (passed == false) return Colors.red;
    return Colors.orange;
  }

  Future<void> _loadRecentActivity() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Query studentScores collection for recent activities
      final querySnapshot = await firestore
          .collection('studentScores')
          .where('studentId', isEqualTo: widget.studentId)
          .where('course', isEqualTo: widget.course)
          .orderBy('submittedAt', descending: true)
          .limit(5)
          .get();

      List<Map<dynamic, dynamic>> activities = [];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['submittedAt'];
        
        activities.add({
          'action': 'Quiz completed: ${data['quizTitle'] ?? 'Quiz'}',
          'date': _formatDateTime(timestamp),
          'score': '${data['score'] ?? 0}/${data['maxScore'] ?? 100}',
          'quizId': data['quizId'], // Add quizId for navigation
        });
      }

      setState(() {
        _recentActivity = activities;
        _isLoadingRecentActivity = false;
      });
    } catch (e) {
      print('❌ Error loading recent activity: $e');
      setState(() {
        _isLoadingRecentActivity = false;
      });
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else {
      return 'Unknown Date';
    }
    
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '${_getMonthName(date.month)} ${date.day}, ${date.year} at $hour:$minute $period';
  }

  Future<void> _calculateGradeStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Query studentScores collection for this specific student
      final querySnapshot = await firestore
          .collection('studentScores')
          .where('studentId', isEqualTo: widget.studentId)
          .where('course', isEqualTo: widget.course)
          .where('status', isEqualTo: 'submitted')
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _gradeStats = {
            'classAverage': 0,
            'highestGrade': 0,
            'lowestGrade': 0,
            'yourGrade': 0,
          };
          _isLoadingStats = false;
        });
        return;
      }

      List<double> percentages = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final percentage = (data['percentage'] ?? 0).toDouble();
        percentages.add(percentage);
      }

      percentages.sort();
      final average = percentages.reduce((a, b) => a + b) / percentages.length;
      
      setState(() {
        _gradeStats = {
          'classAverage': average.round(),
          'highestGrade': percentages.last.round(),
          'lowestGrade': percentages.first.round(),
          'yourGrade': average.round(),
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      print('❌ Error calculating grade stats: $e');
      setState(() {
        _gradeStats = {
          'classAverage': 0,
          'highestGrade': 0,
          'lowestGrade': 0,
          'yourGrade': 0,
        };
        _isLoadingStats = false;
      });
    }
  }

  @override
  void dispose() {
    _pointsEarnedController.dispose();
    _totalPointsController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Profile Card
                    _buildStudentProfileCard(),
                    const SizedBox(height: 24),
                    
                    // Navigation Tabs
                    _buildNavigationTabs(),
                    const SizedBox(height: 24),
                    
                    // Content based on selected tab
                    if (_selectedTabIndex == 0) _buildActivitiesTab(),
                    if (_selectedTabIndex == 1) _buildQuizzesTab(),
                    if (_selectedTabIndex == 2) _buildAssignmentsTab(),
                    if (_selectedTabIndex == 3) _buildProjectsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Grade Student',
              style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Student selector dropdown
          Row(
            children: [
              Text(
                widget.studentName,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Profile Picture
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              widget.studentName[0].toUpperCase(),
              style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.studentId}',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.course,
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
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

  Widget _buildNavigationTabs() {
    final tabs = ['Activities'];
    
    return Row(
      children: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        final isSelected = _selectedTabIndex == index;
        
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab,
                textAlign: TextAlign.center,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitiesTab() {
    // Reordered content:
    // - Remove per-activity cards display
    // - Move Recent Activity to the top area
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent Activity moved to top position
        _buildRecentActivity(),
        const SizedBox(height: 32),
        
        // Grade Input Section
        _buildGradeInputSection(),
        const SizedBox(height: 32),
        
        // Grade Statistics
        _buildGradeStatistics(),
      ],
    );
  }

  Widget _buildActivityItem(Map<dynamic, dynamic> activity) {
    final progress = activity['score'] / activity['total'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'],
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
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
                          activity['date'],
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${activity['score']}/${activity['total']}',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['status'],
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: activity['statusColor'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              activity['status'] == 'Graded' ? AppColors.primaryBlue : AppColors.divider,
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Grade Input',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Points Input Fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points Earned',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pointsEarnedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Points',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalPointsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Comments Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add your comments here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Save Grade Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement save grade functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Grade saved successfully!'),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save Grade',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeStatistics() {
    if (_isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_gradeStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No grade statistics available',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some quizzes to see your statistics',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Text(
                'Grade Statistics',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.bar_chart,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Class Average',
                  value: '${_gradeStats['classAverage']}%',
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Highest Grade',
                  value: '${_gradeStats['highestGrade']}%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Lowest Grade',
                  value: '${_gradeStats['lowestGrade']}%',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Your Grade',
                  value: '${_gradeStats['yourGrade']}%',
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTextStyles.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoadingRecentActivity) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_recentActivity.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity found',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some quizzes to see your activity',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Recent Activity',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._recentActivity.map((activity) => _buildActivityLogItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityLogItem(Map<dynamic, dynamic> activity) {
    final quizId = activity['quizId'] as String?;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: quizId != null
              ? () => _navigateToQuizReview(quizId)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['action'],
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      activity['date'],
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    activity['score'],
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (quizId != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQuizReview(String quizId) async {
    // Navigate to instructor quiz review screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstructorQuizReviewScreen(
          quizId: quizId,
          studentId: widget.studentId,
          studentName: widget.studentName,
        ),
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return Center(
      child: Text(
        'Quizzes tab content coming soon...',
        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Center(
      child: Text(
        'Assignments tab content coming soon...',
        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProjectsTab() {
    return Center(
      child: Text(
        'Projects tab content coming soon...',
        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

