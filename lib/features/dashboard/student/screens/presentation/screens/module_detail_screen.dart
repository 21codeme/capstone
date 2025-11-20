import 'package:flutter/material.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String moduleTitle;
  final int currentSection;
  final int totalSections;
  final double progress;

  const ModuleDetailScreen({
    super.key,
    required this.moduleTitle,
    this.currentSection = 4,
    this.totalSections = 9,
    this.progress = 0.45,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  bool _isBookmarked = false;
  double progress = 0.6;
  int currentSection = 3;
  int totalSections = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/student-dashboard', (route) => false);
          },
        ),
        title: Text(
          widget.moduleTitle,
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
              
              // Show feedback message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isBookmarked 
                      ? 'Module bookmarked successfully!' 
                      : 'Module removed from bookmarks'
                  ),
                  backgroundColor: _isBookmarked 
                    ? AppColors.successGreen 
                    : AppColors.textSecondary,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toInt()}% Complete',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$currentSection/$totalSections Sections',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Video Section
            Text(
              'Video Content',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Placeholder background with gradient
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryBlue.withValues(alpha: 0.3),
                          AppColors.accentBlue.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                  // Placeholder content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Movement Patterns',
                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play button overlay
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 30,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Video Info
            Text(
              'Basic Movement Patterns',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '12:45',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        'SJ',
                        style: AppTextStyles.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dr. Sarah Johnson',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Key Learning Points Section
            Text(
              'Key Learning Points',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _LearningPointCard(
              icon: Icons.lightbulb,
              title: 'Understanding the basic principles of human movement',
              color: AppColors.warningOrange,
            ),

            const SizedBox(height: 16),

            _LearningPointCard(
              icon: Icons.psychology,
              title: 'Analyzing movement patterns and their neurological basis',
              color: AppColors.accentBlue,
            ),

            const SizedBox(height: 16),

            _LearningPointCard(
              icon: Icons.directions_run,
              title: 'Applying movement concepts to real-world scenarios',
              color: AppColors.successGreen,
            ),

            const SizedBox(height: 32),

            // Related Content Section
            Text(
              'Related Content',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _RelatedContentCard(
                    title: 'Running Form Analysis',
                    icon: Icons.directions_run,
                    color: AppColors.primaryBlue,
                    onTap: () => Navigator.pushNamed(context, '/module-detail'),
                  ),
                  const SizedBox(width: 16),
                  _RelatedContentCard(
                    title: 'Postural Assessment',
                    icon: Icons.accessibility_new,
                    color: AppColors.successGreen,
                    onTap: () => Navigator.pushNamed(context, '/module-detail'),
                  ),
                  const SizedBox(width: 16),
                  _RelatedContentCard(
                    title: 'Movement Efficiency',
                    icon: Icons.trending_up,
                    color: AppColors.warningOrange,
                    onTap: () => Navigator.pushNamed(context, '/module-detail'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Understanding Basic Movements Text Section
            Text(
              'Understanding Basic Movements',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Movement is a fundamental aspect of human life, encompassing the complex interaction between the nervous system, muscles, and skeletal structure. Understanding basic movements is crucial for ',
                    ),
                    TextSpan(
                      text: 'physical therapy',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ', athletic performance, and daily activities. The study of movement involves analyzing ',
                    ),
                    TextSpan(
                      text: 'kinematics',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' (the study of motion) and ',
                    ),
                    TextSpan(
                      text: 'kinetics',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' (the forces involved in movement). ',
                    ),
                    TextSpan(
                      text: 'Neuromuscular control',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' plays a vital role in coordinating these complex movements efficiently.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Check Understanding Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to understanding check/quiz
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Check Understanding',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Related Topics Section
            Text(
              'Related Topics',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _RelatedTopicCard(
              title: 'Advanced Movement Analysis',
              progress: 0.4,
              totalItems: 5,
              completedItems: 2,
              isCompleted: false,
            ),

            const SizedBox(height: 16),

            _RelatedTopicCard(
              title: 'Biomechanics Fundamentals',
              progress: 0.0,
              totalItems: 5,
              completedItems: 0,
              isCompleted: false,
            ),

            const SizedBox(height: 16),

            _RelatedTopicCard(
              title: 'Motor Control Systems',
              progress: 0.2,
              totalItems: 5,
              completedItems: 1,
              isCompleted: false,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LearningPointCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _LearningPointCard({
    required this.icon,
    required this.title,
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
            child: Text(
              title,
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedContentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RelatedContentCard({
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
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedTopicCard extends StatelessWidget {
  final String title;
  final double progress;
  final int totalItems;
  final int completedItems;
  final bool isCompleted;

  const _RelatedTopicCard({
    required this.title,
    required this.progress,
    required this.totalItems,
    required this.completedItems,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
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
                Text(
                  '$completedItems/$totalItems Complete',
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.check_circle_outline,
            color: isCompleted ? AppColors.successGreen : AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
