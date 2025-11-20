import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:pathfitcapstone/core/services/student_progress_service.dart';

class StudentIndividualProgressScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String instructorId;

  const StudentIndividualProgressScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.instructorId,
  });

  @override
  State<StudentIndividualProgressScreen> createState() => _StudentIndividualProgressScreenState();
}

class _StudentIndividualProgressScreenState extends State<StudentIndividualProgressScreen> {
  final StudentProgressService _progressService = StudentProgressService();
  
  bool _isLoading = true;
  Map<dynamic, dynamic>? _progressSummary;
  List<Map<dynamic, dynamic>> _quizActivities = [];
  List<Map<dynamic, dynamic>> _performanceTrends = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentProgress();
  }

  Future<void> _loadStudentProgress() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load progress summary
      _progressSummary = await _progressService.getStudentProgressSummary(
        widget.studentId,
        widget.instructorId,
      );
      
      // Load learning activities
      _quizActivities = await _progressService.getStudentLearningActivities(
        widget.studentId,
        widget.instructorId,
      );
      
      // Load performance trends
      _performanceTrends = await _progressService.getStudentPerformanceTrends(
        widget.studentId,
        widget.instructorId,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load progress: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName}\'s Progress'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudentProgress,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildProgressContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Progress',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStudentProgress,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudentInfoCard(),
          const SizedBox(height: 24),
          _buildProgressSummaryCard(),
          const SizedBox(height: 24),
          _buildPerformanceTrendsCard(),
          const SizedBox(height: 24),
          _buildQuizActivitiesSection(),
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryBlue,
              radius: 40,
              child: Text(
                widget.studentName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(width: 20),
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
                  const SizedBox(height: 8),
                  Text(
                    'Student ID: ${widget.studentId}',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instructor ID: ${widget.instructorId}',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummaryCard() {
    if (_progressSummary == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Summary',
              style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_progressSummary!['progressPercentage'] ?? 0) / 100,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(_progressSummary!['progressPercentage'] ?? 0).toStringAsFixed(1)}%',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Quizzes',
                    '${_progressSummary!['totalQuizzes'] ?? 0}',
                    Icons.quiz,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Average Score',
                    '${(_progressSummary!['averageScore'] ?? 0).toStringAsFixed(1)}%',
                    Icons.analytics,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Grade',
                    _progressSummary!['grade'] ?? 'N/A',
                    Icons.grade,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Score Range
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Highest Score',
                    '${(_progressSummary!['highestScore'] ?? 0).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    color: AppColors.successGreen,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Lowest Score',
                    '${(_progressSummary!['lowestScore'] ?? 0).toStringAsFixed(1)}%',
                    Icons.trending_down,
                    color: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color ?? AppColors.primaryBlue,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: color ?? AppColors.textPrimary,
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
    );
  }

  Widget _buildPerformanceTrendsCard() {
    if (_performanceTrends.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends (Last 30 Days)',
              style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              height: 200,
              child: _buildTrendsChart(),
            ),
            
            const SizedBox(height: 16),
            
            // Trend summary
            Row(
              children: [
                Expanded(
                  child: _buildTrendSummaryItem(
                    'Improvement',
                    _calculateImprovement(),
                    Icons.trending_up,
                    AppColors.successGreen,
                  ),
                ),
                Expanded(
                  child: _buildTrendSummaryItem(
                    'Consistency',
                    _calculateConsistency(),
                    Icons.analytics,
                    AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart() {
    // Simple bar chart for performance trends
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _performanceTrends.asMap().entries.map((entry) {
        int index = entry.key;
        Map<dynamic, dynamic> trend = entry.value;
        double score = (trend['score'] ?? 0).toDouble();
        double height = (score / 100) * 150; // Max height 150
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: _getScoreColor(score),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Q${index + 1}',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTrendSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _calculateImprovement() {
    if (_performanceTrends.length < 2) return 'N/A';
    
    double latest = (_performanceTrends.first['score'] ?? 0).toDouble();
    double earliest = (_performanceTrends.last['score'] ?? 0).toDouble();
    double improvement = latest - earliest;
    
    if (improvement > 0) {
      return '+${improvement.toStringAsFixed(1)}%';
    } else if (improvement < 0) {
      return '${improvement.toStringAsFixed(1)}%';
    } else {
      return '0%';
    }
  }

  String _calculateConsistency() {
    if (_performanceTrends.length < 2) return 'N/A';
    
    double totalVariation = 0;
    for (int i = 1; i < _performanceTrends.length; i++) {
      double current = (_performanceTrends[i]['score'] ?? 0).toDouble();
      double previous = (_performanceTrends[i - 1]['score'] ?? 0).toDouble();
      totalVariation += (current - previous).abs();
    }
    
    double averageVariation = totalVariation / (_performanceTrends.length - 1);
    
    if (averageVariation < 5) return 'High';
    if (averageVariation < 15) return 'Medium';
    return 'Low';
  }

  Widget _buildQuizActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz Activities',
          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_quizActivities.isEmpty)
          _buildEmptyActivitiesWidget()
        else
          ..._quizActivities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildEmptyActivitiesWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Quiz Activities Yet',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This student hasn\'t completed any quizzes yet.',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<dynamic, dynamic> activity) {
    final completedAt = activity['completedAt'] as Timestamp?;
    final percentage = activity['percentage'] ?? 0.0;
    final score = activity['score'] ?? 0.0;
    final maxScore = activity['maxScore'] ?? 1.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activity['title'] ?? 'Unknown Quiz',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(percentage),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Score Details
            Row(
              children: [
                Text(
                  'Score: ${score.toStringAsFixed(1)}/${maxScore.toStringAsFixed(1)} points',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (completedAt != null)
                  Text(
                    _formatDate(completedAt.toDate()),
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(percentage)),
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return AppColors.successGreen;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 70) return AppColors.warningOrange;
    if (percentage >= 60) return Colors.amber;
    return AppColors.errorRed;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}





